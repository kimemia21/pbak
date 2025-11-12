import 'package:flutter/material.dart';
import 'package:pbak/theme/app_theme.dart';

class ServiceDetailScreen extends StatelessWidget {
  final String serviceId;

  const ServiceDetailScreen({super.key, required this.serviceId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Details'),
      ),
      body: Center(
        child: Text('Service ID: $serviceId'),
      ),
    );
  }
}
