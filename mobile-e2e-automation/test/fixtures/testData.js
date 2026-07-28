'use strict';

module.exports = {
  validUser: {
    email: 'qa.architect@enterprise.com',
    password: 'P@ssword123!',
    fullName: 'Enterprise Senior QA Architect',
    phone: '+14155552671'
  },

  invalidUsers: {
    emptyEmail: {
      email: '',
      password: 'P@ssword123!',
      expectedError: 'Please enter an email address'
    },
    emptyPassword: {
      email: 'qa.architect@enterprise.com',
      password: '',
      expectedError: 'Please enter a password'
    },
    malformedEmail: {
      email: 'not-an-email-address',
      password: 'P@ssword123!',
      expectedError: 'Enter a valid email format'
    },
    shortPassword: {
      email: 'qa.architect@enterprise.com',
      password: '123',
      expectedError: 'Password must be at least 8 characters'
    },
    badCredentials: {
      email: 'wrong.user@enterprise.com',
      password: 'WrongPassword999',
      expectedSnackbar: 'Invalid credentials provided. Access denied.'
    }
  },

  formValidation: {
    invalidPhones: ['123', 'abc', '+++0000'],
    expectedPhoneError: 'Enter a valid phone number (10+ digits)',
    passwordComplexityRule: 'Password must contain uppercase, lowercase, number, and special character'
  },

  componentData: {
    listItemsCount: 10,
    expectedSnackbarText: 'Flutter Action Executed Successfully!'
  }
};
