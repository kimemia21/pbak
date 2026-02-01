/// Platform-neutral file abstraction.
///
/// On web we can't use `dart:io.File`, so we use a lightweight wrapper that
/// only carries the file path.
class PlatformFile {
  final String path;
  const PlatformFile(this.path);
}

PlatformFile platformFileFromPath(String path) => PlatformFile(path);
