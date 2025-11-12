import 'package:flutter/material.dart';
import 'package:pbak/theme/app_theme.dart';

class InsuranceDetailScreen extends StatelessWidget {
  final String insuranceId;

  const InsuranceDetailScreen({super.key, required this.insuranceId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insurance Details'),
      ),
      body: Center(
        child: Text('Insurance ID: $insuranceId'),
      ),
    );
  }
}
