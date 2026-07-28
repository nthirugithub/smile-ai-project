'use strict';

const { expect } = require('chai');
const driverFactory = require('../../src/driver/driverFactory');
const FormPage = require('../../src/pages/formPage');
const LoginPage = require('../../src/pages/loginPage');
const testData = require('../fixtures/testData');
const excelReporter = require('../../src/utils/excelReporter');
const failureHandler = require('../../src/utils/failureHandler');
const rcaAnalyzer = require('../../src/utils/rcaAnalyzer');
const logger = require('../../src/utils/logger');

describe('Flutter Android E2E - Form Validation Suite', function () {
  this.timeout(120000);

  let driver;
  let formPage;
  let loginPage;
  let suiteStartTime;
  const suiteResults = [];

  before(async function () {
    suiteStartTime = Date.now();
    logger.info('🚀 Starting Form Validation Test Suite...');
    driver = await driverFactory.createDriver('Flutter');
    formPage = new FormPage(driver);
    loginPage = new LoginPage(driver);
  });

  beforeEach(async function () {
    try {
      await driver.execute('flutter:setFrameSync', false, 1000);
    } catch (_) {}

    const isRegisterVisible = await formPage.isDisplayed(formPage.submitFormButton, 'Register Button', 3000);
    if (!isRegisterVisible) {
      try {
        await loginPage.goToSignUp();
      } catch (_) {
        await driver.back();
        await loginPage.goToSignUp();
      }
    }
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

  it('TC_FORM_001: Validate required fields error triggers', async function () {
    const testId = 'TC_FORM_001';
    const scenario = 'Submit blank form and verify required field messages';
    const startTime = Date.now();

    try {
      await formPage.submitForm();

      const nameErrVisible = await formPage.isDisplayed(formPage.fullNameError, 'Full Name Error');
      const emailErrVisible = await formPage.isDisplayed(formPage.emailError, 'Email Error');

      expect(nameErrVisible).to.be.true;
      expect(emailErrVisible).to.be.true;

      suiteResults.push({ testId, module: 'Form', scenario, status: 'PASSED', durationMs: Date.now() - startTime });
      excelReporter.addTestResult({ testId, module: 'Form', scenario, status: 'PASSED', durationMs: Date.now() - startTime });
    } catch (err) {
      const diag = await failureHandler.captureFailureDiagnostics(driver, scenario, err);
      const testResult = {
        testId, module: 'Form', scenario, status: 'FAILED',
        durationMs: Date.now() - startTime, failureReason: err.message,
        screenshotPath: diag.screenshotPath, stackTrace: err.stack
      };
      suiteResults.push(testResult);
      excelReporter.addTestResult(testResult);
      throw err;
    }
  });

  it('TC_FORM_002: Validate password minimum length validation rule', async function () {
    const testId = 'TC_FORM_002';
    const scenario = 'Enter short password and verify Flutter validation message';
    const startTime = Date.now();

    try {
      await formPage.enterFullName('QA Test User');
      await formPage.enterEmail('test.form@example.com');
      await formPage.enterPassword('123');
      await formPage.enterConfirmPassword('123');
      await formPage.submitForm();

      const passwordErrVisible = await formPage.isDisplayed(formPage.passwordLengthError, 'Password Length Error');
      expect(passwordErrVisible).to.be.true;

      suiteResults.push({ testId, module: 'Form', scenario, status: 'PASSED', durationMs: Date.now() - startTime });
      excelReporter.addTestResult({ testId, module: 'Form', scenario, status: 'PASSED', durationMs: Date.now() - startTime });
    } catch (err) {
      const diag = await failureHandler.captureFailureDiagnostics(driver, scenario, err);
      const testResult = {
        testId, module: 'Form', scenario, status: 'FAILED',
        durationMs: Date.now() - startTime, failureReason: err.message,
        screenshotPath: diag.screenshotPath, stackTrace: err.stack
      };
      suiteResults.push(testResult);
      excelReporter.addTestResult(testResult);
      throw err;
    }
  });

  it('TC_FORM_003: Validate successful registration form submission', async function () {
    const testId = 'TC_FORM_003';
    const scenario = 'Fill valid form details and verify registration success';
    const startTime = Date.now();

    try {
      const uniqueEmail = `form.user+${Date.now()}@example.com`;
      await formPage.enterFullName(testData.validUser.fullName);
      await formPage.enterEmail(uniqueEmail);
      await formPage.enterPassword(testData.validUser.password);
      await formPage.enterConfirmPassword(testData.validUser.password);

      await formPage.submitForm();

      // Allow 1s for HTTP POST response & Navigator transition to mount /auth
      await new Promise(r => setTimeout(r, 1000));

      const isLoginVisible = await loginPage.waitForVisible(loginPage.loginButton, 10000, 'Login Button');
      expect(isLoginVisible).to.be.true;

      suiteResults.push({ testId, module: 'Form', scenario, status: 'PASSED', durationMs: Date.now() - startTime });
      excelReporter.addTestResult({ testId, module: 'Form', scenario, status: 'PASSED', durationMs: Date.now() - startTime });
    } catch (err) {
      const diag = await failureHandler.captureFailureDiagnostics(driver, scenario, err);
      const testResult = {
        testId, module: 'Form', scenario, status: 'FAILED',
        durationMs: Date.now() - startTime, failureReason: err.message,
        screenshotPath: diag.screenshotPath, stackTrace: err.stack
      };
      suiteResults.push(testResult);
      excelReporter.addTestResult(testResult);
      throw err;
    }
  });
});
