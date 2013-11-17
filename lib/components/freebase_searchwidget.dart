/*
 * The source code in this file is ported from Google's "Freebase Search
 * Widget", previously "Freebase Suggest"
 * https://developers.google.com/freebase/v1/search-widget
 * (The original source file can be found in orig_js/suggest.js)
 * Therefore the following copyright applies:
 */

/*
 * Copyright 2013, Günter Zöchbauer <guenter@gzoechbauer.com>
 * Copyright 2012, Google Inc.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * @author Dae Park (daepark@google.com)
 */

/*
 *
 */

library freebase_searchwidget;

import "dart:html";
import "dart:async";
import "dart:convert";

import "package:polymer/polymer.dart";

import "package:animation/animation.dart";

part "model.dart";
part "../src/data.dart";
part "../src/status_enum.dart";
part "../src/cssoption.dart";
part "../src/acparam.dart";
part "../src/option.dart";
part "../src/htmltools.dart";


@CustomTag("freebase-searchwidget")
class FreebaseSearchwidget extends PolymerElement {
  FreebaseSearchwidget.created() : super.created();


// TODO check if that or maybe a part of it is necessary/useful in Dart
//  /**
//   * jQuery UI provides a way to be notified when an element is removed from the DOM.
//   * suggest would like to use this facility to properly teardown it's elements from the DOM (suggest list, flyout, etc.).
//   * The following logic tries to determine if "remove" event is already present, else
//   * tries to mimic what jQuery UI does (as of 1.8.5) by adding a hook to $.cleanData or $.fn.remove.
//   */
//  $(function() {
//    var div = $("<div>");
//    $(document.body).append(div);
//    var t = setTimeout(function() {
//      // copied from jquery-ui
//      // for remove event
//      if ( $.cleanData ) {
//        var _cleanData = $.cleanData;
//        $.cleanData = function( elems ) {
//          for ( var i = 0, elem; (elem = elems[i]) != null; i++ ) {
//            $( elem ). triggerHandler( "remove" );
//          }
//          _cleanData( elems );
//        };
//      }
//      else {
//        var _remove = $.fn.remove;
//        $.fn.remove = function( selector, keepData ) {
//          return this.each(function() {
//            if ( !keepData ) {
//              if ( !selector || $.filter( selector, [ this ] ).length ) {
//                $( "*", this ).add( [ this ] ).each(function() {
//                  $( this ). triggerHandler( "remove" );
//                });
//              }
//            }
//            return _remove.call( $(this), selector, keepData );
//          });
//        };
//      }
//    }, 1);
//    div.bind("remove", function() {
//      clearTimeout(t);
//    });
//    div.remove();
//  });

  /**
   * These are the search parameters that are transparently passed
   * to the search service as specified by service_url + service_path
   */
  Map _SEARCH_PARAMS = {
    "key":1,
    "filter":1,
    "spell":1,
    "exact":1,
    "lang":1,
    "scoring":1,
    "prefixed":1,
    "stemmed":1,
    "format":1,
    "mql_output":1,
    "output":1
  };

  @observable String value = "";
  @observable String options = "";

  Option _options = new Option.defaults();
  Map<String,String> _status;
  Point _currentPosition;

  bool _doScrollIgnoreMouseover;
  StreamSubscription _scrollIgnoreMouseover;
  String _flyoutUrl;
  String _flyoutImageUrl;
  Map<String,String> _cache;
  Map<String,Data> _flyoutCache;
  //Map not_char;

  DivElement _statusElement;
  UListElement _listElement;
  DivElement _paneElement;
  DivElement _flyoutpaneElement;
  InputElement _inputElement;

  StreamSubscription _paneMouseDown;
  StreamSubscription _paneMouseUp;
  StreamSubscription _paneClick;
  StreamSubscription _inputKeyDown;
  StreamSubscription _inputKeyPress;
  StreamSubscription _inputKeyPressDelayed;
  StreamSubscription _inputKeyUp;
  StreamSubscription _inputBlur;
  StreamSubscription _inputTextChange;
  StreamSubscription _inputFocus;
  StreamSubscription _inputPaste;
  StreamSubscription _inputPasteDelayed;
  StreamSubscription _windowResize;
  StreamSubscription _windowScroll;
  StreamSubscription _listMouseOver;
  StreamSubscription _listMouseOut;
  StreamSubscription _nomatchClick;
  StreamSubscription _spellLinkClick;
  StreamSubscription _moreLinkClick;
  StreamSubscription _suggestNewClick;
  StreamSubscription _flyoutpaneMouseOver;
  StreamSubscription _flyoutpaneMouseOut;
  StreamSubscription _flyoutpaneMouseDown;

  List<StreamSubscription> _subscriptions;
  //var _pasteTimeout;
  var _onresize;

  // fires on every keypress not only when input looses focus
  static EventStreamProvider<CustomEvent> fbTextChange = new EventStreamProvider<CustomEvent>("fb-textchange");
  Stream<CustomEvent> get onFbTextChange =>  FreebaseSearchwidget.fbTextChange.forTarget(this);
  
  static EventStreamProvider<CustomEvent> fbPaneShow = new EventStreamProvider<CustomEvent>("fb-pane-show");
  Stream<CustomEvent> get onFbPaneShow =>  FreebaseSearchwidget.fbPaneShow.forTarget(this);

  static EventStreamProvider<CustomEvent> fbPaneHide = new EventStreamProvider<CustomEvent>("fb-pane-hide");
  Stream<CustomEvent> get onFbPaneHide =>  FreebaseSearchwidget.fbPaneHide.forTarget(this);

  static EventStreamProvider<CustomEvent> fbSelect = new EventStreamProvider<CustomEvent>("fb-select");
  Stream<CustomEvent> get onFbSelect =>  FreebaseSearchwidget.fbSelect.forTarget(this);
  
  static EventStreamProvider<CustomEvent> fbTrackEvent = new EventStreamProvider<CustomEvent>("fb-track-event");
  Stream<CustomEvent> get onFbTrackEvent =>  FreebaseSearchwidget.fbTrackEvent.forTarget(this);

  static EventStreamProvider<CustomEvent> fbFlyoutPaneHide = new EventStreamProvider<CustomEvent>("fb-flyoutpane-hide");
  Stream<CustomEvent> get onFbFlyoutPaneHide =>  FreebaseSearchwidget.fbFlyoutPaneHide.forTarget(this);

  static EventStreamProvider<CustomEvent> fbFlyoutPaneShow = new EventStreamProvider<CustomEvent>("fb-flyoutpane-show");
  Stream<CustomEvent> get onFbFlyoutPaneShow =>  FreebaseSearchwidget.fbFlyoutPaneShow.forTarget(this);

  static EventStreamProvider<CustomEvent> fbError = new EventStreamProvider<CustomEvent>("fb-error");
  Stream<CustomEvent> get onFbError =>  FreebaseSearchwidget.fbError.forTarget(this);

  static EventStreamProvider<CustomEvent> fbSelectNew = new EventStreamProvider<CustomEvent>("fb-select-new");
  Stream<CustomEvent> get onFbSelectNew =>  FreebaseSearchwidget.fbSelectNew.forTarget(this);

  static EventStreamProvider<CustomEvent> fbRequestFlyout = new EventStreamProvider<CustomEvent>("fb-request-flyout");
  Stream<CustomEvent> get onFbRequestFlyout =>  FreebaseSearchwidget.fbRequestFlyout.forTarget(this);

  static EventStreamProvider<CustomEvent> _onTextChange = new EventStreamProvider<CustomEvent>("textchange");


