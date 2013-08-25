import 'dart:io';
import 'package:polymer/component_build.dart';

// Ref: http://www.dartlang.org/articles/dart-web-components/tools.html
main() {
  var pages = ['web/index.html',
               'test/index.html'];
  var args = new Options().arguments.toList()..addAll(['--', '--deploy']);
//   build(args, pages);
}
