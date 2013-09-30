# Dart Freebase Search Widget

Dart port of Google's [Freebase Search Widget](https://developers.google.com/freebase/v1/search-widget)

## General notes:

### License
BSD 3-clause license (see [LICENSE](https://github.com/zoechi/dart-freebase-search-widget/blob/master/LICENSE) file).

## Changelog
### 2013-09-30
* Updated to latest Dart SDK Dart SDK version 0.7.6.1_r28029
* Getters for custom events added at the element instance 
* Minor fixes

### Freebase API key
An API key for the Google Freebase API is necessary.
You can obtain a key at [Google API Console](https://code.google.com/apis/console) (see also [Obtaining an API key](https://developers.google.com/freebase/v1/search-widget#obtaining-an-api-key)).
To some extend the API can be used without an API key at least if you use the Sandbox version of the API.

## Demo
I have created a very simple [demo page](http://zoechi.github.io/dart-freebase-search-widget/index.html) with just two instances of the component (one left aligned, the other right aligned). Just set the focus and start typing ...
The demo currently works in Google Chrome and Chromium but not yet in Firefox (I didn't yet try others)

## Usage
The files index.html/index.dart in the test subdirectory contain a simple example.

## Known issues:
* Due to limitations of Polymer.dart the options can not be set as a const literal attribute value in HTML.
The [options](https://developers.google.com/freebase/v1/search-widget#configuration-options) can currently only be set by code like in the file test/index.dart.
* Couldn't get it working with dart2js yet.


## TODO
* Write tests.

## Additional authors
* Dae Park (daepark@google.com) Built the original JavaScript version this project is derived from.
