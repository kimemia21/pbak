import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pbak/models/event_model.dart';
import 'package:pbak/services/event_service.dart';

// Service provider
final eventServiceProvider = Provider((ref) => EventService());

// Events provider
final eventsProvider = FutureProvider<List<EventModel>>((ref) async {
  final eventService = ref.read(eventServiceProvider);
  return await eventService.getAllEvents();
});

// Event detail provider
final eventDetailProvider = FutureProvider.family<EventModel?, int>((ref, eventId) async {
  final eventService = ref.read(eventServiceProvider);
  return await eventService.getEventById(eventId);
});

// Event attendees provider
final eventAttendeesProvider = FutureProvider.family((ref, int eventId) async {
  final eventService = ref.read(eventServiceProvider);
  return await eventService.getEventAttendees(eventId);
});

// Event notifier
final eventNotifierProvider = StateNotifierProvider<EventNotifier, AsyncValue<List<EventModel>>>((ref) {
  return EventNotifier(ref.read(eventServiceProvider));
});

class EventNotifier extends StateNotifier<AsyncValue<List<EventModel>>> {
  final EventService _eventService;

  EventNotifier(this._eventService) : super(const AsyncValue.loading()) {
    loadEvents();
  }

  Future<void> loadEvents() async {
    state = const AsyncValue.loading();
    try {
      final events = await _eventService.getAllEvents();
      state = AsyncValue.data(events);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> createEvent(Map<String, dynamic> eventData) async {
    try {
      final newEvent = await _eventService.createEvent(eventData);
      
      if (newEvent != null) {
        state.whenData((events) {
          state = AsyncValue.data([...events, newEvent]);
        });
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateEvent(int eventId, Map<String, dynamic> eventData) async {
    try {
      final updatedEvent = await _eventService.updateEvent(
        eventId: eventId,
        eventData: eventData,
      );
      
      if (updatedEvent != null) {
        await loadEvents();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteEvent(int eventId) async {
    try {
      final success = await _eventService.deleteEvent(eventId);
      
      if (success) {
        await loadEvents();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> registerForEvent(int eventId) async {
    try {
      final success = await _eventService.registerForEvent(eventId);
      
      if (success) {
        await loadEvents();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<bool> unregisterFromEvent(int eventId) async {
    try {
      final success = await _eventService.unregisterFromEvent(eventId);
      
      if (success) {
        await loadEvents();
      }
      return success;
    } catch (e) {
      return false;
    }
  }
}
