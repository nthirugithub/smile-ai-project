'use strict';

const by = require('appium-flutter-finder');

/**
 * Flutter Finder Locator Wrapper API for Flutter Widget Testing
 */
class FlutterFinder {
  /**
   * Locate widget by ValueKey
   * @param {string|number} key 
   */
  byValueKey(key) {
    return by.byValueKey(key);
  }

  /**
   * Locate widget by exact visible Text
   * @param {string} text 
   */
  byText(text) {
    return by.byText(text);
  }

  /**
   * Locate widget by Semantics Label
   * @param {string|RegExp} label 
   */
  bySemanticsLabel(label) {
    return by.bySemanticsLabel(label);
  }

  /**
   * Locate widget by Accessibility ID / Tooltip / Semantics
   * @param {string} id 
   */
  byAccessibilityId(id) {
    return by.byValueKey(id);
  }

  /**
   * Locate widget by Widget Class Type (e.g. 'ElevatedButton', 'TextField')
   * @param {string} type 
   */
  byType(type) {
    return by.byType(type);
  }

  /**
   * Page back key / navigation back
   */
  pageBack() {
    return by.pageBack();
  }

  /**
   * Ancestor finder
   * @param {Object} options { of, matching, matchRoot }
   */
  ancestor({ of, matching, matchRoot = false }) {
    return by.ancestor({ of, matching, matchRoot });
  }

  /**
   * Descendant finder
   * @param {Object} options { of, matching, matchRoot }
   */
  descendant({ of, matching, matchRoot = false }) {
    return by.descendant({ of, matching, matchRoot });
  }

  /**
   * Stringifies/serializes finder for element interaction
   */
  serialize(finder) {
    return typeof finder === 'string' ? finder : JSON.stringify(finder);
  }
}

module.exports = new FlutterFinder();
