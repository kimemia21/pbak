// Conditional export so web builds do not import `dart:io`.
export 'platform_file_io.dart' if (dart.library.html) 'platform_file_web.dart';
