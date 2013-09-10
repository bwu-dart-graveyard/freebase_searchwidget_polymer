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

library freebase_searchwidget_demo;
//import "package:polymer/polymer.dart";
import "dart:html";
import "dart:async";
import "package:freebase_searchwidget/components/freebase_searchwidget.dart";
//import "package:mdv/mdv.dart" as mdv;

void main() { ////<Key generated from https://code.google.com/apis/console>",
//  mdv.initialize();
  var model = new Model();
  model.options = """{
            "key": "AIzaSyDzIKedktcPEY1JxzQrYuZOxjuSG5mWtNk", 
            "filter": ["(all domain:/film)"],
            "lang": "de,en",
            "animate": true
            }""";

  var tmpl = query("#tmpl");
  tmpl.model = model;

  
  Timer.run(() {
  
//FreebaseSearchwidget fb = query("#freebase-searchwidget-left").xtag;
//    fb.option = options;
//    fb.init();
//
    var fb = document.query("#freebase-searchwidget-right").xtag;
//    var fb2 = tmpl.query("#freebase-searchwidget-left");
//    FreebaseSearchwidget.onTextChange.forTarget(fb).listen((d) => window.alert(d));
//    fb.option = options;
//    fb.init();

  });
}