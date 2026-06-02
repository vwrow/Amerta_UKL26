import 'layanan_model.dart';

class PelangganUserModel {
  final int id;
  final String username;
  final String password;
  final String role;
  final String ownerToken;
  final String createdAt;
  final String updatedAt;

  PelangganUserModel({
    required this.id,
    required this.username,
    required this.password,
    required this.role,
    required this.ownerToken,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PelangganUserModel.fromJson(Map<String, dynamic> json) {
    return PelangganUserModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      username: json['username']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      ownerToken: json['owner_token']?.toString() ?? json['ownerToken']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
    );
  }
}

class PelangganModel {
  final int id;
  final int userId;
  final String customerNumber;
  final String name;
  final String phone;
  final String address;
  final int serviceId;
  final String ownerToken;
  final String createdAt;
  final String updatedAt;
  final PelangganUserModel? user;
  final LayananModel? service;

  PelangganModel({
    required this.id,
    required this.userId,
    required this.customerNumber,
    required this.name,
    required this.phone,
    required this.address,
    required this.serviceId,
    required this.ownerToken,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.service,
  });

  factory PelangganModel.fromJson(Map<String, dynamic> json) {
    return PelangganModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id']?.toString() ?? '') ?? 0,
      customerNumber: json['customer_number']?.toString() ?? json['customerNumber']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      serviceId: json['service_id'] is int ? json['service_id'] : int.tryParse(json['service_id']?.toString() ?? '') ?? 0,
      ownerToken: json['owner_token']?.toString() ?? json['ownerToken']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
      user: json['user'] != null ? PelangganUserModel.fromJson(json['user']) : null,
      service: json['service'] != null ? LayananModel.fromJson(json['service']) : null,
    );
  }
}
