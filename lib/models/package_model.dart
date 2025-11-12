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
    return PackageModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      durationDays: json['durationDays'] ?? 0,
      description: json['description'] ?? '',
      benefits: List<String>.from(json['benefits'] ?? []),
      addOns: (json['addOns'] as List<dynamic>?)
              ?.map((e) => AddOn.fromJson(e))
              .toList() ??
          [],
      autoRenew: json['autoRenew'] ?? false,
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
