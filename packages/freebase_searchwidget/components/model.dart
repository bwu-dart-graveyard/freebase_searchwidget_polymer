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

class Model extends ChangeNotifierBase{
  String __$options = "";
  String get options => __$options;
  set options(String value) {
    __$options = notifyPropertyChange(const Symbol('options'), __$options, value);
  }
  
  String __$value = "";
  String get value => __$value;
  set value(String value) {
    __$value = notifyPropertyChange(const Symbol('value'), __$value, value);
  }
  
}
