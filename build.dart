import 'dart:io';
import 'package:polymer/component_build.dart';

// Ref: http://www.dartlang.org/articles/dart-web-components/tools.html
main() {
  var pages = ['web/index.html'];
  var args = new Options().arguments;
  args.addAll(['--', '--deploy']);
  build(args, pages);
}
