import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/providers/notification_provider.dart';
import 'package:pbak/widgets/loading_widget.dart';
import 'package:pbak/widgets/error_widget.dart';
import 'package:pbak/widgets/empty_state_widget.dart';
import 'package:pbak/widgets/animated_card.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notificationsState = ref.watch(notificationNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () {
              // Mark all as read
              notificationsState.whenData((notifications) {
                for (var notif in notifications.where((n) => !n.isRead)) {
                  ref.read(notificationNotifierProvider.notifier).markAsRead(notif.id);
                }
              });
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: notificationsState.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.notifications_none_rounded,
              title: 'No Notifications',
              message: 'You\'re all caught up!',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(notificationNotifierProvider.notifier).loadNotifications();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(AppTheme.paddingM),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return AnimatedCard(
                  margin: const EdgeInsets.only(bottom: AppTheme.paddingM),
                  onTap: () {
                    if (!notification.isRead) {
                      ref.read(notificationNotifierProvider.notifier).markAsRead(notification.id);
                    }
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.paddingS),
                        decoration: BoxDecoration(
                          color: _getTypeColor(notification.type).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                        ),
                        child: Icon(
                          _getTypeIcon(notification.type),
                          color: _getTypeColor(notification.type),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppTheme.paddingM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    notification.title,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: notification.isRead
                                          ? FontWeight.normal
                                          : FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (!notification.isRead)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.deepRed,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.paddingS),
                            Text(
                              notification.message,
                              style: theme.textTheme.bodyMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppTheme.paddingS),
                            Text(
                              _formatTimestamp(notification.timestamp),
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
        loading: () => const LoadingWidget(message: 'Loading notifications...'),
        error: (error, stack) => CustomErrorWidget(
          message: 'Failed to load notifications',
          onRetry: () => ref.read(notificationNotifierProvider.notifier).loadNotifications(),
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'event':
        return Icons.event_rounded;
      case 'payment':
        return Icons.payment_rounded;
      case 'membership':
        return Icons.card_membership_rounded;
      case 'package':
        return Icons.inventory_rounded;
      case 'insurance':
        return Icons.security_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'event':
        return Colors.blue;
      case 'payment':
        return Colors.green;
      case 'membership':
        return AppTheme.goldAccent;
      case 'package':
        return Colors.purple;
      case 'insurance':
        return Colors.orange;
      default:
        return AppTheme.mediumGrey;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return DateFormat('MMM dd, yyyy').format(timestamp);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
}
