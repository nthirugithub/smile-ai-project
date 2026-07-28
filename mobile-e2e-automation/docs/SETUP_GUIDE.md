# Enterprise Flutter Appium Automation - Setup & Troubleshooting Guide

This guide provides step-by-step instructions for setting up your local development environment, configuring real Android devices and emulators, running Appium 2.x with `appium-flutter-driver`, and troubleshooting common issues.

---

## 🛠️ System Prerequisites Setup

### 1. Install Node.js (v18+)
Download and install Node.js from [nodejs.org](https://nodejs.org/).
Verify installation:
```bash
node -v
npm -v
```

### 2. Install Java JDK (v17)
Install OpenJDK 17 or Eclipse Temurin 17.
Set your `JAVA_HOME` environment variable:
- **Windows**: `C:\Program Files\Eclipse Adoptium\jdk-17.x.x-hotspot`
- **macOS/Linux**: `/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home`

Verify Java:
```bash
java -version
```

### 3. Install Android SDK & Configure Environment Variables
Install Android Studio and ensure Android SDK Build-Tools and Platform-Tools are installed.
Set environment variables:
- **`ANDROID_HOME`**: `C:\Users\<Username>\AppData\Local\Android\Sdk` (Windows) or `/Users/<Username>/Library/Android/sdk` (macOS).
- **Add to PATH**:
  - `%ANDROID_HOME%\platform-tools`
  - `%ANDROID_HOME%\tools`
  - `%ANDROID_HOME%\emulator`

Verify ADB:
```bash
adb devices
```

---

## 📱 Appium 2.x & Flutter Driver Installation

### 1. Install Appium 2.x Globally
```bash
npm install -g appium@latest
```
Verify version:
```bash
appium -v
```

### 2. Install Appium Flutter Driver & UiAutomator2 Driver
```bash
appium driver install flutter
appium driver install uiautomator2
```
Verify installed drivers:
```bash
appium driver list
```

---

## ⚙️ Configuration & Environment Variables

Copy or create a `.env` file in `mobile-e2e-automation/`:

```env
APK_PATH=./app/app-release.apk
APP_PACKAGE=com.company.app
APP_ACTIVITY=com.company.app.MainActivity
PLATFORM_NAME=Android
PLATFORM_VERSION=13.0
DEVICE_NAME=Android Emulator
UDID=emulator-5554
AUTOMATION_NAME=Flutter
APPIUM_HOST=127.0.0.1
APPIUM_PORT=4723
TEST_RETRIES=2
LOG_LEVEL=info
```

---

## 🚀 Running Local Executions

### 1. Start Appium Server
In terminal 1:
```bash
appium
```

### 2. Start Connected Android Emulator or Real Device
Verify device connection:
```bash
adb devices
```

### 3. Execute Tests
In terminal 2:
```bash
cd mobile-e2e-automation

# Install dependencies
npm install

# Run all test suites
npm run test:all

# Run specific suite
npm run test:auth
```

---

## ❓ Troubleshooting Guide

### Problem 1: `appium-flutter-driver` cannot find Flutter bindings
**Cause**: The target Flutter APK must be built in `debug` or `profile` mode (or compiled with VM Service / Observatory enabled). Production release builds with stripped symbols do not expose the Flutter VM Service needed for `byValueKey` finders.
**Solution**: Ensure APK is built using:
```bash
flutter build apk --debug
# or
flutter build apk --profile
```

### Problem 2: ADB connection drop or offline device
**Cause**: Emulator freeze or USB debugging disconnect.
**Solution**: Restart ADB daemon:
```bash
adb kill-server
adb start-server
adb devices
```

### Problem 3: Context Switch Failure (UiAutomator2 vs Flutter)
**Cause**: Interacting with native OS popups while in FLUTTER context.
**Solution**: Call `driverFactory.switchContext('NATIVE_APP')` before clicking native popups, and `driverFactory.switchContext('FLUTTER')` afterwards.
