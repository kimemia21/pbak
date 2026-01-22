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
  /// If [memberId] is provided, fetches events with member-specific data (e.g., purchase info)
  /// If [idNumber] is provided, fetches events with member-specific pricing based on ID number
  /// If [discounted] is true (1), fetches events with 50% discount pricing; if false (0), standard pricing
  Future<List<EventModel>> getAllEvents({int? memberId, String? idNumber, required bool discounted}) async {
    try {
      String endpoint;
      if (idNumber != null && idNumber.trim().isNotEmpty) {
        // Pass discounted flag to get 50% off pricing when user clicked "Register with 50% off"
        endpoint = ApiEndpoints.eventsByIdNumber(idNumber.trim(), discounted: discounted);
      } else if (discounted && memberId != null) {
        // Discounted pricing takes priority when explicitly requested
        endpoint = ApiEndpoints.eventsWithDiscount(memberId);
      } else if (memberId != null) {
        endpoint = ApiEndpoints.eventsByMemberId(memberId);
      } else if (discounted) {
        // Discounted without member ID - use query param on base endpoint
        endpoint = '${ApiEndpoints.allEvents}?discounted=1';
      } else {
        endpoint = ApiEndpoints.allEvents;
      }
      final response = await _comms.get(endpoint);
      print('events endpoint : ${endpoint}');

      if (response.success && response.data != null) {
        dynamic data = response.data;

        // Access nested data object if it exists
        if (data is Map && data['data'] != null) {
          data = data['data'];
        }

        // If data is a list, map it to EventModel
        if (data is List) {
          return data
              .map(
                (json) => EventModel.fromJson(json as Map<String, dynamic>),
              )
              .toList();
        }
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load events: $e');
    }
  }

  /// Get current events (e.g. /events?current=1)
  /// If [memberId] is provided, fetches events with member-specific data
  /// If the API returns an empty list, it means no current events.
  Future<List<EventModel>> getCurrentEvents({int? memberId}) async {
    try {
      final response = await _comms.get(ApiEndpoints.currentEvents(current: 1, memberId: memberId));

      if (response.success && response.data != null) {
        dynamic data = response.data;

        if (data is Map && data['data'] != null) {
          data = data['data'];
        }

        if (data is List) {
          return data
              .map(
                (json) => EventModel.fromJson(json as Map<String, dynamic>),
              )
              .toList();
        }
      }

      return [];
    } catch (e) {
      throw Exception('Failed to load current events: $e');
    }
  }

  /// Get event by ID
  Future<EventModel?> getEventById(int eventId) async {
    try {
      final response = await _comms.get(
        ApiEndpoints.eventById(eventId),
      );

      if (response.success && response.data != null) {
        dynamic data = response.data;

        // Access nested data object if it exists
        if (data is Map && data['data'] != null) {
          data = data['data'];
        }

        return EventModel.fromJson(data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to load event: $e');
    }
  }

  /// Create a new event
  Future<EventModel?> createEvent(Map<String, dynamic> eventData) async {
    try {
      final response = await _comms.post(
        ApiEndpoints.createEvent,
        data: eventData,
      );

      if (response.success && response.data != null) {
        dynamic data = response.data;

        // Access nested data object if it exists
        if (data is Map && data['data'] != null) {
          data = data['data'];
        }

        return EventModel.fromJson(data as Map<String, dynamic>);
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
      final response = await _comms.put(
        ApiEndpoints.updateEvent(eventId),
        data: eventData,
      );

      if (response.success && response.data != null) {
        dynamic data = response.data;

        // Access nested data object if it exists
        if (data is Map && data['data'] != null) {
          data = data['data'];
        }

        return EventModel.fromJson(data as Map<String, dynamic>);
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
      final response = await _comms.get(
        ApiEndpoints.eventAttendees(eventId),
      );

      if (response.success && response.data != null) {
        dynamic data = response.data;

        // Access nested data object if it exists
        if (data is Map && data['data'] != null) {
          data = data['data'];
        }

        // If data is a list, map it to UserModel
        if (data is List) {
          return data
              .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load event attendees: $e');
    }
  }
}
