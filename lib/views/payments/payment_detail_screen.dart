import 'package:flutter/material.dart';
import 'package:pbak/theme/app_theme.dart';

class PaymentDetailScreen extends StatelessWidget {
  final String paymentId;

  const PaymentDetailScreen({super.key, required this.paymentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Details'),
      ),
      body: Center(
        child: Text('Payment ID: $paymentId'),
      ),
    );
  }
}
