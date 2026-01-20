import 'package:pbak/models/notification_model.dart';
import 'package:pbak/services/comms/api_endpoints.dart';
import 'package:pbak/services/comms/comms_service.dart';

/// Notifications API wrapper (real backend).
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _comms = CommsService.instance;

  Future<List<NotificationModel>> getMyNotifications() async {
    final response = await _comms.get(ApiEndpoints.myNotificationsV2);
    if (!response.success || response.data == null) return [];

    dynamic data = response.data;
    if (data is Map && data['data'] != null) data = data['data'];

    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  Future<bool> markAsRead(String notificationId) async {
    final response = await _comms.post(ApiEndpoints.markNotificationAsRead(notificationId));
    return response.success;
  }

  Future<bool> markAllAsRead() async {
    final response = await _comms.post(ApiEndpoints.markAllNotificationsAsRead);
    return response.success;
  }

  Future<bool> deleteNotification(String notificationId) async {
    final response = await _comms.delete(ApiEndpoints.deleteNotificationById(notificationId));
    return response.success;
  }
}
