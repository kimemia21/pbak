import 'package:flutter/material.dart';

import 'package:pbak/widgets/premium_ui.dart';

class RegistrationProgressHeader extends StatelessWidget {
  final List<String> stepTitles;
  final int currentStep;
  final int totalSteps;
  final ValueChanged<int>? onStepTap;

  const RegistrationProgressHeader({
    super.key,
    required this.stepTitles,
    required this.currentStep,
    required this.totalSteps,
    this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Material(
      color: cs.surface,
      elevation: 1,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Step ${currentStep + 1} of $totalSteps',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${(((currentStep + 1) / totalSteps) * 100).round()}%',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: (currentStep + 1) / totalSteps,
                  minHeight: 8,
                  backgroundColor: cs.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(PremiumUI.accent(context)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: totalSteps,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final isCompleted = index < currentStep;
                    final isCurrent = index == currentStep;
                    final canTap = index <= currentStep;

                    // Completed steps: neutral chip + check icon (no yellow highlight).
                    return PremiumChip(
                      selected: isCurrent,
                      onTap: canTap ? () => onStepTap?.call(index) : null,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isCompleted)
                            const Icon(Icons.check_rounded)
                          else
                            Text('${index + 1}'),
                          const SizedBox(width: 8),
                          Text(stepTitles[index]),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
