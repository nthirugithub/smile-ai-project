'use strict';

const ExcelJS = require('exceljs');
const path = require('path');
const fs = require('fs');
const env = require('../../config/env.config');
const logger = require('./logger');

class ExcelReporter {
  constructor() {
    this.workbook = new ExcelJS.Workbook();
    this.testResults = [];
    this.failedTests = [];
    this.executionLogs = [];
    this.metadata = {
      executionDate: new Date().toLocaleString(),
      deviceName: env.deviceName,
      androidVersion: env.platformVersion,
      totalDurationMs: 0
    };
  }

  /**
   * Records step log for Sheet 4
   */
  logStep(testName, step, result = 'PASSED', remarks = '') {
    this.executionLogs.push({
      timestamp: new Date().toLocaleTimeString(),
      testName,
      step,
      result,
      remarks
    });
  }

  /**
   * Records completed test result
   */
  addTestResult(testCase) {
    // testCase: { testId, module, scenario, status, device, durationMs, failureReason, screenshotPath }
    this.testResults.push(testCase);
    if (testCase.status === 'FAILED') {
      this.failedTests.push({
        testName: testCase.scenario,
        failureReason: testCase.failureReason || 'Assertion failure',
        screenshotPath: testCase.screenshotPath || 'N/A',
        device: testCase.device || env.deviceName,
        androidVersion: env.platformVersion
      });
    }
  }

  /**
   * Sets overall execution metadata
   */
  setMetadata(meta) {
    this.metadata = { ...this.metadata, ...meta };
  }

  /**
   * Generates and writes Excel_E2E_Report.xlsx
   */
  async generateReport(outputPath = env.excelReportPath) {
    logger.info(`📊 Generating multi-sheet Excel report at: ${outputPath}`);

    const reportsDir = path.dirname(outputPath);
    if (!fs.existsSync(reportsDir)) {
      fs.mkdirSync(reportsDir, { recursive: true });
    }

    const total = this.testResults.length;
    const passed = this.testResults.filter(t => t.status === 'PASSED').length;
    const failed = this.testResults.filter(t => t.status === 'FAILED').length;
    const skipped = this.testResults.filter(t => t.status === 'SKIPPED').length;
    const passRate = total > 0 ? ((passed / total) * 100).toFixed(2) + '%' : '0%';

    // Sheet 1: Summary
    const summarySheet = this.workbook.addWorksheet('Summary');
    summarySheet.columns = [
      { header: 'Metric', key: 'metric', width: 25 },
      { header: 'Value', key: 'value', width: 40 }
    ];
    
    // Style Summary Header
    summarySheet.getRow(1).font = { bold: true, color: { argb: 'FFFFFF' }, size: 12 };
    summarySheet.getRow(1).fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: '1F4E79' } };

    summarySheet.addRows([
      { metric: 'Execution Date', value: this.metadata.executionDate },
      { metric: 'Device Name', value: this.metadata.deviceName },
      { metric: 'Android Version', value: this.metadata.androidVersion },
      { metric: 'Total Tests', value: total },
      { metric: 'Passed', value: passed },
      { metric: 'Failed', value: failed },
      { metric: 'Skipped', value: skipped },
      { metric: 'Pass Percentage', value: passRate },
      { metric: 'Total Duration', value: `${(this.metadata.totalDurationMs / 1000).toFixed(2)}s` }
    ]);

    // Sheet 2: Test Cases
    const testCasesSheet = this.workbook.addWorksheet('Test Cases');
    testCasesSheet.columns = [
      { header: 'Test ID', key: 'testId', width: 15 },
      { header: 'Module', key: 'module', width: 20 },
      { header: 'Scenario', key: 'scenario', width: 45 },
      { header: 'Status', key: 'status', width: 15 },
      { header: 'Device', key: 'device', width: 25 },
      { header: 'Duration (s)', key: 'duration', width: 15 }
    ];
    testCasesSheet.getRow(1).font = { bold: true, color: { argb: 'FFFFFF' }, size: 12 };
    testCasesSheet.getRow(1).fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: '2F5597' } };

    this.testResults.forEach(tc => {
      const row = testCasesSheet.addRow({
        testId: tc.testId || `TC_${Math.floor(Math.random() * 1000)}`,
        module: tc.module || 'E2E',
        scenario: tc.scenario,
        status: tc.status,
        device: tc.device || env.deviceName,
        duration: `${((tc.durationMs || 0) / 1000).toFixed(2)}s`
      });

      const statusCell = row.getCell('status');
      if (tc.status === 'PASSED') {
        statusCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'C6EFCE' } };
        statusCell.font = { color: { argb: '006100' }, bold: true };
      } else if (tc.status === 'FAILED') {
        statusCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFC7CE' } };
        statusCell.font = { color: { argb: '9C0006' }, bold: true };
      }
    });

    // Sheet 3: Failed Tests
    const failedSheet = this.workbook.addWorksheet('Failed Tests');
    failedSheet.columns = [
      { header: 'Test Name', key: 'testName', width: 35 },
      { header: 'Failure Reason', key: 'failureReason', width: 60 },
      { header: 'Screenshot Path', key: 'screenshotPath', width: 45 },
      { header: 'Device', key: 'device', width: 20 },
      { header: 'Android Version', key: 'androidVersion', width: 18 }
    ];
    failedSheet.getRow(1).font = { bold: true, color: { argb: 'FFFFFF' }, size: 12 };
    failedSheet.getRow(1).fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'C00000' } };

    this.failedTests.forEach(ft => {
      failedSheet.addRow(ft);
    });

    // Sheet 4: Execution Logs
    const logsSheet = this.workbook.addWorksheet('Execution Logs');
    logsSheet.columns = [
      { header: 'Timestamp', key: 'timestamp', width: 15 },
      { header: 'Test Name', key: 'testName', width: 30 },
      { header: 'Step', key: 'step', width: 50 },
      { header: 'Result', key: 'result', width: 15 },
      { header: 'Remarks', key: 'remarks', width: 35 }
    ];
    logsSheet.getRow(1).font = { bold: true, color: { argb: 'FFFFFF' }, size: 12 };
    logsSheet.getRow(1).fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: '548235' } };

    this.executionLogs.forEach(log => {
      logsSheet.addRow(log);
    });

    await this.workbook.xlsx.writeFile(outputPath);
    logger.info(`✅ Excel report successfully generated: ${outputPath}`);
  }
}

module.exports = new ExcelReporter();
