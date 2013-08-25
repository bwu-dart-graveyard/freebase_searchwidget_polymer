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


//import 'package:polymer/polymer.dart';
import 'dart:html';
import 'dart:async';
import 'package:freebase_searchwidget/components/freebase_searchwidget.dart';



void main() {
  String options = """{
            "key": "<Key generated from https://code.google.com/apis/console>",
            "filter": ["(all domain:/film)"],
            "lang": "de,en",
            "animate": true
            }""";
  // mdv.initialize(); wird nicht mehr benötigt wenn polymer/boot.js verwendet wird
  //var model = new Model(options);

  Timer.run(() {
    FreebaseSearchwidget fb = query('#freebase-searchwidget-left').xtag;
    fb.options = options;
    fb.init();

    fb = query('#freebase-searchwidget-right').xtag;
    fb.options = options;
    fb.init();
  });
}