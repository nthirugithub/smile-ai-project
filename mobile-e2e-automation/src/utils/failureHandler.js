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
   * Captures full diagnostics on test failure
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
      currentContext: 'Unknown'
    };

    if (!driver) {
      logger.warn('Driver instance unavailable for failure screenshot/logs capture.');
      return diagnostics;
    }

    // 1. Capture Screenshot
    try {
      const screenshotBase64 = await driver.takeScreenshot();
      fs.writeFileSync(screenshotPath, Buffer.from(screenshotBase64, 'base64'));
      diagnostics.screenshotPath = screenshotPath;
      logger.info(`📸 Screenshot captured: ${screenshotPath}`);
    } catch (err) {
      logger.error(`Failed to capture screenshot: ${err.message}`);
    }

    // 2. Capture Device Logs (logcat)
    try {
      let logcatData = '';
      if (typeof driver.getLogs === 'function') {
        const logs = await driver.getLogs('logcat');
        logcatData = logs.map(l => `[${l.timestamp}] ${l.level}: ${l.message}`).join('\n');
      } else {
        logcatData = execSync(`adb -s ${env.udid} logcat -d *:E`, { encoding: 'utf8' });
      }
      fs.writeFileSync(logcatPath, logcatData);
      diagnostics.logcatPath = logcatPath;
      logger.info(`📋 Device logcat captured: ${logcatPath}`);
    } catch (err) {
      logger.warn(`Could not extract logcat logs: ${err.message}`);
    }

    // 3. Capture Flutter Widget Tree Dump
    try {
      const widgetTree = await driver.execute('flutter:getRenderTree');
      fs.writeFileSync(widgetTreePath, typeof widgetTree === 'string' ? widgetTree : JSON.stringify(widgetTree, null, 2));
      diagnostics.widgetTreePath = widgetTreePath;
      logger.info(`🌳 Flutter widget tree dump captured: ${widgetTreePath}`);
    } catch (err) {
      logger.debug(`Flutter render tree dump not supported or context unavailable: ${err.message}`);
    }

    // 4. Capture Current Activity
    try {
      diagnostics.currentActivity = await driver.getCurrentActivity();
    } catch (err) {
      try {
        diagnostics.currentActivity = execSync(`adb -s ${env.udid} shell "dumpsys window | grep mCurrentFocus"`, { encoding: 'utf8' }).trim();
      } catch (e) {
        diagnostics.currentActivity = 'UnknownActivity';
      }
    }

    // Save summary JSON
    fs.writeFileSync(summaryPath, JSON.stringify(diagnostics, null, 2));
    return diagnostics;
  }
}

module.exports = new FailureHandler();
