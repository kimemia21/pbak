// Conditional export so web builds do not import `dart:io`.
export 'platform_image_io.dart' if (dart.library.html) 'platform_image_web.dart';
