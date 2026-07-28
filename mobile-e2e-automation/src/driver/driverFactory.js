'use strict';

const { remote } = require('webdriverio');
const { execSync } = require('child_process');
const fs = require('fs');
const env = require('../../config/env.config');
const { flutterCapabilities, uiAutomator2Capabilities, serverOptions } = require('../../config/appium.config');
const deviceDetector = require('../utils/deviceDetector');
const logger = require('../utils/logger');

class DriverFactory {
  constructor() {
    this.driver = null;
    this.currentContext = 'FLUTTER';
    this.deviceInfo = null;
  }

  /**
   * Initializes Appium session and verifies APK installation
   */
  async createDriver(automationType = 'Flutter') {
    logger.info(`Initializing Appium 2.x session with driver: ${automationType}`);

    // Auto-detect connected device
    this.deviceInfo = deviceDetector.getConnectedDevice();
    
    // Check APK existence and install automatically
    this.ensureApkInstalled();

    const selectedCaps = automationType === 'Flutter' ? flutterCapabilities : uiAutomator2Capabilities;
    
    // Override caps with detected device info
    selectedCaps['appium:udid'] = this.deviceInfo.udid;
    selectedCaps['appium:deviceName'] = this.deviceInfo.deviceName;
    selectedCaps['appium:platformVersion'] = this.deviceInfo.platformVersion;

    const options = {
      ...serverOptions,
      capabilities: selectedCaps
    };

    try {
      this.driver = await remote(options);
      this.currentContext = automationType;
      logger.info(`Appium session successfully launched! Session ID: ${this.driver.sessionId}`);
      
      if (automationType === 'Flutter') {
        // Re-assert setFrameSync(false) with retries — the Flutter isolate may
        // not be fully ready the moment the session is created. Retrying ensures
        // the setting takes effect before the first test command is sent.
        let frameSyncDisabled = false;
        for (let attempt = 1; attempt <= 5; attempt++) {
          try {
            await this.driver.execute('flutter:setFrameSync', false, 1000);
            logger.info(`Flutter frame sync disabled (attempt ${attempt}).`);
            frameSyncDisabled = true;
            break;
          } catch (syncErr) {
            logger.warn(`setFrameSync attempt ${attempt}/5 failed: ${syncErr.message}. Retrying in 1s...`);
            await new Promise(r => setTimeout(r, 1000));
          }
        }
        if (!frameSyncDisabled) {
          logger.warn('Could not disable Flutter frame sync after 5 attempts. Continuing anyway.');
        }
      }
      return this.driver;
    } catch (error) {
      logger.error(`Failed to launch Appium session with ${automationType}: ${error.message}`);
      if (automationType === 'Flutter') {
        logger.warn('⚠️ Flutter VM Service connection timed out. Seamlessly falling back to UiAutomator2 driver session...');
        return await this.createDriver('UiAutomator2');
      }
      throw error;
    }
  }

  /**
   * Verifies APK exists and installs it automatically via ADB if needed
   */
  ensureApkInstalled() {
    if (!fs.existsSync(env.apkPath)) {
      logger.warn(`APK file not found at: ${env.apkPath}. Will rely on Appium remote installation or existing app.`);
      return;
    }

    try {
      const checkInstalled = execSync(`adb -s ${this.deviceInfo.udid} shell pm list packages ${env.appPackage}`, { encoding: 'utf8' });
      if (!checkInstalled.includes(env.appPackage)) {
        logger.info(`App ${env.appPackage} is not installed on device ${this.deviceInfo.udid}. Installing APK...`);
        execSync(`adb -s ${this.deviceInfo.udid} install -r "${env.apkPath}"`, { encoding: 'utf8' });
        logger.info('APK installed successfully!');
      } else {
        logger.info(`App ${env.appPackage} is already installed on device ${this.deviceInfo.udid}.`);
      }
    } catch (err) {
      logger.warn(`ADB installation check failed: ${err.message}. Appium will attempt automatic install.`);
    }
  }

  /**
   * Switches driver context between FLUTTER and NATIVE_APP (UiAutomator2)
   */
  async switchContext(contextName) {
    if (!this.driver) {
      throw new Error('Driver instance is not initialized.');
    }

    logger.info(`Switching driver context to: ${contextName}`);
    try {
      if (typeof this.driver.switchContext === 'function') {
        await this.driver.switchContext(contextName);
      } else {
        await this.driver.execute('flutter:setContext', contextName);
      }
      this.currentContext = contextName;
      logger.info(`Successfully switched context to ${contextName}`);
    } catch (error) {
      logger.warn(`Context switch notice: ${error.message}. Continuing execution.`);
    }
  }

  /**
   * Retrieves active driver instance
   */
  getDriver() {
    if (!this.driver) {
      throw new Error('Driver instance has not been initialized. Call createDriver() first.');
    }
    return this.driver;
  }

  /**
   * Teardown active session
   */
  async quitDriver() {
    if (this.driver) {
      logger.info(`Closing Appium session ID: ${this.driver.sessionId}`);
      try {
        let timer;
        const deletePromise = this.driver.deleteSession();
        const timeoutPromise = new Promise((_, reject) => {
          timer = setTimeout(() => reject(new Error('deleteSession timed out after 10000ms')), 10000);
        });
        await Promise.race([deletePromise, timeoutPromise]).finally(() => clearTimeout(timer));
      } catch (err) {
        logger.warn(`Error terminating session: ${err.message}`);
      } finally {
        this.driver = null;
      }
    }
  }
}

module.exports = new DriverFactory();
