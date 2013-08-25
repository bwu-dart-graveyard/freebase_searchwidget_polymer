/*
 * This file is part of "Dart Freebase Search Widget". It is subject to the
 * license terms in the LICENSE file found in the top-level directory of this
 * distribution and at
 * https://github.com/zoechi/dart-freebase-search-widget/blob/master/LICENSE.
 *
 * No part of "Dart Freebase Search Widget", including this file, may be
 * copied, modified, propagated, or distributed except according to the terms
 * contained in the LICENSE file.
 */

part of freebase_searchwidget;

class CssOption {
  String pane;
  String list;
  String item;
  String itemName;
  String selected;
  String status;
  String flyoutPane;
  String itemType;

  CssOption.defaults() {
    setDefaults();
  }

  void setDefaults() {
    this.pane = "fbs-pane";
    this.list = "fbs-list";
    this.item = "fbs-item";
    this.itemName = "fbs-item-name";
    this.selected = "fbs-selected";
    this.status = "fbs-status";

    this.itemType = "fbs-item-type";
    this.flyoutPane = "fbs-flyout-pane";
  }

  CssOption.withData(Map<String,dynamic> data, {useDefaults: true}) {

    if (useDefaults) {
      this.setDefaults();
    }

    if (data != null) {
      if (data.containsKey('pane')) this.pane = data['pane'];
      if (data.containsKey('list')) this.list = data['list'];
      if (data.containsKey('item')) this.item = data['item'];
      if (data.containsKey('item_name')) this.itemName = data['item_name'];
      if (data.containsKey('selected')) this.selected = data['selected'];
      if (data.containsKey('status')) this.status = data['status'];
      if (data.containsKey('item_type')) this.itemType = data['item_type'];
      if (data.containsKey('flyoutpane')) this.flyoutPane = data['flyoutpane'];
    }
  }

  CssOption({this.pane, this.list, this.item, this.itemName, this.selected, this.status, this.flyoutPane, this.itemType})
  {}

  addPrefixes(String prefix) {
    pane = prefix + pane;
    list = prefix + list;
    item = prefix + item;
    itemName = prefix + itemName;
    selected = prefix + selected;
    status = prefix + status;
    flyoutPane = prefix + flyoutPane;
  }
}