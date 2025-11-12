import 'package:flutter/material.dart';
import 'package:pbak/theme/app_theme.dart';

class TripDetailScreen extends StatelessWidget {
  final String tripId;

  const TripDetailScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Details'),
      ),
      body: Center(
        child: Text('Trip ID: $tripId'),
      ),
    );
  }
}
