class InsuranceModel {
  final String id;
  final String userId;
  final String bikeId;
  final String type;
  final String provider;
  final double price;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final String policyNumber;
  final String? documentUrl;

  InsuranceModel({
    required this.id,
    required this.userId,
    required this.bikeId,
    required this.type,
    required this.provider,
    required this.price,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.policyNumber,
    this.documentUrl,
  });

  factory InsuranceModel.fromJson(Map<String, dynamic> json) {
    return InsuranceModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      bikeId: json['bikeId'] ?? '',
      type: json['type'] ?? '',
      provider: json['provider'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      status: json['status'] ?? '',
      policyNumber: json['policyNumber'] ?? '',
      documentUrl: json['documentUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'bikeId': bikeId,
      'type': type,
      'provider': provider,
      'price': price,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status,
      'policyNumber': policyNumber,
      'documentUrl': documentUrl,
    };
  }

  bool get isActive => status.toLowerCase() == 'active';
  bool get isExpiringSoon {
    final daysUntilExpiry = endDate.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 30 && daysUntilExpiry > 0;
  }

  int get daysRemaining => endDate.difference(DateTime.now()).inDays;
}
