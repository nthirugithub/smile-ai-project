'use strict';

const failureHandler = require('../utils/failureHandler');
const logger = require('../utils/logger');
const env = require('../../config/env.config');

/**
 * Wraps a test scenario with automatic configurable retry logic
 * @param {Function} testFn The async test function to execute
 * @param {Object} options Options object { maxRetries, testTitle, driverGetter }
 */
async function withRetry(testFn, options = {}) {
  const maxRetries = options.maxRetries || env.retries;
  const testTitle = options.testTitle || 'E2E Test Scenario';
  const driverGetter = options.driverGetter;

  let attempt = 0;
  let lastError = null;

  while (attempt <= maxRetries) {
    try {
      if (attempt > 0) {
        logger.warn(`🔄 Retrying test "${testTitle}" (Attempt ${attempt}/${maxRetries})...`);
      }
      const result = await testFn();
      return { result, attempts: attempt };
    } catch (error) {
      lastError = error;
      attempt++;

      logger.error(`❌ Execution attempt ${attempt} failed for "${testTitle}": ${error.message}`);

      if (driverGetter) {
        try {
          const driver = typeof driverGetter === 'function' ? driverGetter() : driverGetter;
          await failureHandler.captureFailureDiagnostics(driver, `${testTitle}_attempt_${attempt}`, error);
        } catch (diagErr) {
          logger.warn(`Diagnostic capture warning on retry: ${diagErr.message}`);
        }
      }

      if (attempt > maxRetries) {
        logger.error(`🚨 Max retries (${maxRetries}) reached for "${testTitle}". Re-throwing failure.`);
        throw lastError;
      }
    }
  }
}

module.exports = { withRetry };
