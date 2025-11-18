import 'package:pbak/models/event_model.dart';
import 'package:pbak/models/user_model.dart';
import 'package:pbak/services/comms/comms_service.dart';
import 'package:pbak/services/comms/api_endpoints.dart';

/// Event Service
/// Handles all event-related API calls
class EventService {
  static final EventService _instance = EventService._internal();
  factory EventService() => _instance;
  EventService._internal();

  final _comms = CommsService.instance;

  /// Get all events
  Future<List<EventModel>> getAllEvents() async {
    try {
      final response = await _comms.get<List>(ApiEndpoints.allEvents);
      
      if (response.success && response.data != null) {
        return response.data!
            .map((json) => EventModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load events: $e');
    }
  }

  /// Get event by ID
  Future<EventModel?> getEventById(int eventId) async {
    try {
      final response = await _comms.get<Map<String, dynamic>>(
        ApiEndpoints.eventById(eventId),
      );
      
      if (response.success && response.data != null) {
        return EventModel.fromJson(response.data!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to load event: $e');
    }
  }

  /// Create a new event
  Future<EventModel?> createEvent(Map<String, dynamic> eventData) async {
    try {
      final response = await _comms.post<Map<String, dynamic>>(
        ApiEndpoints.createEvent,
        data: eventData,
      );
      
      if (response.success && response.data != null) {
        return EventModel.fromJson(response.data!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to create event: $e');
    }
  }

  /// Update event
  Future<EventModel?> updateEvent({
    required int eventId,
    required Map<String, dynamic> eventData,
  }) async {
    try {
      final response = await _comms.put<Map<String, dynamic>>(
        ApiEndpoints.updateEvent(eventId),
        data: eventData,
      );
      
      if (response.success && response.data != null) {
        return EventModel.fromJson(response.data!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to update event: $e');
    }
  }

  /// Delete event
  Future<bool> deleteEvent(int eventId) async {
    try {
      final response = await _comms.delete(ApiEndpoints.deleteEvent(eventId));
      return response.success;
    } catch (e) {
      return false;
    }
  }

  /// Register for an event
  Future<bool> registerForEvent(int eventId) async {
    try {
      final response = await _comms.post(
        ApiEndpoints.registerForEvent(eventId),
      );
      return response.success;
    } catch (e) {
      return false;
    }
  }

  /// Unregister from an event
  Future<bool> unregisterFromEvent(int eventId) async {
    try {
      final response = await _comms.post(
        ApiEndpoints.unregisterFromEvent(eventId),
      );
      return response.success;
    } catch (e) {
      return false;
    }
  }

  /// Get event attendees
  Future<List<UserModel>> getEventAttendees(int eventId) async {
    try {
      final response = await _comms.get<List>(
        ApiEndpoints.eventAttendees(eventId),
      );
      
      if (response.success && response.data != null) {
        return response.data!
            .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load event attendees: $e');
    }
  }
}
