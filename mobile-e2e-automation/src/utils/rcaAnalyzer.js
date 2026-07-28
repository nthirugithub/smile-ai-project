'use strict';

const fs = require('fs');
const path = require('path');
const env = require('../../config/env.config');
const logger = require('./logger');

class RCAAnalyzer {
  /**
   * Analyzes execution failures and categorizes them into RCA buckets with actionable recommendations
   * @param {Array} testResults List of test result objects from suite execution
   */
  analyzeResults(testResults) {
    logger.info('🔍 Performing Root-Cause Analysis (RCA) on execution results...');

    const summary = {
      totalTests: testResults.length,
      passed: 0,
      failed: 0,
      skipped: 0,
      categories: {
        applicationDefects: [],
        automationIssues: [],
        environmentFailures: [],
        flakyTests: []
      },
      recommendations: []
    };

    testResults.forEach(tc => {
      if (tc.status === 'PASSED') {
        summary.passed++;
        if (tc.retriesCount > 0) {
          summary.categories.flakyTests.push({
            testName: tc.scenario,
            attempts: tc.retriesCount + 1,
            reason: 'Test passed after retry; potential animation timing or async Flutter widget build delay.'
          });
        }
      } else if (tc.status === 'FAILED') {
        summary.failed++;
        const category = this.categorizeFailure(tc.failureReason, tc.stackTrace);
        
        summary.categories[category.bucket].push({
          testName: tc.scenario,
          reason: tc.failureReason,
          details: category.explanation,
          recommendation: category.recommendation
        });
      } else {
        summary.skipped++;
      }
    });

    // Generate aggregated recommendations
    summary.recommendations = this.generateRecommendations(summary.categories);

    // Save RCA report JSON & Markdown summary
    this.writeRCAReports(summary);

    return summary;
  }

  /**
   * Categorizes failure reason into standard RCA buckets
   */
  categorizeFailure(failureReason = '', stackTrace = '') {
    const reasonLower = (failureReason + ' ' + stackTrace).toLowerCase();

    if (reasonLower.includes('expected') || reasonLower.includes('assertionerror') || reasonLower.includes('validation error') || reasonLower.includes('widget not found in state')) {
      return {
        bucket: 'applicationDefects',
        explanation: 'Flutter widget validation message or state assertion failed against expected behavior.',
        recommendation: 'Verify Flutter widget code logic, validation rules, or API response handling.'
      };
    }

    if (reasonLower.includes('nodedriver') || reasonLower.includes('typeerror') || reasonLower.includes('is not a function') || reasonLower.includes('undefined')) {
      return {
        bucket: 'automationIssues',
        explanation: 'Framework or test code issue (undefined method, syntax error, or unhandled promise).',
        recommendation: 'Inspect Page Object implementation and test script method invocations.'
      };
    }

    if (reasonLower.includes('adb') || reasonLower.includes('connection refused') || reasonLower.includes('socket hang up') || reasonLower.includes('timeout') || reasonLower.includes('sessionnotcreated')) {
      return {
        bucket: 'environmentFailures',
        explanation: 'Appium server, ADB connection, or emulator responsiveness failure.',
        recommendation: 'Restart Appium server / Android emulator and verify ADB device connectivity.'
      };
    }

    return {
      bucket: 'automationIssues',
      explanation: 'Locator wait timeout or synchronization mismatch on Flutter element.',
      recommendation: 'Upgrade locator strategy to ValueKey or SemanticsLabel, and add explicit waitForVisible.'
    };
  }

  /**
   * Generates framework optimization recommendations based on RCA findings
   */
  generateRecommendations(categories) {
    const recs = [];

    if (categories.applicationDefects.length > 0) {
      recs.push(`🐛 ${categories.applicationDefects.length} Application Defect(s) detected. Coordinate with Flutter dev team to verify bug reports.`);
    }

    if (categories.automationIssues.length > 0) {
      recs.push(`🔧 ${categories.automationIssues.length} Automation Issue(s) detected. Prefer find.byValueKey() and find.bySemanticsLabel() over generic text finders.`);
    }

    if (categories.environmentFailures.length > 0) {
      recs.push(`⚡ ${categories.environmentFailures.length} Environment Failure(s) detected. Increase appium:newCommandTimeout and ADB timeout in appium.config.js.`);
    }

    if (categories.flakyTests.length > 0) {
      recs.push(`🔄 ${categories.flakyTests.length} Flaky Test(s) detected. Replace fixed sleep pauses with explicit widget readiness checks.`);
    }

    if (recs.length === 0) {
      recs.push('🎉 Clean execution! All test suites executed reliably without transient failures.');
    }

    return recs;
  }

  /**
   * Writes RCA report files under reports/
   */
  writeRCAReports(summary) {
    const rcaJsonPath = path.join(env.reportsDir, 'RCA_Summary.json');
    const rcaMdPath = path.join(env.reportsDir, 'RCA_Summary.md');

    fs.writeFileSync(rcaJsonPath, JSON.stringify(summary, null, 2));

    let mdContent = `# Root-Cause Analysis (RCA) Executive Summary\n\n`;
    mdContent += `**Total Tests:** ${summary.totalTests} | **Passed:** ${summary.passed} | **Failed:** ${summary.failed} | **Skipped:** ${summary.skipped}\n\n`;

    mdContent += `## Failure Breakdown\n\n`;
    mdContent += `- 🐛 **Application Defects:** ${summary.categories.applicationDefects.length}\n`;
    mdContent += `- 🔧 **Automation Issues:** ${summary.categories.automationIssues.length}\n`;
    mdContent += `- ⚡ **Environment Failures:** ${summary.categories.environmentFailures.length}\n`;
    mdContent += `- 🔄 **Flaky Tests (Retried):** ${summary.categories.flakyTests.length}\n\n`;

    mdContent += `## Recommendations & Improvements\n\n`;
    summary.recommendations.forEach(rec => {
      mdContent += `- ${rec}\n`;
    });

    fs.writeFileSync(rcaMdPath, mdContent);
    logger.info(`📄 RCA Summary generated: ${rcaMdPath}`);
  }
}

module.exports = new RCAAnalyzer();
