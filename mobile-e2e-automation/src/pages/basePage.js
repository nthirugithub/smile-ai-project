'use strict';

const flutterFinder = require('../driver/flutterFinder');
const gestures = require('../utils/gestures');
const logger = require('../utils/logger');
const excelReporter = require('../utils/excelReporter');

class BasePage {
  constructor(driver) {
    this.driver = driver;
    this.finder = flutterFinder;
  }

  /**
   * Safe wait for Flutter element to become visible / rendered using flutter:waitFor
   */
  async waitForVisible(finder, timeoutMs = 15000, description = 'Flutter element') {
    logger.info(`Waiting for ${description} to be visible...`);
    const serialized = this.finder.serialize(finder);
    const timeoutInSeconds = Math.max(1, Math.floor(timeoutMs / 1000));
    try {
      await this.driver.execute('flutter:waitFor', serialized, timeoutInSeconds);
      return true;
    } catch (err) {
      logger.warn(`Timeout waiting for ${description} after ${timeoutMs}ms: ${err.message}`);
      return false;
    }
  }

  /**
   * Clicks a Flutter widget cleanly without Promise.race command flooding
   */
  async click(finder, description = 'Widget', timeoutMs = 15000) {
    logger.step(this.constructor.name, `Click on ${description}`);
    excelReporter.logStep(this.constructor.name, `Click on ${description}`);
    
    const serialized = this.finder.serialize(finder);
    try {
      await this.driver.execute('flutter:click', serialized);
    } catch (err) {
      logger.warn(`flutter:click execution fallback notice for ${description}: ${err.message}`);
      try {
        await this.driver.elementClick(serialized);
      } catch (fallbackErr) {
        logger.error(`Failed to click ${description}: ${fallbackErr.message}`);
        throw fallbackErr;
      }
    }
  }

  /**
   * Enters text into Flutter TextField widget
   */
  async enterText(finder, text, description = 'TextField') {
    logger.step(this.constructor.name, `Enter text into ${description}: "${text}"`);
    excelReporter.logStep(this.constructor.name, `Enter text into ${description}`);
    
    const serialized = this.finder.serialize(finder);
    await this.click(finder, description);
    try {
      await this.driver.execute('flutter:enterText', text);
    } catch (err) {
      try {
        await this.driver.elementSendKeys(serialized, text);
      } catch (sendErr) {
        logger.error(`Failed to enter text into ${description}: ${sendErr.message}`);
        throw sendErr;
      }
    }
  }

  /**
   * Retrieves visible text content from Flutter Text widget
   */
  async getText(finder, description = 'Text Widget') {
    logger.info(`Getting text content from ${description}`);
    const serialized = this.finder.serialize(finder);
    try {
      return await this.driver.execute('flutter:getText', serialized);
    } catch (err) {
      return await this.driver.getElementText(serialized);
    }
  }

  /**
   * Checks if Flutter widget is rendered on current screen
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
      await this.click(this.finder.pageBack(), 'Page Back Key');
    } catch (err) {
      await this.driver.back();
    }
  }

  /**
   * Perform gesture scroll down
   */
  async scrollDown() {
    await gestures.scrollDown(this.driver);
  }

  /**
   * Perform gesture scroll up
   */
  async scrollUp() {
    await gestures.scrollUp(this.driver);
  }
}

module.exports = BasePage;
