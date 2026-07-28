'use strict';

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const env = require('../../config/env.config');
const logger = require('./logger');

class FailureHandler {
  constructor() {
    if (!fs.existsSync(env.failuresDir)) {
      fs.mkdirSync(env.failuresDir, { recursive: true });
    }
  }

  /**
   * Helper to execute an async promise with a strict timeout guard
   */
  async withTimeout(promise, timeoutMs = 5000, label = 'Operation') {
    let timer;
    const timeoutPromise = new Promise((_, reject) => {
      timer = setTimeout(() => reject(new Error(`${label} timed out after ${timeoutMs}ms`)), timeoutMs);
    });
    try {
      const result = await Promise.race([promise, timeoutPromise]);
      return result;
    } finally {
      clearTimeout(timer);
    }
  }

  /**
   * Logs active Node.js event loop handles and requests
   */
  logActiveHandles() {
    if (typeof process._getActiveHandles === 'function') {
      const handles = process._getActiveHandles();
      logger.info(`🔍 Active Node.js handles count: ${handles.length}`);
    }
    if (typeof process._getActiveRequests === 'function') {
      const reqs = process._getActiveRequests();
      logger.info(`🔍 Active Node.js requests count: ${reqs.length}`);
    }
  }

  /**
   * Captures full diagnostics on test failure with strict non-blocking timeout guards
   * @param {Object} driver WebdriverIO / Appium driver instance
   * @param {string} testTitle Name of failing test case
   * @param {Error} error Stack trace & failure error
   */
  async captureFailureDiagnostics(driver, testTitle, error) {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const sanitizedTitle = testTitle.replace(/[^a-zA-Z0-9_-]/g, '_');
    const prefix = `Failure_${sanitizedTitle}_${timestamp}`;

    const screenshotPath = path.join(env.failuresDir, `${prefix}.png`);
    const logcatPath = path.join(env.failuresDir, `${prefix}_logcat.log`);
    const widgetTreePath = path.join(env.failuresDir, `${prefix}_widgetTree.json`);
    const summaryPath = path.join(env.failuresDir, `${prefix}_summary.json`);

    logger.error(`🚨 Failure detected in test: "${testTitle}"`);
    logger.error(`Error details: ${error ? error.message : 'Unknown error'}`);

    const diagnostics = {
      testTitle,
      timestamp: new Date().toISOString(),
      errorName: error ? error.name : 'Error',
      errorMessage: error ? error.message : 'Unknown error',
      stackTrace: error ? error.stack : 'No stack trace available',
      screenshotPath: null,
      logcatPath: null,
      widgetTreePath: null,
      currentActivity: 'Unknown',
      currentContext: 'FLUTTER'
    };

    // 1. Capture Screenshot via ADB screencap (avoids driver context switching)
    try {
      const targetUdid = env.udid || 'emulator-5554';
      execSync(`adb -s ${targetUdid} shell screencap -p /sdcard/failure_shot.png`, { encoding: 'utf8', timeout: 5000 });
      execSync(`adb -s ${targetUdid} pull /sdcard/failure_shot.png "${screenshotPath}"`, { encoding: 'utf8', timeout: 5000 });
      diagnostics.screenshotPath = screenshotPath;
      logger.info(`📸 ADB screenshot captured: ${screenshotPath}`);
    } catch (adbErr) {
      logger.warn(`ADB screenshot capture notice: ${adbErr.message}`);
    }

    // 2. Capture Device Logs (logcat via ADB - 5s timeout)
    try {
      const targetUdid = env.udid || 'emulator-5554';
      const logcatData = execSync(`adb -s ${targetUdid} logcat -d *:E`, { encoding: 'utf8', timeout: 5000 });
      fs.writeFileSync(logcatPath, logcatData);
      diagnostics.logcatPath = logcatPath;
      logger.info(`📋 Device logcat captured: ${logcatPath}`);
    } catch (err) {
      logger.warn(`Could not extract logcat logs via ADB: ${err.message}`);
    }

    // 3. Capture Flutter Widget Tree Dump (5s timeout - non-blocking)
    if (driver) {
      try {
        const widgetTree = await this.withTimeout(driver.execute('flutter:getRenderTree'), 5000, 'flutter:getRenderTree');
        fs.writeFileSync(widgetTreePath, typeof widgetTree === 'string' ? widgetTree : JSON.stringify(widgetTree, null, 2));
        diagnostics.widgetTreePath = widgetTreePath;
        logger.info(`🌳 Flutter widget tree dump captured: ${widgetTreePath}`);
      } catch (err) {
        logger.debug(`Flutter render tree dump skipped/timed out: ${err.message}`);
      }
    }

    // 4. Capture Current Activity (3s timeout)
    try {
      const targetUdid = env.udid || 'emulator-5554';
      diagnostics.currentActivity = execSync(`adb -s ${targetUdid} shell "dumpsys window | grep mCurrentFocus"`, { encoding: 'utf8', timeout: 3000 }).trim();
    } catch (err) {
      diagnostics.currentActivity = 'UnknownActivity';
    }

    // Save summary JSON
    try {
      fs.writeFileSync(summaryPath, JSON.stringify(diagnostics, null, 2));
    } catch (e) {
      // ignore
    }

    this.logActiveHandles();
    return diagnostics;
  }
}

module.exports = new FailureHandler();
