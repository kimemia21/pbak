import 'dart:math' as math;
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

/// App Loader - Clean minimal loading screen
class AppLoader extends StatefulWidget {
  const AppLoader({super.key});

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
    _initializeApp();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      final launchService = LaunchService();
      final launchConfig = await launchService.fetchLaunchConfig();
      
      if (kIsWeb) {
        await CacheManager.checkAndClearCache(launchConfig.version);
      }
      
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      print('⚠️ AppLoader: Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                ClipOval(
                  child: Image.asset(
                    'assets/images/logo.jpg',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD4A03E),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.two_wheeler_rounded, size: 50, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // PBAK text
                const Text(
                  'PBAK',
                  style: TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 6,
                  ),
                ),
                const SizedBox(height: 32),
                // Cool loading indicator
                SizedBox(
                  width: 32,
                  height: 32,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (_, __) => CustomPaint(
                      painter: _LoadingPainter(_controller.value),
                    ),
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

// Custom loading painter for cool dots animation
class _LoadingPainter extends CustomPainter {
  final double progress;
  _LoadingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    const dotCount = 8;
    const dotRadius = 3.0;
    final radius = size.width / 2 - dotRadius;

    for (int i = 0; i < dotCount; i++) {
      final angle = (i / dotCount) * 3.14159 * 2 - 3.14159 / 2;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      
      // Calculate opacity based on progress
      final opacity = ((progress * dotCount - i) % dotCount) / dotCount;
      paint.color = const Color(0xFFD4A03E).withOpacity(opacity.clamp(0.2, 1.0));
      
      canvas.drawCircle(Offset(x, y), dotRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LoadingPainter oldDelegate) => true;
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
