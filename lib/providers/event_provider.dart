import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pbak/models/event_model.dart';
import 'package:pbak/services/mock_api/mock_api_service.dart';

final eventsProvider = FutureProvider<List<EventModel>>((ref) async {
  final apiService = MockApiService();
  return await apiService.getEvents();
});

final eventDetailProvider = FutureProvider.family<EventModel, String>((ref, eventId) async {
  final apiService = MockApiService();
  return await apiService.getEventById(eventId);
});

final eventNotifierProvider = StateNotifierProvider<EventNotifier, AsyncValue<List<EventModel>>>((ref) {
  return EventNotifier();
});

class EventNotifier extends StateNotifier<AsyncValue<List<EventModel>>> {
  final _apiService = MockApiService();

  EventNotifier() : super(const AsyncValue.loading()) {
    loadEvents();
  }

  Future<void> loadEvents() async {
    state = const AsyncValue.loading();
    try {
      final events = await _apiService.getEvents();
      state = AsyncValue.data(events);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> createEvent(Map<String, dynamic> eventData) async {
    try {
      final newEvent = await _apiService.createEvent(eventData);
      state.whenData((events) {
        state = AsyncValue.data([...events, newEvent]);
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> registerForEvent(String eventId, String userId) async {
    try {
      await _apiService.registerForEvent(eventId, userId);
      return true;
    } catch (e) {
      return false;
    }
  }
}
