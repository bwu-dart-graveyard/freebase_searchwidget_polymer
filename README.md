# Dart Freebase Search Widget

Dart port of Google's [Freebase Search Widget](https://developers.google.com/freebase/v1/search-widget)

## General notes:

### License
BSD 3-clause license (see [LICENSE](https://github.com/zoechi/dart-freebase-search-widget/blob/master/LICENSE) file).

### Freebase API key
An API key for the Google Freebase API is necessary.
You can obtain a key at [Google API Console](https://code.google.com/apis/console) (see also [Obtaining an API key](https://developers.google.com/freebase/v1/search-widget#obtaining-an-api-key)).
To some extend the API can be used without an API key at least if you use the Sandbox version of the API.


## Known issues:
* The original Freebase Search Widget provides several custom Events. None of them are implemented yet.
* Due to limitations of Polymer.dart the options can not be set as an attribute in HTML.
The [options](https://developers.google.com/freebase/v1/search-widget#configuration-options) can currently only be set by code as in the file index.dart.


## TODO
* Provide custom events as in the original.
* Write tests.

## Additional authors
* Dae Park (daepark@google.com) Built the original JavaScript version this project is derived from.
