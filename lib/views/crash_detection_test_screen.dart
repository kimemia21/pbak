import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/providers/crash_detection_provider.dart';
import 'package:pbak/widgets/custom_button.dart';
import 'package:pbak/widgets/animated_card.dart';

class CrashDetectionTestScreen extends ConsumerWidget {
  const CrashDetectionTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final crashState = ref.watch(crashDetectorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crash Detection Test'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            AnimatedCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        crashState.isMonitoring
                            ? Icons.sensors_rounded
                            : Icons.sensors_off_rounded,
                        color: crashState.isMonitoring
                            ? Colors.green
                            : Colors.grey,
                        size: 32,
                      ),
                      const SizedBox(width: AppTheme.paddingM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Crash Detection',
                              style: theme.textTheme.titleLarge,
                            ),
                            Text(
                              crashState.isMonitoring ? 'Active' : 'Inactive',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: crashState.isMonitoring
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: crashState.isMonitoring,
                        onChanged: (value) {
                          if (value) {
                            ref.read(crashDetectorProvider.notifier).startMonitoring();
                          } else {
                            ref.read(crashDetectorProvider.notifier).stopMonitoring();
                          }
                        },
                      ),
                    ],
                  ),
                  if (crashState.isMonitoring) ...[
                    const SizedBox(height: AppTheme.paddingM),
                    Container(
                      padding: const EdgeInsets.all(AppTheme.paddingS),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: AppTheme.paddingS),
                          Expanded(
                            child: Text(
                              'Monitoring accelerometer and gyroscope sensors',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppTheme.paddingM),

            // Current State
            AnimatedCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current State',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppTheme.paddingM),
                  _StatusRow(
                    label: 'Crash Detected',
                    value: crashState.crashDetected ? 'YES' : 'NO',
                    color: crashState.crashDetected ? AppTheme.deepRed : Colors.grey,
                  ),
                  const Divider(),
                  _StatusRow(
                    label: 'Alert Active',
                    value: crashState.alertActive ? 'YES' : 'NO',
                    color: crashState.alertActive ? AppTheme.deepRed : Colors.grey,
                  ),
                  const Divider(),
                  _StatusRow(
                    label: 'Emergency Called',
                    value: crashState.emergencyCalled ? 'YES' : 'NO',
                    color: crashState.emergencyCalled ? AppTheme.deepRed : Colors.grey,
                  ),
                  if (crashState.alertActive) ...[
                    const Divider(),
                    _StatusRow(
                      label: 'Countdown',
                      value: '${crashState.countdown}s',
                      color: AppTheme.goldAccent,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppTheme.paddingM),

            // Last Crash Event
            if (crashState.lastCrashEvent != null) ...[
              AnimatedCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last Crash Event',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppTheme.paddingM),
                    _InfoRow(
                      label: 'Type',
                      value: crashState.lastCrashEvent!.type.toString().split('.').last,
                    ),
                    const SizedBox(height: AppTheme.paddingS),
                    _InfoRow(
                      label: 'Time',
                      value: '${crashState.lastCrashEvent!.timestamp.hour}:${crashState.lastCrashEvent!.timestamp.minute}:${crashState.lastCrashEvent!.timestamp.second}',
                    ),
                    const SizedBox(height: AppTheme.paddingS),
                    _InfoRow(
                      label: 'Magnitude',
                      value: '${crashState.lastCrashEvent!.magnitude.toStringAsFixed(2)} m/s²',
                    ),
                    const SizedBox(height: AppTheme.paddingS),
                    _InfoRow(
                      label: 'Description',
                      value: crashState.lastCrashEvent!.description,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.paddingM),
            ],

            // Test Actions
            AnimatedCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Test Actions',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppTheme.paddingM),
                  CustomButton(
                    text: 'Simulate Crash',
                    onPressed: crashState.isMonitoring
                        ? () {
                            ref.read(crashDetectorProvider.notifier).simulateCrash();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Simulating crash event...'),
                                backgroundColor: AppTheme.deepRed,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        : null,
                    icon: Icons.warning_rounded,
                    backgroundColor: AppTheme.deepRed,
                  ),
                  const SizedBox(height: AppTheme.paddingM),
                  CustomButton(
                    text: 'Reset Crash State',
                    onPressed: crashState.crashDetected
                        ? () {
                            ref.read(crashDetectorProvider.notifier).resetCrash();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Crash state reset'),
                              ),
                            );
                          }
                        : null,
                    icon: Icons.refresh_rounded,
                    isOutlined: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.paddingM),

            // Instructions
            AnimatedCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: AppTheme.paddingS),
                      Text(
                        'How to Test',
                        style: theme.textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.paddingM),
                  _InstructionStep(
                    number: '1',
                    text: 'Toggle crash detection ON using the switch above',
                  ),
                  const SizedBox(height: AppTheme.paddingS),
                  _InstructionStep(
                    number: '2',
                    text: 'Tap "Simulate Crash" to trigger a test crash event',
                  ),
                  const SizedBox(height: AppTheme.paddingS),
                  _InstructionStep(
                    number: '3',
                    text: 'The screen will turn RED with a 30-second countdown',
                  ),
                  const SizedBox(height: AppTheme.paddingS),
                  _InstructionStep(
                    number: '4',
                    text: 'You can cancel the alert by tapping "I\'M OK" button',
                  ),
                  const SizedBox(height: AppTheme.paddingS),
                  _InstructionStep(
                    number: '5',
                    text: 'If not cancelled, emergency contact will be called',
                  ),
                  const SizedBox(height: AppTheme.paddingM),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.paddingM),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      border: Border.all(color: Colors.orange, width: 1),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: AppTheme.paddingS),
                        Expanded(
                          child: Text(
                            'Note: In a real crash, the device will vibrate, play an alert sound, and automatically call your emergency contact if you don\'t cancel within 30 seconds.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.paddingM),

            // Technical Info
            AnimatedCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detection Thresholds',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppTheme.paddingM),
                  _InfoRow(
                    label: 'Impact Threshold',
                    value: '30.0 m/s²',
                  ),
                  const SizedBox(height: AppTheme.paddingS),
                  _InfoRow(
                    label: 'Sudden Stop Threshold',
                    value: '25.0 m/s²',
                  ),
                  const SizedBox(height: AppTheme.paddingS),
                  _InfoRow(
                    label: 'Check Interval',
                    value: '100 ms',
                  ),
                  const SizedBox(height: AppTheme.paddingS),
                  _InfoRow(
                    label: 'Alert Countdown',
                    value: '30 seconds',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatusRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.paddingS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyLarge,
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.paddingM,
              vertical: AppTheme.paddingS,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
            ),
            child: Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: theme.textTheme.bodySmall,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _InstructionStep extends StatelessWidget {
  final String number;
  final String text;

  const _InstructionStep({
    required this.number,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppTheme.paddingS),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
