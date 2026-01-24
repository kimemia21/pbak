
import 'dart:html' as html;

class CacheManager {
  /// Clears browser cache for the web

  static const String _versionKey = "app_version";
  static const String _firstVisitKey = "app_first_visit_done";

  /// Check if cache needs to be cleared based on server version
  /// [serverVersion] - The version string from the server's /launch endpoint
  static Future<void> checkAndClearCache(String serverVersion) async {
    // Use localStorage directly to avoid SharedPreferences key prefix issues
    final String savedVersion = html.window.localStorage[_versionKey] ?? '0.0';
    final String? firstVisitDone = html.window.localStorage[_firstVisitKey];

    print("🔄 CacheManager: Saved version: $savedVersion | Server version: $serverVersion");
    print("🔄 CacheManager: First visit done: $firstVisitDone");

    // Check if this is the very first visit (no version saved yet)
    final bool isFirstVisit = savedVersion == '0.0' && firstVisitDone == null;

    if (isFirstVisit) {
      // First visit - just save the version, don't reload (prevents tab closing issue)
      print("🔄 CacheManager: First visit detected. Saving version without reload.");
      html.window.localStorage[_versionKey] = serverVersion;
      html.window.localStorage[_firstVisitKey] = 'true';
      return;
    }

    // Compare versions
    final double savedVersionNum = double.tryParse(savedVersion) ?? 0.0;
    final double serverVersionNum = double.tryParse(serverVersion) ?? 0.0;

    if (savedVersionNum < serverVersionNum) {
      // Server has a newer version - clear cache
      print("🔄 CacheManager: Version mismatch! Clearing cache...");
      print("🔄 CacheManager: Upgrading from $savedVersion → $serverVersion");
      
      // Save the new version BEFORE clearing cache (to prevent reload loop)
      html.window.localStorage[_versionKey] = serverVersion;
      
      // Clear render cache and reload
      await clearCache();
      
      // Note: Code below won't execute because clearCache() reloads the page
      print("🔄 CacheManager: Cache cleared and version updated to $serverVersion");
    } else {
      print("🔄 CacheManager: Version up to date. No cache clearing needed.");
    }
  }

  static Future<void> clearCache() async {
    print('🔄 CacheManager: Clearing browser render cache...');
    
    // Clear application cache (deprecated but still works in some browsers)
    html.window.applicationCache?.update();

    // Unregister service workers to clear cached assets
    if (html.window.navigator.serviceWorker != null) {
      try {
        final registrations = await html.window.navigator.serviceWorker!.getRegistrations();
        for (var registration in registrations) {
          await registration.unregister();
          print('🔄 CacheManager: Service worker unregistered.');
        }
      } catch (e) {
        print('🔄 CacheManager: Error unregistering service workers: $e');
      }
    }

    // Clear browser caches using Cache API (for PWA/service worker caches)
    try {
      await html.window.caches?.delete('flutter_app');
      await html.window.caches?.delete('flutter-app-manifest');
      print('🔄 CacheManager: Browser caches cleared.');
    } catch (e) {
      print('🔄 CacheManager: Cache API not available or error: $e');
    }

    print('🔄 CacheManager: Render cache cleared. Reloading with fresh assets...');
    
    // Force hard reload - bypass cache (true = force reload from server)
    html.window.location.reload();
  }

  /// Clears specific asset cache (e.g., images)
  static Future<void> clearAssetCache(String assetPath) async {
    // Add timestamp to force browser to reload asset
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final newPath = '$assetPath?v=$timestamp';

    // Update asset source with timestamped version
    final elements = html.document.querySelectorAll('img[src*="$assetPath"]');
    for (var element in elements) {
      element.setAttribute('src', newPath);
    }
  }
}



/**
 * Cache Management - Server-Driven Version Control
 * 
 * The version is fetched from the server's /launch endpoint:
 * Response: { "data": [{ "allow_discount": 1, "version": "1.4" }] }
 * 
 * In main.dart:
 * 
 *   final launchService = LaunchService();
 *   final launchConfig = await launchService.fetchLaunchConfig();
 *   
 *   if (kReleaseMode && kIsWeb) {
 *     await CacheManager.checkAndClearCache(launchConfig.version);
 *   }
 * 
 * When the server version is higher than the locally saved version,
 * the cache is cleared and the page reloads with fresh assets.
 */