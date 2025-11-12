class PaymentModel {
  final String id;
  final String userId;
  final String transactionId;
  final double amount;
  final String method;
  final String status;
  final DateTime date;
  final String purpose;
  final String? reference;
  final String? receiptUrl;

  PaymentModel({
    required this.id,
    required this.userId,
    required this.transactionId,
    required this.amount,
    required this.method,
    required this.status,
    required this.date,
    required this.purpose,
    this.reference,
    this.receiptUrl,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      transactionId: json['transactionId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      method: json['method'] ?? '',
      status: json['status'] ?? '',
      date: DateTime.parse(json['date']),
      purpose: json['purpose'] ?? '',
      reference: json['reference'],
      receiptUrl: json['receiptUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'transactionId': transactionId,
      'amount': amount,
      'method': method,
      'status': status,
      'date': date.toIso8601String(),
      'purpose': purpose,
      'reference': reference,
      'receiptUrl': receiptUrl,
    };
  }

  bool get isSuccessful => status.toLowerCase() == 'completed';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isFailed => status.toLowerCase() == 'failed';
}
