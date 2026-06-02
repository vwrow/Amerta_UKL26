class LayananModel {
  final int id;
  final String name;
  final int minUsage;
  final int maxUsage;
  final int price;
  final String ownerToken;
  final String createdAt;
  final String updatedAt;

  LayananModel({
    required this.id,
    required this.name,
    required this.minUsage,
    required this.maxUsage,
    required this.price,
    required this.ownerToken,
    required this.createdAt,
    required this.updatedAt,
  });

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  factory LayananModel.fromJson(Map<String, dynamic> json) {
    return LayananModel(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      minUsage: _toInt(json['min_usage'] ?? json['minUsage']),
      maxUsage: _toInt(json['max_usage'] ?? json['maxUsage']),
      price: _toInt(json['price']),
      ownerToken:
          json['owner_token']?.toString() ?? json['ownerToken']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'min_usage': minUsage,
        'max_usage': maxUsage,
        'price': price,
      };
}
