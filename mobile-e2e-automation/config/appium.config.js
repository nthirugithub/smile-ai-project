'use strict';

const env = require('./env.config');

const flutterCapabilities = {
  platformName: env.platformName,
  'appium:platformVersion': env.platformVersion,
  'appium:deviceName': env.deviceName,
  'appium:udid': env.udid,
  'appium:automationName': 'Flutter',
  'appium:app': env.apkPath,
  'appium:appPackage': env.appPackage,
  'appium:appActivity': env.appActivity,
  'appium:autoGrantPermissions': true,
  'appium:noReset': false,
  'appium:fullReset': false,
  'appium:newCommandTimeout': 300,
  'appium:adbExecTimeout': 60000,
  'appium:retryBackoff': 1000,
  'appium:maxRetryCount': 3
};

const uiAutomator2Capabilities = {
  platformName: env.platformName,
  'appium:platformVersion': env.platformVersion,
  'appium:deviceName': env.deviceName,
  'appium:udid': env.udid,
  'appium:automationName': 'UiAutomator2',
  'appium:app': env.apkPath,
  'appium:appPackage': env.appPackage,
  'appium:appActivity': env.appActivity,
  'appium:autoGrantPermissions': true,
  'appium:noReset': true,
  'appium:newCommandTimeout': 300
};

module.exports = {
  flutterCapabilities,
  uiAutomator2Capabilities,
  serverOptions: {
    hostname: env.appiumHost,
    port: env.appiumPort,
    path: '/'
  }
};
