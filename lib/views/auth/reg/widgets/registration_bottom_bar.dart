import 'package:flutter/material.dart';

import 'package:pbak/theme/app_theme.dart';

class RegistrationBottomBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final bool isLoading;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final VoidCallback? onSubmit;

  const RegistrationBottomBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.isLoading,
    this.onBack,
    this.onNext,
    this.onSubmit,
  });

  bool get _isLast => currentStep == totalSteps - 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Material(
      elevation: 6,
      color: cs.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              if (currentStep > 0) ...[
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: isLoading ? null : onBack,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppTheme.brightRed, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_back_rounded, size: 20),
                    label: const Text(
                      'Back',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 3,
                child: FilledButton.icon(
                  onPressed: isLoading
                      ? null
                      : () {
                          if (_isLast) {
                            onSubmit?.call();
                          } else {
                            onNext?.call();
                          }
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.brightRed,
                    foregroundColor: AppTheme.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    ),
                  ),
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: AppTheme.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          _isLast
                              ? Icons.check_circle_rounded
                              : Icons.arrow_forward_rounded,
                          size: 20,
                        ),
                  label: Text(
                    _isLast ? 'Complete Registration' : 'Continue',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
