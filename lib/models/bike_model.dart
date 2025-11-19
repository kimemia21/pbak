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
    print('Parsing BikeModel from JSON: $json');
    // Handle nested model object
    String makeName = '';
    String modelName = '';
    
    if (json['model'] != null && json['model'] is Map) {
      final modelObj = json['model'] as Map<String, dynamic>;
      modelName = modelObj['model_name'] ?? modelObj['modelName'] ?? '';
      
      if (modelObj['make'] != null && modelObj['make'] is Map) {
        final makeObj = modelObj['make'] as Map<String, dynamic>;
        makeName = makeObj['make_name'] ?? makeObj['makeName'] ?? '';
      }
    }
    
    return BikeModel(
      id: (json['bike_id'] ?? json['id'] ?? '').toString(),
      userId: (json['member_id'] ?? json['userId'] ?? '').toString(),
      make: makeName.isNotEmpty ? makeName : (json['make'] ?? ''),
      model: modelName.isNotEmpty ? modelName : (json['model'] ?? ''),
      type: json['type'] ?? json['category'] ?? '',
      registrationNumber: json['registration_number'] ?? json['registrationNumber'] ?? '',
      engineNumber: json['engine_number'] ?? json['engineNumber'] ?? '',
      year: json['yom'] ?? json['year'] ?? json['model_year'] ?? 0,
      color: json['color'],
      imageUrl: json['bike_photo_url'] ?? json['imageUrl'],
      linkedPackageId: json['linkedPackageId']?.toString(),
      addedDate: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : (json['addedDate'] != null 
              ? DateTime.parse(json['addedDate']) 
              : DateTime.now()),
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
