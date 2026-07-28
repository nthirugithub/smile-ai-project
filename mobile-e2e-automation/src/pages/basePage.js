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
   * Safe wait for Flutter element to become visible / rendered
   */
  async waitForVisible(finder, timeoutMs = 15000, description = 'Flutter element') {
    logger.info(`Waiting for ${description} to be visible...`);
    const serialized = this.finder.serialize(finder);
    
    const startTime = Date.now();
    while (Date.now() - startTime < timeoutMs) {
      try {
        const isRendered = await this.driver.execute('flutter:checkHealth');
        if (isRendered) {
          await this.driver.elementSendKeys(serialized, ''); // touch finder check
          return true;
        }
      } catch (err) {
        // Continue polling
      }
      await this.driver.pause(500);
    }
    logger.warn(`Timeout waiting for ${description} after ${timeoutMs}ms.`);
    return false;
  }

  /**
   * Clicks a Flutter widget
   */
  async click(finder, description = 'Widget') {
    logger.step(this.constructor.name, `Click on ${description}`);
    excelReporter.logStep(this.constructor.name, `Click on ${description}`);
    
    const serialized = this.finder.serialize(finder);
    try {
      await this.driver.elementClick(serialized);
    } catch (err) {
      logger.warn(`Flutter elementClick failed for ${description}: ${err.message}. Retrying via flutter execute tap...`);
      await this.driver.execute('flutter:click', serialized);
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
      await this.driver.elementSendKeys(serialized, text);
    } catch (err) {
      await this.driver.execute('flutter:enterText', text);
    }
  }

  /**
   * Retrieves visible text content from Flutter Text widget
   */
  async getText(finder, description = 'Text Widget') {
    logger.info(`Getting text content from ${description}`);
    const serialized = this.finder.serialize(finder);
    try {
      return await this.driver.getElementText(serialized);
    } catch (err) {
      return await this.driver.execute('flutter:getText', serialized);
    }
  }

  /**
   * Checks if Flutter widget is rendered on current screen
   */
  async isDisplayed(finder, description = 'Widget') {
    try {
      const text = await this.getText(finder, description);
      return text !== null && text !== undefined;
    } catch (err) {
      return false;
    }
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
