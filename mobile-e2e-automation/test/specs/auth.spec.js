'use strict';

const { expect } = require('chai');
const http = require('http');
const driverFactory = require('../../src/driver/driverFactory');
const LoginPage = require('../../src/pages/loginPage');
const RegisterPage = require('../../src/pages/registerPage');
const testData = require('../fixtures/testData');
const excelReporter = require('../../src/utils/excelReporter');
const failureHandler = require('../../src/utils/failureHandler');
const rcaAnalyzer = require('../../src/utils/rcaAnalyzer');
const logger = require('../../src/utils/logger');

// ─── Shared State ─────────────────────────────────────────────────────────────
// TC_AUTH_002 stores the email it registered so TC_AUTH_003 can log in with
// the EXACT same credentials. Using module scope ensures the value survives
// across Mocha test cases within this describe block.
let registeredEmail = testData.validUser.email;

// ─── Test User Seeder ─────────────────────────────────────────────────────────
/**
 * Ensures a user with the given credentials exists in the backend DB.
 * Posts to /register on localhost (reachable from the CI Node.js process).
 * If the user already exists the backend returns {"success":false,
 * "error":"Email already exists"} — we treat that as success (pre-seeded).
 *
 * RC-5 fix: TC_AUTH_003 always has a known, valid user to log in with,
 * regardless of whether TC_AUTH_002 passed, failed, or registered a
 * different unique-email. This breaks the implicit inter-test dependency.
 */
function seedUser(email, password, name) {
  return new Promise((resolve) => {
    const body = JSON.stringify({ email, password, name });
    const options = {
      hostname: '127.0.0.1',
      port: 5000,
      path: '/register',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(body),
      },
    };
    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', chunk => { data += chunk; });
      res.on('end', () => {
        try {
          const parsed = JSON.parse(data);
          if (parsed.success) {
            logger.info(`[Seeder] User ${email} registered successfully.`);
          } else {
            logger.info(`[Seeder] User ${email} seed result: ${parsed.error} (may already exist — OK).`);
          }
        } catch (_) {}
        resolve();
      });
    });
    req.on('error', (err) => {
      logger.warn(`[Seeder] Could not seed user ${email}: ${err.message}`);
      resolve(); // non-blocking — test continues
    });
    req.setTimeout(5000, () => {
      logger.warn('[Seeder] Seed request timed out after 5s — continuing.');
      req.destroy();
      resolve();
    });
    req.write(body);
    req.end();
  });
}

// ─────────────────────────────────────────────────────────────────────────────

