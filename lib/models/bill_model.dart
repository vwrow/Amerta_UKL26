import 'layanan_model.dart';
import 'pelanggan_model.dart';

class BillPaymentModel {
  final int id;
  final int billId;
  final String paymentDate;
  final bool verified;
  final int totalAmount;
  final String paymentProof;
  final String ownerToken;
  final String createdAt;
  final String updatedAt;

  BillPaymentModel({
    required this.id,
    required this.billId,
    required this.paymentDate,
    required this.verified,
    required this.totalAmount,
    required this.paymentProof,
    required this.ownerToken,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BillPaymentModel.fromJson(Map<String, dynamic> json) {
    return BillPaymentModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      billId: json['bill_id'] is int ? json['bill_id'] : int.tryParse(json['bill_id']?.toString() ?? '') ?? 0,
      paymentDate: json['payment_date']?.toString() ?? json['paymentDate']?.toString() ?? '',
      verified: json['verified'] == true || json['verified'] == 1 || json['verified'] == 'true',
      totalAmount: json['total_amount'] is int ? json['total_amount'] : int.tryParse(json['total_amount']?.toString() ?? '') ?? 0,
      paymentProof: json['payment_proof']?.toString() ?? json['paymentProof']?.toString() ?? '',
      ownerToken: json['owner_token']?.toString() ?? json['ownerToken']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
    );
  }
}

class BillAdminModel {
  final int id;
  final int userId;
  final String name;
  final String phone;
  final String ownerToken;
  final String createdAt;
  final String updatedAt;

  BillAdminModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.ownerToken,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BillAdminModel.fromJson(Map<String, dynamic> json) {
    return BillAdminModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      ownerToken: json['owner_token']?.toString() ?? json['ownerToken']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
    );
  }
}

class BillModel {
  final int id;
  final int customerId;
  final int adminId;
  final int month;
  final int year;
  final String measurementNumber;
  final int usageValue;
  final int price;
  final int serviceId;
  final bool paid;
  final String ownerToken;
  final String createdAt;
  final String updatedAt;
  final LayananModel? service;
  final BillAdminModel? admin;
  final PelangganModel? customer;
  final BillPaymentModel? payment;
  final int amount;
  final bool verifiedPayment;

  BillModel({
    required this.id,
    required this.customerId,
    required this.adminId,
    required this.month,
    required this.year,
    required this.measurementNumber,
    required this.usageValue,
    required this.price,
    required this.serviceId,
    required this.paid,
    required this.ownerToken,
    required this.createdAt,
    required this.updatedAt,
    this.service,
    this.admin,
    this.customer,
    this.payment,
    required this.amount,
    required this.verifiedPayment,
  });

  static int _toInt(dynamic val) {
    if (val is int) return val;
    if (val is double) return val.toInt();
    if (val is String) return int.tryParse(val) ?? 0;
    return 0;
  }

  factory BillModel.fromJson(Map<String, dynamic> json) {
    return BillModel(
      id: _toInt(json['id']),
      customerId: _toInt(json['customer_id'] ?? json['customerId']),
      adminId: _toInt(json['admin_id'] ?? json['adminId']),
      month: _toInt(json['month']),
      year: _toInt(json['year']),
      measurementNumber: json['measurement_number']?.toString() ?? json['measurementNumber']?.toString() ?? '',
      usageValue: _toInt(json['usage_value'] ?? json['usageValue']),
      price: _toInt(json['price']),
      serviceId: _toInt(json['service_id'] ?? json['serviceId']),
      paid: json['paid'] == true || json['paid'] == 1 || json['paid'] == 'true',
      ownerToken: json['owner_token']?.toString() ?? json['ownerToken']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
      service: json['service'] != null ? LayananModel.fromJson(json['service']) : null,
      admin: json['admin'] != null ? BillAdminModel.fromJson(json['admin']) : null,
      customer: json['customer'] != null ? PelangganModel.fromJson(json['customer']) : null,
      payment: _parsePayment(json['payments'] ?? json['payment']),
      amount: _toInt(json['amount'] ?? json['price']),
      verifiedPayment: json['verified_payment'] == true || json['verified_payment'] == 1 || json['verified_payment'] == 'true' || (json['payments'] != null && (json['payments']['verified'] == true || json['payments']['verified'] == 1)),
    );
  }

  static BillPaymentModel? _parsePayment(dynamic jsonVal) {
    if (jsonVal == null) return null;
    if (jsonVal is Map<String, dynamic>) {
      return BillPaymentModel.fromJson(jsonVal);
    }
    if (jsonVal is List && jsonVal.isNotEmpty) {
      return BillPaymentModel.fromJson(jsonVal.first);
    }
    return null;
  }
}