  bool get applyAuthorStyles => true;
  
  
@override
void enteredView() { 
    super.enteredView();

    _subscriptions = [ this._paneMouseDown,
                      this._paneMouseUp,
                      this._paneClick,
                      this._inputKeyDown,
                      this._inputKeyPress,
                      this._inputKeyPressDelayed,
                      this._inputKeyUp,
                      this._inputBlur,
                      this._inputTextChange,
                      this._inputFocus,
                      this._inputPaste,
                      this._inputPasteDelayed,
                      this._windowResize,
                      this._windowScroll,
                      this._listMouseOver,
                      this._listMouseOut,
                      this._nomatchClick,
                      this._spellLinkClick,
                      this._moreLinkClick,
                      this._suggestNewClick,
                      this._flyoutpaneMouseOver,
                      this._flyoutpaneMouseOut,
                      this._flyoutpaneMouseDown];

    this._inputElement = shadowRoot.query("#inputElement");

    // Debug providing options using custom attrib
    //String optionsJson = shadowRoot.query("#optons").text;
    //SpanElement so = shadowRoot.query("#options");
    //String optionsJson = so.text;
    //this._options = new Option.fromJson(optionsJson);
    this._options = new Option.fromJson(options); // TODO doesn't work due to bug #12262

    Option o = this._options;
    if (o.key == null) {
      print("Options must contain a value for key.");
      return;
    }

    CssOption css = o.css;

    css.addPrefixes(o.cssPrefix);

    // suggest parameters
    o.acParam = new AcParam.fromOption(o);

    // flyout service lang is the first specified lang
    o.flyoutLang = null;
    if (o.acParam.lang != null) {
      var lang = o.acParam.lang;
      if (lang is List && lang.length > 0) {
        lang = lang.join(",");
      }
      if (lang != null) {
        o.flyoutLang = lang;
      }
    }

    // status texts
    this._status = {
      "START": "", //Status.START: "",
      "LOADING": "", //Status.LOADING: "",
      "SELECT": "", //Status.SELECT: "",
      "ERROR": "" //Status.ERROR: ""
    };

    if ((o.status != null) && (o.status is List) && (o.status.length >= 3)) {
      this._status[Status.START] = o.status[0] != null ? o.status[0] : "";
      this._status[Status.LOADING] = o.status[1] != null ? o.status[1] : "";
      this._status[Status.SELECT] = o.status[2] != null ? o.status[2] : "";
      if (o.status.length == 4) {
        this._status[Status.ERROR] = o.status[3] != null ? o.status[3] : "";
      }
    }

    // create the container for the drop down list
    var s = new DivElement();
    s.style.display = "none";
    s.classes.add(css.status);
    var l = new UListElement();
    l.classes.add(css.list);
    var p = new DivElement()
    ..style.display = "none"
    ..style.zIndex = "1500";
    p.classes
      ..add("fbs-reset")
      ..add(css.pane);

    this._statusElement = s;
    this._listElement = l;
    this._paneElement = p;

    p
      ..append(s)
      ..append(l);


    if (o.parent != null) {
      o.parent.append(p);
    }
    else {
      p.style.position = "absolute";
      if (o.zIndex != null) {
        p.style.zIndex = o.zIndex.toString();
      }
      document.body.append(p);
    }
    this._paneMouseDown = p.onMouseDown.listen((e) {
      //console.log("pane mousedown");
      this._inputElement.dataset["dont_hide"] = "true";
      e.stopPropagation();
    });

    this._paneMouseUp = p.onMouseUp.listen((e) {
      //console.log("pane mouseup");
      if (this._inputElement.dataset["dont_hide"] == "true") {
        this._inputElement.focus();
      }
      this._inputElement.dataset.remove("dont_hide");
      e.stopPropagation();
    });

    this._paneClick = p.onClick.listen((e) {
      //console.log("pane click");
      e.stopPropagation();
      var s = this._getSelected();
      if (s != null) {
        this._onSelect(s);
        this._hideAll();
      }
    });

    _listMouseOver = l.onMouseOver.listen((e) => this._hoveroverList(e));
    _listMouseOut = l.onMouseOut.listen((e) => this._hoveroutList());
    //console.log(this.pane, this.list);

    this._inputElement.autocomplete = "off";

    this._inputKeyDown = this._inputElement.onKeyDown.listen((e) => this._keyDown(e));
    this._inputKeyPress = this._inputElement.onKeyPress.listen((e) => this._keyPress(e));
    this._inputKeyPress = this._inputElement.onKeyUp.listen((e) => this._keyUp(e));
    this._inputBlur = this._inputElement.onBlur.listen((e) => this._blur(e));
    //this._inputTextChange = this._inputElement.onChange.listen((e) => this._textChange());
    this._inputTextChange = _onTextChange.forTarget(this).listen((e) => this._textChange());
    this._inputFocus = this._inputElement.onFocus.listen((e) => this._focus(e));
    this._inputPaste = this._inputElement.onPaste.listen((e) {
//        .bind($.browser.msie ? "paste.suggest" : "input.suggest", function(e)) { // TODO makes Dart this dinguishion automatically
        if(this._inputPasteDelayed != null) {
          this._inputPasteDelayed.cancel();
        }
        var future = new Future.delayed(const Duration(milliseconds: 0));
        this._inputPasteDelayed = future.asStream().listen(this._textChange());
    });

    // resize handler
    this._onresize = (e) {
      this._invalidatePosition();
      if (HtmlTools.isVisible(p)) {
        this._position();
        if (o.flyout != null && this._flyoutpaneElement != null && HtmlTools.isVisible(this._flyoutpaneElement)) {
          var s = this._getSelected();
          if (s != null) {
            this._flyoutPosition(s);
          }
        }
      }
    };

    _windowResize = window.onResize.listen(this._onresize);
    _windowScroll = window.onScroll.listen(this._onresize);

    _init();
  }


  _invalidatePosition() {
    this._currentPosition = null;
  }

  _statusStart() {
    this._hideAll();
    HtmlTools.siblings(this._statusElement).forEach((e) => HtmlTools.hideElement(e));

    if (this._status[Status.START] != null) {
      this._statusElement.text = this._status[Status.START];
      HtmlTools.showElement(this._statusElement);
      if (!HtmlTools.isVisible(this._paneElement)) {
        this._position();
        this._paneShow();
      }
    }
    if (this._status[Status.LOADING] != null) {
      this._statusElement.classes.remove("loading");
    }
  }


  _statusLoading() {
    HtmlTools.siblings(this._statusElement).forEach((e) => HtmlTools.showElement(e));

    if (this._status[Status.LOADING] != null) {
      this._statusElement
        ..classes.add("loading")
        ..text = this._status[Status.LOADING];
      HtmlTools.showElement(this._statusElement);

      if (!HtmlTools.isVisible(this._paneElement)) {
        this._position();
        this._paneShow();
      }
    }
    else {
      HtmlTools.hideElement(this._statusElement);
    }
  }

  _statusSelect() {
    HtmlTools.siblings(this._statusElement).forEach((e) => HtmlTools.showElement(e));

    if (this._status[Status.SELECT] != null) {
      this._statusElement.text = this._status[Status.SELECT];
      HtmlTools.showElement(this._statusElement);
    }
    else {
      HtmlTools.hideElement(this._statusElement);
    }
    if (this._status[Status.LOADING] != null) {
      this._statusElement.classes.remove("loading");
    }
  }

  _statusError() {
    HtmlTools.siblings(this._statusElement).forEach((e) => HtmlTools.showElement(e));
    if (this._status[Status.ERROR] != null) {
      this._statusElement.text = this._status[Status.ERROR];
      HtmlTools.showElement(this._statusElement);
    }
    else {
      HtmlTools.hideElement(this._statusElement);
    }
    if (this._status[Status.LOADING] != null ) {
      this._statusElement.classes.remove("loading");
    }
  }

  _focus(e) {
    //console.log("_focus", this.input.val() === "");

    if (this._inputElement.value == "") {
      this._statusStart();
    }
    else {
      this._focusHook(e);
    }
  }

  // override to be notified on focus and input has a value
  _focusHook(e) {
    //console.log("_focusHook", this.input.data("data.suggest"));
    if((this._inputElement.dataset.length > 0) &&
        (!HtmlTools.isVisible(this._paneElement)) &&
        (this._listElement.queryAll("." + this._options.css.item).length > 0)) { // TODO this.list
      this._position();
      this._paneShow();
    }
  }

  _keyDown(e) {
    var key = e.keyCode;
    if (key == KeyCode.TAB) { // tab
      this._tab(e);
    }
    else if (key == KeyCode.UP || key == KeyCode.DOWN) { // up/down
      if (!e.shiftKey) {
        // prevents cursor/caret from moving (in Safari)
        e.preventDefault();
      }
    }
  }

  _keyPress(e) {
    var key = e.keyCode;
    if (key == KeyCode.UP || key == KeyCode.DOWN) { // up/down
      if (!e.shiftKey) {
        // prevents cursor/caret from moving
        e.preventDefault();
      }
    }
    else if (key == KeyCode.ENTER) { // enter
      this._enter(e);
    }
  }

  _keyUp(e) {
    var key = e.keyCode;
    //console.log("_keyUp", key);
    if (key == KeyCode.UP) { // up
      e.preventDefault();
      this._up(e);
    }
    else if (key == KeyCode.DOWN) { // down
      e.preventDefault();
      this._down(e);
    }
    else if (e.ctrlKey && key == KeyCode.M) { // 77
      this._paneElement.query(".fbs-more-link").click();
    }
    else if (this._isChar(e) || e.keyCode == KeyCode.BACKSPACE || e.keyCode == KeyCode.DELETE) {
      //this._textChange();
      if(this._inputKeyPressDelayed != null) {
        this._inputKeyPressDelayed.cancel();
      }
      var future = new Future.delayed(const Duration(milliseconds: 0));
      this._inputKeyPressDelayed = future.asStream().listen(this._textChange());
    }
    else if (key == KeyCode.ESC) {
      // _escape - WebKit doesn't fire keypress for _escape
      this._escape(e);
    }
    return true;
  }

  _blur(e) { // x to prevent overriding method of the base class
    //console.log("blur", "dont_hide", this.input.data("dont_hide"),
    //            "data.suggest", this.input.data("data.suggest"));
    if (this._inputElement.dataset["dont_hide"] != null) {
      return;
    }
    var data = new Data.fromJson(this._inputElement.dataset["data"]);
    this._hideAll();
  }

  _tab(e) {
    if (e.shiftKey || e.metaKey || e.ctrlKey) {
      return;
    }

    var o = this._options;
    var visible = HtmlTools.isVisible(this._paneElement) &&
      this._listElement.queryAll("." + o.css.item).length > 0;
    var s = this._getSelected();

    //console.log("_tab", visible, s);

    if (visible && s != null) {
      this._onSelect(s);
      this._hideAll();
    }
  }

