/// Non-web implementation of CacheManager.
///
/// On mobile/desktop this is a no-op.
class CacheManager {
  static Future<void> checkAndClearCache(String serverVersion) async {
    // No-op on non-web platforms.
  }
}
