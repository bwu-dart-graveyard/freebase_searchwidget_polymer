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

class AcParam {
  String key;
  List<String> filter;
  String spell;
  bool exact;
  String lang;
  String scoring;
  bool prefixed;
  bool stemmed;
  String format;
  String mqlOutput;
  String output;

  AcParam() {
  }

  AcParam.fromOption(Option option) {
    this.key = option.key;
    this.filter = option.filter;
    this.spell = option.spell;
    this.exact = option.exact;
    this.lang = option.lang;
    this.scoring = option.scoring;
    this.prefixed = option.prefixed;
    this.stemmed = option.stemmed;
    this.format = option.format;
    this.mqlOutput = option.mqlOutput;
    this.output = option.output;
  }
}