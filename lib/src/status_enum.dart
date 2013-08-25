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

abstract class Status {
  static const START = 'START';
  static const LOADING = 'LOADING';
  static const SELECT = 'SELECT';
  static const ERROR = 'ERROR';
}