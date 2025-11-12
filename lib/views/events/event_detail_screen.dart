import 'package:flutter/material.dart';
import 'package:pbak/theme/app_theme.dart';

class EventDetailScreen extends StatelessWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
      ),
      body: Center(
        child: Text('Event ID: $eventId'),
      ),
    );
  }
}
