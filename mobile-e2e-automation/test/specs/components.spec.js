'use strict';

const { expect } = require('chai');
const driverFactory = require('../../src/driver/driverFactory');
const ComponentsPage = require('../../src/pages/componentsPage');
const gestures = require('../../src/utils/gestures');
const excelReporter = require('../../src/utils/excelReporter');
const failureHandler = require('../../src/utils/failureHandler');
const rcaAnalyzer = require('../../src/utils/rcaAnalyzer');
const logger = require('../../src/utils/logger');
const testData = require('../fixtures/testData');

describe('Flutter Android E2E - UI Component & Gestures Suite', function () {
  this.timeout(60000);

  let driver;
  let compPage;
  let suiteStartTime;
  const suiteResults = [];

  before(async function () {
    suiteStartTime = Date.now();
    logger.info('🚀 Starting UI Components & Gestures Test Suite...');
    driver = await driverFactory.createDriver('Flutter');
    compPage = new ComponentsPage(driver);
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

  it('TC_COMP_001: Validate Buttons and Widget Visibility', async function () {
    const testId = 'TC_COMP_001';
    const scenario = 'Validate button visibility and interactive widget state';
    const startTime = Date.now();

    try {
      const isLoginBtnVisible = await compPage.clickElevatedButton();
      const isSignUpVisible = await compPage.clickTextButton();
      const isEmailInputVisible = await compPage.clickIconButton();

      expect(isLoginBtnVisible).to.be.true;
      expect(isSignUpVisible).to.be.true;
      expect(isEmailInputVisible).to.be.true;

      suiteResults.push({ testId, module: 'Components', scenario, status: 'PASSED', durationMs: Date.now() - startTime });
      excelReporter.addTestResult({ testId, module: 'Components', scenario, status: 'PASSED', durationMs: Date.now() - startTime });
    } catch (err) {
      const diag = await failureHandler.captureFailureDiagnostics(driver, scenario, err);
      const testResult = {
        testId, module: 'Components', scenario, status: 'FAILED',
        durationMs: Date.now() - startTime, failureReason: err.message,
        screenshotPath: diag.screenshotPath, stackTrace: err.stack
      };
      suiteResults.push(testResult);
      excelReporter.addTestResult(testResult);
      throw err;
    }
  });

  it('TC_COMP_002: Validate Gestures (Tap, Double Tap, Scroll)', async function () {
    const testId = 'TC_COMP_002';
    const scenario = 'Perform multi-touch W3C gestures on Flutter screen';
    const startTime = Date.now();

    try {
      const { width, height } = await gestures.getScreenBounds(driver);

      await gestures.tap(driver, width / 2, height / 2);
      await gestures.doubleTap(driver, width / 2, height / 2);
      await gestures.scrollDown(driver, 0.5);
      await gestures.scrollUp(driver, 0.5);

      suiteResults.push({ testId, module: 'Components', scenario, status: 'PASSED', durationMs: Date.now() - startTime });
      excelReporter.addTestResult({ testId, module: 'Components', scenario, status: 'PASSED', durationMs: Date.now() - startTime });
    } catch (err) {
      const diag = await failureHandler.captureFailureDiagnostics(driver, scenario, err);
      const testResult = {
        testId, module: 'Components', scenario, status: 'FAILED',
        durationMs: Date.now() - startTime, failureReason: err.message,
        screenshotPath: diag.screenshotPath, stackTrace: err.stack
      };
      suiteResults.push(testResult);
      excelReporter.addTestResult(testResult);
      throw err;
    }
  });
});
