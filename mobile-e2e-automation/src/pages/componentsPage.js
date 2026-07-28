'use strict';

const BasePage = require('./basePage');

class ComponentsPage extends BasePage {
  constructor(driver) {
    super(driver);

    // Flutter UI Components
    this.elevatedBtn = this.finder.byValueKey('elevated_button_key');
    this.textBtn = this.finder.byValueKey('text_button_key');
    this.iconBtn = this.finder.byValueKey('icon_button_key');
    
    // Dialog & Overlay Locators
    this.showDialogBtn = this.finder.byValueKey('show_dialog_btn');
    this.dialogTitle = this.finder.byText('Flutter Alert Dialog');
    this.dialogConfirmBtn = this.finder.byText('Confirm');
    this.dialogCancelBtn = this.finder.byText('Cancel');

    // BottomSheet & Snackbar
    this.showBottomSheetBtn = this.finder.byValueKey('show_bottom_sheet_btn');
    this.bottomSheetTitle = this.finder.byText('Bottom Sheet Modal');
    this.showSnackbarBtn = this.finder.byValueKey('show_snackbar_btn');
    this.snackbarText = this.finder.byValueKey('flutter_snackbar_key');

    // ListView & GridView
    this.listView = this.finder.byValueKey('flutter_list_view');
    this.firstListItem = this.finder.byValueKey('list_item_0');
    this.tenthListItem = this.finder.byValueKey('list_item_9');

    this.gridView = this.finder.byValueKey('flutter_grid_view');
    this.gridCard = this.finder.byValueKey('grid_card_0');

    // Interactive Card
    this.sampleCard = this.finder.byValueKey('sample_card_widget');
  }

  async clickElevatedButton() {
    await this.click(this.elevatedBtn, 'ElevatedButton Widget');
  }

  async clickTextButton() {
    await this.click(this.textBtn, 'TextButton Widget');
  }

  async clickIconButton() {
    await this.click(this.iconBtn, 'IconButton Widget');
  }

  async triggerAlertDialog() {
    await this.click(this.showDialogBtn, 'Show Dialog Button');
  }

  async isDialogVisible() {
    return await this.isDisplayed(this.dialogTitle, 'Alert Dialog Title');
  }

  async confirmDialog() {
    await this.click(this.dialogConfirmBtn, 'Dialog Confirm Button');
  }

  async triggerBottomSheet() {
    await this.click(this.showBottomSheetBtn, 'Show Bottom Sheet Button');
  }

  async isBottomSheetVisible() {
    return await this.isDisplayed(this.bottomSheetTitle, 'Bottom Sheet Title');
  }

  async triggerSnackbar() {
    await this.click(this.showSnackbarBtn, 'Show Snackbar Button');
  }

  async getSnackbarMessage() {
    return await this.getText(this.snackbarText, 'Flutter Snackbar Message');
  }

  async scrollToListItem(itemKey) {
    const itemFinder = this.finder.byValueKey(itemKey);
    await this.scrollUntilVisible(this.listView, itemFinder);
    return await this.isDisplayed(itemFinder, `List Item: ${itemKey}`);
  }
}

module.exports = ComponentsPage;
