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


class HtmlTools {
  // find all siblings of the provided element
  static List siblings(Element element) {
    var siblings = new List<Element>();

    var sibling = element.previousElementSibling;

    while (sibling != null) {
      siblings.add(sibling);
      sibling = sibling.previousElementSibling;
    }

    sibling = element.nextElementSibling;

    while (sibling != null) {
      siblings.add(sibling);
      sibling = sibling.nextElementSibling;
    }

    return siblings;
  }

  // find all siblings before the provided element
  static List prevSiblings(Element element) {
    var siblings = new List<Element>();

    var sibling = element.previousElementSibling;

    while (sibling != null) {
      siblings.add(sibling);
      sibling = sibling.previousElementSibling;
    }

    return siblings;
  }

  // find all siblings after the provided element
  static List nextSiblings(Element element) {
    var siblings = new List<Element>();

    var sibling = element.nextElementSibling;

    while (sibling != null) {
      siblings.add(sibling);
      sibling = sibling.nextElementSibling;
    }

    return siblings;
  }

// hide the provided element
  static void hideElement(Element e) {
    e.style.display = 'none';
  }

  // show the provided element
  static void showElement(Element e) {
    e.style.display = 'block';
  }

  static bool isVisible(Element e) {
    return (e.offsetHeight + e.offsetWidth != 0);
  }
}