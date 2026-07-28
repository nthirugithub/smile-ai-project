# Enterprise Flutter Android E2E Automation Framework

[![Appium 2.x](https://img.shields.io/badge/Appium-2.x-blue.svg)](https://appium.io/)
[![Flutter Driver](https://img.shields.io/badge/Driver-appium--flutter--driver-green.svg)](https://github.com/appium/appium-flutter-driver)
[![Node.js](https://img.shields.io/badge/Node.js-%3E%3D18.0.0-brightgreen.svg)](https://nodejs.org/)
[![Mocha & Chai](https://img.shields.io/badge/Test%20Runner-Mocha%20%7C%20Chai-red.svg)](https://mochajs.org/)
[![Reports](https://img.shields.io/badge/Reporting-Mochawesome%20%7C%20ExcelJS-orange.svg)](https://github.com/adamgruber/mochawesome)

An enterprise-grade, highly scalable, production-ready End-to-End (E2E) mobile automation testing framework engineered for **Flutter Android applications**.

This framework leverages **Appium 2.x**, **`appium-flutter-driver`** (with automatic **`UiAutomator2`** fallback), **Node.js**, **Mocha**, **Chai**, **Mochawesome**, **ExcelJS**, **Winston**, **Smart AI Dynamic Screen Discovery**, **Automated Failure Diagnostics & Retries**, **Root Cause Analysis (RCA)**, and **GitHub Actions CI/CD**.

---

## 🌟 Key Features

1. **Flutter-Native & Hybrid Automation**:
   - Primary interaction via `appium-flutter-driver` and Flutter Finder APIs (`find.byValueKey`, `find.byText`, `find.bySemanticsLabel`, `find.byAccessibilityId`).
   - Seamless context switching to `UiAutomator2` for OS permission dialogs or system native popups.
2. **Page Object Model (POM) Architecture**:
   - Reusable Page Object base class with safe wait wrappers, explicit visibility checks, gesture integration, and step-level log assertions.
3. **Smart AI Screen & Widget Discovery Engine**:
   - Scans active Flutter screens on-the-fly, extracts interactive widgets (`TextFields`, `ElevatedButtons`, `Dropdowns`, `Dialogs`), auto-generates Page Object JavaScript classes, and executes dynamic test scenarios automatically.
4. **Comprehensive Multi-Sheet Excel & HTML Reports**:
   - Generates `reports/Flutter_E2E_Report.xlsx` using ExcelJS with 4 structured sheets (`Summary`, `Test Cases`, `Failed Tests`, `Execution Logs`).
   - Generates visual Mochawesome HTML reports with pass/fail charts and embedded screenshot links.
5. **Robust Failure Diagnostics & Transient Failure Retries**:
   - Automatic retry wrapper for transient failures.
   - On failure, automatically captures:
     - 📸 High-resolution screenshot (`.png`)
     - 📋 ADB `logcat` logs
     - 🌳 Flutter render widget tree JSON dump
     - 📍 Active Activity & stack trace
6. **Root Cause Analysis (RCA) Engine**:
   - Categorizes failures into **Application Defect**, **Automation Issue**, **Environment Failure**, or **Flaky Test**, generating actionable engineering recommendations.
7. **CI/CD Pipeline with GitHub Actions**:
   - Production workflow (`.github/workflows/flutter-appium.yml`) with automated JDK 17, Android SDK setup, reactive Android Emulator execution, Appium 2.x configuration, and report artifact uploads.

---

## 📁 Repository Structure

```
mobile-e2e-automation/
├── .github/
│   └── workflows/
│       └── flutter-appium.yml         # GitHub Actions Pipeline
├── config/
│   ├── appium.config.js               # Appium 2.x server & driver configuration
│   └── env.config.js                  # Environment variables & capabilities reader
├── src/
│   ├── ai/
│   │   ├── screenAnalyzer.js          # Dynamic Flutter Widget & Screen Discovery Engine
│   │   └── pageObjectGenerator.js     # Auto-generates POM code & test scenarios
│   ├── driver/
│   │   ├── driverFactory.js           # Session manager, context switching & fallback driver
│   │   └── flutterFinder.js           # Wrappers for find.byValueKey, byText, bySemantics, etc.
│   ├── pages/
│   │   ├── basePage.js                # Base Page Object with common Flutter interactions
│   │   ├── loginPage.js               # Auth POM (login, logout, validations)
│   │   ├── formPage.js                # Form POM (inputs, pickers, dropdowns, radios)
│   │   ├── homePage.js                # Home & Navigation POM (drawers, bottom nav, tabs)
│   │   └── componentsPage.js          # UI Components POM (buttons, dialogs, lists, cards)
│   ├── utils/
│   │   ├── logger.js                  # Winston structured logging utility
│   │   ├── gestures.js                # Reusable touch/scroll/swipe/pinch W3C gestures
│   │   ├── failureHandler.js          # Screenshot, logcat, widget tree & stacktrace capture
│   │   ├── excelReporter.js           # Multi-sheet ExcelJS report generator
│   │   ├── rcaAnalyzer.js             # Root Cause Analysis summary & categorization
│   │   └── deviceDetector.js          # Auto-detection for real devices & emulators
│   └── helpers/
│       └── retryHelper.js             # Configurable transient failure retry wrapper
├── test/
│   ├── fixtures/
│   │   └── testData.js                # Form inputs, login credentials, test assertions
│   └── specs/
│       ├── auth.spec.js               # E2E Authentication Test Suite
│       ├── forms.spec.js              # E2E Flutter Form Validation Test Suite
│       ├── components.spec.js         # UI Components & Gestures Test Suite
│       ├── navigation.spec.js         # Navigation, Drawer & Deep Link Test Suite
│       └── aiDiscovery.spec.js        # AI Dynamic Discovery & Dynamic Scenario Test Suite
├── app/                               # Target APK location (app-release.apk)
├── reports/                           # Output directory for Mochawesome & Excel reports
├── .gitignore
├── .mocharc.js                        # Mocha test runner configuration
├── package.json                       # Node.js dependencies & execution scripts
└── README.md
```

---

## ⚡ Quick Start & Execution Commands

### 1. Prerequisites
- **Node.js**: `v18.0.0+`
- **Java JDK**: `17`
- **Android SDK**: `API Level 30+` with `ANDROID_HOME` configured
- **Appium 2.x**: Installed globally (`npm install -g appium@latest`)
- **Flutter Appium Driver**: `appium driver install --source=npm appium-flutter-driver`

### 2. Installation
```bash
cd mobile-e2e-automation
npm install
```

### 3. Run Test Suites
```bash
# Run all E2E test suites
npm run test:all

# Run specific modules
npm run test:auth
npm run test:forms
npm run test:components
npm run test:navigation

# Run AI Smart Screen Discovery Suite
npm run test:ai
```

---

## 📊 Reports & Output Artifacts

After every test execution, the framework automatically populates the `reports/` folder:

1. **`reports/Flutter_E2E_Report.xlsx`**:
   - **Sheet 1 (Summary)**: Execution Date, Device Name, OS Version, Total Tests, Pass/Fail Counts, Pass Rate %, Total Duration.
   - **Sheet 2 (Test Cases)**: Matrix of all test cases with execution status, device, module, and duration.
   - **Sheet 3 (Failed Tests)**: Exception reason, screenshot paths, device model, and OS version.
   - **Sheet 4 (Execution Logs)**: Timestamped step-by-step logs of every action.

2. **`reports/index.html`**:
   - Interactive Mochawesome HTML dashboard featuring visual pass/fail graphs and embedded failure screenshots.

3. **`reports/RCA_Summary.md`**:
   - Executive summary of Root Cause Analysis categorizing failures into Application Defects, Automation Issues, Environment Failures, and Flaky Tests.

---

## 🛠️ GitHub Actions CI/CD Integration

The framework includes a fully automated workflow located at `.github/workflows/flutter-appium.yml`.

### Key Pipeline Features:
- Runs automatically on `push` and `pull_request` to `main`/`master`/`develop`.
- Features `workflow_dispatch` trigger allowing manual execution of specific test suites.
- Configures macOS hardware runner for high-performance hardware-accelerated Android Emulator (API 33).
- Launches Appium 2.x server in background with Flutter driver.
- Uploads `Flutter_E2E_Report.xlsx`, `index.html`, failure screenshots, and execution logs as workflow artifacts.
