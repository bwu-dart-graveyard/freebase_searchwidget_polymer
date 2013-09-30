library app_bootstrap;

import 'package:polymer/polymer.dart';
import 'dart:mirrors' show currentMirrorSystem;

import 'package:freebase_searchwidget/components/freebase_searchwidget.dart' as i0;
import 'index.dart' as i1;

void main() {
  initPolymer([
      'package:freebase_searchwidget/components/freebase_searchwidget.dart',
      'index.dart',
    ], currentMirrorSystem().isolate.rootLibrary.uri.toString());
}
