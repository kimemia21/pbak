import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pbak/models/event_model.dart';
import 'package:pbak/utils/event_selectors.dart';
import 'package:pbak/services/event_service.dart';
import 'package:pbak/providers/auth_provider.dart';

// Service provider
final eventServiceProvider = Provider((ref) => EventService());

// Events provider - fetches events with member_id when user is logged in
final eventsProvider = FutureProvider<List<EventModel>>((ref) async {
  final eventService = ref.read(eventServiceProvider);
  final authState = ref.watch(authProvider);
  final memberId = authState.valueOrNull?.memberId;
  return await eventService.getAllEvents(memberId: memberId, discounted: false);
});

// Current events provider (used for payments selection in KYC)
// Uses member_id when user is logged in for member-specific data
final currentEventsProvider = FutureProvider<List<EventModel>>((ref) async {
  final eventService = ref.read(eventServiceProvider);
  final authState = ref.watch(authProvider);
  final memberId = authState.valueOrNull?.memberId;
  return await eventService.getCurrentEvents(memberId: memberId);
});

// Current events with discounted pricing
// Uses member_id when user is logged in for member-specific data
final currentDiscountedEventsProvider = FutureProvider<List<EventModel>>((ref) async {
  final eventService = ref.read(eventServiceProvider);
  final authState = ref.watch(authProvider);
  final memberId = authState.valueOrNull?.memberId;
  return await eventService.getAllEvents(memberId: memberId, discounted: true);
});

/// Events provider with member-specific pricing based on ID number.
/// Pass the user's ID number to get events with correct pricing for that member.
final eventsByIdNumberProvider = FutureProvider.family<List<EventModel>, String>((ref, idNumber) async {
  final eventService = ref.read(eventServiceProvider);
  return await eventService.getAllEvents(idNumber: idNumber, discounted: false);
});

/// Upcoming events derived from [eventsProvider], sorted by soonest first.
///
/// This ensures Home/Events/KYC all use the same selection logic.
final upcomingEventsProvider = FutureProvider<List<EventModel>>((ref) async {
  final events = await ref.watch(eventsProvider.future);
  // Keep selector logic in one place.
  return EventSelectors.upcomingSorted(events);
});

/// Events provider with 50% discount pricing for PBAK member referral registration.
/// Use this when user clicks "Register with 50% off" button.
/// Uses member_id when user is logged in for member-specific data.
final discountedEventsProvider = FutureProvider<List<EventModel>>((ref) async {
  final eventService = ref.read(eventServiceProvider);
  final authState = ref.watch(authProvider);
  final memberId = authState.valueOrNull?.memberId;
  return await eventService.getAllEvents(memberId: memberId, discounted: true);
});

/// Discounted events provider with member-specific pricing based on ID number.
/// Pass the user's ID number to get discounted events with correct pricing.
final discountedEventsByIdNumberProvider = FutureProvider.family<List<EventModel>, String>((ref, idNumber) async {
  final eventService = ref.read(eventServiceProvider);
  // When discounted is true, the API returns member pricing (50% off)
  return await eventService.getAllEvents(idNumber: idNumber, discounted: true);
});

// Event attendees provider
final eventAttendeesProvider = FutureProvider.family((ref, int eventId) async {
  final eventService = ref.read(eventServiceProvider);
  return await eventService.getEventAttendees(eventId);
});

// Event notifier
final eventNotifierProvider = StateNotifierProvider<EventNotifier, AsyncValue<List<EventModel>>>((ref) {
  final authState = ref.watch(authProvider);
  final memberId = authState.valueOrNull?.memberId;
  return EventNotifier(ref.read(eventServiceProvider), memberId: memberId);
});

class EventNotifier extends StateNotifier<AsyncValue<List<EventModel>>> {
  final EventService _eventService;
  final int? _memberId;
  final bool _discounted;

  EventNotifier(this._eventService, {int? memberId, bool discounted = false}) 
      : _memberId = memberId,
        _discounted = discounted,
        super(const AsyncValue.loading()) {
    loadEvents(discounted: discounted);
  }

  Future<void> loadEvents({bool? discounted}) async {
    state = const AsyncValue.loading();
    try {
      final useDiscount = discounted ?? _discounted;
      final events = await _eventService.getAllEvents(memberId: _memberId, discounted: useDiscount);
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
        await loadEvents(discounted: _discounted);
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
        await loadEvents(discounted: _discounted);
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
        await loadEvents(discounted: _discounted);
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
        await loadEvents(discounted: _discounted);
      }
      return success;
    } catch (e) {
      return false;
    }
  }
}
