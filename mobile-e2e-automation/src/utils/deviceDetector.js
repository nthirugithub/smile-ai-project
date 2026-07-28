'use strict';

const { execSync } = require('child_process');
const logger = require('./logger');

class DeviceDetector {
  /**
   * Auto-detects connected Android devices or running emulators via ADB
   * Returns metadata object: { udid, deviceName, platformVersion, isEmulator }
   */
  getConnectedDevice() {
    try {
      const output = execSync('adb devices', { encoding: 'utf8' });
      const lines = output.split('\n').filter(line => line.trim() && !line.startsWith('List of devices'));
      
      if (lines.length === 0) {
        logger.warn('No active ADB devices detected. Falling back to default configuration.');
        return {
          udid: 'emulator-5554',
          deviceName: 'Android Emulator',
          platformVersion: '13.0',
          isEmulator: true
        };
      }

      const firstDeviceLine = lines[0];
      const [udid, status] = firstDeviceLine.split(/\s+/);
      
      if (status !== 'device') {
        logger.warn(`Device ${udid} is in status: ${status}. Waiting or using default.`);
      }

      let model = 'Android Device';
      let version = '13.0';
      
      try {
        model = execSync(`adb -s ${udid} shell getprop ro.product.model`, { encoding: 'utf8' }).trim() || model;
        version = execSync(`adb -s ${udid} shell getprop ro.build.version.release`, { encoding: 'utf8' }).trim() || version;
      } catch (err) {
        logger.debug(`Could not retrieve props for device ${udid}: ${err.message}`);
      }

      const isEmulator = udid.includes('emulator') || model.toLowerCase().includes('sdk') || model.toLowerCase().includes('emulator');

      logger.info(`Detected Android Device -> UDID: ${udid}, Model: ${model}, OS Version: ${version}, Emulator: ${isEmulator}`);

      return {
        udid,
        deviceName: model,
        platformVersion: version,
        isEmulator
      };
    } catch (error) {
      logger.error(`Error during ADB device detection: ${error.message}`);
      return {
        udid: process.env.UDID || 'emulator-5554',
        deviceName: process.env.DEVICE_NAME || 'Android Emulator',
        platformVersion: process.env.PLATFORM_VERSION || '13.0',
        isEmulator: true
      };
    }
  }
}

module.exports = new DeviceDetector();
