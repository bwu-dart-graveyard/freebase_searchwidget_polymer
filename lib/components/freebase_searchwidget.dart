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

import 'dart:html';
import 'dart:async';
import 'dart:convert';

import 'package:polymer/polymer.dart';
//import 'package:observe/observe.dart';
import 'package:animation/animation.dart';

part '../src/data.dart';
part '../src/status_enum.dart';
part '../src/cssoption.dart';
part '../src/acparam.dart';
part '../src/option.dart';
part '../src/htmltools.dart';

@CustomTag('freebase-searchwidget')
class FreebaseSearchwidget extends PolymerElement with ObservableMixin {

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
  Map SEARCH_PARAMS = {
    'key':1,
    'filter':1,
    'spell':1,
    'exact':1,
    'lang':1,
    'scoring':1,
    'prefixed':1,
    'stemmed':1,
    'format':1,
    'mql_output':1,
    'output':1
  };

  @observable
  String value = '';

  @observable
  String options = '';

  Option _options = new Option.defaults();
  Map<String,String> _status;
  Point _position;

  bool doScrollIgnoreMouseover;
  StreamSubscription scrollIgnoreMouseover;
  String flyout_url;
  String flyout_image_url;
  Map<String,String> cache;
  Map<String,Data> flyoutCache;
  Map not_char;

  DivElement statusElement;
  UListElement listElement;
  DivElement paneElement;
  DivElement flyoutpaneElement;
  InputElement inputElement;

  StreamSubscription paneMouseDown;
  StreamSubscription paneMouseUp;
  StreamSubscription paneClick;
  StreamSubscription inputKeyDown;
  StreamSubscription inputKeyPress;
  StreamSubscription inputKeyPressDeleyed;
  StreamSubscription inputKeyUp;
  StreamSubscription inputBlur;
  StreamSubscription inputTextChange;
  StreamSubscription inputFocus;
  StreamSubscription inputPaste;
  StreamSubscription inputPasteDelayed;
  StreamSubscription windowResize;
  StreamSubscription windowScroll;
  StreamSubscription listMouseOver;
  StreamSubscription listMouseOut;
  StreamSubscription nomatchClick;
  StreamSubscription spellLinkClick;
  StreamSubscription moreLinkClick;
  StreamSubscription suggestNewClick;
  StreamSubscription flyoutpaneMouseOver;
  StreamSubscription flyoutpaneMouseOut;
  StreamSubscription flyoutpaneMouseDown;

  List<StreamSubscription> subscriptions;
  var paste_timeout;
  var onresize;

  //created() { // Debug providing options using custom attrib
  init() {
    super.created();

    subscriptions = [ this.paneMouseDown,
                      this.paneMouseUp,
                      this.paneClick,
                      this.inputKeyDown,
                      this.inputKeyPress,
                      this.inputKeyPressDeleyed,
                      this.inputKeyUp,
                      this.inputBlur,
                      this.inputTextChange,
                      this.inputFocus,
                      this.inputPaste,
                      this.inputPasteDelayed,
                      this.windowResize,
                      this.windowScroll,
                      this.listMouseOver,
                      this.listMouseOut,
                      this.nomatchClick,
                      this.spellLinkClick,
                      this.moreLinkClick,
                      this.suggestNewClick,
                      this.flyoutpaneMouseOver,
                      this.flyoutpaneMouseOut,
                      this.flyoutpaneMouseDown];

    this.inputElement = shadowRoot.query('#inputElement');

    // Debug providing options using custom attrib
    //String optionsJson = shadowRoot.query('#optons').text;
    //SpanElement so = shadowRoot.query('#options');
    //String optionsJson = so.text;
    //this._options = new Option.fromJson(optionsJson);
    this._options = new Option.fromJson(options); // TODO doesn't work due to bug #12262

    Option o = this._options;

    CssOption css = o.css;

    css.addPrefixes(o.cssPrefix);

    // suggest parameters
    o.acParam = new AcParam.fromOption(o);

    // flyout service lang is the first specified lang
    o.flyoutLang = null;
    if (o.acParam.lang != null) {
      var lang = o.acParam.lang;
      if (lang is List && lang.length > 0) {
        lang = lang.join(',');
      }
      if (lang != null) {
        o.flyoutLang = lang;
      }
    }

    // status texts
    this._status = {
      Status.START: '',
      Status.LOADING: '',
      Status.SELECT: '',
      Status.ERROR: ''
    };

    if ((o.status != null) && (o.status is List) && (o.status.length >= 3)) {
      this._status[Status.START] = o.status[0] != null ? o.status[0] : '';
      this._status[Status.LOADING] = o.status[1] != null ? o.status[1] : '';
      this._status[Status.SELECT] = o.status[2] != null ? o.status[2] : '';
      if (o.status.length == 4) {
        this._status[Status.ERROR] = o.status[3] != null ? o.status[3] : '';
      }
    }

    // create the container for the drop down list
    var s = new DivElement();
    s.style.display = 'none';
    s.classes.add(css.status);
    var l = new UListElement();
    l.classes.add(css.list);
    var p = new DivElement();
    p.style.display = 'none';
    p.classes
      ..add('fbs-reset')
      ..add(css.pane);

    this.statusElement = s;
    this.listElement = l;
    this.paneElement = p;

    p
      ..append(s)
      ..append(l);


    if (o.parent != null) {
      o.parent.append(p);
    }
    else {
      p.style.position = 'absolute';
      if (o.zIndex != null) {
        p.style.zIndex = o.zIndex.toString();
      }
      document.body.append(p);
    }
    this.paneMouseDown = p.onMouseDown.listen((e) {
      //console.log("pane mousedown");
      this.inputElement.dataset['dont_hide'] = 'true';
      e.stopPropagation();
    });

    this.paneMouseUp = p.onMouseUp.listen((e) {
      //console.log("pane mouseup");
      if (this.inputElement.dataset['dont_hide'] == 'true') {
        this.inputElement.focus();
      }
      this.inputElement.dataset.remove('dont_hide');
      e.stopPropagation();
    });

    this.paneClick = p.onClick.listen((e) {
      //console.log("pane click");
      e.stopPropagation();
      var s = this.get_selected();
      if (s != null) {
        this.onselect(s);
        this.hide_all();
      }
    });

    listMouseOver = l.onMouseOver.listen((e) => this.hoverover_list(e));
    listMouseOut = l.onMouseOut.listen((e) => this.hoverout_list());
    //console.log(this.pane, this.list);

    this.inputElement.autocomplete = 'off';

    this.inputKeyDown = this.inputElement.onKeyDown.listen((e) => this.keydown(e));
    this.inputKeyPress = this.inputElement.onKeyPress.listen((e) => this.keypress(e));
    this.inputKeyPress = this.inputElement.onKeyUp.listen((e) => this.keyup(e));
    this.inputBlur = this.inputElement.onBlur.listen((e) => this.blurx(e));
    this.inputTextChange = this.inputElement.onChange.listen((e) => this.textchange());
    this.inputFocus = this.inputElement.onFocus.listen((e) => this.focusx(e));
    this.inputPaste = this.inputElement.onPaste.listen((e) {
//        .bind($.browser.msie ? "paste.suggest" : "input.suggest", function(e)) { // TODO makes Dart this dinguishion automatically
        if(this.inputPasteDelayed != null) {
          this.inputPasteDelayed.cancel();
        }
        var future = new Future.delayed(const Duration(milliseconds: 0));
        this.inputPasteDelayed = future.asStream().listen(this.textchange());
    });

    // resize handler
    this.onresize = (e) {
      this.invalidate_position();
      if (HtmlTools.isVisible(p)) {
        this.position();
        if (o.flyout != null && this.flyoutpaneElement != null && HtmlTools.isVisible(this.flyoutpaneElement)) {
          var s = this.get_selected();
          if (s != null) {
            this.flyout_position(s);
          }
        }
      }
    };

    windowResize = window.onResize.listen(this.onresize);
    windowScroll = window.onScroll.listen(this.onresize);

    _init();
  }


