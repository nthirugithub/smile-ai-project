'use strict';

const flutterFinder = require('../driver/flutterFinder');
const gestures = require('../utils/gestures');
const logger = require('../utils/logger');
const excelReporter = require('../utils/excelReporter');

/**
 * BasePage — all Flutter element interactions.
 *
 * ROOT CAUSE FIX (RC-2):
 * W3C `elementClick()` bypasses `flutter:setFrameSync(false)` in some
 * appium-flutter-driver versions and calls `waitUntilNoTransientCallbacks`
 * regardless. When a SnackBar is showing (ModalBarrier blocking:true) or an
 * entrance animation is running, `waitUntilNoTransientCallbacks` never
 * resolves → 180-second hang.
 *
 * FIX: Re-assert `flutter:setFrameSync(false)` before EVERY command that
 * communicates with the Flutter extension, and use `flutter:clickElement`
 * (execute-script path, which respects frame-sync off) as the PRIMARY click
 * method, falling back to W3C `elementClick` only if the execute call throws.
 */
class BasePage {
  constructor(driver) {
    this.driver = driver;
    this.finder = flutterFinder;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FRAME SYNC GUARD
  // ─────────────────────────────────────────────────────────────────────────

  /**
   * Re-asserts setFrameSync(false) before commands.
   * Suppresses any error so it never blocks the actual command.
   */
  async _disableFrameSync() {
    try {
      await this.driver.execute('flutter:setFrameSync', false, 1000);
    } catch (_) {
      // ignore — driver might not support it or already set
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CORE INTERACTION METHODS
  // ─────────────────────────────────────────────────────────────────────────

  /**
   * Waits until a Flutter element is visible using flutter:waitFor.
   * Returns true if found within timeoutMs, false otherwise.
   */
  async waitForVisible(finder, timeoutMs = 15000, description = 'Flutter element') {
    logger.info(`Waiting for ${description} to be visible (${timeoutMs}ms)...`);
    await this._disableFrameSync();
    const serialized = this.finder.serialize(finder);
    try {
      await this.driver.execute('flutter:waitFor', serialized, timeoutMs);
      return true;
    } catch (err) {
      logger.warn(`Timeout waiting for ${description} after ${timeoutMs}ms: ${err.message}`);
      // Re-assert frame sync off after a waitFor timeout — some driver versions
      // re-enable frame sync when a waitFor command fails.
      await this._disableFrameSync();
      return false;
    }
  }

  /**
   * Waits until a Flutter element is ABSENT using flutter:waitForAbsent.
   * Used to wait for SnackBars and loading overlays to dismiss.
   */
  async waitForAbsent(finder, timeoutMs = 10000, description = 'Flutter element') {
    logger.info(`Waiting for ${description} to disappear (${timeoutMs}ms)...`);
    await this._disableFrameSync();
    const serialized = this.finder.serialize(finder);
    try {
      await this.driver.execute('flutter:waitForAbsent', serialized, timeoutMs);
      return true;
    } catch (err) {
      logger.warn(`Timeout waiting for ${description} to disappear: ${err.message}`);
      await this._disableFrameSync();
      return false;
    }
  }

  /**
   * Clicks a Flutter widget.
   *
   * PRIMARY: flutter:clickElement (execute-script path — respects setFrameSync off)
   * FALLBACK: W3C elementClick
   *
   * RC-2 fix: execute-script path does NOT call waitUntilNoTransientCallbacks
   * when frame sync is disabled. W3C elementClick DOES call it regardless.
   */
  async click(finder, description = 'Widget') {
    logger.step(this.constructor.name, `Click on ${description}`);
    excelReporter.logStep(this.constructor.name, `Click on ${description}`);

    await this._disableFrameSync();
    const serialized = this.finder.serialize(finder);

    try {
      // PRIMARY: execute path — honours setFrameSync(false)
      await this.driver.execute('flutter:clickElement', serialized);
    } catch (err) {
      logger.warn(`flutter:clickElement notice for ${description}: ${err.message}. Retrying via W3C elementClick...`);
      try {
        await this._disableFrameSync();
        await this.driver.elementClick(serialized);
      } catch (fallbackErr) {
        logger.error(`Failed to click ${description}: ${fallbackErr.message}`);
        throw fallbackErr;
      }
    }
  }

  /**
   * Enters text into a Flutter TextField.
   * Clicks the field first to focus it, then sends keys.
   */
  async enterText(finder, text, description = 'TextField') {
    logger.step(this.constructor.name, `Enter text into ${description}: "${text}"`);
    excelReporter.logStep(this.constructor.name, `Enter text into ${description}`);

    await this._disableFrameSync();
    const serialized = this.finder.serialize(finder);
    await this.click(finder, description);
    try {
      await this.driver.elementSendKeys(serialized, text);
    } catch (err) {
      logger.warn(`elementSendKeys notice for ${description}: ${err.message}. Retrying via flutter:enterText...`);
      try {
        await this.driver.execute('flutter:enterText', text);
      } catch (fallbackErr) {
        logger.error(`Failed to enter text into ${description}: ${fallbackErr.message}`);
        throw fallbackErr;
      }
    }
  }

  /**
   * Retrieves visible text content from a Flutter Text widget.
   */
  async getText(finder, description = 'Text Widget') {
    logger.info(`Getting text content from ${description}`);
    await this._disableFrameSync();
    const serialized = this.finder.serialize(finder);
    try {
      return await this.driver.getElementText(serialized);
    } catch (err) {
      logger.warn(`getElementText notice for ${description}: ${err.message}`);
      throw err;
    }
  }

  /**
   * Checks if a Flutter widget is rendered on the current screen.
   * Uses a short timeout so negative checks fail fast.
   */
  async isDisplayed(finder, description = 'Widget', timeoutMs = 5000) {
    return await this.waitForVisible(finder, timeoutMs, description);
  }

  /**
   * Navigates back.
   */
  async goBack() {
    logger.step(this.constructor.name, 'Navigate Back');
    try {
      await this.click(this.finder.pageBack(), 'Page Back Key');
    } catch (err) {
      await this.driver.back();
    }
  }

  /**
   * Scroll down gesture.
   */
  async scrollDown() {
    await gestures.scrollDown(this.driver);
  }

  /**
   * Scroll up gesture.
   */
  async scrollUp() {
    await gestures.scrollUp(this.driver);
  }
}

module.exports = BasePage;
