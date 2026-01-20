import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/providers/insurance_provider.dart';
import 'package:pbak/models/insurance_provider_model.dart';
import 'package:pbak/widgets/loading_widget.dart';
import 'package:pbak/widgets/error_widget.dart';
import 'package:pbak/widgets/empty_state_widget.dart';
import 'package:pbak/widgets/animated_card.dart';
import 'package:pbak/widgets/custom_button.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class InsuranceScreen extends ConsumerWidget {
  const InsuranceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final myInsuranceAsync = ref.watch(myInsuranceProvider);
    final insuranceProvidersAsync = ref.watch(insuranceProvidersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insurance'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myInsuranceProvider);
          ref.invalidate(insuranceProvidersProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                    return const EmptyStateWidget(
                      icon: Icons.security_rounded,
                      title: 'No Active Insurance',
                      message: 'Get insurance coverage for your bikes from our trusted providers below',
                    );
                  }

                  return Column(
                    children: insurances.map((insurance) {
                      final isExpiring = insurance.isExpiringSoon;
                      
                      return AnimatedCard(
                        margin: const EdgeInsets.only(bottom: AppTheme.paddingM),
                        onTap: () =>{},
                        //  context.push('/insurance/${insurance.id}'),
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
                'Insurance Providers',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: AppTheme.paddingS),
              Text(
                'Trusted insurance partners for your bike coverage',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppTheme.paddingM),

              insuranceProvidersAsync.when(
                data: (providers) {
                  if (providers.isEmpty) {
                    return const EmptyStateWidget(
                      icon: Icons.business_rounded,
                      title: 'No Providers Available',
                      message: 'Insurance providers will appear here',
                    );
                  }

                  return Column(
                    children: providers.map((provider) {
                      return _InsuranceProviderCard(provider: provider);
                    }).toList(),
                  );
                },
                loading: () => const LoadingWidget(message: 'Loading providers...'),
                error: (error, stack) => CustomErrorWidget(
                  message: 'Failed to load insurance providers',
                  onRetry: () => ref.invalidate(insuranceProvidersProvider),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card widget for displaying insurance provider information
class _InsuranceProviderCard extends StatelessWidget {
  final InsuranceProviderModel provider;

  const _InsuranceProviderCard({required this.provider});

  Future<void> _launchUrl(String url) async {
    String formattedUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      formattedUrl = 'https://$url';
    }
    final uri = Uri.parse(formattedUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _makePhoneCall(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedCard(
      margin: const EdgeInsets.only(bottom: AppTheme.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with logo, name, and verification badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Provider Logo/Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: provider.logoUrl != null && provider.logoUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        child: Image.network(
                          provider.logoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.business_rounded,
                            color: theme.colorScheme.onPrimaryContainer,
                            size: 28,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.business_rounded,
                        color: theme.colorScheme.onPrimaryContainer,
                        size: 28,
                      ),
              ),
              const SizedBox(width: AppTheme.paddingM),
              
              // Provider Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            provider.providerName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (provider.isVerified)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.verified_rounded,
                                  size: 14,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Verified',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (provider.contactPerson != null)
                      Text(
                        provider.contactPerson!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.paddingM),
          
          // Rating and Reviews
          if (provider.rating != null)
            Row(
              children: [
                ...List.generate(5, (index) {
                  final filled = index < (provider.rating ?? 0).round();
                  return Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 18,
                    color: filled ? Colors.amber : theme.colorScheme.outline,
                  );
                }),
                const SizedBox(width: 8),
                Text(
                  provider.ratingText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (provider.totalReviews != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    '(${provider.totalReviews} reviews)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          
          const SizedBox(height: AppTheme.paddingM),
          const Divider(),
          const SizedBox(height: AppTheme.paddingS),
          
          // Address
          if (provider.fullAddress.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    provider.fullAddress,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          
          if (provider.operatingHours != null) ...[
            const SizedBox(height: AppTheme.paddingS),
            Row(
              children: [
                Icon(
                  Icons.schedule_outlined,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Hours: ${provider.operatingHours}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
          
          const SizedBox(height: AppTheme.paddingM),
          
          // Action Buttons
          Row(
            children: [
              if (provider.phone != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _makePhoneCall(provider.phone!),
                    icon: const Icon(Icons.phone_outlined, size: 18),
                    label: const Text('Call'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              if (provider.phone != null && provider.email != null)
                const SizedBox(width: AppTheme.paddingS),
              if (provider.email != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _sendEmail(provider.email!),
                    icon: const Icon(Icons.email_outlined, size: 18),
                    label: const Text('Email'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
            ],
          ),
          
          if (provider.website != null) ...[
            const SizedBox(height: AppTheme.paddingS),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _launchUrl(provider.website!),
                icon: const Icon(Icons.language_rounded, size: 18),
                label: const Text('Visit Website'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
