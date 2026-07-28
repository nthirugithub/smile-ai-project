'use strict';

const winston = require('winston');
const path = require('path');
const fs = require('fs');
const env = require('../../config/env.config');

if (!fs.existsSync(env.logsDir)) {
  fs.mkdirSync(env.logsDir, { recursive: true });
}

const customFormat = winston.format.printf(({ level, message, timestamp, ...metadata }) => {
  let msg = `${timestamp} [${level.toUpperCase()}] : ${message}`;
  if (Object.keys(metadata).length > 0) {
    msg += ` ${JSON.stringify(metadata)}`;
  }
  return msg;
});

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss.SSS' }),
    winston.format.splat(),
    customFormat
  ),
  transports: [
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.timestamp({ format: 'HH:mm:ss' }),
        customFormat
      )
    }),
    new winston.transports.File({
      filename: path.join(env.logsDir, 'execution.log'),
      maxsize: 10485760, // 10MB
      maxFiles: 5
    }),
    new winston.transports.File({
      filename: path.join(env.logsDir, 'errors.log'),
      level: 'error'
    })
  ]
});

// Helper step logger for structured reporting
logger.step = function (testName, stepDescription) {
  const logMessage = `[STEP] [${testName}] -> ${stepDescription}`;
  logger.info(logMessage);
  return logMessage;
};

module.exports = logger;
