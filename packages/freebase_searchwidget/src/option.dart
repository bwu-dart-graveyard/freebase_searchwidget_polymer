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

class Option {
  AcParam acParam;
  bool advanced;
  String align;
  bool animate;
  CssOption css;

  String _cssPrefix = "";
  String get cssPrefix => _cssPrefix;
  set cssPrefix(String value) => value != null ? this.cssPrefix = value : this.cssPrefix = "";

  bool exact;
  List<String> filter;
  bool flyout;
  String flyoutImageServicePath;
  String flyoutImageServiceUrl;
  String flyoutImageUrl;
  String flyoutLang;
  Element flyoutParent;
  String flyoutServicePath;
  String flyoutServiceUrl;
  String format;
  String key;
  String lang;
  String mqlOutput;
  Map nomatch;
  String output;
  Element parent;
  bool prefixed;
  String queryParamName;
  String servicePath;
  String serviceUrl;
  String scoring;
  bool showId;
  bool soft;
  String spell;
  List status;
  bool stemmed;
  bool suggestNew;
  int xhrDelay;
  int zIndex;

  Option() {
  }


  Option.defaults() {
    this.setDefaults();
  }

  void setDefaults() {
    this.status = [
              "Start typing to get suggestions...",
              "Searching...",
              "Select an item from the list:",
              "Sorry, something went wrong. Please try again later"
              ];
    this.soft = false;
    this.css = new CssOption.defaults();
    this.parent = null;
    this.animate = false;
    this.zIndex = null;

    /**
     * filter, spell, lang, exact, scoring, key, prefixed, stemmed, format
    *
     * are the new parameters used by the new freebase search on googleapis.
     * Please refer the the API documentation as these parameters
     * will be transparently passed through to the search service.
    *
     * @see http://wiki.freebase.com/wiki/ApiSearch
     */

    // search filters
    this.filter = null;

    // spelling corrections
    this.spell = "always";
    this.exact = true;
    this.scoring = null;
    // language to search (default to en)
    this.lang = null; // NULL defaults ot "en"

    // API key: required for googleapis
    this.key = null;

    this.prefixed = true;
    this.stemmed = null;
    this.format = null;
    // Enable structured input name:value pairs that get appended to the search filters
    // For example:
    //
    //   "bob dylan type:artist"
    //
    // Would get translated to the following request:
    //
    //    /freebase/v1/search?query=bob+dylan&filter=<original filter>&filter=(all type:artist)
    //
    this.advanced = true;

    // If an item does not have a "notable" field, display the id or mid of the item
    this.showId = true;

    // query param name for the search service.
    // If query name was "foo": search?foo=...
    this.queryParamName = "query";

    // base url for autocomplete service
    this.serviceUrl = "https://www.googleapis.com/freebase/v1";

    // service_url + service_path = url to autocomplete service
    this.servicePath = "/search";

    // "left", "right" or null
    // where list will be aligned left or right with the input
    this.align = null;

    // whether or not to show flyout on mouseover
    this.flyout = true;

    // default is service_url if NULL
    this.flyoutServiceUrl = null;

    // flyout_service_url + flyout_service_path =
    // url to search with output=(notable:/client/summary description type).
    this.flyoutServicePath = "/search?filter=(all mid:\${id})&" +
    "output=(notable:/client/summary description type)&key=\${key}";

    // default is service_url if NULL
    this.flyoutImageServiceUrl = null;

    this.flyoutImageServicePath=
      "/image\${id}?maxwidth=75&key=\${key}&errorid=/freebase/no_image_png";

    // jQuery selector to specify where the flyout
    // will be appended to (defaults to document.body).
    this.flyoutParent = null;

    // text snippet you want to show for the suggest
    // new option
    // clicking will trigger an fb-select-new event
    // along with the input value
    this.suggestNew = null;

    this.nomatch = {
      "text": "no matches",
      "title": "No suggested matches",
      "heading": "Tips on getting better suggestions:",
      "tips": [
             "Enter more or fewer characters",
             "Add words related to your original search",
             "Try alternate spellings",
             "Check your spelling"
             ]
    };


    // the delay before sending off the ajax request to the
    // suggest and flyout service
    this.xhrDelay = 200;
  }

  /*
   * see https://developers.google.com/freebase/v1/search-widget#configuration-options
   */
  Option.fromJson(String json, {bool useDefaults : true}) {

    if (useDefaults) {
      this.setDefaults();
    }

    if (json != null && json.isNotEmpty) {
       Map<String, dynamic> map = JSON.decode(json);

       if (map.containsKey("advanced")) this.advanced = map["advanced"] == "true";
       if (map.containsKey("exact")) this.exact = map["exact"] == true;
       if (map.containsKey("filter")) this.filter = map["filter"];
       if (map.containsKey("key")) this.key = map["key"];
       if (map.containsKey("lang")) this.lang = map["lang"];
       if (map.containsKey("scoring")) this.scoring = map["scoring"];
       if (map.containsKey("spell")) this.spell = map["spell"];
       if (map.containsKey("flyout")) this.flyout = map["flyout"] == "true";
       if (map.containsKey("suggest_new")) this.suggestNew = map["suggest_new"];
       if (map.containsKey("css")) this.css = new CssOption.withData(map["css"], useDefaults: useDefaults);
       if (map.containsKey("css_prefix")) this.cssPrefix = map["css_prefix"];
       if (map.containsKey("show_id")) this.showId = map["show_id"] == "true";
       if (map.containsKey("service_url")) this.serviceUrl = map["service_url"];
       if (map.containsKey("service_path")) this.servicePath = map["service_path"];
       if (map.containsKey("flyout_service_url")) this.flyoutImageServiceUrl = map["flyout_service_url"];
       if (map.containsKey("flyout_service_path")) this.flyoutServicePath = map["flyout_service_path"];
       if (map.containsKey("flyout_image_service_url")) this.flyoutImageServiceUrl = map["flyout_image_service_url"];
       if (map.containsKey("flyout_image_service_path")) this.flyoutImageServicePath = map["flyout_image_service_path"];
       if (map.containsKey("flyout_parent")) this.flyoutParent = document.query(map["flyout_parent"]);
       if (map.containsKey("align")) this.align = map["align"];
       if (map.containsKey("status")) this.status = map["status"];
       if (map.containsKey("parent")) this.parent = document.query(map["parent"]);
       if (map.containsKey("animate")) this.animate = map["animate"] == "true";
       if (map.containsKey("xhr_delay")) this.xhrDelay = map["xhr_delay"];
       if (map.containsKey("zIndex")) this.zIndex = map["zIndex"];
    }
  }
}
