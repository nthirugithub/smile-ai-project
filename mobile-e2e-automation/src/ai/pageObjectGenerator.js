'use strict';

const fs = require('fs');
const path = require('path');
const logger = require('../utils/logger');

class PageObjectGenerator {
  /**
   * Generates a reusable Page Object JavaScript class file from discovered screen metadata
   * @param {Object} screenAnalysis Output from ScreenAnalyzer.analyzeCurrentScreen()
   * @param {string} outputDir Target directory for generated Page Objects
   */
  generatePageObject(screenAnalysis, outputDir) {
    const className = `${screenAnalysis.screenTitle}Page`;
    const filePath = path.join(outputDir, `${className.charAt(0).toLowerCase() + className.slice(1)}.js`);

    logger.info(`🤖 Auto-generating Page Object Class: ${className} -> ${filePath}`);

    let code = `'use strict';\n\n`;
    code += `const BasePage = require('./basePage');\n\n`;
    code += `/**\n`;
    code += ` * Auto-Generated Page Object for ${screenAnalysis.screenTitle}\n`;
    code += ` * Discovered at: ${screenAnalysis.timestamp}\n`;
    code += ` */\n`;
    code += `class ${className} extends BasePage {\n`;
    code += `  constructor(driver) {\n`;
    code += `    super(driver);\n\n`;

    // Generate Text Field locators
    screenAnalysis.widgets.textFields.forEach(field => {
      const varName = field.id;
      code += `    // ${field.label} (${field.type})\n`;
      code += `    this.${varName} = this.finder.byValueKey('${field.key}');\n`;
    });

    // Generate Button locators
    screenAnalysis.widgets.buttons.forEach(btn => {
      const varName = btn.id;
      code += `    // ${btn.label} (${btn.type})\n`;
      code += `    this.${varName} = this.finder.byValueKey('${btn.key}');\n`;
    });

    code += `  }\n\n`;

    // Generate action methods
    screenAnalysis.widgets.textFields.forEach(field => {
      const methodSuffix = field.id.replace(/^./, str => str.toUpperCase());
      code += `  async enter${methodSuffix}(val) {\n`;
      code += `    await this.enterText(this.${field.id}, val, '${field.label}');\n`;
      code += `  }\n\n`;
    });

    screenAnalysis.widgets.buttons.forEach(btn => {
      const methodSuffix = btn.id.replace(/^./, str => str.toUpperCase());
      code += `  async click${methodSuffix}() {\n`;
      code += `    await this.click(this.${btn.id}, '${btn.label}');\n`;
      code += `  }\n\n`;
    });

    code += `}\n\n`;
    code += `module.exports = ${className};\n`;

    if (!fs.existsSync(outputDir)) {
      fs.mkdirSync(outputDir, { recursive: true });
    }

    fs.writeFileSync(filePath, code);
    logger.info(`✅ Page Object code written successfully: ${filePath}`);
    return filePath;
  }
}

module.exports = new PageObjectGenerator();
