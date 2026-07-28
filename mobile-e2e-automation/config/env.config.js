'use strict';

const path = require('path');
require('dotenv').config();

const ROOT_DIR = path.resolve(__dirname, '..');

module.exports = {
  // App settings
  apkPath: process.env.APK_PATH || path.join(ROOT_DIR, 'app', 'app-release.apk'),
  appPackage: process.env.APP_PACKAGE || 'com.example.smile_analysis',
  appActivity: process.env.APP_ACTIVITY || 'com.example.smile_analysis.MainActivity',

  // Device & Platform Config
  platformName: process.env.PLATFORM_NAME || 'Android',
  platformVersion: process.env.PLATFORM_VERSION || '13.0',
  deviceName: process.env.DEVICE_NAME || 'Android Emulator',
  udid: process.env.UDID || 'emulator-5554',
  automationName: process.env.AUTOMATION_NAME || 'Flutter',

  // Appium Server Config
  appiumHost: process.env.APPIUM_HOST || '127.0.0.1',
  appiumPort: parseInt(process.env.APPIUM_PORT || '4723', 10),

  // Test Runner Controls
  retries: parseInt(process.env.TEST_RETRIES || '2', 10),
  implicitWaitMs: parseInt(process.env.IMPLICIT_WAIT_MS || '10000', 10),
  explicitWaitMs: parseInt(process.env.EXPLICIT_WAIT_MS || '20000', 10),

  // Output paths
  reportsDir: path.join(ROOT_DIR, 'reports'),
  failuresDir: path.join(ROOT_DIR, 'reports', 'failures'),
  logsDir: path.join(ROOT_DIR, 'logs'),
  excelReportPath: path.join(ROOT_DIR, 'reports', 'Flutter_E2E_Report.xlsx')
};