  _enter(e) {
    var o = this._options;
    var isVisible = HtmlTools.isVisible(this._paneElement);

    //console.log("_enter", visible);

    if (isVisible) {
      if (e.shiftKey) {
        this._shiftEnter(e);
        e.preventDefault();
        return;
      }
      else if (this._listElement.queryAll("." + o.css.item).length > 0) {
        var s = this._getSelected();
        if (s != null) {
          this._onSelect(s);
          this._hideAll();
          e.preventDefault();
          return;
        }
        else if (o.soft == null) {
          var data = new Data.fromJson(this._inputElement.dataset["data"]);
          if (this._listElement.queryAll("." + this._options.css.item + ":visible").length > 0) {
            this._upDown(false);
            e.preventDefault();
            return;
          }
        }
      }
    }
    if (o.soft != null) {
      // submit form
      this._softEnter();
    }
    else {
      e.preventDefault();
    }
  }

  _softEnter([e]) {}

  _escape(e) {
    this._hideAll();
  }

  _up(e) {
    //console.log("_up");
    this._upDown(true, e.ctrlKey || e.shiftKey);
  }

  _down(e) {
    //console.log("_down");
    this._upDown(false, null, e.ctrlKey || e.shiftKey);
  }

  _upDown(goup, [gofirst = false, golast = false]) {
    //console.log("_upDown", goup, gofirst, golast);
    var o = this._options,
        css = o.css,
        p = this._paneElement,
        l = this._listElement;

    if (!HtmlTools.isVisible(p)) {
      if (!goup) {
        this._textChange();
      }
      return;
    }
    LIElement li = l.query("." + css.item + ":visible"); // TODO l

    if (li.children.length == 0) {
      return;
    }

    var first = li.children[0];
    var last = li.children[li.children.length - 1];
    var cur = this._getSelected();
    if (cur == null) {
      cur = [];
    }

    if(this._scrollIgnoreMouseover != null) {
      this._scrollIgnoreMouseover.cancel();
    }

    this._doScrollIgnoreMouseover = false;

    if (goup) {//up
      if (gofirst) {
        this._goto(first);
      }
      else if (cur.length == null || cur.length == 0) {
        this._goto(last);
      }
      else if (cur[0] == first) {
        first.classes.remove(css.selected);
        this._inputElement.value = this._inputElement.dataset["original"];
        this.value = this._inputElement.value;
        this._hoveroutList();
      }
      else {
        var prev = HtmlTools.prevSiblings(document.query("." + css.item + ":visible:first"));
        this._goto(prev);
      }
    }
    else {//down
      if (golast) {
        this._goto(last);
      }
      else if (cur.length == 0) {
        this._goto(first);
      }
      else if (cur[0] == last) {
        last.classes.remove(css.selected);
        this._inputElement.value = this._inputElement.dataset["original"];
        this.value = this._inputElement.value;
        this._hoveroutList();
      }
      else {
        var next = HtmlTools.nextSiblings(document.query("." + css.item + ":visible:first"));
        this._goto(next);
      }
    }
  }

  _goto(LIElement li) {

    li.dispatchEvent(new MouseEvent("mouseover"));
    var d = JSON.decode(li.dataset["data"]);
    this._inputElement.value = (d != null ? d.name : this._inputElement.dataset["original"]);
    this.value = this._inputElement.value;
    this._scrollTo(li);
  }

  _scrollTo(LIElement item) {
    var l = this._listElement,
        scrollTop = l.scrollTop,
        scrollBottom = scrollTop + l.clientHeight; // innerHeight(),
        var item_height = item.borderEdge.height; //outerHeight(),
        var offsetTop = HtmlTools.prevSiblings(item).length * item_height,
        offsetBottom = offsetTop + item_height;
    if (offsetTop < scrollTop) {
      this._ignoreMouseover();
      l.scrollTop = offsetTop;
    }
    else if (offsetBottom > scrollBottom) {
      this._ignoreMouseover();
      l.scrollTop = scrollTop + offsetBottom - scrollBottom;
    }
  }

  _textChange() {
    this._inputElement.dataset.remove("data");
    this.dispatchEvent(new CustomEvent("fb-textchange", detail:this.id)); // TODO this.id should be this - after fix of https://code.google.com/p/dart/issues/detail?id=12641
    var v = this._inputElement.value;
    this.value = v;
    if (v == "") {
      this._statusStart();
      return;
    }
    else {
      this._statusLoading();
    }
    this._request(v);
  }

  _response(Data data, int cursor, [bool first]) {
    if (data == null) {
      return;
    }
    if (data.cost != null) {
      this._trackEvent("name", "response", "cost", data.cost);
    }

    if (!this._checkResponse(data)) {
      return;
    }
    var result = [];

    if(data.result != null) {
      result = data.result;
    } else {
      throw "response: data doesn\'t contain result";
    }

    this._responseHook(data, cursor);

    var first = null;
    var o = this._options;

    var i = 0;
    result.forEach((e) {

      var eData = new Data();
      eData.addAll(e);
      if (eData.id == null && eData.mid != null) {
          // For compatitibility reasons, store the mid as id
          eData.id = eData.mid;
      }
      var li = this._createItem(eData, data);
      this._listMouseOver = li.onMouseOver.listen((e) => this._mouseoverItem(e));
      li.dataset["data"] = eData.toJson();
      this._listElement.append(li);
      if (i == 0) {
        first = li;
        i++;
      }
    });

    this._inputElement.dataset["original"] = this._inputElement.value;

    if (this._listElement.queryAll("." + o.css.item).length == 0 && o.nomatch != null) {
      var nomatch = new LIElement();
      nomatch.classes.add("fbs-nomatch");
      if (o.nomatch["text"] != null) {
        nomatch.text = o.nomatch["text"];
      }
      else {
        if (o.nomatch["title"] != null) {
          var tmpEm = new Element.tag("em");
          tmpEm.classes.add("fbs-nomatch-text");
          tmpEm.text = o.nomatch["title"];
          nomatch.append(tmpEm);
        }
        if (o.nomatch["heading"] != null) {
          var heading = new HeadingElement.h3();
          heading.text = o.nomatch["heading"];
          nomatch.append(heading);
        }
        var tips = o.nomatch["tips"];
        if (tips != null && tips.length > 0) {
          var tipsElement = new UListElement();
          tipsElement.classes.add("fbs-search-tips");

          tips.forEach((i,tip) {
            var tipElement = new LIElement();
            tipElement.text = tip;
            tipsElement.append(tipElement);
          });
          nomatch.append(tipsElement);
        }
      }
      _nomatchClick = nomatch.onClick.listen((e) => e.stopPropagation());
      this._listElement.append(nomatch);
    }

    this._showHook(data, cursor != -1, first);
    this._position();
    this._paneShow();
  }

  _paneShow() {
    var show = false;
    var p = this._paneElement;

    if (this._listElement.queryAll("* > li").length > 0) {
      show = true;
    }
// TODO zu prüfen ob das so passt (not selector mit if geprüft)
      if (!show) {
        p.children //(":not(." + this.options.css.list + ")") // TODO selector
          .forEach((e) {
            if (!e.classes.contains(this._options.css.list) && e.style.display != "none") {
              show = true;
              return false;
            }
          });
      }
    if (show) {
      if (this._options.animate) { // TODO

        if (!HtmlTools.isVisible(p)) {
        var v = p.style.visibility == "" ? "visible" : p.style.visibility;
        var d = p.style.display;
        var o = p.style.overflow == "" ? "visible" : p.style.overflow;

        p.style.visibility = "hidden";
        p.style.display = "block";
        p.style.overflow = "hidden";

        var height = p.borderEdge.height.toString() + "px";

        p.style.display = d;
        p.style.visibility = v;

        p.style.height = "1px";
        HtmlTools.showElement(p);

        var anim = new ElementAnimation(p)
        ..properties = {"height": height }
        ..duration = 200
        ..onComplete.first.then((e) { p.style.overflow = o; p.style.height = "auto"; })
        ..run();
        }

        this.dispatchEvent(new CustomEvent("fb-pane-show", detail: this.id)); // TODO detail
      }
      else {
        HtmlTools.showElement(p);
        this.dispatchEvent(new CustomEvent("fb-pane-show", detail:this.id)); // TODO detail
      }
    }
    else {
      HtmlTools.hideElement(p);
      this.dispatchEvent(new CustomEvent("fb-pane-hide", detail:this.id)); // detail
    }
  }


  _mouseoverItem(e) {
    if (this._doScrollIgnoreMouseover != null) {
      return;
    }
    var target = e.target;
    while (target.nodeName.toLowerCase() != "li") {
      target = target.parent; // ("li:first"); // TODO selector
    }
    var li = target;
    var css = this._options.css;
    var l = this._listElement;

      l.queryAll("." + css.item) // TODO l
        .forEach((e) {
          if (e != li.children[0]) {
            e.classes.remove(css.selected);
          }
        });
    if (!li.classes.contains(css.selected)) {
      li.classes.add(css.selected);
      this._mouseoverItemHook(li);
    }
  }

  _hoveroverList(e) {
  }

