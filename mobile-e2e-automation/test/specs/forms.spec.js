'use strict';

const { expect } = require('chai');
const driverFactory = require('../../src/driver/driverFactory');
const FormPage = require('../../src/pages/formPage');
const testData = require('../fixtures/testData');
const excelReporter = require('../../src/utils/excelReporter');
const failureHandler = require('../../src/utils/failureHandler');
const rcaAnalyzer = require('../../src/utils/rcaAnalyzer');
const logger = require('../../src/utils/logger');

describe('Flutter Android E2E - Form Validation Suite', function () {
  this.timeout(300000);

  let driver;
  let formPage;
  let suiteStartTime;
  const suiteResults = [];

  before(async function () {
    suiteStartTime = Date.now();
    logger.info('🚀 Starting Form Validation Test Suite...');
    driver = await driverFactory.createDriver('Flutter');
    formPage = new FormPage(driver);
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

      const nameErr = await formPage.getFullNameError();
      const emailErr = await formPage.getEmailError();

      expect(nameErr).to.contain('Full name is required');
      expect(emailErr).to.contain('Email is required');

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

  it('TC_FORM_002: Validate phone number format rule', async function () {
    const testId = 'TC_FORM_002';
    const scenario = 'Enter invalid phone format and verify Flutter validation message';
    const startTime = Date.now();

    try {
      await formPage.enterPhone(testData.formValidation.invalidPhones[0]);
      await formPage.submitForm();

      const phoneErr = await formPage.getPhoneError();
      expect(phoneErr).to.contain(testData.formValidation.expectedPhoneError);

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

  it('TC_FORM_003: Validate successful form submission with DatePicker, Dropdown, Radio & Checkbox', async function () {
    const testId = 'TC_FORM_003';
    const scenario = 'Fill valid form details and verify success confirmation';
    const startTime = Date.now();

    try {
      await formPage.enterFullName(testData.validUser.fullName);
      await formPage.enterEmail(testData.validUser.email);
      await formPage.enterPhone(testData.validUser.phone);
      await formPage.enterPassword(testData.validUser.password);

      await formPage.selectDateOfBirth();
      await formPage.selectCountry('United States');
      await formPage.selectGender('male');
      await formPage.toggleTerms(true);
      await formPage.toggleNewsletter(true);

      await formPage.submitForm();

      const isSuccess = await formPage.isFormSubmittedSuccessfully();
      expect(isSuccess).to.be.true;

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
