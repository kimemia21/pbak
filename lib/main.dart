import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/utils/router.dart';
import 'package:pbak/providers/theme_provider.dart';
import 'package:pbak/providers/crash_detection_provider.dart';
import 'package:pbak/widgets/crash_alert_overlay.dart';
void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  //  await BackgroundCrashService.initializeService();

  runApp(const ProviderScope(child: MyApp()));
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
