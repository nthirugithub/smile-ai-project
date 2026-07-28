'use strict';

const { expect } = require('chai');
const driverFactory = require('../../src/driver/driverFactory');
const ComponentsPage = require('../../src/pages/componentsPage');
const gestures = require('../../src/utils/gestures');
const excelReporter = require('../../src/utils/excelReporter');
const failureHandler = require('../../src/utils/failureHandler');
const rcaAnalyzer = require('../../src/utils/rcaAnalyzer');
const logger = require('../../src/utils/logger');

describe('Flutter Android E2E - UI Component & Gestures Suite', function () {
  this.timeout(300000);

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

  it('TC_COMP_001: Validate Buttons (ElevatedButton, TextButton, IconButton)', async function () {
    const testId = 'TC_COMP_001';
    const scenario = 'Validate button clicks and interactive widget state';
    const startTime = Date.now();

    try {
      await compPage.clickElevatedButton();
      await compPage.clickTextButton();
      await compPage.clickIconButton();

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

  it('TC_COMP_002: Validate Flutter Dialog, BottomSheet and Snackbar popups', async function () {
    const testId = 'TC_COMP_002';
    const scenario = 'Validate dialog modal, bottom sheet display and snackbar text';
    const startTime = Date.now();

    try {
      await compPage.triggerAlertDialog();
      const isDialogShown = await compPage.isDialogVisible();
      expect(isDialogShown).to.be.true;
      await compPage.confirmDialog();

      await compPage.triggerBottomSheet();
      const isSheetShown = await compPage.isBottomSheetVisible();
      expect(isSheetShown).to.be.true;

      await compPage.triggerSnackbar();
      const snackMsg = await compPage.getSnackbarMessage();
      expect(snackMsg).to.not.be.empty;

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

  it('TC_COMP_003: Validate Gestures (Swipe, Long Press, Pinch, Zoom)', async function () {
    const testId = 'TC_COMP_003';
    const scenario = 'Perform multi-touch W3C gestures on Flutter screen';
    const startTime = Date.now();

    try {
      const { width, height } = await driver.getWindowSize();

      await gestures.tap(driver, width / 2, height / 2);
      await gestures.doubleTap(driver, width / 2, height / 2);
      await gestures.longPress(driver, width / 2, height / 2, 1000);
      await gestures.scrollDown(driver, 0.5);
      await gestures.scrollUp(driver, 0.5);
      await gestures.zoom(driver);
      await gestures.pinch(driver);

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