  _position() {
    var p  = this._paneElement;
    var o = this._options;

    if (o.parent != null) {
      return;
    }

    if (this._currentPosition == null) {
      var inp = this._inputElement;
      Point pos = inp.borderEdge.topLeft;
      int input_width = inp.borderEdge.width;
      int input_height = inp.borderEdge.height;
      pos = new Point(pos.x, pos.y + input_height);

      // temporary switch visibility to get dimensions
      var v = p.style.visibility == "" ? "visible" : p.style.visibility;
      var d = p.style.display;

      p.style.visibility = "hidden";
      p.style.display = "block";

      var pane_width = p.offsetWidth;
      var pane_height = p.offsetHeight;

      p.style.display = d;
      p.style.visibility = v;


      var pane_right = pos.x + pane_width;
      var pane_bottom = pos.y + pane_height;
      var pane_half = pos.y + pane_height / 2;
      var scroll_left =  window.scrollX;
      var scroll_top =  window.scrollY;
      var window_width = window.innerWidth;
      var window_height = window.innerHeight;
      var window_right = window_width + scroll_left;
      var window_bottom = window_height + scroll_top;

      // is input left or right side of window?
      var left = true;
      if ("left" == o.align ) {
        left = true;
      }
      else if ("right" == o.align ) {
        left = false;
      }
      else if (pos.x > (scroll_left + window_width/2)) {
        left = false;
      }
      
      if (!left) {
        var leftPos = pos.x - (pane_width - input_width);
        if (leftPos > scroll_left) {
          pos = new Point(leftPos, pos.y);
        }
      }

      if (pane_half > window_bottom) {
        // can we see at least half of the list?
        var top = pos.x - input_height - pane_height;
        if (top > scroll_top) {
          pos = new Point(pos.x, top);
        }
      }
      this._currentPosition = pos;
    }
    p.style.top = this._currentPosition.y.toString() + "px";
    p.style.left = this._currentPosition.x.toString() + "px";
  }

  _ignoreMouseover([e]) {
    this._doScrollIgnoreMouseover = true;
    var future = new Future.delayed(const Duration(milliseconds: 1000));
    this._scrollIgnoreMouseover = future.asStream().listen(this._ignoreMouseoverReset());
  }

  _ignoreMouseoverReset() {
    this._doScrollIgnoreMouseover = false;
  }

  _getSelected() {
    var selected = null,
    select_class = this._options.css.selected;

    this._listElement.queryAll("li") // TODO this.list
      .forEach((e) {
        if (e.classes.contains(select_class) &&
            HtmlTools.isVisible(e)) {
          selected = e;
          return false;
        }
      });
    return selected;
  }

  _onSelect(selected) {
    var data = new Data.fromJson(selected.dataset["data"]);
    if (data != null) {
      this._inputElement
        ..value = data.name //["name"]
        ..dataset["data"] = data.toJson();
      this.value = this._inputElement.value;
      this.dispatchEvent(new CustomEvent("fb-select", detail: data));
        

      this._trackEvent("name", "fb-select", "index", HtmlTools.prevSiblings(selected).length);
    }
  }

  _trackEvent(category, action, [label, value]) {
      this.dispatchEvent(new CustomEvent("fb-track-event", detail: {
        "category": category,
        "action":action,
        "label": label,
        "value": value
      }));
    //console.log("_trackEvent", category, action, label, value);
  }


  _strongify(str, substr) {
    // safely markup substr within str with <strong>
    var strong = new DivElement();
    var index = str.toLowerCase().indexOf(substr.toLowerCase());
    if (index >= 0) {
      var substr_len = substr.length;
      var pre = new SpanElement();
      pre.text = str.substring(0, index);
      var em = new Element.tag("strong");
      em.text = str.substring(index, index + substr_len);
      var post = new SpanElement();
      post.text = str.substring(index + substr_len);
      strong.append(pre);
      strong.append(em);
      strong.append(post);
    }
    else {
      strong.text = str;
    }
    return strong;
  }


  _isChar(e) {
    if (e.type == "keypress") {
      if ((e.metaKey || e.ctrlKey) && e.charCode == KeyCode.F7) { // TODO 118 warum F7??
        // ctrl+v
        return true;
      } else if (true) { //("isChar" in e) { // TODO umsetzen
          return e.isChar;
      }
    }
    else {
      return KeyCode.isCharacterKey(e.keyCode);
//        var not_char = this.keyCode.not_char; // TODO prüfen
//        if (not_char == null) {
//          not_char = {};
//          $.each($.suggest.keyCode, function(k,v) {
//            not_char["" + v] = 1;
//          });
//          $.suggest.keyCode.not_char = not_char;
//        }
//        return !(("" + e.keyCode) in not_char);
    }
  }


  /**
   * Parse input string into actual query string and structured name:value list
   *
   * "bob dylan type:artist" -> ["bob dylan", ["type:artist"]]
   * "Dear... type:film name{full}:Dear..." -> ["Dear...", ["type:film", "name{full}:Dear..."]]
   */
  List _parseInput(str) {
      // only pick out valid name:value pairs
      // a name:value is valid
      // 1. if there are no spaces before/after ":"
      // 2. name does not have any spaces
      // 3. value does not have any spaces OR value is double quoted
      var regex = new RegExp(r'/(\S+)\:(?:\"([^\"]+)\"|(\S+))/g');
      String qstr = str;
      var filters = [];
      var overrides = {};
      var m = regex.firstMatch(str);
      while (m != null) {
          if (_SEARCH_PARAMS.containsKey(m[1])) {
              //overrides[m[1]] = $.isEmptyObject(m[2]) ? m[3] : m[2]; // TODO isEmptyObject implementieren http://api.jquery.com/jQuery.isEmptyObject/
          }
          else {
              filters.add(m[0]);
          }
          qstr = qstr.replaceAll(m[0], "");
          m = regex.firstMatch(str);
      }
      qstr = qstr.replaceAll(r"/\s+/g", " ").trim(); // TODO
      return [qstr, filters, overrides];
  }

  /**
   * Convenient methods and regexs to determine valid mql ids.
   */
  var _mqlkeyFast = r"/^[_A-Za-z0-9][A-Za-z0-9_-]*$/";
  var _mqlkeySlow = r"/^(?:[A-Za-z0-9]|\$[A-F0-9]{4})(?:[A-Za-z0-9_-]|\$[A-F0-9]{4})*$/";

  bool _checkMqlKey(val) {
    RegExp regexFast = new RegExp(_mqlkeyFast);
    RegExp regexSlow = new RegExp(_mqlkeySlow);

      if (regexFast.hasMatch(val)) {
          return true;
      }
      else if (regexSlow.hasMatch(val)) {
          return true;
      }
      return false;
  }

  _checkMqlId(String val) {
      if (val.indexOf("/") == 0) {
          var keys = val.split("/");
          // remove beginning "/"
          keys.removeAt(0); 
          if (keys.length == 1 && keys[0] == "") {
              // "/" is a valid id
              return true;
          }
          else {
              for (var i=0, l=keys.length; i<l; i++) {
                  if (!_checkMqlKey(keys[i])) {
                      return false;
                  }
              }
              return true;
          }
      }
      else {
          return false;
      }
  }


  bool is_system_type(type_id) {
    if (type_id == null) {
      return false;
    }
    return (type_id.indexOf("/type/") == 0);
  }


// *THE* Freebase suggest implementation
  _init() {
    var o = this._options;
    if (o.flyoutServiceUrl == null) {
      o.flyoutServiceUrl = o.serviceUrl;
    }
    this._flyoutUrl = o.flyoutServiceUrl;
    if (o.flyoutServicePath != null) {
        this._flyoutUrl += o.flyoutServicePath;
    }
    // set api key for flyout service (search)
    this._flyoutUrl = this._flyoutUrl.replaceFirst(r"${key}", o.key);
    if (o.flyoutImageServiceUrl == null) {
      o.flyoutImageServiceUrl = o.serviceUrl;
    }
    this._flyoutImageUrl = o.flyoutImageServiceUrl;
    if (o.flyoutImageServicePath != null) {
        this._flyoutImageUrl += o.flyoutImageServicePath;
    }
    // set api key for image api
    this._flyoutImageUrl = this._flyoutImageUrl.replaceFirst(r"${key}", o.key);

    if (this._cache == null) {
      this._cache = {};
    }

    if (o.flyout) {
      this._flyoutpaneElement = new DivElement();
      this._flyoutpaneElement
        ..style.display = "none"
        ..classes.add("fbs-reset")
        ..classes.add(o.css.flyoutPane);

      if (o.flyoutParent != null) {
        o.flyoutParent.append(this._flyoutpaneElement);
      }
      else {
        this._flyoutpaneElement.style.position = "absolute";
        if (o.zIndex != null) {
          this._flyoutpaneElement.style.zIndex = o.zIndex.toString();
        }
        document.body.append(this._flyoutpaneElement); // TODO oder besser an shadowRoot anhängen? (flyout funktioniert dann nicht mehr richtig)
      }

      this._flyoutpaneMouseOver = _flyoutpaneElement.onMouseOver.listen((e) => _hoveroverList(e));
      this._flyoutpaneMouseOut = _flyoutpaneElement.onMouseOut.listen((e) => _hoveroutList(e));
      this._flyoutpaneMouseDown = _flyoutpaneElement.onMouseDown.listen((e) {
        e.stopPropagation();
        this._paneElement.click();
      });

      if (_flyoutCache == null) {
        _flyoutCache = new Map<String,Data>();
      }
    }
  }

