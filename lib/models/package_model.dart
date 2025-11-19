class PackageModel {
  final String id;
  final String name;
  final double price;
  final int durationDays;
  final String description;
  final List<String> benefits;
  final List<AddOn> addOns;
  final bool autoRenew;
  final String? iconUrl;

  PackageModel({
    required this.id,
    required this.name,
    required this.price,
    required this.durationDays,
    required this.description,
    required this.benefits,
    required this.addOns,
    this.autoRenew = false,
    this.iconUrl,
  });

  factory PackageModel.fromJson(Map<String, dynamic> json) {
    // Parse features JSON if it's a string
    Map<String, dynamic>? features;
    if (json['features'] != null) {
      if (json['features'] is String) {
        try {
          features = json['features'] as Map<String, dynamic>;
        } catch (e) {
          features = {};
        }
      } else if (json['features'] is Map) {
        features = json['features'] as Map<String, dynamic>;
      }
    }
    
    // Extract benefits from features or use default
    List<String> benefits = [];
    if (features != null) {
      features.forEach((key, value) {
        if (value != null && value != false) {
          benefits.add('$key: ${value.toString()}');
        }
      });
    }
    
    return PackageModel(
      id: (json['package_id'] ?? json['id'] ?? '').toString(),
      name: json['package_name'] ?? json['name'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      durationDays: json['duration_days'] ?? json['durationDays'] ?? 0,
      description: json['description'] ?? '',
      benefits: benefits.isEmpty ? ['No benefits listed'] : benefits,
      addOns: (json['addOns'] as List<dynamic>?)
              ?.map((e) => AddOn.fromJson(e))
              .toList() ??
          [],
      autoRenew: (json['auto_renew_default'] ?? json['autoRenew'] ?? 0) == 1,
      iconUrl: json['iconUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'durationDays': durationDays,
      'description': description,
      'benefits': benefits,
      'addOns': addOns.map((e) => e.toJson()).toList(),
      'autoRenew': autoRenew,
      'iconUrl': iconUrl,
    };
  }

  String get durationText {
    if (durationDays < 30) {
      return '$durationDays days';
    } else if (durationDays < 365) {
      final months = (durationDays / 30).round();
      return '$months ${months == 1 ? 'month' : 'months'}';
    } else {
      final years = (durationDays / 365).round();
      return '$years ${years == 1 ? 'year' : 'years'}';
    }
  }
}

class AddOn {
  final String id;
  final String name;
  final double price;
  final String description;

  AddOn({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
  });

  factory AddOn.fromJson(Map<String, dynamic> json) {
    return AddOn(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'description': description,
    };
  }
}
