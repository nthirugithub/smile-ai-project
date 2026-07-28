'use strict';

module.exports = {
  diff: true,
  extension: ['js'],
  package: './package.json',
  reporter: 'mochawesome',
  'reporter-option': [
    'reportDir=reports',
    'reportFilename=mochawesome',
    'quiet=false',
    'overwrite=true',
    'html=true',
    'json=true',
    'consoleReporter=spec'
  ],
  retries: 1,
  slow: '10000',
  timeout: '300000', // 5 minutes per spec for E2E mobile operations
  ui: 'bdd',
  spec: ['test/specs/**/*.spec.js']
};
