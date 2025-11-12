class BikeModel {
  final String id;
  final String userId;
  final String make;
  final String model;
  final String type;
  final String registrationNumber;
  final String engineNumber;
  final int year;
  final String? color;
  final String? imageUrl;
  final String? linkedPackageId;
  final DateTime addedDate;

  BikeModel({
    required this.id,
    required this.userId,
    required this.make,
    required this.model,
    required this.type,
    required this.registrationNumber,
    required this.engineNumber,
    required this.year,
    this.color,
    this.imageUrl,
    this.linkedPackageId,
    required this.addedDate,
  });

  factory BikeModel.fromJson(Map<String, dynamic> json) {
    return BikeModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      make: json['make'] ?? '',
      model: json['model'] ?? '',
      type: json['type'] ?? '',
      registrationNumber: json['registrationNumber'] ?? '',
      engineNumber: json['engineNumber'] ?? '',
      year: json['year'] ?? 0,
      color: json['color'],
      imageUrl: json['imageUrl'],
      linkedPackageId: json['linkedPackageId'],
      addedDate: DateTime.parse(json['addedDate']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'make': make,
      'model': model,
      'type': type,
      'registrationNumber': registrationNumber,
      'engineNumber': engineNumber,
      'year': year,
      'color': color,
      'imageUrl': imageUrl,
      'linkedPackageId': linkedPackageId,
      'addedDate': addedDate.toIso8601String(),
    };
  }
}
