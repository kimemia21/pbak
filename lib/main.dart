import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pbak/CacheManager.dart';
import 'package:pbak/services/launch_service.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/utils/router.dart';
import 'package:pbak/providers/theme_provider.dart';
import 'package:pbak/providers/crash_detection_provider.dart';
import 'package:pbak/widgets/crash_alert_overlay.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Run the app with splash/loading screen that handles version check
  runApp(const ProviderScope(child: AppLoader()));
}

/// App Loader - Shows loading indicator while checking version
class AppLoader extends StatefulWidget {
  const AppLoader({super.key});

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader> {
  bool _isLoading = true;
  String _statusMessage = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Update status
      setState(() => _statusMessage = 'Checking for updates...');
      
      // Fetch launch config from server (includes version)
      final launchService = LaunchService();
      final launchConfig = await launchService.fetchLaunchConfig();
      
      // Check cache version against server version (web only)
      if (kIsWeb) {
        setState(() => _statusMessage = 'Verifying app version...');
        await CacheManager.checkAndClearCache(launchConfig.version);
      }
      
      // await BackgroundCrashService.initializeService();
      
      // Done loading
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Ready!';
        });
      }
    } catch (e) {
      print('⚠️ AppLoader: Error during initialization: $e');
      // Continue to app even if version check fails
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Ready!';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF1A1A2E), // Dark background
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo
                Image.asset(
                  'assets/images/logo.jpg',
                  width: 120,
                  height: 120,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.motorcycle,
                        size: 60,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                // Loading indicator
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                  ),
                ),
                const SizedBox(height: 20),
                // Status message
                Text(
                  _statusMessage,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const MyApp();
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final crashState = ref.watch(crashDetectorProvider);

    return MaterialApp.router(
      title: 'PBAK',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        // Keep typography consistent across devices by disabling system text
        // scaling (some devices/OS settings can make fonts too big/small).
        final mq = MediaQuery.of(context);

        return MediaQuery(
          data: mq.copyWith(textScaler: const TextScaler.linear(1.0)),
          child: Stack(
            children: [
              child ?? const SizedBox(),
              if (crashState.alertActive) const CrashAlertOverlay(),
            ],
          ),
        );
      },
    );
  }
}