  invalidate_position() {
    this._position = null;
  }

  status_start() {
    this.hide_all();
    HtmlTools.siblings(this.statusElement).forEach((e) => HtmlTools.hideElement(e));

    if (this._status[Status.START] != null) {
      this.statusElement.text = this._status[Status.START];
      HtmlTools.showElement(this.statusElement);
      if (!HtmlTools.isVisible(this.paneElement)) {
        this.position();
        this.pane_show();
      }
    }
    if (this._status[Status.LOADING] != null) {
      this.statusElement.classes.remove('loading');
    }
  }


  status_loading() {
    HtmlTools.siblings(this.statusElement).forEach((e) => HtmlTools.showElement(e));

    if (this._status[Status.LOADING] != null) {
      this.statusElement
        ..classes.add('loading')
        ..text = this._status[Status.LOADING];
      HtmlTools.showElement(this.statusElement);

      if (!HtmlTools.isVisible(this.paneElement)) {
        this.position();
        this.pane_show();
      }
    }
    else {
      HtmlTools.hideElement(this.statusElement);
    }
  }

  status_select() {
    HtmlTools.siblings(this.statusElement).forEach((e) => HtmlTools.showElement(e));

    if (this._status[Status.SELECT] != null) {
      this.statusElement.text = this._status[Status.SELECT];
      HtmlTools.showElement(this.statusElement);
    }
    else {
      HtmlTools.hideElement(this.statusElement);
    }
    if (this._status[Status.LOADING] != null) {
      this.statusElement.classes.remove('loading');
    }
  }

  status_error() {
    HtmlTools.siblings(this.statusElement).forEach((e) => HtmlTools.showElement(e));
    if (this._status[Status.ERROR] != null) {
      this.statusElement.text = this._status[Status.ERROR];
      HtmlTools.showElement(this.statusElement);
    }
    else {
      HtmlTools.hideElement(this.statusElement);
    }
    if (this._status[Status.LOADING] != null ) {
      this.statusElement.classes.remove('loading');
    }
  }

  focusx(e) {
    //console.log("focusx", this.input.val() === "");

    if (this.inputElement.value == '') {
      this.status_start();
    }
    else {
      this.focus_hook(e);
    }
  }

  // override to be notified on focus and input has a value
  focus_hook(e) {
    //console.log("focus_hook", this.input.data("data.suggest"));
    if((this.inputElement.dataset.length > 0) &&
        (!HtmlTools.isVisible(this.paneElement)) &&
        (this.listElement.queryAll('.' + this._options.css.item).length > 0)) { // TODO this.list
      this.position();
      this.pane_show();
    }
  }

  keydown(e) {
    var key = e.keyCode;
    if (key == KeyCode.TAB) { // tab
      this.tab(e);
    }
    else if (key == KeyCode.UP || key == KeyCode.DOWN) { // up/down
      if (!e.shiftKey) {
        // prevents cursor/caret from moving (in Safari)
        e.preventDefault();
      }
    }
  }

  keypress(e) {
    var key = e.keyCode;
    if (key == KeyCode.UP || key == KeyCode.DOWN) { // up/down
      if (!e.shiftKey) {
        // prevents cursor/caret from moving
        e.preventDefault();
      }
    }
    else if (key == KeyCode.ENTER) { // enter
      this.enter(e);
    }
  }

  keyup(e) {
    var key = e.keyCode;
    //console.log("keyup", key);
    if (key == KeyCode.UP) { // up
      e.preventDefault();
      this.up(e);
    }
    else if (key == KeyCode.DOWN) { // down
      e.preventDefault();
      this.down(e);
    }
    else if (e.ctrlKey && key == KeyCode.M) { // 77
      this.paneElement.query('.fbs-more-link').click();
    }
    else if (this.is_char(e) || e.keyCode == KeyCode.BACKSPACE || e.keyCode == KeyCode.DELETE) {
      //this.textchange();
      if(this.inputKeyPressDeleyed != null) {
        this.inputKeyPressDeleyed.cancel();
      }
      var future = new Future.delayed(const Duration(milliseconds: 0));
      this.inputKeyPressDeleyed = future.asStream().listen(this.textchange());
    }
    else if (key == KeyCode.ESC) {
      // escape - WebKit doesn't fire keypress for escape
      this.escape(e);
    }
    return true;
  }

