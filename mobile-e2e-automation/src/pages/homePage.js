'use strict';

const BasePage = require('./basePage');

class HomePage extends BasePage {
  constructor(driver) {
    super(driver);

    // App Bar & Drawer
    this.drawerMenuButton = this.finder.byValueKey('open_drawer_button');
    this.drawerHeader = this.finder.byValueKey('drawer_header');
    this.drawerHomeOption = this.finder.byValueKey('drawer_item_home');
    this.drawerProfileOption = this.finder.byValueKey('drawer_item_profile');
    this.drawerSettingsOption = this.finder.byValueKey('drawer_item_settings');

    // Bottom Navigation Bar
    this.bottomNavHome = this.finder.byValueKey('bottom_nav_home');
    this.bottomNavExplore = this.finder.byValueKey('bottom_nav_explore');
    this.bottomNavForms = this.finder.byValueKey('bottom_nav_forms');
    this.bottomNavProfile = this.finder.byValueKey('bottom_nav_profile');

    // TabBar
    this.tabOverview = this.finder.byText('Overview');
    this.tabAnalytics = this.finder.byText('Analytics');
    this.tabReports = this.finder.byText('Reports');

    // Screen Headers
    this.homeTitle = this.finder.byText('Home Dashboard');
    this.exploreTitle = this.finder.byText('Explore Feed');
    this.formsTitle = this.finder.byText('Flutter Forms');
    this.profileTitle = this.finder.byText('User Profile');
    this.settingsTitle = this.finder.byText('Settings');
  }

  async openNavigationDrawer() {
    await this.click(this.drawerMenuButton, 'Open Drawer Button');
  }

  async navigateViaDrawer(option) {
    await this.openNavigationDrawer();
    let targetFinder;
    switch (option.toLowerCase()) {
      case 'home': targetFinder = this.drawerHomeOption; break;
      case 'profile': targetFinder = this.drawerProfileOption; break;
      case 'settings': targetFinder = this.drawerSettingsOption; break;
      default: targetFinder = this.finder.byText(option);
    }
    await this.click(targetFinder, `Drawer Option: ${option}`);
  }

  async navigateViaBottomNav(tabName) {
    let targetFinder;
    switch (tabName.toLowerCase()) {
      case 'home': targetFinder = this.bottomNavHome; break;
      case 'explore': targetFinder = this.bottomNavExplore; break;
      case 'forms': targetFinder = this.bottomNavForms; break;
      case 'profile': targetFinder = this.bottomNavProfile; break;
      default: targetFinder = this.finder.byText(tabName);
    }
    await this.click(targetFinder, `Bottom Nav Tab: ${tabName}`);
  }

  async selectTab(tabTitle) {
    const tabFinder = this.finder.byText(tabTitle);
    await this.click(tabFinder, `TabBar Tab: ${tabTitle}`);
  }

  async isScreenActive(screenName) {
    let titleFinder;
    switch (screenName.toLowerCase()) {
      case 'home': titleFinder = this.homeTitle; break;
      case 'explore': titleFinder = this.exploreTitle; break;
      case 'forms': titleFinder = this.formsTitle; break;
      case 'profile': titleFinder = this.profileTitle; break;
      case 'settings': titleFinder = this.settingsTitle; break;
      default: titleFinder = this.finder.byText(screenName);
    }
    return await this.isDisplayed(titleFinder, `Screen Title: ${screenName}`);
  }

  /**
   * Restarts Flutter application
   */
  async restartApp() {
    await this.driver.execute('flutter:restart');
  }
}

module.exports = HomePage;
