import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/providers/payment_provider.dart';
import 'package:pbak/models/payment_model.dart';
import 'package:pbak/widgets/loading_widget.dart';
import 'package:pbak/widgets/error_widget.dart';
import 'package:pbak/widgets/empty_state_widget.dart';
import 'package:intl/intl.dart';

class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final paymentsAsync = ref.watch(myPaymentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
        elevation: 0,
      ),
      body: paymentsAsync.when(
        data: (payments) {
          if (payments.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.receipt_long_rounded,
              title: 'No Payments Yet',
              message: 'Your payment transactions will appear here once you make a payment.',
            );
          }

          // Calculate totals
          final totalAmount = payments.fold<double>(
            0, (sum, p) => sum + p.paymentTotal);
          final successfulPayments = payments.where((p) => p.isSuccessful).length;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(myPaymentsProvider);
            },
            child: CustomScrollView(
              slivers: [
                // Summary Card
                SliverToBoxAdapter(
                  child: _buildSummaryCard(
                    context,
                    theme,
                    totalAmount,
                    payments.length,
                    successfulPayments,
                  ),
                ),

                // Payments List Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.paddingM,
                      AppTheme.paddingM,
                      AppTheme.paddingM,
                      AppTheme.paddingS,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Transactions',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${payments.length} total',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Payments List
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingM),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final payment = payments[index];
                        return _PaymentCard(payment: payment);
                      },
                      childCount: payments.length,
                    ),
                  ),
                ),

                // Bottom Padding
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppTheme.paddingXL),
                ),
              ],
            ),
          );
        },
        loading: () => const LoadingWidget(message: 'Loading payments...'),
        error: (error, stack) => CustomErrorWidget(
          message: 'Failed to load payments',
          onRetry: () => ref.invalidate(myPaymentsProvider),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    ThemeData theme,
    double totalAmount,
    int totalPayments,
    int successfulPayments,
  ) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.paddingM),
      padding: const EdgeInsets.all(AppTheme.paddingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.paddingM),
              Text(
                'Total Payments',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.paddingM),
          Text(
            'KES ${NumberFormat('#,###.00').format(totalAmount)}',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.paddingM),
          Row(
            children: [
              _SummaryChip(
                icon: Icons.receipt_rounded,
                label: '$totalPayments transactions',
                color: Colors.white,
              ),
              const SizedBox(width: AppTheme.paddingM),
              _SummaryChip(
                icon: Icons.check_circle_rounded,
                label: '$successfulPayments successful',
                color: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final PaymentModel payment;

  const _PaymentCard({required this.payment});

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'SUCCESS':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'FAILED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getPaymentIcon() {
    if (payment.isPackagePayment) {
      return Icons.card_membership_rounded;
    } else if (payment.isEventPayment) {
      return Icons.event_rounded;
    }
    return Icons.payment_rounded;
  }

  String _getPaymentTypeLabel() {
    if (payment.isPackagePayment) {
      return 'Package';
    } else if (payment.isEventPayment) {
      return 'Event';
    }
    return 'Payment';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(payment.paymentStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.paddingM),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          onTap: () => _showPaymentDetails(context, theme),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.paddingM),
            child: Column(
              children: [
                // Header Row
                Row(
                  children: [
                    // Payment Icon
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getPaymentIcon(),
                        color: statusColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppTheme.paddingM),

                    // Payment Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            payment.purpose,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _getPaymentTypeLabel(),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  payment.safeRef,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Amount
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'KES ${NumberFormat('#,###.00').format(payment.paymentTotal)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                payment.isSuccessful
                                    ? Icons.check_circle_rounded
                                    : payment.isPending
                                        ? Icons.hourglass_top_rounded
                                        : Icons.cancel_rounded,
                                size: 12,
                                color: statusColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                payment.safePaymentStatus,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: AppTheme.paddingM),
                Divider(
                  height: 1,
                  color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                ),
                const SizedBox(height: AppTheme.paddingS),

                // Footer Row
                Row(
                  children: [
                    // Payment Method
                    Row(
                      children: [
                        Icon(
                          Icons.phone_android_rounded,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          payment.safePaymentMethod,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Transaction ID
                    Text(
                      'ID: ${payment.orderId}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPaymentDetails(BuildContext context, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PaymentDetailsSheet(payment: payment),
    );
  }
}

class _PaymentDetailsSheet extends StatelessWidget {
  final PaymentModel payment;

  const _PaymentDetailsSheet({required this.payment});

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'SUCCESS':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'FAILED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(payment.paymentStatus);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppTheme.paddingL,
          AppTheme.paddingM,
          AppTheme.paddingL,
          MediaQuery.of(context).padding.bottom + AppTheme.paddingL,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.paddingL),

            // Status Icon
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  payment.isSuccessful
                      ? Icons.check_circle_rounded
                      : payment.isPending
                          ? Icons.hourglass_top_rounded
                          : Icons.cancel_rounded,
                  color: statusColor,
                  size: 48,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.paddingM),

            // Amount
            Center(
              child: Text(
                'KES ${NumberFormat('#,###.00').format(payment.paymentTotal)}',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.paddingS),

            // Status
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  payment.safePaymentStatus,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.paddingL),

            // Details Section
            _buildDetailRow(theme, 'Purpose', payment.purpose),
            _buildDetailRow(theme, 'Order ID', '#${payment.orderId}'),
            _buildDetailRow(theme, 'Reference', payment.safePaymentRef),
            _buildDetailRow(theme, 'Transaction ID', payment.safeTrxId),
            _buildDetailRow(theme, 'Payment Method', payment.safePaymentMethod),
            if (payment.paymentStatusDesc != null && payment.paymentStatusDesc!.isNotEmpty)
              _buildDetailRow(theme, 'Status Info', payment.paymentStatusDesc!),

            const SizedBox(height: AppTheme.paddingL),

            // Close Button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.paddingM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
