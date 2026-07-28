'use strict';

const logger = require('./logger');

class GestureUtils {
  /**
   * Safely retrieves screen dimensions with fallback if driver does not support getWindowSize
   */
  async getScreenBounds(driver) {
    try {
      const size = await driver.getWindowSize();
      if (size && size.width && size.height) {
        return size;
      }
    } catch (err) {
      logger.warn(`getWindowSize notice: ${err.message}. Using default screen bounds (1080x2340).`);
    }
    return { width: 1080, height: 2340 };
  }

  /**
   * Performs W3C Single Tap on coordinates or element
   */
  async tap(driver, x, y) {
    logger.info(`Performing W3C Tap at (${x}, ${y})`);
    await driver.performActions([
      {
        type: 'pointer',
        id: 'finger1',
        parameters: { pointerType: 'touch' },
        actions: [
          { type: 'pointerMove', duration: 0, x: Math.round(x), y: Math.round(y) },
          { type: 'pointerDown', button: 0 },
          { type: 'pause', duration: 100 },
          { type: 'pointerUp', button: 0 }
        ]
      }
    ]);
    await driver.releaseActions();
  }

  /**
   * Performs W3C Double Tap
   */
  async doubleTap(driver, x, y) {
    logger.info(`Performing W3C Double Tap at (${x}, ${y})`);
    await driver.performActions([
      {
        type: 'pointer',
        id: 'finger1',
        parameters: { pointerType: 'touch' },
        actions: [
          { type: 'pointerMove', duration: 0, x: Math.round(x), y: Math.round(y) },
          { type: 'pointerDown', button: 0 },
          { type: 'pause', duration: 50 },
          { type: 'pointerUp', button: 0 },
          { type: 'pause', duration: 100 },
          { type: 'pointerDown', button: 0 },
          { type: 'pause', duration: 50 },
          { type: 'pointerUp', button: 0 }
        ]
      }
    ]);
    await driver.releaseActions();
  }

  /**
   * Performs W3C Long Press
   */
  async longPress(driver, x, y, durationMs = 1500) {
    logger.info(`Performing W3C Long Press at (${x}, ${y}) for ${durationMs}ms`);
    await driver.performActions([
      {
        type: 'pointer',
        id: 'finger1',
        parameters: { pointerType: 'touch' },
        actions: [
          { type: 'pointerMove', duration: 0, x: Math.round(x), y: Math.round(y) },
          { type: 'pointerDown', button: 0 },
          { type: 'pause', duration: durationMs },
          { type: 'pointerUp', button: 0 }
        ]
      }
    ]);
    await driver.releaseActions();
  }

  /**
   * Performs W3C Scroll/Swipe from start (x1, y1) to end (x2, y2)
   */
  async swipe(driver, startX, startY, endX, endY, durationMs = 800) {
    logger.info(`Performing Swipe from (${startX}, ${startY}) to (${endX}, ${endY})`);
    await driver.performActions([
      {
        type: 'pointer',
        id: 'finger1',
        parameters: { pointerType: 'touch' },
        actions: [
          { type: 'pointerMove', duration: 0, x: Math.round(startX), y: Math.round(startY) },
          { type: 'pointerDown', button: 0 },
          { type: 'pointerMove', duration: durationMs, x: Math.round(endX), y: Math.round(endY) },
          { type: 'pointerUp', button: 0 }
        ]
      }
    ]);
    await driver.releaseActions();
  }

  /**
   * Performs Swipe Up / Scroll Down
   */
  async scrollDown(driver, distanceFactor = 0.6) {
    const { width, height } = await this.getScreenBounds(driver);
    const startX = width / 2;
    const startY = height * 0.8;
    const endY = height * (0.8 - distanceFactor);
    await this.swipe(driver, startX, startY, startX, endY);
  }

  /**
   * Performs Swipe Down / Scroll Up
   */
  async scrollUp(driver, distanceFactor = 0.6) {
    const { width, height } = await this.getScreenBounds(driver);
    const startX = width / 2;
    const startY = height * 0.2;
    const endY = height * (0.2 + distanceFactor);
    await this.swipe(driver, startX, startY, startX, endY);
  }

