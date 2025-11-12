class ServiceModel {
  final String id;
  final String name;
  final String category;
  final String description;
  final String location;
  final double latitude;
  final double longitude;
  final String contactPhone;
  final String? contactEmail;
  final String type;
  final List<String> services;
  final double? rating;
  final String? imageUrl;
  final String? openingHours;

  ServiceModel({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.contactPhone,
    this.contactEmail,
    required this.type,
    required this.services,
    this.rating,
    this.imageUrl,
    this.openingHours,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      contactPhone: json['contactPhone'] ?? '',
      contactEmail: json['contactEmail'],
      type: json['type'] ?? '',
      services: List<String>.from(json['services'] ?? []),
      rating: json['rating']?.toDouble(),
      imageUrl: json['imageUrl'],
      openingHours: json['openingHours'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'contactPhone': contactPhone,
      'contactEmail': contactEmail,
      'type': type,
      'services': services,
      'rating': rating,
      'imageUrl': imageUrl,
      'openingHours': openingHours,
    };
  }
}
