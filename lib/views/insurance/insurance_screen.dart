import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/providers/insurance_provider.dart';
import 'package:pbak/widgets/loading_widget.dart';
import 'package:pbak/widgets/error_widget.dart';
import 'package:pbak/widgets/empty_state_widget.dart';
import 'package:pbak/widgets/animated_card.dart';
import 'package:pbak/widgets/custom_button.dart';
import 'package:intl/intl.dart';

class InsuranceScreen extends ConsumerWidget {
  const InsuranceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final myInsuranceAsync = ref.watch(myInsuranceProvider);
    final availableInsuranceAsync = ref.watch(availableInsuranceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insurance'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Insurance',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: AppTheme.paddingM),
            
            myInsuranceAsync.when(
              data: (insurances) {
                if (insurances.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.security_rounded,
                    title: 'No Active Insurance',
                    message: 'Get insurance coverage for your bikes',
                  );
                }

                return Column(
                  children: insurances.map((insurance) {
                    final isExpiring = insurance.isExpiringSoon;
                    
                    return AnimatedCard(
                      margin: const EdgeInsets.only(bottom: AppTheme.paddingM),
                      onTap: () => context.push('/insurance/${insurance.id}'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      insurance.provider,
                                      style: theme.textTheme.titleLarge,
                                    ),
                                    Text(
                                      insurance.type,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.paddingS,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: insurance.isActive
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                                ),
                                child: Text(
                                  insurance.status,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: insurance.isActive ? Colors.green : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.paddingM),
                          const Divider(),
                          const SizedBox(height: AppTheme.paddingS),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Policy: ${insurance.policyNumber}',
                                style: theme.textTheme.bodySmall,
                              ),
                              Text(
                                'KES ${NumberFormat('#,###').format(insurance.price)}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.paddingS),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 16,
                                color: theme.textTheme.bodySmall?.color,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Expires: ${DateFormat('MMM dd, yyyy').format(insurance.endDate)}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                          if (isExpiring) ...[
                            const SizedBox(height: AppTheme.paddingS),
                            Container(
                              padding: const EdgeInsets.all(AppTheme.paddingS),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppTheme.radiusS),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.warning_rounded,
                                    size: 16,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Expires in ${insurance.daysRemaining} days',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const LoadingWidget(),
              error: (error, stack) => const CustomErrorWidget(
                message: 'Failed to load insurance',
              ),
            ),

            const SizedBox(height: AppTheme.paddingL),
            Text(
              'Available Plans',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: AppTheme.paddingM),

            availableInsuranceAsync.when(
              data: (insurances) {
                return Column(
                  children: insurances.map((insurance) {
                    return AnimatedCard(
                      margin: const EdgeInsets.only(bottom: AppTheme.paddingM),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            insurance.provider,
                            style: theme.textTheme.titleLarge,
                          ),
                          Text(
                            insurance.type,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: AppTheme.paddingM),
                          Text(
                            'KES ${NumberFormat('#,###').format(insurance.price)}/year',
                            style: theme.textTheme.headlineSmall,
                          ),
                          const SizedBox(height: AppTheme.paddingM),
                          CustomButton(
                            text: 'Get Quote',
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Getting quote for ${insurance.type}...'),
                                ),
                              );
                            },
                            isOutlined: true,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const LoadingWidget(),
              error: (error, stack) => const CustomErrorWidget(
                message: 'Failed to load available insurance',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
