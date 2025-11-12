import 'package:flutter/material.dart';
import 'package:pbak/theme/app_theme.dart';

class CreateEventScreen extends StatelessWidget {
  const CreateEventScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Event'),
      ),
      body: const Center(
        child: Text('Create Event Form'),
      ),
    );
  }
}