  blurx(e) { // x to prevent overriding method of the base class
    //console.log("blur", "dont_hide", this.input.data("dont_hide"),
    //            "data.suggest", this.input.data("data.suggest"));
    if (this.inputElement.dataset['dont_hide'] != null) {
      return;
    }
    var data = new Data.fromJson(this.inputElement.dataset['data']);
    this.hide_all();
  }

  tab(e) {
    if (e.shiftKey || e.metaKey || e.ctrlKey) {
      return;
    }

    var o = this._options;
    var visible = HtmlTools.isVisible(this.paneElement) &&
      this.listElement.queryAll('.' + o.css.item).length > 0;
    var s = this.get_selected();

    //console.log("tab", visible, s);

    if (visible && s) {
      this.onselect(s);
      this.hide_all();
    }
  }

  enter(e) {
    var o = this._options;
    var visible = HtmlTools.isVisible(this.paneElement);

    //console.log("enter", visible);

    if (visible) {
      if (e.shiftKey) {
        this.shift_enter(e);
        e.preventDefault();
        return;
      }
      else if (this.listElement.queryAll('.' + o.css.item).length > 0) {
        var s = this.get_selected();
        if (s) {
          this.onselect(s);
          this.hide_all();
          e.preventDefault();
          return;
        }
        else if (o.soft == null) {
          var data = new Data.fromJson(this.inputElement.dataset['data']);
          if (this.listElement.queryAll('.' + this._options.css.item + ':visible').length > 0) {
            this.updown(false);
            e.preventDefault();
            return;
          }
        }
      }
    }
    if (o.soft != null) {
      // submit form
      this.soft_enter();
    }
    else {
      e.preventDefault();
    }
  }

  soft_enter([e]) {}

  escape(e) {
    this.hide_all();
  }

  up(e) {
    //console.log("up");
    this.updown(true, e.ctrlKey || e.shiftKey);
  }

  down(e) {
    //console.log("up");
    this.updown(false, null, e.ctrlKey || e.shiftKey);
  }

  updown(goup, [gofirst = false, golast = false]) {
    //console.log("updown", goup, gofirst, golast);
    var o = this._options,
        css = o.css,
        p = this.paneElement,
        l = this.listElement;

    if (!HtmlTools.isVisible(p)) {
      if (!goup) {
        this.textchange();
      }
      return;
    }
    LIElement li = l.query('.' + css.item + ':visible'); // TODO l

    if (li.children.length == 0) {
      return;
    }

    var first = li.children[0];
    var last = li.children[li.children.length - 1];
    var cur = this.get_selected();
    if (cur == null) {
      cur = [];
    }

    if(this.scrollIgnoreMouseover != null) {
      this.scrollIgnoreMouseover.cancel();
    }

    this.doScrollIgnoreMouseover = false;

    if (goup) {//up
      if (gofirst) {
        this._goto(first);
      }
      else if (cur.length == null || cur.length == 0) {
        this._goto(last);
      }
      else if (cur[0] == first[0]) {
        first.classes.remove(css.selected);
        this.inputElement.value = this.inputElement.dataset['original'];
        this.hoverout_list();
      }
      else {
        var prev = HtmlTools.prevSiblings(document.query('.' + css.item + ':visible:first'));
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
      else if (cur[0] == last[0]) {
        last.classes.remove(css.selected);
        this.inputElement.value = this.inputElement.dataset['original'];
        this.hoverout_list();
      }
      else {
        var next = HtmlTools.nextSiblings(document.query('.' + css.item + ':visible:first'));
        this._goto(next);
      }
    }
  }

  _goto(LIElement li) {

    li.dispatchEvent(new MouseEvent('mouseover'));
    var d = JSON.decode(li.dataset['data']);
    this.inputElement.value = (d != null ? d.name : this.inputElement.dataset['original']);
    this.scroll_to(li);
  }

  scroll_to(LIElement item) {
    var l = this.listElement,
        scrollTop = l.scrollTop(),
        scrollBottom = scrollTop + l.innerHeight(),
        item_height = item.borderEdge.height; //outerHeight(),
        var offsetTop = HtmlTools.prevSiblings(item).length * item_height,
        offsetBottom = offsetTop + item_height;
    if (offsetTop < scrollTop) {
      this.ignore_mouseover();
      l.scrollTop(offsetTop);
    }
    else if (offsetBottom > scrollBottom) {
      this.ignore_mouseover();
      l.scrollTop(scrollTop + offsetBottom - scrollBottom);
    }
  }

  textchange() {
    this.inputElement.dataset.remove('data');
    this.inputElement.dispatchEvent(new Event("fb-textchange"));
    var v = this.inputElement.value;
    if (v == "") {
      this.status_start();
      return;
    }
    else {
      this.status_loading();
    }
    this.request(v);
  }

  response(Data data, int cursor, [bool first]) {
    if (data == null) {
      return;
    }
    if (data.cost != null) {
      this.trackEvent('name', "response", "cost", data.cost);
    }

    if (!this.check_response(data)) {
      return;
    }
    var result = [];

    if(data.result != null) {
      result = data.result;
    } else {
      throw 'response: data doesn\'t contain result';
    }

    this.response_hook(data, cursor);

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
      var li = this.create_item(eData, data);
      this.listMouseOver = li.onMouseOver.listen((e) => this.mouseover_item(e));
      li.dataset['data'] = eData.toJson();
      this.listElement.append(li);
      if (i == 0) {
        first = li;
        i++;
      }
    });

    this.inputElement.dataset['original'] = this.inputElement.value;

