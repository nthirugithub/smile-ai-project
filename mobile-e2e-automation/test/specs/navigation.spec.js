'use strict';

const { expect } = require('chai');
const driverFactory = require('../../src/driver/driverFactory');
const HomePage = require('../../src/pages/homePage');
const LoginPage = require('../../src/pages/loginPage');
const testData = require('../fixtures/testData');
const excelReporter = require('../../src/utils/excelReporter');
const failureHandler = require('../../src/utils/failureHandler');
const rcaAnalyzer = require('../../src/utils/rcaAnalyzer');
const logger = require('../../src/utils/logger');

describe('Flutter Android E2E - Navigation Suite', function () {
  this.timeout(300000);

  let driver;
  let homePage;
  let loginPage;
  let suiteStartTime;
  const suiteResults = [];

  before(async function () {
    suiteStartTime = Date.now();
    logger.info('🚀 Starting Navigation Test Suite...');
    driver = await driverFactory.createDriver('Flutter');
    homePage = new HomePage(driver);
    loginPage = new LoginPage(driver);
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

  it('TC_NAV_001: Validate Navigation between Login and Register screens', async function () {
    const testId = 'TC_NAV_001';
    const scenario = 'Navigate between Login and Register screens';
    const startTime = Date.now();

    try {
      await loginPage.goToSignUp();
      const isRegisterTitleVisible = await homePage.isDisplayed(homePage.finder.byText('Create Account'), 'Create Account Title');
      expect(isRegisterTitleVisible).to.be.true;

      await homePage.click(homePage.finder.byText('Sign In'), 'Sign In Link');
      const isLoginBtnVisible = await loginPage.waitForVisible(loginPage.loginButton, 10000, 'Login Button');
      expect(isLoginBtnVisible).to.be.true;

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

  it('TC_NAV_002: Validate Login screen elements visibility', async function () {
    const testId = 'TC_NAV_002';
    const scenario = 'Verify Login screen interactive elements';
    const startTime = Date.now();

    try {
      const isEmailVisible = await loginPage.waitForVisible(loginPage.emailInput, 10000, 'Email Input');
      const isPasswordVisible = await loginPage.waitForVisible(loginPage.passwordInput, 10000, 'Password Input');
      const isLoginBtnVisible = await loginPage.waitForVisible(loginPage.loginButton, 10000, 'Login Button');

      expect(isEmailVisible).to.be.true;
      expect(isPasswordVisible).to.be.true;
      expect(isLoginBtnVisible).to.be.true;

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