  /**
   * Performs Drag & Drop from source coordinates to target coordinates
   */
  async dragAndDrop(driver, startX, startY, endX, endY) {
    logger.info(`Performing Drag and Drop from (${startX}, ${startY}) to (${endX}, ${endY})`);
    await driver.performActions([
      {
        type: 'pointer',
        id: 'finger1',
        parameters: { pointerType: 'touch' },
        actions: [
          { type: 'pointerMove', duration: 0, x: Math.round(startX), y: Math.round(startY) },
          { type: 'pointerDown', button: 0 },
          { type: 'pause', duration: 500 },
          { type: 'pointerMove', duration: 1000, x: Math.round(endX), y: Math.round(endY) },
          { type: 'pointerUp', button: 0 }
        ]
      }
    ]);
    await driver.releaseActions();
  }

  /**
   * Performs Pinch gesture (zoom out)
   */
  async pinch(driver) {
    logger.info('Performing Pinch gesture');
    const { width, height } = await this.getScreenBounds(driver);
    const centerX = width / 2;
    const centerY = height / 2;

    await driver.performActions([
      {
        type: 'pointer',
        id: 'finger1',
        parameters: { pointerType: 'touch' },
        actions: [
          { type: 'pointerMove', duration: 0, x: centerX - 200, y: centerY - 200 },
          { type: 'pointerDown', button: 0 },
          { type: 'pointerMove', duration: 800, x: centerX - 50, y: centerY - 50 },
          { type: 'pointerUp', button: 0 }
        ]
      },
      {
        type: 'pointer',
        id: 'finger2',
        parameters: { pointerType: 'touch' },
        actions: [
          { type: 'pointerMove', duration: 0, x: centerX + 200, y: centerY + 200 },
          { type: 'pointerDown', button: 0 },
          { type: 'pointerMove', duration: 800, x: centerX + 50, y: centerY + 50 },
          { type: 'pointerUp', button: 0 }
        ]
      }
    ]);
    await driver.releaseActions();
  }

  /**
   * Performs Zoom gesture (pinch open)
   */
  async zoom(driver) {
    logger.info('Performing Zoom gesture');
    const { width, height } = await this.getScreenBounds(driver);
    const centerX = width / 2;
    const centerY = height / 2;

    await driver.performActions([
      {
        type: 'pointer',
        id: 'finger1',
        parameters: { pointerType: 'touch' },
        actions: [
          { type: 'pointerMove', duration: 0, x: centerX - 50, y: centerY - 50 },
          { type: 'pointerDown', button: 0 },
          { type: 'pointerMove', duration: 800, x: centerX - 250, y: centerY - 250 },
          { type: 'pointerUp', button: 0 }
        ]
      },
      {
        type: 'pointer',
        id: 'finger2',
        parameters: { pointerType: 'touch' },
        actions: [
          { type: 'pointerMove', duration: 0, x: centerX + 50, y: centerY + 50 },
          { type: 'pointerDown', button: 0 },
          { type: 'pointerMove', duration: 800, x: centerX + 250, y: centerY + 250 },
          { type: 'pointerUp', button: 0 }
        ]
      }
    ]);
    await driver.releaseActions();
  }

  /**
   * Scroll until element finder becomes visible (Flutter scroll)
   */
  async scrollToElement(driver, scrollViewFinder, itemFinder, maxSwipes = 10) {
    logger.info('Scrolling to element using Flutter scroll command');
    try {
      await driver.execute('flutter:scrollUntilVisible', scrollViewFinder, {
        item: itemFinder,
        dxScroll: 0,
        dyScroll: -300
      });
      return true;
    } catch (err) {
      logger.warn(`Flutter driver scroll command failed: ${err.message}. Falling back to W3C swipe scroll.`);
      for (let i = 0; i < maxSwipes; i++) {
        try {
          const isVisible = await driver.execute('flutter:checkHealth');
          if (isVisible) break;
        } catch (e) {
          // ignore
        }
        await this.scrollDown(driver);
      }
      return false;
    }
  }
}

module.exports = new GestureUtils();
