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

library freebase_searchwidget_test;

import 'package:unittest/unittest.dart';
import 'dart:html';
import 'package:unittest/html_enhanced_config.dart';

import '../lib/components/freebase_searchwidget.dart';

void runWidgetTests() {

  useHtmlEnhancedConfiguration();

  group('some group', () {

    //Element host;

    setUp(() {

    });

    tearDown(() {

    });

    test("some test", () {
      expect(document.query('#freebase-searchwidget-left'), isNotNull);
      expect(document.query('#freebase-searchwidget-left').xtag, new isInstanceOf<FreebaseSearchwidget>());

    });
  });
}