  @override
  leftView() {
    this._paneElement.remove();
    this._listElement.remove();

    this._subscriptions.forEach((e) {
      if(e != null) {
        e.cancel();
      }
    });

    this._inputElement.dataset.clear() ;

    if (this._flyoutpaneElement != null) {
      this._flyoutpaneElement.remove();
    }
    this._inputElement.dataset.remove("requestCount");
    this._inputElement.dataset.remove("flyoutRequestCount");

    super.leftView();
  }

  _shiftEnter(e) {
    if (this._options.suggestNew) {
      this._suggestNew();
      this._hideAll();
    }
  }

  _hideAll() {
    HtmlTools.hideElement(this._paneElement);
    if (this._flyoutpaneElement != null) {
      HtmlTools.hideElement(this._flyoutpaneElement);
    }
    this.dispatchEvent(new CustomEvent("fb-pane-hide", detail: this.id)); // TODO detail
    this.dispatchEvent(new CustomEvent("fb-flyoutpane-hide", detail: this.id)); // TODO detail
  }

  _request(val, [int cursor]) {
    var o = this._options;
    var query = val;
    var filter = o.acParam.filter != null ? o.acParam.filter : [];

    // SEARCH_PARAMS can be overridden inline
    var extend_ac_param = null;

    // clone original filters so that we don't modify it
    filter = new List.from(filter);

    if (o.advanced) {
        // parse out additional filters in input value
        var structured = _parseInput(query);
        query = structured[0];
        if (structured[1].length > 0) {
            // all advance filters are ANDs
            filter.add("(all " + structured[1].join(" ") + ")");
        }
        extend_ac_param = structured[2];
        if (_checkMqlId(query)) {
            // handle anything that looks like a valid mql id:
            // filter=(all%20alias{start}:/people/pers)&prefixed=true
            filter.add("(any alias{start}:\"" + query + "\" mid:\"" +
                        query + "\")");
            extend_ac_param["prefixed"] = true;
            query = "";
        }
    }

    var data = new Data();
    data[o.queryParamName] = query;

    if (cursor != null) {
      data.cursor = cursor;
    }
    // $.extend(data, o.ac_param, extend_ac_param); // TODO
    if (filter.length > 0) {
        data.filter = filter; //["filter"] = filter;
    }

    var url = o.serviceUrl + o.servicePath + "?" + data.toUrlEncoded();
    var cached = this._cache[url];
    if (cached != null) {
      this._response(cached, cursor != null ? cursor : -1, true);
      return;
    }

    var callsStr = this._inputElement.dataset["request.count.suggest"];
    int calls = callsStr != null ? int.parse(callsStr, radix: 10) : 0;

    //window.console.log(url);

    var request = new HttpRequest();
    request
    ..open("GET", url)
    ..onLoadStart.first.then((e) {
      if (calls == null) {
        calls = 0;
      }
      if (calls == 0) {
        this._trackEvent("name", "start_session");
      }
      calls += 1;
      this._trackEvent("name", "request", "count", calls);
      this._inputElement.dataset["request.count.suggest"] = calls.toString();
    })
    ..onLoadEnd.listen((ProgressEvent e) {
      if (request.status == 200) {
        data = new Data.fromJson(request.responseText);
        this._cache[url] = data;
        data.prefix = val;  // keep track of prefix to match up response with input value
        this._response(data, cursor != null ? cursor : -1);
      }
    })
    ..onReadyStateChange.listen((ProgressEvent e) {
      if(request.readyState == HttpRequest.DONE) {
          this._trackEvent("name", "request", "tid");
          //request.getResponseHeader("X-Metaweb-TID")); // has to be enabled - how?
      }
    })
    ..onError.listen(
      (var e) {
        this._statusError();
        this._trackEvent("name", "request", "error", {
          "url": url,
          "response": request.responseText != null ? request.responseText : ""
        });
        this.dispatchEvent(new CustomEvent("fb-error", detail: [val, cursor]));
    });

    var future = new Future.delayed(new Duration(milliseconds: o.xhrDelay), () => request.send());
  }


  LIElement _createItem(Data data, Data response_data) {
    var css = this._options.css;
    var li =  new LIElement();
    li.classes.add(css.item);
    var label = new LabelElement();
    label.append(_strongify(data.name != null ? data.name : data.id, response_data.prefix));
    var name = new DivElement();
    name.classes.add(css.itemName);
    name.append(label);
    var nt = data.notable;
    if (data.under != null) {
      var small = new Element.tag("small");
      small.text = " (" + data.under + ")";
      label.query(":first").append(small);
    }
    if ((nt != null && is_system_type(nt["id"])) ||
        (this._options.scoring != null  &&
         this._options.scoring.toUpperCase() == "SCHEMA")) {
      var small = new Element.tag("small");
      small.text = " (" + data.id + ")";
      label.query(":first").append(small);
    }

    li.append(name);
    var type = new DivElement();
    type.classes.add(css.itemType);
    if (nt != null && nt["name"] != null) {
      type.text = nt["name"];
    }
    else if (this._options.showId && data.id != null) {
        // display human readable id if no notable type
        type.text = data.id;
    }
    if(name.children.length > 0) {
      name.insertBefore(type, name.children.first);
    } else {
      name.append(type);
    }

    //console.log("_createItem", li);
    return li;
  }


  _mouseoverItemHook(li) {
    var data = new Data.fromJson(li.dataset["data"]);

    if (this._options.flyout) {
      if (data != null) {
        this._flyoutRequest(data);
      }
      else {
        //this._flyoutpaneElement.hide();
      }
    }
  }

  _checkResponse(Data response_data) {
    return response_data.prefix == this._inputElement.value;
  }

  _responseHook(Data response_data, int cursor) {
    if (this._flyoutpaneElement != null) {
      HtmlTools.hideElement(this._flyoutpaneElement);
    }
    if (cursor != null && cursor > 0) {
      this._paneElement.queryAll(".fbs-more").forEach((e) => e.remove());
    }
    else {
      //this.pane.hide();
      this._listElement.children.clear();
    }
  }

  _showHook(Data response_data, cursor, LIElement first) {
    this._statusSelect();

    var o = this._options;
    var p = this._paneElement;
    var l = this._listElement;
    var result = response_data.result;
    var more = p.query(".fbs-more"); // TODO p
    var suggestnew = p.query(".fbs-suggestnew"); // TODO p
    var status = p.query(".fbs-status"); // TODO p

    // spell/correction
    var correction = response_data.correction;
    if (correction != null && correction.length > 0) {
      var spell_link = new AnchorElement();
      spell_link
        ..href = "#"
        ..classes.add("fbs-spell-link")
        ..append(correction[0]);

      _spellLinkClick = spell_link.onClick.listen((e) {
          e.preventDefault();
          e.stopPropagation();
          this._inputElement.value = correction[0];
          this.value = this._inputElement.value;
          this.dispatchEvent(new Event("textchange"));
        });
      var searchInsteadElement = new SpanElement();
      searchInsteadElement.text = "Search instead for ";
      this._statusElement
        ..children.clear()
        ..append(searchInsteadElement)
        ..append(spell_link);
      HtmlTools.showElement(this._statusElement);
    }

    // more
    if (result != null && result.length > 0 && response_data.cursor != null ) {
      if (more == null) {
        var more_link = new AnchorElement();
        more_link
          ..classes.add("fbs-more-link")
          ..href = "#"
          ..title = "(Ctrl+m)"
          ..text = "view more";
        more = new DivElement();
        more
          ..classes.add("fbs-more")
          ..append(more_link);
        if (response_data.cursor <= 200) { // TODO make querylimit an option with default to 200
          _moreLinkClick = more_link.onClick.listen((e) {
            e.preventDefault();
            e.stopPropagation();
            var m = this._paneElement.query(".fbs-more"); // TODO $(this).parent(".fbs-more")
            this._more(int.parse(m.dataset["cursor"], radix: 10));
          });
        } else {
          more_link.style.pointerEvents = "none";
          more_link.style.cursor = "default";
          more_link.text = "query limit reached";
        }
        l.parent.insertBefore(more, l.nextElementSibling);
      }
      more.dataset["cursor"] = response_data.cursor.toString();
      HtmlTools.showElement(more);
    }
    else {
      if (more != null) {
        more.remove();
      }
    }

    // suggest_new
    if (o.suggestNew != null) {
      if (suggestnew == null) {
        // create suggestnew option
        var button = new ButtonElement();
        button.classes.add("fbs-suggestnew-button");
        button.text = o.suggestNew;
        suggestnew = new DivElement();
        suggestnew.classes.add("fbs-suggestnew");
        var tmpDiv = new DivElement();
        tmpDiv
          ..classes.add("fbs-suggestnew-description")
          ..text = "Your item not in the list?";
        var tmpSpan = new SpanElement();
        tmpSpan
          ..classes.add("fbs-suggestnew-shortcut")
          ..text = "(Shift+Enter)";
        suggestnew
          ..append(tmpDiv)
          ..append(button)
          ..append(tmpSpan);

        _suggestNewClick = suggestnew.onClick.listen((e) {
            e.stopPropagation();
            this._suggestNew(e);
          });
        p.append(suggestnew);
      }
      HtmlTools.showElement(suggestnew);
    }
    else {
      if (suggestnew != null) {
        suggestnew.remove();
      }
    }

    // scroll to first if clicked on "more"
    if ((first != null) && cursor) {
      var top = HtmlTools.prevSiblings(first).length * first.getBoundingClientRect().height;

      animate(first.parent, properties: {"scrollTop": top})
        .onComplete.first.then((e) => first.dispatchEvent(new MouseEvent("mouseover")));
    }
  }

