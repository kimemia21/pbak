import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/utils/router.dart';
import 'package:pbak/providers/theme_provider.dart';
import 'package:pbak/providers/crash_detection_provider.dart';
import 'package:pbak/widgets/crash_alert_overlay.dart';
import 'package:pbak/services/crash_detection/background_crash_service.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // await BackgroundCrashService.initializeService();
  
  runApp( 
    
     const ProviderScope(child: MyApp())
    );
}


class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final crashState = ref.watch(crashDetectorProvider);

    return  MaterialApp(home:
 
    MaterialApp.router(
      title: 'PBAK Kenya',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        return Stack(
          children: [
            child ?? const SizedBox(),
            if (crashState.alertActive) const CrashAlertOverlay(),
          ],
        );
      },
    ));
  }
}
