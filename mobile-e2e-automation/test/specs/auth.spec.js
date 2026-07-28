'use strict';

const { expect } = require('chai');
const driverFactory = require('../../src/driver/driverFactory');
const LoginPage = require('../../src/pages/loginPage');
const testData = require('../fixtures/testData');
const excelReporter = require('../../src/utils/excelReporter');
const failureHandler = require('../../src/utils/failureHandler');
const rcaAnalyzer = require('../../src/utils/rcaAnalyzer');
const logger = require('../../src/utils/logger');

describe('Flutter Android E2E - Authentication Suite', function () {
  this.timeout(300000); // 5 minutes

  let driver;
  let loginPage;
  let suiteStartTime;
  const suiteResults = [];

  before(async function () {
    suiteStartTime = Date.now();
    logger.info('🚀 Starting Authentication Test Suite...');
    driver = await driverFactory.createDriver('Flutter');
    loginPage = new LoginPage(driver);
  });

  after(async function () {
    const duration = Date.now() - suiteStartTime;
    excelReporter.setMetadata({ totalDurationMs: duration });
    await excelReporter.generateReport();
    rcaAnalyzer.analyzeResults(suiteResults);
    await driverFactory.quitDriver();
  });

  it('TC_AUTH_001: Validate login form with empty credentials', async function () {
    const testId = 'TC_AUTH_001';
    const scenario = 'Validate login with empty fields';
    const startTime = Date.now();

    try {
      await loginPage.login('', '');
      
      const emailErr = await loginPage.getEmailValidationError();
      expect(emailErr).to.contain(testData.invalidUsers.emptyEmail.expectedError);

      suiteResults.push({ testId, module: 'Auth', scenario, status: 'PASSED', durationMs: Date.now() - startTime });
      excelReporter.addTestResult({ testId, module: 'Auth', scenario, status: 'PASSED', durationMs: Date.now() - startTime });
    } catch (err) {
      const diag = await failureHandler.captureFailureDiagnostics(driver, scenario, err);
      const testResult = {
        testId,
        module: 'Auth',
        scenario,
        status: 'FAILED',
        durationMs: Date.now() - startTime,
        failureReason: err.message,
        screenshotPath: diag.screenshotPath,
        stackTrace: err.stack
      };
      suiteResults.push(testResult);
      excelReporter.addTestResult(testResult);
      throw err;
    }
  });

  it('TC_AUTH_002: Validate login with invalid email format', async function () {
    const testId = 'TC_AUTH_002';
    const scenario = 'Validate login with malformed email format';
    const startTime = Date.now();

    try {
      await loginPage.login(testData.invalidUsers.malformedEmail.email, testData.invalidUsers.malformedEmail.password);
      
      const emailErr = await loginPage.getEmailValidationError();
      expect(emailErr).to.contain(testData.invalidUsers.malformedEmail.expectedError);

      suiteResults.push({ testId, module: 'Auth', scenario, status: 'PASSED', durationMs: Date.now() - startTime });
      excelReporter.addTestResult({ testId, module: 'Auth', scenario, status: 'PASSED', durationMs: Date.now() - startTime });
    } catch (err) {
      const diag = await failureHandler.captureFailureDiagnostics(driver, scenario, err);
      const testResult = {
        testId,
        module: 'Auth',
        scenario,
        status: 'FAILED',
        durationMs: Date.now() - startTime,
        failureReason: err.message,
        screenshotPath: diag.screenshotPath,
        stackTrace: err.stack
      };
      suiteResults.push(testResult);
      excelReporter.addTestResult(testResult);
      throw err;
    }
  });

  it('TC_AUTH_003: Validate authentication with valid credentials and verify session persistence', async function () {
    const testId = 'TC_AUTH_003';
    const scenario = 'Perform successful login and verify dashboard state';
    const startTime = Date.now();

    try {
      await loginPage.login(testData.validUser.email, testData.validUser.password);
      
      const isDashboardVisible = await loginPage.isLoggedIn();
      expect(isDashboardVisible).to.be.true;

      suiteResults.push({ testId, module: 'Auth', scenario, status: 'PASSED', durationMs: Date.now() - startTime });
      excelReporter.addTestResult({ testId, module: 'Auth', scenario, status: 'PASSED', durationMs: Date.now() - startTime });
    } catch (err) {
      const diag = await failureHandler.captureFailureDiagnostics(driver, scenario, err);
      const testResult = {
        testId,
        module: 'Auth',
        scenario,
        status: 'FAILED',
        durationMs: Date.now() - startTime,
        failureReason: err.message,
        screenshotPath: diag.screenshotPath,
        stackTrace: err.stack
      };
      suiteResults.push(testResult);
      excelReporter.addTestResult(testResult);
      throw err;
    }
  });

  it('TC_AUTH_004: Validate user logout', async function () {
    const testId = 'TC_AUTH_004';
    const scenario = 'Perform logout and verify redirection to login screen';
    const startTime = Date.now();

    try {
      await loginPage.logout();
      
      const isDashboardVisible = await loginPage.isLoggedIn();
      expect(isDashboardVisible).to.be.false;

      suiteResults.push({ testId, module: 'Auth', scenario, status: 'PASSED', durationMs: Date.now() - startTime });
      excelReporter.addTestResult({ testId, module: 'Auth', scenario, status: 'PASSED', durationMs: Date.now() - startTime });
    } catch (err) {
      const diag = await failureHandler.captureFailureDiagnostics(driver, scenario, err);
      const testResult = {
        testId,
        module: 'Auth',
        scenario,
        status: 'FAILED',
        durationMs: Date.now() - startTime,
        failureReason: err.message,
        screenshotPath: diag.screenshotPath,
        stackTrace: err.stack
      };
      suiteResults.push(testResult);
      excelReporter.addTestResult(testResult);
      throw err;
    }
  });
});