  _suggestNew([e]) {
    var v = this._inputElement.value;
    if (v == "") {
      return;
    }
    //console.log("_suggestNew", v);
    this._inputElement
      ..dataset["data"] = v;
    this.dispatchEvent(new CustomEvent("fb-select-new", detail: v));
    this._trackEvent("name", "fb-select-new", "index", "new");
    this._hideAll();
  }

  _more(int cursor) {
    if (cursor != null && cursor > 0) {
      var orig = this._inputElement.dataset["original"];
      if (orig != null) {
        this._inputElement.value = orig;
        this.value = this._inputElement.value;
      }
      this._request(this._inputElement.value, cursor);
      this._trackEvent("name", "more", "cursor", cursor);
    }
    return false;
  }

  _flyoutRequest(Data data) {
    var o = this._options;
    var sug_data = new Data.fromJson(this._flyoutpaneElement.dataset["data"]);
    if (sug_data != null && data.id == sug_data["id"]) {
      if (!HtmlTools.isVisible(this._flyoutpaneElement)) {
        var s = this._getSelected();
        this._flyoutPosition(s);
        HtmlTools.showElement(this._flyoutpaneElement);
        this.dispatchEvent(new CustomEvent("fb-flyoutpane-show", detail: this.id)); // TODO detail
      }
      return;
    }

    // check $.suggest.flyout.cache
    var cached = this._flyoutCache[data.id];
    if (cached != null && cached["id"] != null && cached["html"] != null) {
      // CLI-10009: use cached item only if id and html present
      this._flyoutResponse(cached);
      return;
    }

    //this.flyoutpane.hide();
    var flyout_id = data.id;
    var url = this._flyoutUrl.replaceFirst(r"${id}", data.id);


    var request = new HttpRequest();
    request
    ..open("GET", url)
    ..onLoadStart.first.then((e) {
      var calls = this._inputElement.dataset["flyoutRequestCount"] != null ?
          int.parse(this._inputElement.dataset["flyoutRequestCount"], radix: 10) : 0;
      calls += 1;
      this._trackEvent("name", "flyout.request", "count", calls);
      this._inputElement.dataset["flyoutRequestCount"] = calls.toString();
    })
    ..onLoadEnd.listen((e) {
      if (request.status == 200) {
        data = new Data.fromJson(request.responseText);
        data["req:id"] = flyout_id;
        if (data.result != null && data.result.length > 0) {
          data.html =
              _createFlyout(data.result[0],
                  this._flyoutImageUrl);
        }
        _flyoutCache[flyout_id] = data;
        this._flyoutResponse(data);
      }
    })
    ..onReadyStateChange.listen((e) {
      if(request.readyState == HttpRequest.DONE) {
        this._trackEvent("name", "flyout", "tid"); //,
//        request.getResponseHeader("X-Metaweb-TID"));
      }
    })
    ..onError.listen(
      (e) {
        this._trackEvent("name", "flyout", "error", {
          "url": url,
          "response": request.responseText != null ? request.responseText : ""
        });
    });

    new Future.delayed(new Duration(milliseconds: o.xhrDelay), () => request.send());

    this.dispatchEvent(new CustomEvent("fb-request-flyout", detail: { // TODO detail: request)); 
      "url": url,
      "cache": true
    }));
  }

  _flyoutResponse(Data data) {
    var o = this._options;
    var p = this._paneElement;
    var s = this._getSelected();
    if (HtmlTools.isVisible(p) && s != null) {
      var sug_data = new Data.fromJson(s.dataset["data"]);
      if ((sug_data != null) && (data["req:id"] == sug_data["id"]) && (data.html != null)) {
        this._flyoutpaneElement.children.clear();
        this._flyoutpaneElement.append(data.html);
        this._flyoutPosition(s);
        HtmlTools.showElement(this._flyoutpaneElement);
        this._flyoutpaneElement.dataset["data"] = sug_data.toJson();
        this.dispatchEvent(new CustomEvent("fb-flyoutpane-show", detail: this.id)); // TODO detail
      }
    }
  }

  _flyoutPosition(LIElement item) {
    if (this._options.flyoutParent != null) {
      return;
    }

    var p = this._paneElement;
    var fp = this._flyoutpaneElement;
    var css = this._options.css;
    Point pos;

    // temporary switch visibility to get dimensions
    var v = fp.style.visibility == "" ? "visible" : p.style.visibility;
    var d = fp.style.display;

    fp.style.visibility = "hidden";
    fp.style.display = "block";

    Point old_pos = fp.offset.topLeft;
    var flyout_size = new Point(fp.offsetWidth, fp.offsetHeight);

    fp.style.display = d;
    fp.style.visibility = v;

    Point pane_pos = p.offset.topLeft;
    var pane_width = p.offset.width;

    if (this._options.flyout == "bottom") {
      // flyout position on top/bottom
      pos = pane_pos;
      var input_pos = this._inputElement.offset.topLeft;
      if (pane_pos.y < input_pos.y) {
        pos = new Point(pos.x, pos.y - flyout_size.y);
      }
      else {
        pos = new Point(pos.x, pos.y + p.offset.height);
      }
      fp.classes.add(css.flyoutPane + "-bottom");
    }
    else {
      pos = item.borderEdge.topLeft;
      var item_height = item.offsetHeight;

      pos = new Point(pos.x + pane_width, pos.y);
      var flyout_right = pos.x + flyout_size.x;
      var scroll_left =  document.body.scrollLeft;
      var window_right = window.innerWidth + scroll_left;

      pos = new Point(pos.x, pos.y + item_height - flyout_size.y);
      if (pos.y < pane_pos.y) {
        pos = new Point(pos.x, pane_pos.y);
      }

      if (flyout_right > window_right) {
        var left = pos.x - (pane_width + flyout_size.x);
        if (left > scroll_left) {
          pos = new Point(left, pos.y);
        }
      }
      fp.classes.remove(css.flyoutPane + "-bottom");
    }

    if (!(pos.y == old_pos.y &&
          pos.x == old_pos.x)) {
      fp.style
        ..top = pos.y.toString() + "px"
        ..left = pos.x.toString() + "px";
    }
  }

  _hoveroutList([e]) {
    if (this._flyoutpaneElement != null && this._getSelected() == null) {
      HtmlTools.hideElement(this._flyoutpaneElement);
    }
  }


/**
 * Utility method to get values of an object specified by one or more
 * (nested) keys. For example:
 * <code>
 *   _getValue(my_dict, ["foo", "bar"])
 *   // Would resolve to my_dict["foo"]["bar"];
 * </code>
 * The method will return null, if any of the path specified refers to
 * a null or undefined value in the object.
 *
 * If resolved_search_values is TRUE, this will flatten search api
 * values that are arrays of entities ({mid, name})
 * to an array of their names and ALWAYS return an array of strings
 * of length >= 0.
 */
  _getValue(obj, path, [resolve_search_values]) {
    if (obj == null || path == null || path.length == 0) {
      return null;
    }
    if (!(path is List)) {
      path = [path];
    }
    var v = null;
    path.forEach((p){
      v = obj[p];
      if (v == null) {
        return false;
      }
      obj = v;
      return true;
    });
    if (resolve_search_values != null) {
      if (v == null) {
        return [];
      }
      if (!(v is List)) {
        v = [v];
      }
      var values = [];
      v.forEach((value) {
        if (value is Map) {
          if (value["name"] != null) {
            value = value["name"];
          }
          else if (value["id"] != null || value["mid"] != null) {
            value = value["id"] != null ? value["id"] : value["mid"];
          }
          else if (value["value"] != null) {
            // For cvts, value may contain other useful info (like date, etc.)
            var cvts = [];
            value.forEach((k, v) {
              if (k != "value") {
                cvts.add(v);
              }
            });
            value = value["value"] as String;
            if (cvts.length > 0) {
              value += " (" + cvts.join(", ") + ")";
            }
          }
        }
        if (value is List && value.length > 0) {
          value = value[0].value;
        }
        if (value != null) {
          values.add(value);
        }
      });
      return values;
    }
    // Cast undefined to null.
    return v == null ? null : v;
  }

