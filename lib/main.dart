import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pbak/CacheManager.dart';
import 'package:pbak/services/launch_service.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/utils/router.dart';
import 'package:pbak/providers/theme_provider.dart';
import 'package:pbak/providers/crash_detection_provider.dart';
import 'package:pbak/widgets/crash_alert_overlay.dart';
import 'package:pbak/widgets/first_open_info_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Fix for CanvasKit Typeface error on web
  if (kIsWeb) {
    // Pre-load Google Fonts configuration
    GoogleFonts.config.allowRuntimeFetching = true;
  }
  
  runApp(const ProviderScope(child: AppLoader()));
}

/// Premium App Loader with engaging animations
class AppLoader extends StatefulWidget {
  const AppLoader({super.key});

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader> with TickerProviderStateMixin {
  bool _isLoading = true;
  late AnimationController _spinController;
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Spin animation for the circular loader
    _spinController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    // Pulse animation for logo
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Fade in animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutBack),
    );

    _fadeController.forward();
    _initializeApp();
  }

  @override
  void dispose() {
    _spinController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      print('🔧 AppLoader: Initializing app...');
      
      final launchService = LaunchService();
      final launchConfig = await launchService.fetchLaunchConfig();
      
      print('🔧 AppLoader: Got launch config, version: ${launchConfig.version}');
      
      if (kIsWeb) {
        try {
          await CacheManager.checkAndClearCache(launchConfig.version);
          print('🔧 AppLoader: Cache check completed');
        } catch (cacheError) {
          print('⚠️ AppLoader: Cache error (non-fatal): $cacheError');
          // Continue even if cache check fails
        }
      }
      
      // Add minimum display time for smooth UX
      await Future.delayed(const Duration(milliseconds: 1500));
      
      print('🔧 AppLoader: Initialization complete');
      if (mounted) setState(() => _isLoading = false);
    } catch (e, stackTrace) {
      print('⚠️ AppLoader: Error: $e');
      print('⚠️ AppLoader: Stack trace: $stackTrace');
      // Always continue even if initialization fails
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFFAFAFA),
                  const Color(0xFFFFFFFF),
                  const Color(0xFFF5F5F5),
                ],
              ),
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Premium logo with glow effect
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer glow
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Container(
                                width: 140 + (_pulseController.value * 20),
                                height: 140 + (_pulseController.value * 20),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      const Color(0xFFD4A03E).withOpacity(0.3 * (1 - _pulseController.value)),
                                      const Color(0xFFD4A03E).withOpacity(0),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          // Logo container with shadow
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFD4A03E).withOpacity(0.3),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/logo.jpg',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFFE5B74E),
                                        Color(0xFFD4A03E),
                                        Color(0xFFC4902E),
                                      ],
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.two_wheeler_rounded,
                                    size: 60,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Premium brand name with letter spacing
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Color(0xFF2A2A2A),
                            Color(0xFF1A1A1A),
                            Color(0xFF2A2A2A),
                          ],
                        ).createShader(bounds),
                        child: const Text(
                          'PBAK',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 12,
                            height: 1,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                    
                      const SizedBox(height: 60),
                      
                      // Premium loading indicator with multiple layers
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer ring
                            AnimatedBuilder(
                              animation: _spinController,
                              builder: (context, child) {
                                return Transform.rotate(
                                  angle: _spinController.value * 2 * math.pi,
                                  child: CustomPaint(
                                    size: const Size(80, 80),
                                    painter: _RingPainter(
                                      progress: _spinController.value,
                                      color: const Color(0xFFD4A03E),
                                      strokeWidth: 3.0,
                                    ),
                                  ),
                                );
                              },
                            ),
                            // Inner ring (counter-rotation)
                            AnimatedBuilder(
                              animation: _spinController,
                              builder: (context, child) {
                                return Transform.rotate(
                                  angle: -_spinController.value * 1.5 * math.pi,
                                  child: CustomPaint(
                                    size: const Size(60, 60),
                                    painter: _RingPainter(
                                      progress: _spinController.value,
                                      color: const Color(0xFFD4A03E).withOpacity(0.4),
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                );
                              },
                            ),
                            // Center dot
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return Container(
                                  width: 8 + (_pulseController.value * 4),
                                  height: 8 + (_pulseController.value * 4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFD4A03E),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFD4A03E).withOpacity(0.5),
                                        blurRadius: 8 * _pulseController.value,
                                        spreadRadius: 2 * _pulseController.value,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Loading text with animated dots
                      AnimatedBuilder(
                        animation: _spinController,
                        builder: (context, child) {
                          final dots = '.' * ((_spinController.value * 3).floor() % 4);
                          return Text(
                            'Loading$dots',
                            style: TextStyle(
                              color: const Color(0xFF999999).withOpacity(0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return const MyApp();
  }
}

/// Custom painter for ring loader
class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Draw arc
    const startAngle = -math.pi / 2;
    final sweepAngle = math.pi * 1.5; // 270 degrees

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => 
      oldDelegate.progress != progress;
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
        final mq = MediaQuery.of(context);

        return MediaQuery(
          data: mq.copyWith(textScaler: const TextScaler.linear(1.0)),
          child: FirstOpenInfoDialogGate(
            child: Stack(
              children: [
                child ?? const SizedBox(),
                if (crashState.alertActive) const CrashAlertOverlay(),
              ],
            ),
          ),
        );
      },
    );
  }
}