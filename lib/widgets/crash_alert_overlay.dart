import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/providers/crash_detection_provider.dart';
import 'package:pbak/widgets/custom_button.dart';

class CrashAlertOverlay extends ConsumerWidget {
  const CrashAlertOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final crashState = ref.watch(crashDetectorProvider);

    if (!crashState.alertActive) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        color: AppTheme.deepRed.withOpacity(0.95),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.paddingL),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Warning Icon
                  Container(
                    padding: const EdgeInsets.all(AppTheme.paddingL),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.warning_rounded,
                      size: 80,
                      color: AppTheme.deepRed,
                    ),
                  ),
                  const SizedBox(height: AppTheme.paddingXL),

                  // Title
                  Text(
                    'CRASH DETECTED',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.paddingM),

                  // Message
                  Text(
                    crashState.emergencyCalled
                        ? 'Calling emergency contact...'
                        : 'Emergency services will be called in:',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.paddingL),

                  // Countdown
                  if (!crashState.emergencyCalled) ...[
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 8,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${crashState.countdown}',
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                color: Colors.white,
                                fontSize: 60,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.paddingXL),

                    // Cancel Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          ref.read(crashDetectorProvider.notifier).cancelAlert();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.deepRed,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppTheme.paddingL,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusM),
                          ),
                        ),
                        child: Text(
                          'I\'M OK - CANCEL ALERT',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppTheme.deepRed,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.paddingM),

                    // Info text
                    Text(
                      'Tap above if you\'re safe and don\'t need help',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ] else ...[
                    // Emergency called state
                    const SizedBox(height: AppTheme.paddingL),
                    Container(
                      padding: const EdgeInsets.all(AppTheme.paddingL),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      ),
                      child: Column(
                        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                          const SizedBox(height: AppTheme.paddingM),
                          Text(
                            'Help is on the way',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Crash details
                  if (crashState.lastCrashEvent != null) ...[
                    const SizedBox(height: AppTheme.paddingXL),
                    Container(
                      padding: const EdgeInsets.all(AppTheme.paddingM),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Crash Details:',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: AppTheme.paddingS),
                          Text(
                            crashState.lastCrashEvent!.description,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
