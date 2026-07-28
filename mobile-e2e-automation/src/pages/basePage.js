'use strict';

const flutterFinder = require('../driver/flutterFinder');
const gestures = require('../utils/gestures');
const logger = require('../utils/logger');
const excelReporter = require('../utils/excelReporter');

/**
 * BasePage — core interaction helpers for Flutter Driver & WebdriverIO.
 */
class BasePage {
  constructor(driver) {
    this.driver = driver;
    this.finder = flutterFinder;
  }

  /**
   * Re-asserts setFrameSync(false) before commands.
   */
  async _disableFrameSync() {
    try {
      await this.driver.execute('flutter:setFrameSync', false, 1000);
    } catch (_) {
      // ignore
    }
  }

  /**
   * Waits until a Flutter element is visible using flutter:waitFor.
   * Returns true if found within timeoutMs, false otherwise.
   */
  async waitForVisible(finder, timeoutMs = 10000, description = 'Flutter element') {
    logger.info(`Waiting for ${description} to be visible (${timeoutMs}ms)...`);
    await this._disableFrameSync();
    const serialized = this.finder.serialize(finder);
    try {
      await this.driver.execute('flutter:waitFor', serialized, timeoutMs);
      return true;
    } catch (err) {
      logger.warn(`Timeout waiting for ${description} after ${timeoutMs}ms: ${err.message}`);
      await this._disableFrameSync();
      return false;
    }
  }

  /**
   * Waits until a Flutter element is ABSENT using flutter:waitForAbsent.
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
   * Checks waitForVisible first so missing elements fail with a clean error
   * instead of timing out in Flutter Driver tap command.
   */
  async click(finder, description = 'Widget', timeoutMs = 10000) {
    logger.step(this.constructor.name, `Click on ${description}`);
    excelReporter.logStep(this.constructor.name, `Click on ${description}`);

    const isVisible = await this.waitForVisible(finder, timeoutMs, description);
    if (!isVisible) {
      const err = new Error(`Element "${description}" was not found or is not visible on screen within ${timeoutMs}ms.`);
      logger.error(err.message);
      throw err;
    }

    await this._disableFrameSync();
    const serialized = this.finder.serialize(finder);

    try {
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
   * Enters text into a Flutter TextField widget.
   */
  async enterText(finder, text, description = 'TextField', timeoutMs = 10000) {
    logger.step(this.constructor.name, `Enter text into ${description}: "${text}"`);
    excelReporter.logStep(this.constructor.name, `Enter text into ${description}`);

    await this.click(finder, description, timeoutMs);
    const serialized = this.finder.serialize(finder);
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
   * Checks if Flutter widget is rendered on current screen.
   */
  async isDisplayed(finder, description = 'Widget', timeoutMs = 5000) {
    return await this.waitForVisible(finder, timeoutMs, description);
  }

  /**
   * Performs Back Navigation
   */
  async goBack() {
    logger.step(this.constructor.name, 'Navigate Back');
    try {
      await this.click(this.finder.pageBack(), 'Page Back Key', 3000);
    } catch (err) {
      await this.driver.back();
    }
  }

  /**
   * Scroll down gesture
   */
  async scrollDown() {
    await gestures.scrollDown(this.driver);
  }

  /**
   * Scroll up gesture
   */
  async scrollUp() {
    await gestures.scrollUp(this.driver);
  }
}

module.exports = BasePage;
