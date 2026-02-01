// Conditional export so non-web platforms don't import `dart:html`.
//
// Any importers of `package:pbak/CacheManager.dart` will get the right
// implementation for their platform.
export 'cache_manager_io.dart' if (dart.library.html) 'cache_manager_web.dart';
