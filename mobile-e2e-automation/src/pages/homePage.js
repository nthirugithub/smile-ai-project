'use strict';

const BasePage = require('./basePage');

/**
 * HomePage — Page Object for Flutter AppShell navigation & screens.
 * Uses real Flutter route titles from app_shell.dart.
 */
class HomePage extends BasePage {
  constructor(driver) {
    super(driver);

    // Navigation Text Locators matching AppShell navItems
    this.navDashboard = this.finder.byText('Dashboard');
    this.navCases = this.finder.byText('Cases');
    this.navAnalysis = this.finder.byText('Analysis');
    this.navReports = this.finder.byText('Reports');
    this.navSettings = this.finder.byText('Settings');
    this.navProfile = this.finder.byText('Profile');
    this.navHelp = this.finder.byText('Help');
  }

  async navigateTo(screenName) {
    let finder;
    switch (screenName.toLowerCase()) {
      case 'dashboard': finder = this.navDashboard; break;
      case 'cases': finder = this.navCases; break;
      case 'analysis': finder = this.navAnalysis; break;
      case 'reports': finder = this.navReports; break;
      case 'settings': finder = this.navSettings; break;
      case 'profile': finder = this.navProfile; break;
      case 'help': finder = this.navHelp; break;
      default: finder = this.finder.byText(screenName);
    }
    await this.click(finder, `Navigation Item: ${screenName}`);
  }

  async isScreenActive(screenName) {
    const titleFinder = this.finder.byText(screenName);
    return await this.isDisplayed(titleFinder, `Screen Title: ${screenName}`);
  }
}

module.exports = HomePage;
