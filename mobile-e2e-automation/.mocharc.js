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
  retries: 0,
  slow: '10000',
  timeout: '60000', // 1 minute per spec for fast E2E execution
  ui: 'bdd',
  exit: true,
  spec: ['test/specs/suite300.spec.js']
};
