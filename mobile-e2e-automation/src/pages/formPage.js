'use strict';

const BasePage = require('./basePage');

class FormPage extends BasePage {
  constructor(driver) {
    super(driver);

    // Form Field Locators (ValueKeys)
    this.fullNameInput = this.finder.byValueKey('full_name_input');
    this.emailInput = this.finder.byValueKey('form_email_input');
    this.phoneInput = this.finder.byValueKey('phone_input');
    this.passwordInput = this.finder.byValueKey('form_password_input');
    this.dobPickerButton = this.finder.byValueKey('dob_picker_button');
    this.countryDropdown = this.finder.byValueKey('country_dropdown');
    this.genderMaleRadio = this.finder.byValueKey('gender_male_radio');
    this.genderFemaleRadio = this.finder.byValueKey('gender_female_radio');
    this.termsCheckbox = this.finder.byValueKey('terms_checkbox');
    this.newsletterSwitch = this.finder.byValueKey('newsletter_switch');
    this.submitFormButton = this.finder.byValueKey('submit_form_button');

    // Validation Message Locators
    this.fullNameError = this.finder.byValueKey('full_name_error');
    this.emailError = this.finder.byValueKey('form_email_error');
    this.phoneError = this.finder.byValueKey('phone_error');
    this.passwordError = this.finder.byValueKey('form_password_error');
    this.termsError = this.finder.byValueKey('terms_error');
    this.formSuccessBanner = this.finder.byValueKey('form_success_banner');
  }

  async enterFullName(name) {
    await this.enterText(this.fullNameInput, name, 'Full Name');
  }

  async enterEmail(email) {
    await this.enterText(this.emailInput, email, 'Email Field');
  }

  async enterPhone(phone) {
    await this.enterText(this.phoneInput, phone, 'Phone Number Field');
  }

  async enterPassword(password) {
    await this.enterText(this.passwordInput, password, 'Password Field');
  }

  async selectDateOfBirth() {
    await this.click(this.dobPickerButton, 'Date of Birth Picker');
    // Click OK / Confirm on Flutter DatePicker dialog
    const confirmButton = this.finder.byText('OK');
    await this.click(confirmButton, 'DatePicker OK Button');
  }

  async selectCountry(countryName) {
    await this.click(this.countryDropdown, 'Country Dropdown');
    const optionFinder = this.finder.byText(countryName);
    await this.click(optionFinder, `Country Option: ${countryName}`);
  }

  async selectGender(gender = 'male') {
    const radio = gender.toLowerCase() === 'male' ? this.genderMaleRadio : this.genderFemaleRadio;
    await this.click(radio, `Gender Radio: ${gender}`);
  }

  async toggleTerms(agree = true) {
    if (agree) {
      await this.click(this.termsCheckbox, 'Terms & Conditions Checkbox');
    }
  }

  async toggleNewsletter(enable = true) {
    if (enable) {
      await this.click(this.newsletterSwitch, 'Newsletter Switch');
    }
  }

  async submitForm() {
    await this.click(this.submitFormButton, 'Submit Form Button');
  }

  // Getters for Flutter validation error messages
  async getFullNameError() {
    return await this.getText(this.fullNameError, 'Full Name Error Message');
  }

  async getEmailError() {
    return await this.getText(this.emailError, 'Form Email Error Message');
  }

  async getPhoneError() {
    return await this.getText(this.phoneError, 'Phone Error Message');
  }

  async getPasswordError() {
    return await this.getText(this.passwordError, 'Form Password Error Message');
  }

  async getTermsError() {
    return await this.getText(this.termsError, 'Terms Error Message');
  }

  async isFormSubmittedSuccessfully() {
    return await this.isDisplayed(this.formSuccessBanner, 'Form Success Banner');
  }
}

module.exports = FormPage;
