'use strict';

const BasePage = require('./basePage');

/**
 * FormPage — Page Object for Flutter Form screens (RegisterScreen & LoginScreen).
 * Uses actual ValueKeys defined in register_card.dart and login_card.dart.
 */
class FormPage extends BasePage {
  constructor(driver) {
    super(driver);

    // Registration Form Locators (matching register_card.dart)
    this.fullNameInput = this.finder.byValueKey('register_name_input');
    this.emailInput = this.finder.byValueKey('register_email_input');
    this.passwordInput = this.finder.byValueKey('register_password_input');
    this.confirmPasswordInput = this.finder.byValueKey('register_confirm_password_input');
    this.submitFormButton = this.finder.byValueKey('register_button_key');

    // Validation Text Locators
    this.fullNameError = this.finder.byText('Full name is required');
    this.emailError = this.finder.byText('Email is required');
    this.passwordError = this.finder.byText('Password is required');
    this.passwordLengthError = this.finder.byText('Password must be at least 8 characters');
    this.confirmPasswordError = this.finder.byText('Please confirm your password');
    this.formSuccessBanner = this.finder.byText('Registration Successful');
  }

  async enterFullName(name) {
    await this.enterText(this.fullNameInput, name, 'Full Name Field');
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

  async submitForm() {
    await this.click(this.submitFormButton, 'Create Account Button');
  }

  async getFullNameError() {
    return await this.getText(this.fullNameError, 'Full Name Error Message');
  }

  async getEmailError() {
    return await this.getText(this.emailError, 'Email Error Message');
  }

  async getPasswordError() {
    return await this.getText(this.passwordError, 'Password Error Message');
  }

  async isFormSubmittedSuccessfully() {
    return await this.isDisplayed(this.formSuccessBanner, 'Form Success Banner');
  }
}

module.exports = FormPage;
