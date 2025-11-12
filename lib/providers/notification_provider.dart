import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pbak/models/notification_model.dart';
import 'package:pbak/services/mock_api/mock_api_service.dart';
import 'package:pbak/providers/auth_provider.dart';

final notificationsProvider = FutureProvider<List<NotificationModel>>((ref) async {
  final authState = ref.watch(authProvider);
  return authState.when(
    data: (user) async {
      if (user != null) {
        final apiService = MockApiService();
        return await apiService.getMyNotifications(user.id);
      }
      return [];
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

final notificationNotifierProvider = StateNotifierProvider<NotificationNotifier, AsyncValue<List<NotificationModel>>>((ref) {
  return NotificationNotifier(ref);
});

class NotificationNotifier extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  final Ref _ref;
  final _apiService = MockApiService();

  NotificationNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    state = const AsyncValue.loading();
    try {
      final authState = _ref.read(authProvider);
      authState.when(
        data: (user) async {
          if (user != null) {
            final notifications = await _apiService.getMyNotifications(user.id);
            state = AsyncValue.data(notifications);
          } else {
            state = const AsyncValue.data([]);
          }
        },
        loading: () => state = const AsyncValue.loading(),
        error: (e, stack) => state = AsyncValue.error(e, stack),
      );
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _apiService.markNotificationAsRead(notificationId);
      state.whenData((notifications) {
        final updatedNotifications = notifications.map((notif) {
          if (notif.id == notificationId) {
            return notif.copyWith(isRead: true);
          }
          return notif;
        }).toList();
        state = AsyncValue.data(updatedNotifications);
      });
    } catch (e) {
      // Handle error
    }
  }

  int get unreadCount {
    return state.when(
      data: (notifications) => notifications.where((n) => !n.isRead).length,
      loading: () => 0,
      error: (_, __) => 0,
    );
  }
}
