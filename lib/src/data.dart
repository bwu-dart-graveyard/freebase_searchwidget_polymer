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

class Data implements Map<String,dynamic>{
  var _map = new Map<String,dynamic>();

  int get cost => _map.containsKey('cost') ? _map['cost'] : null;
  set cost(int value) => _map['cost'] = value;

  String get correction => _map.containsKey('correction') ? _map['correction'] : null;
  set correction(String value) => _map['correction'] = value;

  int get cursor => _map.containsKey('cursor') ? _map['cursor'] : null;
  set cursor(int value) => _map['cursor'] = value;

  String get id => _map['id']; //_map.containsKey('id') ? _map['id'] : null;
  set id(String value) => _map['id'] = value;

  List get filter => _map.containsKey('filter') ? _map['filter'] : null;
  set filter(List value) => _map['filter'] = value;

  String get mid => _map.containsKey('mid') ? _map['mid'] : null;
  set mid(String value) => _map['mid'] = value;

  String get name => _map.containsKey('name') ? _map['name'] : null;
  set name(String value) => _map['name'] = value;

  DivElement get html => _map.containsKey('html') ? _map['html'] : null;
  set html(DivElement value) => _map['html'] = value;

  Map get notable => _map.containsKey('notable') ? _map['notable'] : null;
  set notable(Map value) => _map['notable'] = value;

  String get prefix => _map.containsKey('prefix') ? _map['prefix'] : null;
  set prefix(String value) => _map['prefix'] = value;

  List get result => _map.containsKey('result') ? _map['result'] : null;
  set result(List value) => _map['result'] = value;

  String get type => _map.containsKey('type') ? _map['type'] : null;
  set type(String value) => _map['type'] = value;

  String get under => _map.containsKey('under') ? _map['under'] : null;
  set under(String value) => _map['under'] = value;

  Data() {
  }

  Data.fromJson(String json) {
    if (json != null) {
      _map = JSON.decode(json);
    }
  }

  String toUrlEncoded() {
    return urlEncodeMap(_map);
  }

  static String urlEncodeMap(Map<String,dynamic> data) {
    return data.keys.map((key) {
      if (data[key] != null) {
        if (key == 'filter') {
          return '${Uri.encodeComponent(key)}=${Uri.encodeComponent(data[key][0])}';
        } else {
          return '${Uri.encodeComponent(key)}=${Uri.encodeComponent(data[key].toString())}';
        }
      } else {
        return '';
      }
    }).join("&");
  }


  String toJson(){
    return JSON.encode(_map);
  }

  operator [](Object key) {
    return _map[key];
  }

  void operator []=(String key, value) {
    _map[key] = value;
  }

  void addAll(Map<String, dynamic> other) {
    _map.addAll(other);
  }

  void clear() {
    _map.clear();
  }

  bool containsKey(Object key) {
    return _map.containsKey(key);
  }

  bool containsValue(Object value) {
    return _map.containsValue(value);
  }

  void forEach(void f(String key, value)) {
    _map.forEach(f);
  }

  bool get isEmpty => _map.isEmpty;

  bool get isNotEmpty => _map.isNotEmpty;

  Iterable<String> get keys => _map.keys;

  int get length => _map.length;

  putIfAbsent(String key, ifAbsent()) {
    return _map.put(key, ifAbsent);
  }

  remove(Object key) {
    return _map.remove(key);
  }

  Iterable get values => _map.values;
}