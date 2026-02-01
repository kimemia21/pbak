import 'dart:io';

/// Platform-neutral file abstraction.
///
/// On IO platforms this is a real `dart:io` [File].
typedef PlatformFile = File;

PlatformFile platformFileFromPath(String path) => File(path);