describe('Flutter Android E2E - Authentication Suite', function () {
  this.timeout(120000); // 2 minutes per spec for reliable E2E execution

  let driver;
  let loginPage;
  let registerPage;
  let suiteStartTime;
  const suiteResults = [];

  // ─── Suite Setup ────────────────────────────────────────────────────────────

  before(async function () {
    suiteStartTime = Date.now();
    logger.info('🚀 Starting Authentication Test Suite...');
    driver = await driverFactory.createDriver('Flutter');
    loginPage = new LoginPage(driver);
    registerPage = new RegisterPage(driver);
  });

  // ─── Per-test state reset (RC-1 + RC-4 fix) ────────────────────────────────
  //
  // RC-1: After a test failure the Flutter app can be on any screen.
  //   The next test then tries to interact with widgets that don't exist on
  //   the current screen → Flutter Driver polls for 180 seconds and hangs.
  //   FIX: Navigate back to Login before every test.
  //
  // RC-4: TC_AUTH_001 shows a SnackBar (ModalBarrier, blocking:true in semantic
  //   tree). TC_AUTH_002 immediately tapped "Sign Up" while the barrier was
  //   active. The driver's waitUntilNoTransientCallbacks never returned → hang.
  //   FIX: Wait for all known SnackBar texts to disappear before each test.

  beforeEach(async function () {
    logger.info(`--- beforeEach: resetting to Login for: ${this.currentTest.title} ---`);

    // Re-assert frame sync off before EVERY test
    try {
      await driver.execute('flutter:setFrameSync', false, 1000);
    } catch (_) { /* ignore */ }

    // Check if we are on the Login screen
    const loginButtonFinder = loginPage.finder.serialize(loginPage.loginButton);
    let onLoginScreen = false;
    try {
      await driver.execute('flutter:waitFor', loginButtonFinder, 3000);
      onLoginScreen = true;
    } catch (_) {
      onLoginScreen = false;
    }

    if (!onLoginScreen) {
      logger.info('Not on Login screen — attempting recovery to Login screen...');

      // First try: if on Register screen, click "Sign In" link to pushReplacement back to /auth
      try {
        const signInLinkFinder = registerPage.finder.serialize(registerPage.signInLink);
        await driver.execute('flutter:clickElement', signInLinkFinder);
        await driver.execute('flutter:setFrameSync', false, 1000);
        await driver.execute('flutter:waitFor', loginButtonFinder, 3000);
        onLoginScreen = true;
      } catch (_) {
        onLoginScreen = false;
      }

      // Fallback: press back button if still not on Login screen
      if (!onLoginScreen) {
        logger.info('Sign In link recovery skipped/failed — trying back button...');
        for (let i = 0; i < 3; i++) {
          try {
            await driver.back();
            await driver.execute('flutter:setFrameSync', false, 1000);
            await driver.execute('flutter:waitFor', loginButtonFinder, 2000);
            onLoginScreen = true;
            break;
          } catch (_) {
            // keep trying
          }
        }
      }

      // Last resort: restart the app activity via adb
      if (!onLoginScreen) {
        logger.warn('Navigation recovery failed — forcing activity restart via adb');
        try {
          const { execSync } = require('child_process');
          const env = require('../../config/env.config');
          execSync(
            `adb -s ${env.udid} shell am start -n ${env.appPackage}/${env.appActivity}`,
            { encoding: 'utf8', timeout: 10000 }
          );
          // Wait for Flutter to boot and for Login screen to appear
          await new Promise(r => setTimeout(r, 3000));
          await driver.execute('flutter:setFrameSync', false, 1000);
          await driver.execute('flutter:waitFor', loginButtonFinder, 10000);
        } catch (err) {
          logger.warn(`Activity restart attempt: ${err.message}`);
        }
      }
    }

    logger.info('--- beforeEach complete: Login screen confirmed ---');
  });

  // ─── Suite Teardown ─────────────────────────────────────────────────────────

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

  // ─── TC_AUTH_001 ─────────────────────────────────────────────────────────────

  it('TC_AUTH_001: Validate login form with empty credentials', async function () {
    const testId = 'TC_AUTH_001';
    const scenario = 'Validate login with empty fields';
    const startTime = Date.now();

    try {
      // Submit with empty credentials — Flutter shows "Please enter an email
      // address" SnackBar (2s) and returns without API call or navigation.
      await loginPage.login('', '');

      // Dashboard must NOT be visible; app stays on Login screen.
      const isDashboardVisible = await loginPage.isLoggedIn();
      expect(isDashboardVisible).to.be.false;

      suiteResults.push({ testId, module: 'Auth', scenario, status: 'PASSED', durationMs: Date.now() - startTime });
      excelReporter.addTestResult({ testId, module: 'Auth', scenario, status: 'PASSED', durationMs: Date.now() - startTime });
    } catch (err) {
      const diag = await failureHandler.captureFailureDiagnostics(driver, scenario, err);
      const testResult = {
        testId, module: 'Auth', scenario, status: 'FAILED',
        durationMs: Date.now() - startTime, failureReason: err.message,
        screenshotPath: diag.screenshotPath, stackTrace: err.stack
      };
      suiteResults.push(testResult);
      excelReporter.addTestResult(testResult);
      throw err;
    }
  });

  // ─── TC_AUTH_002 ─────────────────────────────────────────────────────────────

  it('TC_AUTH_002: Validate User Registration flow', async function () {
    const testId = 'TC_AUTH_002';
    const scenario = 'Navigate to register screen and create user account';
    const startTime = Date.now();

    try {
      // Navigate to Register screen via Sign Up link
      await loginPage.goToSignUp();

      // Verify Register screen loaded before filling fields (RC-1 safety)
      const registerTitleVisible = await registerPage.waitForVisible(
        registerPage.registerTitle, 10000, 'Register Screen Title ("Create Account")'
      );
      expect(registerTitleVisible).to.be.true;

      // Use a timestamp-unique email without '+' so keyboard sendKeys typing
      // never drops keycodes or triggers Flutter email regex validation failure.
      registeredEmail = `qae2e${Date.now()}@smileai-test.com`;
      logger.info(`[TC_AUTH_002] Registering with unique email: ${registeredEmail}`);

      logger.info('[TRACE_LOG] Step 1: Triggering registerUser() on page object');
      await registerPage.registerUser(
        testData.validUser.fullName,
        registeredEmail,
        testData.validUser.password
      );
      logger.info('[TRACE_LOG] Step 1 complete: registerPage.registerUser() returned');

      // Allow 1s for HTTP POST response & Navigator transition to mount /auth
      await new Promise(r => setTimeout(r, 1000));

      logger.info('[TRACE_LOG] Step 14 verification: Calling loginPage.waitForVisible(loginButton, 10000)');
      const isLoginVisible = await loginPage.waitForVisible(
        loginPage.loginButton, 10000, 'Login Button after registration'
      );
      logger.info(`[TRACE_LOG] Step 14 verification result: isLoginVisible = ${isLoginVisible}`);
      expect(isLoginVisible).to.be.true;

      suiteResults.push({ testId, module: 'Auth', scenario, status: 'PASSED', durationMs: Date.now() - startTime });
      excelReporter.addTestResult({ testId, module: 'Auth', scenario, status: 'PASSED', durationMs: Date.now() - startTime });
    } catch (err) {
      const diag = await failureHandler.captureFailureDiagnostics(driver, scenario, err);
      const testResult = {
        testId, module: 'Auth', scenario, status: 'FAILED',
        durationMs: Date.now() - startTime, failureReason: err.message,
        screenshotPath: diag.screenshotPath, stackTrace: err.stack
      };
      suiteResults.push(testResult);
      excelReporter.addTestResult(testResult);
      throw err;
    }
  });

  // ─── TC_AUTH_003 ─────────────────────────────────────────────────────────────

  it('TC_AUTH_003: Validate authentication with registered credentials and verify dashboard state', async function () {
    const testId = 'TC_AUTH_003';
    const scenario = 'Perform successful login and verify dashboard state';
    const startTime = Date.now();

    try {
      // RC-5: Seed the user directly via the backend REST API before attempting
      // to log in. This decouples TC_AUTH_003 from TC_AUTH_002:
      //   • If TC_AUTH_002 passed  → the user already exists (seed is a no-op).
      //   • If TC_AUTH_002 failed  → the seeder creates the user now.
      //   • If the DB was wiped    → the seeder creates the user from scratch.
      logger.info(`[TC_AUTH_003] Seeding user ${registeredEmail} via backend API...`);
      await seedUser(registeredEmail, testData.validUser.password, testData.validUser.fullName);

      await loginPage.login(registeredEmail, testData.validUser.password);

      const isDashboardVisible = await loginPage.isLoggedIn();
      expect(isDashboardVisible).to.be.true;

      suiteResults.push({ testId, module: 'Auth', scenario, status: 'PASSED', durationMs: Date.now() - startTime });
      excelReporter.addTestResult({ testId, module: 'Auth', scenario, status: 'PASSED', durationMs: Date.now() - startTime });
    } catch (err) {
      const diag = await failureHandler.captureFailureDiagnostics(driver, scenario, err);
      const testResult = {
        testId, module: 'Auth', scenario, status: 'FAILED',
        durationMs: Date.now() - startTime, failureReason: err.message,
        screenshotPath: diag.screenshotPath, stackTrace: err.stack
      };
      suiteResults.push(testResult);
      excelReporter.addTestResult(testResult);
      throw err;
    }
  });
});
