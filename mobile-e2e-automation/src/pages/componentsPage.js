'use strict';

const BasePage = require('./basePage');

/**
 * ComponentsPage — Page Object for Flutter UI Components & Interactivity.
 * Uses actual ValueKeys and Text finders present in the SmileAI Flutter app.
 */
class ComponentsPage extends BasePage {
  constructor(driver) {
    super(driver);

    // Real Flutter Buttons & Inputs
    this.elevatedBtn = this.finder.byValueKey('login_button_key');
    this.textBtn = this.finder.byText('Sign Up');
    this.iconBtn = this.finder.byValueKey('register_button_key');
    this.emailInput = this.finder.byValueKey('email_input_key');
  }

  async clickElevatedButton() {
    return await this.waitForVisible(this.elevatedBtn, 5000, 'Login Button');
  }

  async clickTextButton() {
    return await this.waitForVisible(this.textBtn, 5000, 'Sign Up Link');
  }

  async clickIconButton() {
    return await this.waitForVisible(this.emailInput, 5000, 'Email Input Field');
  }
}

module.exports = ComponentsPage;
