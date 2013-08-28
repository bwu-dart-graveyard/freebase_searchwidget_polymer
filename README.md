# Dart Freebase Search Widget

Dart port of Google's [Freebase Search Widget](https://developers.google.com/freebase/v1/search-widget)

## General notes:

### License
BSD 3-clause license (see [LICENSE](https://github.com/zoechi/dart-freebase-search-widget/blob/master/LICENSE) file).

### Freebase API key
An API key for the Google Freebase API is necessary.
You can obtain a key at [Google API Console](https://code.google.com/apis/console) (see also [Obtaining an API key](https://developers.google.com/freebase/v1/search-widget#obtaining-an-api-key)).
To some extend the API can be used without an API key at least if you use the Sandbox version of the API.

## Usage
The files index.html/index.dart in the test subdirectory contain a simple example.

## Known issues:
* Due to limitations of Polymer.dart the options can not be set as a const literal attribute value in HTML.
The [options](https://developers.google.com/freebase/v1/search-widget#configuration-options) can currently only be set by code like in the file test/index.dart.
* Couldn't get it working with dart2js yet.


## TODO
* Write tests.
* Check build/dart2js regular after each available Dart update.

## Additional authors
* Dae Park (daepark@google.com) Built the original JavaScript version this project is derived from.