    if (this.listElement.queryAll('.' + o.css.item).length == 0 && o.nomatch != null) {
      var nomatch = new LIElement();
      nomatch.classes.add('fbs-nomatch');
      if (o.nomatch['text'] != null) {
        nomatch.text = o.nomatch['text'];
      }
      else {
        if (o.nomatch['title'] != null) {
          var tmpEm = new Element.tag('em');
          tmpEm.classes.add('fbs-nomatch-text');
          tmpEm.text = o.nomatch['title'];
          nomatch.append(tmpEm);
        }
        if (o.nomatch['heading'] != null) {
          var heading = new HeadingElement.h3();
          heading.text = o.nomatch['heading'];
          nomatch.append(heading);
        }
        var tips = o.nomatch['tips'];
        if (tips != null && tips.length > 0) {
          var tipsElement = new UListElement();
          tipsElement.classes.add('fbs-search-tips');

          tips.forEach((i,tip) {
            var tipElement = new LIElement();
            tipElement.text = tip;
            tipsElement.append(tipElement);
          });
          nomatch.append(tipsElement);
        }
      }
      nomatchClick = nomatch.onClick.listen((e) => e.stopPropagation());
      this.listElement.append(nomatch);
    }

    this.show_hook(data, cursor != -1, first);
    this.position();
    this.pane_show();
  }

  pane_show() {
    var show = false;
    var p = this.paneElement;

    if (this.listElement.queryAll('* > li').length > 0) {
      show = true;
    }
// TODO zu prüfen ob das so passt (not selector mit if geprüft)
      if (!show) {
        p.children //(':not(.' + this.options.css.list + ')') // TODO selector
          .forEach((e) {
            if (!e.classes.contains(this._options.css.list) && e.style.display != 'none') {
              show = true;
              return false;
            }
          });
      }
    if (show) {
      if (this._options.animate) { // TODO

        if (!HtmlTools.isVisible(p)) {
        var v = p.style.visibility == '' ? 'visible' : p.style.visibility;
        var d = p.style.display;
        var o = p.style.overflow == '' ? 'visible' : p.style.overflow;

        p.style.visibility = 'hidden';
        p.style.display = 'block';
        p.style.overflow = 'hidden';

        var height = p.borderEdge.height.toString() + 'px';

        p.style.display = d;
        p.style.visibility = v;

        p.style.height = '1px';
        HtmlTools.showElement(p);

        var anim = new ElementAnimation(p)
        ..properties = {'height': height }
        ..duration = 200
        ..onComplete.first.then((e) { p.style.overflow = o; p.style.height = 'auto'; })
        ..run();
        }

        this.inputElement.dispatchEvent(new Event("fb-pane-show"));
      }
      else {
        HtmlTools.showElement(p);
        this.inputElement.dispatchEvent(new Event("fb-pane-show"));
      }
    }
    else {
      HtmlTools.hideElement(p);
      this.inputElement.dispatchEvent(new Event("fb-pane-hide"));
    }
  }


  mouseover_item(e) {
    if (this.doScrollIgnoreMouseover != null) {
      return;
    }
    var target = e.target;
    while (target.nodeName.toLowerCase() != "li") {
      target = target.parent; // ("li:first"); // TODO selector
    }
    var li = target;
    var css = this._options.css;
    var l = this.listElement;

      l.queryAll('.' + css.item) // TODO l
        .forEach((e) {
          if (e != li.children[0]) {
            e.classes.remove(css.selected);
          }
        });
    if (!li.classes.contains(css.selected)) {
      li.classes.add(css.selected);
      this.mouseover_item_hook(li);
    }
  }

  hoverover_list(e) {
  }

  position() {
    var p  = this.paneElement;
    var o = this._options;

    if (o.parent != null) {
      return;
    }

    if (this._position == null) {
      var inp = this.inputElement;
      Point pos = inp.borderEdge.topLeft;
      int input_width = inp.borderEdge.width;
      int input_height = inp.borderEdge.height;
      pos = new Point(pos.x, pos.y + input_height);

      // temporary switch visibility to get dimensions
      var v = p.style.visibility == '' ? 'visible' : p.style.visibility;
      var d = p.style.display;

      p.style.visibility = 'hidden';
      p.style.display = 'block';

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
      if ('left' == o.align ) {
        left = true;
      }
      else if ('right' == o.align ) {
        left = false;
      }
      else if (pos.x > (scroll_left + window_width/2)) {
        left = false;
      }
      if (!left) {
        left = pos.x - (pane_width - input_width);
        if (left > scroll_left) {
          pos = new Point(left, pos.y);
        }
      }

      if (pane_half > window_bottom) {
        // can we see at least half of the list?
        var top = pos.x - input_height - pane_height;
        if (top > scroll_top) {
          pos = new Point(pos.x, top);
        }
      }
      this._position = pos;
    }
    p.style.top = this._position.y.toString() + 'px';
    p.style.left = this._position.x.toString() + 'px';
  }

  ignore_mouseover([e]) {
    this.doScrollIgnoreMouseover = true;
    var future = new Future.delayed(const Duration(milliseconds: 1000));
    this.scrollIgnoreMouseover = future.asStream().listen(this.ignore_mouseover_reset());
  }

  ignore_mouseover_reset() {
    this.doScrollIgnoreMouseover = false;
  }

  get_selected() {
    var selected = null,
    select_class = this._options.css.selected;

    this.listElement.queryAll('li') // TODO this.list
      .forEach((e) {
        if (e.classes.contains(select_class) &&
            HtmlTools.isVisible(e)) {
          selected = e;
          return false;
        }
      });
    return selected;
  }

  onselect(selected) {
    var data = new Data.fromJson(selected.dataset['data']);
    if (data != null) {
      this.inputElement
        ..value = data.name //['name']
        ..dataset['data'] = data.toJson()
        ..dispatchEvent(new Event("fb-select"));
        ;

      this.trackEvent('name', "fb-select", "index", HtmlTools.prevSiblings(selected).length);
    }
  }

  trackEvent(category, action, [label, value]) {
      this.inputElement.dispatchEvent(new Event("fb-track-event")); // TODO
//        category: category,
//        action:action,
//        label: label,
//        value: value
//      });
    //console.log("trackEvent", category, action, label, value);
  }


  strongify(str, substr) {
    // safely markup substr within str with <strong>
    var strong = new DivElement();
    var index = str.toLowerCase().indexOf(substr.toLowerCase());
    if (index >= 0) {
      var substr_len = substr.length;
      var pre = new SpanElement();
      pre.text = str.substring(0, index);
      var em = new Element.tag('strong');
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


  is_char(e) {
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
//            not_char['' + v] = 1;
//          });
//          $.suggest.keyCode.not_char = not_char;
//        }
//        return !(('' + e.keyCode) in not_char);
    }
  }


  /**
   * Parse input string into actual query string and structured name:value list
   *
   * "bob dylan type:artist" -> ["bob dylan", ["type:artist"]]
   * "Dear... type:film name{full}:Dear..." -> ["Dear...", ["type:film", "name{full}:Dear..."]]
   */
  List parse_input(str) {
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
          if (SEARCH_PARAMS.containsKey(m[1])) {
              //overrides[m[1]] = $.isEmptyObject(m[2]) ? m[3] : m[2]; // TODO isEmptyObject implementieren http://api.jquery.com/jQuery.isEmptyObject/
          }
          else {
              filters.add(m[0]);
          }
          qstr = qstr.replaceAll(m[0], '');
          m = regex.firstMatch(str);
      }
      qstr = qstr.replaceAll(r'/\s+/g', ' ').trim(); // TODO
      return [qstr, filters, overrides];
  }

  /**
   * Convenient methods and regexs to determine valid mql ids.
   */
  var mqlkey_fast = r'/^[_A-Za-z0-9][A-Za-z0-9_-]*$/';
  var mqlkey_slow = r'/^(?:[A-Za-z0-9]|\$[A-F0-9]{4})(?:[A-Za-z0-9_-]|\$[A-F0-9]{4})*$/';

  bool check_mql_key(val) {
    RegExp regexFast = new RegExp(mqlkey_fast);
    RegExp regexSlow = new RegExp(mqlkey_slow);

      if (regexFast.hasMatch(val)) {
          return true;
      }
      else if (regexSlow.hasMatch(val)) {
          return true;
      }
      return false;
  }

  check_mql_id(String val) {
      if (val.indexOf("/") == 0) {
          var keys = val.split("/");
          // remove beginning '/'
          keys.shift();
          if (keys.length == 1 && keys[0] == "") {
              // "/" is a valid id
              return true;
          }
          else {
              for (var i=0, l=keys.length; i<l; i++) {
                  if (!check_mql_key(keys[i])) {
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
    this.flyout_url = o.flyoutServiceUrl;
    if (o.flyoutServicePath != null) {
        this.flyout_url += o.flyoutServicePath;
    }
    // set api key for flyout service (search)
    this.flyout_url = this.flyout_url.replaceFirst(r'${key}', o.key);
    if (o.flyoutImageServiceUrl == null) {
      o.flyoutImageServiceUrl = o.serviceUrl;
    }
    this.flyout_image_url = o.flyoutImageServiceUrl;
    if (o.flyoutImageServicePath != null) {
        this.flyout_image_url += o.flyoutImageServicePath;
    }
    // set api key for image api
    this.flyout_image_url = this.flyout_image_url.replaceFirst(r'${key}', o.key);

    if (this.cache == null) {
      this.cache = {};
    }

    if (o.flyout) {
      this.flyoutpaneElement = new DivElement();
      this.flyoutpaneElement
        ..style.display = 'none'
        ..classes.add('fbs-reset')
        ..classes.add(o.css.flyoutPane);

      if (o.flyoutParent != null) {
        o.flyoutParent.append(this.flyoutpaneElement);
      }
      else {
        this.flyoutpaneElement.style.position = 'absolute';
        if (o.zIndex != null) {
          this.flyoutpaneElement.style.zIndex = o.zIndex.toString();
        }
        document.body.append(this.flyoutpaneElement); // TODO oder besser an shadowRoot anhängen? (flyout funktioniert dann nicht mehr richtig)
      }

      this.flyoutpaneMouseOver = flyoutpaneElement.onMouseOver.listen((e) => hoverover_list(e));
      this.flyoutpaneMouseOut = flyoutpaneElement.onMouseOut.listen((e) => hoverout_list(e));
      this.flyoutpaneMouseDown = flyoutpaneElement.onMouseDown.listen((e) {
        e.stopPropagation();
        this.paneElement.click();
      });

      if (flyoutCache == null) {
        flyoutCache = new Map<String,Data>();
      }
    }
  }

  removed() {
    this.paneElement.remove();
    this.listElement.remove();

    this.subscriptions.forEach((e) {
      if(e != null) {
        e.cancel();
      }
    });

    this.inputElement.dataset.clear() ;

    if (this.flyoutpaneElement != null) {
      this.flyoutpaneElement.remove();
    }
    this.inputElement.dataset.remove('requestCount');
    this.inputElement.dataset.remove('flyoutRequestCount');

    super.removed();
  }

  shift_enter(e) {
    if (this._options.suggestNew) {
      this.suggest_new();
      this.hide_all();
    }
  }

  hide_all() {
    HtmlTools.hideElement(this.paneElement);
    if (this.flyoutpaneElement != null) {
      HtmlTools.hideElement(this.flyoutpaneElement);
    }
    this.inputElement.dispatchEvent(new Event("fb-pane-hide"));
    this.inputElement.dispatchEvent(new Event("fb-flyoutpane-hide"));
  }

  request(val, [int cursor]) {
    var o = this._options;
    var query = val;
    var filter = o.acParam.filter != null ? o.acParam.filter : [];

    // SEARCH_PARAMS can be overridden inline
    var extend_ac_param = null;

    // clone original filters so that we don't modify it
    filter = new List.from(filter);

    if (o.advanced) {
        // parse out additional filters in input value
        var structured = parse_input(query);
        query = structured[0];
        if (structured[1].length > 0) {
            // all advance filters are ANDs
            filter.add("(all " + structured[1].join(" ") + ")");
        }
        extend_ac_param = structured[2];
        if (check_mql_id(query)) {
            // handle anything that looks like a valid mql id:
            // filter=(all%20alias{start}:/people/pers)&prefixed=true
            filter.add("(any alias{start}:\"" + query + "\" mid:\"" +
                        query + "\")");
            extend_ac_param['prefixed'] = true;
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
        data.filter = filter; //['filter'] = filter;
    }

    var url = o.serviceUrl + o.servicePath + '?' + data.toUrlEncoded();
    var cached = cache[url];
    if (cached != null) {
      this.response(cached, cursor != null ? cursor : -1, true);
      return;
    }

    var callsStr = this.inputElement.dataset['request.count.suggest'];
    int calls = callsStr != null ? int.parse(callsStr, radix: 10) : 0;


    var request = new HttpRequest();
    request
    ..open('GET', url)
    ..onLoadStart.first.then((e) {
      if (calls == null) {
        calls = 0;
      }
      if (calls == 0) {
        this.trackEvent('name', 'start_session');
      }
      calls += 1;
      this.trackEvent('name', 'request', 'count', calls);
      this.inputElement.dataset['request.count.suggest'] = calls.toString();
    })
    ..onLoadEnd.listen((HttpRequestProgressEvent e) {
      if (request.status == 200) {
        data = new Data.fromJson(request.responseText);
        cache[url] = data;
        data.prefix = val;  // keep track of prefix to match up response with input value
        this.response(data, cursor != null ? cursor : -1);
      }
    })
    ..onReadyStateChange.listen((HttpRequestProgressEvent e) {
      if(request.readyState == HttpRequest.DONE) {
          this.trackEvent('name', 'request', 'tid');
          //request.getResponseHeader('X-Metaweb-TID')); // has to be enabled - how?
      }
    })
    ..onError.listen(
      (var e) {
        this.status_error();
        this.trackEvent('name', 'request', 'error', {
          'url': url,
          'response': request.responseText != null ? request.responseText : ''
        });
        this.inputElement.dispatchEvent(new Event('fb-error')); //, xhr);
    });

    var future = new Future.delayed(new Duration(milliseconds: o.xhrDelay), () => request.send());
  }


  LIElement create_item(Data data, Data response_data) {
    var css = this._options.css;
    var li =  new LIElement();
    li.classes.add(css.item);
    var label = new LabelElement();
    label.append(strongify(data.name != null ? data.name : data.id, response_data.prefix));
    var name = new DivElement();
    name.classes.add(css.itemName);
    name.append(label);
    var nt = data.notable;
    if (data.under != null) {
      var small = new Element.tag('small');
      small.text = ' (' + data.under + ')';
      label.query(':first').append(small);
    }
    if ((nt != null && is_system_type(nt['id'])) ||
        (this._options.scoring != null  &&
         this._options.scoring.toUpperCase() == 'SCHEMA')) {
      var small = new Element.tag('small');
      small.text = ' (' + data.id + ')';
      label.query(':first').append(small);
    }

    li.append(name);
    var type = new DivElement();
    type.classes.add(css.itemType);
    if (nt != null && nt['name'] != null) {
      type.text = nt['name'];
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

    //console.log("create_item", li);
    return li;
  }


  mouseover_item_hook(li) {
    var data = new Data.fromJson(li.dataset['data']);

    if (this._options.flyout) {
      if (data != null) {
        this.flyout_request(data);
      }
      else {
        //this.flyoutpaneElement.hide();
      }
    }
  }

  check_response(Data response_data) {
    return response_data.prefix == this.inputElement.value;
  }

  response_hook(Data response_data, int cursor) {
    if (this.flyoutpaneElement != null) {
      HtmlTools.hideElement(this.flyoutpaneElement);
    }
    if (cursor != null && cursor > 0) {
      this.paneElement.queryAll(".fbs-more").forEach((e) => e.remove());
    }
    else {
      //this.pane.hide();
      this.listElement.children.clear();
    }
  }

  show_hook(Data response_data, cursor, LIElement first) {
    this.status_select();

    var o = this._options;
    var p = this.paneElement;
    var l = this.listElement;
    var result = response_data.result;
    var more = p.query('.fbs-more'); // TODO p
    var suggestnew = p.query('.fbs-suggestnew'); // TODO p
    var status = p.query('.fbs-status'); // TODO p

    // spell/correction
    var correction = response_data.correction;
    if (correction != null && correction.length > 0) {
      var spell_link = new AnchorElement();
      spell_link
        ..href = '#'
        ..classes.add('fbs-spell-link')
        ..append(correction[0]);

      spellLinkClick = spell_link.onClick.listen((e) {
          e.preventDefault();
          e.stopPropagation();
          this.inputElement.value = correction[0];
          this.inputElement.dispatchEvent(new Event("textchange"));
        });
      var searchInsteadElement = new SpanElement();
      searchInsteadElement.text = 'Search instead for ';
      this.statusElement
        ..children.clear()
        .append(searchInsteadElement)
        .append(spell_link);
      HtmlTools.showElement(this.statusElement);
    }

    // more
    if (result != null && result.length > 0 && response_data.cursor != null ) {
      if (more == null) {
        var more_link = new AnchorElement();
        more_link
          ..classes.add('fbs-more-link')
          ..href = '#'
          ..title = '(Ctrl+m)'
          ..text = 'view more';
        more = new DivElement();
        more
          ..classes.add('fbs-more')
          ..append(more_link);
        if (response_data.cursor <= 200) { // TODO make querylimit an option with default to 200
          moreLinkClick = more_link.onClick.listen((e) {
            e.preventDefault();
            e.stopPropagation();
            var m = this.paneElement.query(".fbs-more"); // TODO $(this).parent('.fbs-more')
            this.more(int.parse(m.dataset['cursor'], radix: 10));
          });
        } else {
          more_link.style.pointerEvents = 'none';
          more_link.style.cursor = 'default';
          more_link.text = 'query limit reached';
        }
        l.parent.insertBefore(more, l.nextElementSibling);
      }
      more.dataset['cursor'] = response_data.cursor.toString();
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
        button.classes.add('fbs-suggestnew-button');
        button.text(o.suggestNew);
        suggestnew = new DivElement();
        suggestnew.classes.add('fbs-suggestnew');
        var tmpDiv = new DivElement();
        tmpDiv
          ..classes.add('fbs-suggestnew-description')
          ..text = 'Your item not in the list?';
        var tmpSpan = new SpanElement();
        tmpSpan
          ..classes.add('fbs-suggestnew-shortcut')
          ..text = '(Shift+Enter)';
        suggestnew
          ..append(tmpDiv)
          ..append(button)
          ..append(tmpSpan);

        suggestNewClick = suggestnew.onClick.listen((e) {
            e.stopPropagation();
            this.suggest_new(e);
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

      animate(first.parent, properties: {'scrollTop': top})
        .onComplete.first.then((e) => first.dispatchEvent(new MouseEvent('mouseover')));
    }
  }

  suggest_new([e]) {
    var v = this.inputElement.value;
    if (v == "") {
      return;
    }
    //console.log("suggest_new", v);
    this.inputElement
      ..dataset['data'] = v
      ..dispatchEvent(new Event("fb-select-new"));
    this.trackEvent('name', "fb-select-new", "index", "new");
    this.hide_all();
  }

  more(int cursor) {
    if (cursor != null && cursor > 0) {
      var orig = this.inputElement.dataset['original'];
      if (orig != null) {
        this.inputElement.value = orig;
      }
      this.request(this.inputElement.value, cursor);
      this.trackEvent('name', 'more', 'cursor', cursor);
    }
    return false;
  }

  flyout_request(Data data) {
    var o = this._options;
    var sug_data = new Data.fromJson(this.flyoutpaneElement.dataset['data']);
    if (sug_data != null && data.id == sug_data['id']) {
      if (!HtmlTools.isVisible(this.flyoutpaneElement)) {
        var s = this.get_selected();
        this.flyout_position(s);
        HtmlTools.showElement(this.flyoutpaneElement);
        this.inputElement.dispatchEvent(new Event('fb-flyoutpane-show'));
      }
      return;
    }

    // check $.suggest.flyout.cache
    var cached = this.flyoutCache[data.id];
    if (cached != null && cached['id'] != null && cached['html'] != null) {
      // CLI-10009: use cached item only if id and html present
      this.flyout_response(cached);
      return;
    }

    //this.flyoutpane.hide();
    var flyout_id = data.id;
    var url = this.flyout_url.replaceFirst(r'${id}', data.id);


    var request = new HttpRequest();
    request
    ..open('GET', url)
    ..onLoadStart.first.then((e) {
      var calls = this.inputElement.dataset['flyoutRequestCount'] != null ?
          int.parse(this.inputElement.dataset['flyoutRequestCount'], radix: 10) : 0;
      calls += 1;
      this.trackEvent('name', 'flyout.request', 'count', calls);
      this.inputElement.dataset['flyoutRequestCount'] = calls.toString();
    })
    ..onLoadEnd.listen((e) {
      if (request.status == 200) {
        data = new Data.fromJson(request.responseText);
        data['req:id'] = flyout_id;
        if (data.result != null && data.result.length > 0) {
          data.html =
              create_flyout(data.result[0],
                  this.flyout_image_url);
        }
        flyoutCache[flyout_id] = data;
        this.flyout_response(data);
      }
    })
    ..onReadyStateChange.listen((e) {
      if(request.readyState == HttpRequest.DONE) {
        this.trackEvent('name', 'flyout', 'tid'); //,
//        request.getResponseHeader('X-Metaweb-TID'));
      }
    })
    ..onError.listen(
      (e) {
        this.trackEvent('name', 'flyout', 'error', {
          'url': url,
          'response': request.responseText != null ? request.responseText : ''
        });
    });

    new Future.delayed(new Duration(milliseconds: o.xhrDelay), () => request.send());

    this.inputElement.dispatchEvent(new Event("fb-request-flyout"));
  }

  flyout_response(Data data) {
    var o = this._options;
    var p = this.paneElement;
    var s = this.get_selected();
    if (HtmlTools.isVisible(p) && s != null) {
      var sug_data = new Data.fromJson(s.dataset['data']);
      if ((sug_data != null) && (data["req:id"] == sug_data['id']) && (data.html != null)) {
        this.flyoutpaneElement.children.clear();
        this.flyoutpaneElement.append(data.html);
        this.flyout_position(s);
        HtmlTools.showElement(this.flyoutpaneElement);
        this.flyoutpaneElement.dataset['data'] = sug_data.toJson();
        this.inputElement.dispatchEvent(new Event("fb-flyoutpane-show"));
      }
    }
  }

  flyout_position(LIElement item) {
    if (this._options.flyoutParent != null) {
      return;
    }

    var p = this.paneElement;
    var fp = this.flyoutpaneElement;
    var css = this._options.css;
    Point pos;

    // temporary switch visibility to get dimensions
    var v = fp.style.visibility == '' ? 'visible' : p.style.visibility;
    var d = fp.style.display;

    fp.style.visibility = 'hidden';
    fp.style.display = 'block';

    Point old_pos = fp.offset.topLeft;
    var flyout_size = new Point(fp.offsetWidth, fp.offsetHeight);

    fp.style.display = d;
    fp.style.visibility = v;

    Point pane_pos = p.offset.topLeft;
    var pane_width = p.offset.width;

    if (this._options.flyout == "bottom") {
      // flyout position on top/bottom
      pos = pane_pos;
      var input_pos = this.inputElement.offset.topLeft;
      if (pane_pos.y < input_pos.y) {
        pos = new Point(pos.x, pos.y - flyout_size.y);
      }
      else {
        pos = new Point(pos.x, pos.y + p.offset.height);
      }
      fp.addClass(css.flyoutpane + "-bottom");
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
        ..top = pos.y.toString() + 'px'
        ..left = pos.x.toString() + 'px';
    }
  }

  hoverout_list([e]) {
    if (this.flyoutpaneElement != null && this.get_selected() == null) {
      HtmlTools.hideElement(this.flyoutpaneElement);
    }
  }


/**
 * Utility method to get values of an object specified by one or more
 * (nested) keys. For example:
 * <code>
 *   get_value(my_dict, ['foo', 'bar'])
 *   // Would resolve to my_dict['foo']['bar'];
 * </code>
 * The method will return null, if any of the path specified refers to
 * a null or undefined value in the object.
 *
 * If resolved_search_values is TRUE, this will flatten search api
 * values that are arrays of entities ({mid, name})
 * to an array of their names and ALWAYS return an array of strings
 * of length >= 0.
 */
  get_value(obj, path, [resolve_search_values]) {
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
          if (value['name'] != null) {
            value = value['name'];
          }
          else if (value['id'] != null || value['mid'] != null) {
            value = value['id'] != null ? value['id'] : value['mid'];
          }
          else if (value['value'] != null) {
            // For cvts, value may contain other useful info (like date, etc.)
            var cvts = [];
            value.forEach((k, v) {
              if (k != 'value') {
                cvts.add(v);
              }
            });
            value = value['value'];
            if (cvts.length > 0) {
              value += ' (' + cvts.join(', ') + ')';
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

  is_commons_id(String id) {
    RegExp base = new RegExp(r'/^\/base\//');
    RegExp user = new RegExp(r'/^\/user\//');
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
 * @param flyout_image_url:String - The url template for the image url.
 *   The substring, "${id}", will be replaced by data.id. It is assumed all
 *   parameters to the flyout image service (api key, dimensions, etc.) is
 *   already encoded into the url template.
 */
  DivElement create_flyout(var data, flyout_image_url) {

    var name = data['name'];
    var id = null;
    var image = null;
    var notable_props = [];
    var notable_types = [];
    var notable_seen = {}; // Notable types already added
    var notable = this.get_value(data, 'notable');
    if (notable != null && notable['name'] != null) {
      notable_types.add(notable['name']);
      notable_seen[notable['name']] = true;
    }
    if (notable != null && is_system_type(notable['id'])) {
      id = data.id;
    }
    else {
      id = data['mid'];
      image = flyout_image_url.replaceFirst(r'${id}', id);
    }
    var description_src = 'freebase';
    var description = this.get_value(
        data, ['output', 'description', 'wikipedia'], true);
    if (description != null && description.length > 0) {
      description_src = 'wikipedia';
    }
    else {
      description = this.get_value(
          data, ['output', 'description', 'freebase'], true);
    }
    if (description != null && description.length > 0) {
      description = description[0];
    }
    else {
      description = null;
    }
    var summary = get_value(data, ['output', 'notable:/client/summary']);
    if (summary != null) {
      var notable_paths = get_value(summary, '/common/topic/notable_paths');
      if (notable_paths != null && notable_paths.length > 0) {
        notable_paths.forEach((String path) {
          var values = get_value(summary, path, true);
          if (values != null && values.length > 0) {
            var prop_text = path.split('/');
            prop_text.length -= 1;
            notable_props.add([prop_text, values.join(', ')]);
          }
        });
      }
    }
    var types = get_value(
        data, ['output', 'type', '/type/object/type'], true);
    if (types != null && types.length > 0) {
      types.forEach((t) {
        if (notable_seen[t] == null || notable_seen[t] == false) {
          notable_types.add(t);
          notable_seen[t] = true;
        }
      });
    }
    var content = new DivElement();
    content.classes.add('fbs-flyout-content');
    if (name != null) {
      var h1 = new HeadingElement.h1();
      h1
        ..id='fbs-flyout-title'
        ..text = name;
      content.append(h1);
    }
    var h3 = new HeadingElement.h3();
    h3
      ..classes.addAll(['fbs-topic-properties', 'fbs-flyout-id'])
      ..text = id;
    content.append(h3);

    notable_props.forEach((prop) {

      var h3 = new HeadingElement.h3();
      var strong = new Element.tag('strong');
      strong.text = prop[0][0] + ': ';

      var textNode =
      h3
        ..classes.add('fbs-topic-properties')
        ..append(strong)
        ..append(new Text(prop[1]));
      content.append(h3);
    });

    if (description != null) {
      var p = new ParagraphElement();
      p.classes.add('fbs-topic-article');

      var em = new Element.tag('em');
      em
        ..classes.add('fbs-citation')
        ..text = '[' + description_src + '] ';
      var text = new Text(description);
      p
        ..append(em)
        ..append(text);

      content.append(p);
    }

    if (image != null) {
      content.children.forEach((e) => e.classes.add('fbs-flyout-image-true'));

      var img = new ImageElement();
      img
        ..id = 'fbs-topic-image'
        ..classes.add('fbs-flyout-image-true')
        ..src = image;

      if(content.children.length > 0) {
        content.insertBefore(img, content.children.first);
      } else {
        content.append(img);
      }
    }
    var flyout_types = new SpanElement();
    flyout_types
      ..classes.add('fbs-flyout-types')
      ..text = notable_types.getRange(0, notable_types.length < 10 ? notable_types.length : 10).join(', ');
    var footer = new DivElement();
    footer
      ..classes.add('fbs-attribution')
      ..append(flyout_types);

    var ret = new DivElement();
    ret
      ..append(content)
      ..append(footer);
    return ret;
  }


  var f = new InputElement(type: 'text');
}