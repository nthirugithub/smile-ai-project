'use strict';

const BasePage = require('./basePage');

class LoginPage extends BasePage {
  constructor(driver) {
    super(driver);

    // Widget Locators with dual ValueKey and Text fallback support
    this.emailInput = this.finder.byValueKey('email_input_key');
    this.passwordInput = this.finder.byValueKey('password_input_key');
    this.loginButton = this.finder.byValueKey('login_button_key');
    this.logoutButton = this.finder.byValueKey('logout_button_key');
    
    // Text locators matching actual Flutter app screens
    this.emailInputText = this.finder.byText('Email Address');
    this.passwordInputText = this.finder.byText('Password');
    this.loginButtonText = this.finder.byText('Sign In');
    
    // Error & Dashboard Text Locators
    this.emailErrorText = this.finder.byText('Please enter an email address');
    this.passwordErrorText = this.finder.byText('Please enter a password');
    this.loginErrorSnackbar = this.finder.byText('Invalid credentials provided. Access denied.');
    this.userDashboardHeader = this.finder.byText('Dashboard');
  }

  /**
   * Enter email address
   */
  async enterEmail(email) {
    await this.enterText(this.emailInput, email, 'Email Address Field');
  }

  /**
   * Enter password
   */
  async enterPassword(password) {
    await this.enterText(this.passwordInput, password, 'Password Field');
  }

  /**
   * Click login button
   */
  async clickLogin() {
    await this.click(this.loginButton, 'Login Button');
  }

  /**
   * Perform end-to-end login scenario
   */
  async login(email, password) {
    if (email) await this.enterEmail(email);
    if (password) await this.enterPassword(password);
    await this.clickLogin();
  }

  /**
   * Click logout button
   */
  async logout() {
    await this.click(this.logoutButton, 'Logout Button');
  }

  /**
   * Retrieves email field validation error message
   */
  async getEmailValidationError() {
    return await this.getText(this.emailErrorText, 'Email Validation Error');
  }

  /**
   * Retrieves password field validation error message
   */
  async getPasswordValidationError() {
    return await this.getText(this.passwordErrorText, 'Password Validation Error');
  }

  /**
   * Retrieves general login error snackbar text
   */
  async getLoginErrorMessage() {
    return await this.getText(this.loginErrorSnackbar, 'Login Error Snackbar');
  }

  /**
   * Validates if user dashboard is displayed after successful login
   */
  async isLoggedIn() {
    return await this.isDisplayed(this.userDashboardHeader, 'User Dashboard');
  }
}

module.exports = LoginPage;