  _isCommonsId(String id) {
    RegExp base = new RegExp(r"/^\/base\//");
    RegExp user = new RegExp(r"/^\/user\//");
    if (base.hasMatch(id) || user.hasMatch(id)) {
      return false;
    }
    return true;
  }

/**
 * Create the flyout html content given the search result
 * containing output=(notable:/client/summary description type).
 * The resulting html will be cached for optimization.
 *
 * @param data:Object - The search result with
 *     output=(notable:/client/summary description type).
 * @param _flyoutImageUrl:String - The url template for the image url.
 *   The substring, "${id}", will be replaced by data.id. It is assumed all
 *   parameters to the flyout image service (api key, dimensions, etc.) is
 *   already encoded into the url template.
 */
  DivElement _createFlyout(var data, _flyoutImageUrl) {

    var name = data["name"];
    var id = null;
    var image = null;
    var notable_props = [];
    var notable_types = [];
    var notable_seen = {}; // Notable types already added
    var notable = this._getValue(data, "notable");
    if (notable != null && notable["name"] != null) {
      notable_types.add(notable["name"]);
      notable_seen[notable["name"]] = true;
    }
    if (notable != null && is_system_type(notable["id"])) {
      id = data.id;
    }
    else {
      id = data["mid"];
      image = _flyoutImageUrl.replaceFirst(r"${id}", id);
    }
    var description_src = "freebase";
    var description = this._getValue(
        data, ["output", "description", "wikipedia"], true);
    if (description != null && description.length > 0) {
      description_src = "wikipedia";
    }
    else {
      description = this._getValue(
          data, ["output", "description", "freebase"], true);
    }
    if (description != null && description.length > 0) {
      description = description[0];
    }
    else {
      description = null;
    }
    var summary = _getValue(data, ["output", "notable:/client/summary"]);
    if (summary != null) {
      var notable_paths = _getValue(summary, "/common/topic/notable_paths");
      if (notable_paths != null && notable_paths.length > 0) {
        notable_paths.forEach((String path) {
          var values = _getValue(summary, path, true);
          if (values != null && values.length > 0) {
            var prop_text = path.split("/");
            prop_text.length -= 1;
            notable_props.add([prop_text, values.join(", ")]);
          }
        });
      }
    }
    var types = _getValue(
        data, ["output", "type", "/type/object/type"], true);
    if (types != null && types.length > 0) {
      types.forEach((t) {
        if (notable_seen[t] == null || notable_seen[t] == false) {
          notable_types.add(t);
          notable_seen[t] = true;
        }
      });
    }
    var content = new DivElement();
    content.classes.add("fbs-flyout-content");
    if (name != null) {
      var h1 = new HeadingElement.h1();
      h1
        ..id="fbs-flyout-title"
        ..text = name;
      content.append(h1);
    }
    var h3 = new HeadingElement.h3();
    h3
      ..classes.addAll(["fbs-topic-properties", "fbs-flyout-id"])
      ..text = id;
    content.append(h3);

    notable_props.forEach((prop) {

      var h3 = new HeadingElement.h3();
      var strong = new Element.tag("strong");
      strong.text = prop[0][0] + ": ";

      var textNode =
      h3
        ..classes.add("fbs-topic-properties")
        ..append(strong)
        ..append(new Text(prop[1]));
      content.append(h3);
    });

    if (description != null) {
      var p = new ParagraphElement();
      p.classes.add("fbs-topic-article");

      var em = new Element.tag("em");
      em
        ..classes.add("fbs-citation")
        ..text = "[" + description_src + "] ";
      var text = new Text(description);
      p
        ..append(em)
        ..append(text);

      content.append(p);
    }

    if (image != null) {
      content.children.forEach((e) => e.classes.add("fbs-flyout-image-true"));

      var img = new ImageElement();
      img
        ..id = "fbs-topic-image"
        ..classes.add("fbs-flyout-image-true")
        ..src = image;

      if(content.children.length > 0) {
        content.insertBefore(img, content.children.first);
      } else {
        content.append(img);
      }
    }
    var flyout_types = new SpanElement();
    flyout_types
      ..classes.add("fbs-flyout-types")
      ..text = notable_types.getRange(0, notable_types.length < 10 ? notable_types.length : 10).join(", ");
    var footer = new DivElement();
    footer
      ..classes.add("fbs-attribution")
      ..append(flyout_types);

    var ret = new DivElement();
    ret
      ..append(content)
      ..append(footer);
    return ret;
  }


  //var f = new InputElement(type: "text");
}

/**
the following code is supposed to be in separate files, but due to limitations in build/deploy separate code files are not supported yet
*/

