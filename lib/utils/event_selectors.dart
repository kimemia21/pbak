import 'package:pbak/models/event_model.dart';

/// Shared helpers for selecting/sorting events consistently across the app.
class EventSelectors {
  /// Returns upcoming events sorted by soonest first.
  ///
  /// [limit] if provided, returns at most that many events.
  static List<EventModel> upcomingSorted(
    List<EventModel> events, {
    int? limit,
  }) {
    final upcoming = events.where((e) => e.isUpcoming).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    if (limit != null && limit >= 0 && upcoming.length > limit) {
      return upcoming.take(limit).toList();
    }
    return upcoming;
  }

  /// Returns past events sorted by most recent first.
  static List<EventModel> pastSorted(List<EventModel> events) {
    final past = events.where((e) => e.isPast).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return past;
  }
}
