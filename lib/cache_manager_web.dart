import 'dart:html' as html;

/// Web implementation of CacheManager.
class CacheManager {
  static const String _versionKey = 'app_version';
  static const String _firstVisitKey = 'first_visit_done';
  static const String _reloadRequiredKey = 'reload_required';

  /// Checks if the cache should be cleared based on version changes.
  static Future<void> checkAndClearCache(String serverVersion) async {
    try {
      final String savedVersion = html.window.localStorage[_versionKey] ?? '0.0';
      final String? firstVisitDone = html.window.localStorage[_firstVisitKey];
      final String? reloadRequired = html.window.localStorage[_reloadRequiredKey];

      // Check if a reload was scheduled from a previous visit
      if (reloadRequired == 'true') {
        html.window.localStorage.remove(_reloadRequiredKey);
        await _performCacheClear();
        html.window.localStorage[_versionKey] = serverVersion;
        return;
      }

      // First visit: store version and mark, do not clear.
      if (firstVisitDone == null) {
        html.window.localStorage[_versionKey] = serverVersion;
        html.window.localStorage[_firstVisitKey] = 'true';
        return;
      }

      // Version changed: schedule cache clear for next reload instead of forcing reload
      if (savedVersion != serverVersion) {
        html.window.localStorage[_reloadRequiredKey] = 'true';
        html.window.localStorage[_versionKey] = serverVersion;
        // Clear caches without reloading - will take effect on next natural page load
        await _performCacheClear();
      }
    } catch (_) {
      // Ignore cache errors.
    }
  }

  static Future<void> _performCacheClear() async {
    try {
      // Attempt to update old app cache (if available)
      html.window.applicationCache?.update();

      // Unregister service workers
      if (html.window.navigator.serviceWorker != null) {
        final registrations = await html.window.navigator.serviceWorker!.getRegistrations();
        for (final reg in registrations) {
          await reg.unregister();
        }
      }

      // Clear caches
      await html.window.caches?.delete('flutter_app');
      await html.window.caches?.delete('flutter-app-manifest');
      
      // Note: We do NOT force reload here anymore
    } catch (_) {
      // Ignore cache errors.
    }
  }

  static Future<void> clearCache() async {
    try {
      await _performCacheClear();
      // Only reload if explicitly called (e.g., from settings)
      html.window.location.reload();
    } catch (_) {
      // Ignore cache errors.
    }
  }

  /// Utility to force refresh images (optional).
  static void refreshImageAssets(String assetPath) {
    try {
      final elements = html.document.querySelectorAll('img[src*="$assetPath"]');
      for (final el in elements) {
        final src = el.getAttribute('src');
        if (src != null) {
          el.setAttribute('src', '$src?v=${DateTime.now().millisecondsSinceEpoch}');
        }
      }
    } catch (_) {}
  }
}
