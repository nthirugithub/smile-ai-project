'use strict';

const BasePage = require('./basePage');

class RegisterPage extends BasePage {
  constructor(driver) {
    super(driver);

    // ValueKey finders matching register_card.dart
    this.nameInput = this.finder.byValueKey('register_name_input');
    this.emailInput = this.finder.byValueKey('register_email_input');
    this.passwordInput = this.finder.byValueKey('register_password_input');
    this.confirmPasswordInput = this.finder.byValueKey('register_confirm_password_input');
    this.registerButton = this.finder.byValueKey('register_button_key');

    // Text locators
    this.registerTitle = this.finder.byText('Create Account');
    this.signInLink = this.finder.byText('Sign In');
  }

  async enterFullName(name) {
    await this.enterText(this.nameInput, name, 'Full Name Field');
  }

  async enterEmail(email) {
    await this.enterText(this.emailInput, email, 'Email Field');
  }

  async enterPassword(password) {
    await this.enterText(this.passwordInput, password, 'Password Field');
  }

  async enterConfirmPassword(password) {
    await this.enterText(this.confirmPasswordInput, password, 'Confirm Password Field');
  }

  async clickRegister() {
    await this.click(this.registerButton, 'Create Account Button');
  }

  async registerUser(name, email, password) {
    if (name) await this.enterFullName(name);
    if (email) await this.enterEmail(email);
    if (password) {
      await this.enterPassword(password);
      await this.enterConfirmPassword(password);
    }
    await this.clickRegister();
  }

  async goToLogin() {
    await this.click(this.signInLink, 'Sign In Link');
  }
}

module.exports = RegisterPage;