//class AcParam {
//  String key;
//  List<String> filter;
//  String spell;
//  bool exact;
//  String lang;
//  String scoring;
//  bool prefixed;
//  bool stemmed;
//  String format;
//  String mqlOutput;
//  String output;
//
//  AcParam() {
//  }
//
//  AcParam.fromOption(Option option) {
//    this.key = option.key;
//    this.filter = option.filter;
//    this.spell = option.spell;
//    this.exact = option.exact;
//    this.lang = option.lang;
//    this.scoring = option.scoring;
//    this.prefixed = option.prefixed;
//    this.stemmed = option.stemmed;
//    this.format = option.format;
//    this.mqlOutput = option.mqlOutput;
//    this.output = option.output;
//  }
//}
//
//class CssOption {
//  String pane;
//  String list;
//  String item;
//  String itemName;
//  String selected;
//  String status;
//  String flyoutPane;
//  String itemType;
//
//  CssOption.defaults() {
//    setDefaults();
//  }
//
//  void setDefaults() {
//    this.pane = "fbs-pane";
//    this.list = "fbs-list";
//    this.item = "fbs-item";
//    this.itemName = "fbs-item-name";
//    this.selected = "fbs-selected";
//    this.status = "fbs-status";
//
//    this.itemType = "fbs-item-type";
//    this.flyoutPane = "fbs-flyout-pane";
//  }
//
//  CssOption.withData(Map<String,dynamic> data, {useDefaults: true}) {
//
//    if (useDefaults) {
//      this.setDefaults();
//    }
//
//    if (data != null) {
//      if (data.containsKey("pane")) this.pane = data["pane"];
//      if (data.containsKey("list")) this.list = data["list"];
//      if (data.containsKey("item")) this.item = data["item"];
//      if (data.containsKey("item_name")) this.itemName = data["item_name"];
//      if (data.containsKey("selected")) this.selected = data["selected"];
//      if (data.containsKey("status")) this.status = data["status"];
//      if (data.containsKey("item_type")) this.itemType = data["item_type"];
//      if (data.containsKey("flyoutpane")) this.flyoutPane = data["flyoutpane"];
//    }
//  }
//
//  CssOption({this.pane, this.list, this.item, this.itemName, this.selected, this.status, this.flyoutPane, this.itemType})
//  {}
//
//  addPrefixes(String prefix) {
//    pane = prefix + pane;
//    list = prefix + list;
//    item = prefix + item;
//    itemName = prefix + itemName;
//    selected = prefix + selected;
//    status = prefix + status;
//    flyoutPane = prefix + flyoutPane;
//  }
//}
//
//class Data implements Map<String,dynamic>{
//  var _map = new Map<String,dynamic>();
//
//  int get cost => _map.containsKey("cost") ? _map["cost"] : null;
//  set cost(int value) => _map["cost"] = value;
//
//  String get correction => _map.containsKey("correction") ? _map["correction"] : null;
//  set correction(String value) => _map["correction"] = value;
//
//  int get cursor => _map.containsKey("cursor") ? _map["cursor"] : null;
//  set cursor(int value) => _map["cursor"] = value;
//
//  String get id => _map["id"]; //_map.containsKey("id") ? _map["id"] : null;
//  set id(String value) => _map["id"] = value;
//
//  List get filter => _map.containsKey("filter") ? _map["filter"] : null;
//  set filter(List value) => _map["filter"] = value;
//
//  String get mid => _map.containsKey("mid") ? _map["mid"] : null;
//  set mid(String value) => _map["mid"] = value;
//
//  String get name => _map.containsKey("name") ? _map["name"] : null;
//  set name(String value) => _map["name"] = value;
//
//  DivElement get html => _map.containsKey("html") ? _map["html"] : null;
//  set html(DivElement value) => _map["html"] = value;
//
//  Map get notable => _map.containsKey("notable") ? _map["notable"] : null;
//  set notable(Map value) => _map["notable"] = value;
//
//  String get prefix => _map.containsKey("prefix") ? _map["prefix"] : null;
//  set prefix(String value) => _map["prefix"] = value;
//
//  List get result => _map.containsKey("result") ? _map["result"] : null;
//  set result(List value) => _map["result"] = value;
//
//  String get type => _map.containsKey("type") ? _map["type"] : null;
//  set type(String value) => _map["type"] = value;
//
//  String get under => _map.containsKey("under") ? _map["under"] : null;
//  set under(String value) => _map["under"] = value;
//
//  Data() {
//  }
//
//  Data.fromJson(String json) {
//    if (json != null) {
//      _map = JSON.decode(json);
//    }
//  }
//
//  String toUrlEncoded() {
//    return urlEncodeMap(_map);
//  }
//
//  static String urlEncodeMap(Map<String,dynamic> data) {
//    return data.keys.map((key) {
//      if (data[key] != null) {
//        if (key == "filter") {
//          return "${Uri.encodeComponent(key)}=${Uri.encodeComponent(data[key][0])}";
//        } else {
//          return "${Uri.encodeComponent(key)}=${Uri.encodeComponent(data[key].toString())}";
//        }
//      } else {
//        return "";
//      }
//    }).join("&");
//  }
//
//
//  String toJson(){
//    return JSON.encode(_map);
//  }
//
//  operator [](Object key) {
//    return _map[key];
//  }
//
//  void operator []=(String key, value) {
//    _map[key] = value;
//  }
//
//  void addAll(Map<String, dynamic> other) {
//    _map.addAll(other);
//  }
//
//  void clear() {
//    _map.clear();
//  }
//
//  bool containsKey(Object key) {
//    return _map.containsKey(key);
//  }
//
//  bool containsValue(Object value) {
//    return _map.containsValue(value);
//  }
//
//  void forEach(void f(String key, value)) {
//    _map.forEach(f);
//  }
//
//  bool get isEmpty => _map.isEmpty;
//
//  bool get isNotEmpty => _map.isNotEmpty;
//
//  Iterable<String> get keys => _map.keys;
//
//  int get length => _map.length;
//
//  putIfAbsent(String key, ifAbsent()) {
//    return _map.put(key, ifAbsent);
//  }
//
//  remove(Object key) {
//    return _map.remove(key);
//  }
//
//  Iterable get values => _map.values;
//}
//
//
//class HtmlTools {
//  // find all siblings of the provided element
//  static List siblings(Element element) {
//    var siblings = new List<Element>();
//
//    var sibling = element.previousElementSibling;
//
//    while (sibling != null) {
//      siblings.add(sibling);
//      sibling = sibling.previousElementSibling;
//    }
//
//    sibling = element.nextElementSibling;
//
//    while (sibling != null) {
//      siblings.add(sibling);
//      sibling = sibling.nextElementSibling;
//    }
//
//    return siblings;
//  }
//
//  // find all siblings before the provided element
//  static List prevSiblings(Element element) {
//    var siblings = new List<Element>();
//
//    var sibling = element.previousElementSibling;
//
//    while (sibling != null) {
//      siblings.add(sibling);
//      sibling = sibling.previousElementSibling;
//    }
//
//    return siblings;
//  }
//
//  // find all siblings after the provided element
//  static List nextSiblings(Element element) {
//    var siblings = new List<Element>();
//
//    var sibling = element.nextElementSibling;
//
//    while (sibling != null) {
//      siblings.add(sibling);
//      sibling = sibling.nextElementSibling;
//    }
//
//    return siblings;
//  }
//
//// hide the provided element
//  static void hideElement(Element e) {
//    e.style.display = "none";
//  }
//
//  // show the provided element
//  static void showElement(Element e) {
//    e.style.display = "block";
//  }
//
//  static bool isVisible(Element e) {
//    return (e.offsetHeight + e.offsetWidth != 0);
//  }
//}
//
//class Model extends ObservableBase{
//  @observable
//  String options;
//  @observable
//  String value;
//}
//
//class Option {
//  AcParam acParam;
//  bool advanced;
//  String align;
//  bool animate;
//  CssOption css;
//
//  String _cssPrefix = "";
//  String get cssPrefix => _cssPrefix;
//  set cssPrefix(String value) => value != null ? this.cssPrefix = value : this.cssPrefix = "";
//
//  bool exact;
//  List<String> filter;
//  bool flyout;
//  String flyoutImageServicePath;
//  String flyoutImageServiceUrl;
//  String flyoutImageUrl;
//  String flyoutLang;
//  Element flyoutParent;
//  String flyoutServicePath;
//  String flyoutServiceUrl;
//  String format;
//  String key;
//  String lang;
//  String mqlOutput;
//  Map nomatch;
//  String output;
//  Element parent;
//  bool prefixed;
//  String queryParamName;
//  String servicePath;
//  String serviceUrl;
//  String scoring;
//  bool showId;
//  bool soft;
//  String spell;
//  List status;
//  bool stemmed;
//  bool suggestNew;
//  int xhrDelay;
//  int zIndex;
//
//  Option() {
//  }
//
//
//  Option.defaults() {
//    this.setDefaults();
//  }
//
//  void setDefaults() {
//    this.status = [
//              "Start typing to get suggestions...",
//              "Searching...",
//              "Select an item from the list:",
//              "Sorry, something went wrong. Please try again later"
//              ];
//    this.soft = false;
//    this.css = new CssOption.defaults();
//    this.parent = null;
//    this.animate = false;
//    this.zIndex = null;
//
//    /**
//     * filter, spell, lang, exact, scoring, key, prefixed, stemmed, format
//    *
//     * are the new parameters used by the new freebase search on googleapis.
//     * Please refer the the API documentation as these parameters
//     * will be transparently passed through to the search service.
//    *
//     * @see http://wiki.freebase.com/wiki/ApiSearch
//     */
//
//    // search filters
//    this.filter = null;
//
//    // spelling corrections
//    this.spell = "always";
//    this.exact = true;
//    this.scoring = null;
//    // language to search (default to en)
//    this.lang = null; // NULL defaults ot "en"
//
//    // API key: required for googleapis
//    this.key = null;
//
//    this.prefixed = true;
//    this.stemmed = null;
//    this.format = null;
//    // Enable structured input name:value pairs that get appended to the search filters
//    // For example:
//    //
//    //   "bob dylan type:artist"
//    //
//    // Would get translated to the following request:
//    //
//    //    /freebase/v1/search?query=bob+dylan&filter=<original filter>&filter=(all type:artist)
//    //
//    this.advanced = true;
//
//    // If an item does not have a "notable" field, display the id or mid of the item
//    this.showId = true;
//
//    // query param name for the search service.
//    // If query name was "foo": search?foo=...
//    this.queryParamName = "query";
//
//    // base url for autocomplete service
//    this.serviceUrl = "https://www.googleapis.com/freebase/v1";
//
//    // service_url + service_path = url to autocomplete service
//    this.servicePath = "/search";
//
//    // "left", "right" or null
//    // where list will be aligned left or right with the input
//    this.align = null;
//
//    // whether or not to show flyout on mouseover
//    this.flyout = true;
//
//    // default is service_url if NULL
//    this.flyoutServiceUrl = null;
//
//    // flyout_service_url + flyout_service_path =
//    // url to search with output=(notable:/client/summary description type).
//    this.flyoutServicePath = "/search?filter=(all mid:\${id})&" +
//    "output=(notable:/client/summary description type)&key=\${key}";
//
//    // default is service_url if NULL
//    this.flyoutImageServiceUrl = null;
//
//    this.flyoutImageServicePath=
//      "/image\${id}?maxwidth=75&key=\${key}&errorid=/freebase/no_image_png";
//
//    // jQuery selector to specify where the flyout
//    // will be appended to (defaults to document.body).
//    this.flyoutParent = null;
//
//    // text snippet you want to show for the suggest
//    // new option
//    // clicking will trigger an fb-select-new event
//    // along with the input value
//    this.suggestNew = null;
//
//    this.nomatch = {
//      "text": "no matches",
//      "title": "No suggested matches",
//      "heading": "Tips on getting better suggestions:",
//      "tips": [
//             "Enter more or fewer characters",
//             "Add words related to your original search",
//             "Try alternate spellings",
//             "Check your spelling"
//             ]
//    };
//
//
//    // the delay before sending off the ajax request to the
//    // suggest and flyout service
//    this.xhrDelay = 200;
//  }
//
//  /*
//   * see https://developers.google.com/freebase/v1/search-widget#configuration-options
//   */
//  Option.fromJson(String json, {bool useDefaults : true}) {
////abstract class Status {
////  static const String START = "START";
////  static const String LOADING = "LOADING";
////  static const String SELECT = "SELECT";
////  static const String ERROR = "ERROR";
////}
//    if (useDefaults) {
//      this.setDefaults();
//    }
//
//    if (json != null && json.isNotEmpty) {
//       Map<String, dynamic> map = JSON.decode(json);
//
//       if (map.containsKey("advanced")) this.advanced = map["advanced"] == "true";
//       if (map.containsKey("exact")) this.exact = map["exact"] == true;
//       if (map.containsKey("filter")) this.filter = map["filter"];
//       if (map.containsKey("key")) this.key = map["key"];
//       if (map.containsKey("lang")) this.lang = map["lang"];
//       if (map.containsKey("scoring")) this.scoring = map["scoring"];
//       if (map.containsKey("spell")) this.spell = map["spell"];
//       if (map.containsKey("flyout")) this.flyout = map["flyout"] == "true";
//       if (map.containsKey("suggest_new")) this.suggestNew = map["suggest_new"];
//       if (map.containsKey("css")) this.css = new CssOption.withData(map["css"], useDefaults: useDefaults);
//       if (map.containsKey("css_prefix")) this.cssPrefix = map["css_prefix"];
//       if (map.containsKey("show_id")) this.showId = map["show_id"] == "true";
//       if (map.containsKey("service_url")) this.serviceUrl = map["service_url"];
//       if (map.containsKey("service_path")) this.servicePath = map["service_path"];
//       if (map.containsKey("flyout_service_url")) this.flyoutImageServiceUrl = map["flyout_service_url"];
//       if (map.containsKey("flyout_service_path")) this.flyoutServicePath = map["flyout_service_path"];
//       if (map.containsKey("flyout_image_service_url")) this.flyoutImageServiceUrl = map["flyout_image_service_url"];
//       if (map.containsKey("flyout_image_service_path")) this.flyoutImageServicePath = map["flyout_image_service_path"];
//       if (map.containsKey("flyout_parent")) this.flyoutParent = document.query(map["flyout_parent"]);
//       if (map.containsKey("align")) this.align = map["align"];
//       if (map.containsKey("status")) this.status = map["status"];
//       if (map.containsKey("parent")) this.parent = document.query(map["parent"]);
//       if (map.containsKey("animate")) this.animate = map["animate"] == "true";
//       if (map.containsKey("xhr_delay")) this.xhrDelay = map["xhr_delay"];
//       if (map.containsKey("zIndex")) this.zIndex = map["zIndex"];
//    }
//  }
//}
//
//
//abstract class Status {
//  static const String START = "START";
//  static const String LOADING = "LOADING";
//  static const String SELECT = "SELECT";
//  static const String ERROR = "ERROR";
//}
