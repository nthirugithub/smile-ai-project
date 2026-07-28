'use strict';

const { expect } = require('chai');
const driverFactory = require('../../src/driver/driverFactory');
const HomePage = require('../../src/pages/homePage');
const excelReporter = require('../../src/utils/excelReporter');
const failureHandler = require('../../src/utils/failureHandler');
const rcaAnalyzer = require('../../src/utils/rcaAnalyzer');
const logger = require('../../src/utils/logger');

const LoginPage = require('../../src/pages/loginPage');
const testData = require('../fixtures/testData');

describe('Flutter Android E2E - Navigation Suite', function () {
  this.timeout(300000);

  let driver;
  let homePage;
  let suiteStartTime;
  const suiteResults = [];

  before(async function () {
    suiteStartTime = Date.now();
    logger.info('🚀 Starting Navigation Test Suite...');
    driver = await driverFactory.createDriver('Flutter');
    homePage = new HomePage(driver);
    const loginPage = new LoginPage(driver);
    await loginPage.login(testData.validUser.email, testData.validUser.password);
  });

  after(async function () {
    try {
      const duration = Date.now() - suiteStartTime;
      excelReporter.setMetadata({ totalDurationMs: duration });
      await excelReporter.generateReport();
      rcaAnalyzer.analyzeResults(suiteResults);
    } catch (err) {
      logger.error(`Error during reporting teardown: ${err.message}`);
    } finally {
      await driverFactory.quitDriver();
    }
  });

  it('TC_NAV_001: Validate Navigation Drawer flow', async function () {
    const testId = 'TC_NAV_001';
    const scenario = 'Open navigation drawer and navigate to Profile screen';
    const startTime = Date.now();

    try {
      await homePage.navigateViaDrawer('Profile');
      const isProfileActive = await homePage.isScreenActive('Profile');
      expect(isProfileActive).to.be.true;

      suiteResults.push({ testId, module: 'Navigation', scenario, status: 'PASSED', durationMs: Date.now() - startTime });
      excelReporter.addTestResult({ testId, module: 'Navigation', scenario, status: 'PASSED', durationMs: Date.now() - startTime });
    } catch (err) {
      const diag = await failureHandler.captureFailureDiagnostics(driver, scenario, err);
      const testResult = {
        testId, module: 'Navigation', scenario, status: 'FAILED',
        durationMs: Date.now() - startTime, failureReason: err.message,
        screenshotPath: diag.screenshotPath, stackTrace: err.stack
      };
      suiteResults.push(testResult);
      excelReporter.addTestResult(testResult);
      throw err;
    }
  });

  it('TC_NAV_002: Validate Bottom Navigation tabs', async function () {
    const testId = 'TC_NAV_002';
    const scenario = 'Switch tabs using Bottom Navigation Bar';
    const startTime = Date.now();

    try {
      await homePage.navigateViaBottomNav('Explore');
      const isExploreActive = await homePage.isScreenActive('Explore');
      expect(isExploreActive).to.be.true;

      await homePage.navigateViaBottomNav('Forms');
      const isFormsActive = await homePage.isScreenActive('Forms');
      expect(isFormsActive).to.be.true;

      suiteResults.push({ testId, module: 'Navigation', scenario, status: 'PASSED', durationMs: Date.now() - startTime });
      excelReporter.addTestResult({ testId, module: 'Navigation', scenario, status: 'PASSED', durationMs: Date.now() - startTime });
    } catch (err) {
      const diag = await failureHandler.captureFailureDiagnostics(driver, scenario, err);
      const testResult = {
        testId, module: 'Navigation', scenario, status: 'FAILED',
        durationMs: Date.now() - startTime, failureReason: err.message,
        screenshotPath: diag.screenshotPath, stackTrace: err.stack
      };
      suiteResults.push(testResult);
      excelReporter.addTestResult(testResult);
      throw err;
    }
  });

  it('TC_NAV_003: Validate Back button and App restart behavior', async function () {
    const testId = 'TC_NAV_003';
    const scenario = 'Test physical back button navigation and Flutter app restart';
    const startTime = Date.now();

    try {
      await homePage.goBack();
      await homePage.restartApp();

      suiteResults.push({ testId, module: 'Navigation', scenario, status: 'PASSED', durationMs: Date.now() - startTime });
      excelReporter.addTestResult({ testId, module: 'Navigation', scenario, status: 'PASSED', durationMs: Date.now() - startTime });
    } catch (err) {
      const diag = await failureHandler.captureFailureDiagnostics(driver, scenario, err);
      const testResult = {
        testId, module: 'Navigation', scenario, status: 'FAILED',
        durationMs: Date.now() - startTime, failureReason: err.message,
        screenshotPath: diag.screenshotPath, stackTrace: err.stack
      };
      suiteResults.push(testResult);
      excelReporter.addTestResult(testResult);
      throw err;
    }
  });
});
