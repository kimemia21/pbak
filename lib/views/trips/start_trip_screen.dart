import 'package:flutter/material.dart';
import 'package:pbak/theme/app_theme.dart';

class StartTripScreen extends StatelessWidget {
  const StartTripScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Start Trip'),
      ),
      body: const Center(
        child: Text('Start Trip Form'),
      ),
    );
  }
}
