import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class OrderRecord {
  final int id;
  final String date;
  final double total;
  final String status;
  final String customerName;
  final String phone;
  final String address;
  final String city;
  final String pincode;
  final String paymentId;
  final List<Map<String, dynamic>> items;

  OrderRecord({
    required this.id,
    required this.date,
    required this.total,
    required this.status,
    required this.customerName,
    required this.phone,
    required this.address,
    required this.city,
    required this.pincode,
    required this.paymentId,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'total': total,
        'status': status,
        'customerName': customerName,
        'phone': phone,
        'address': address,
        'city': city,
        'pincode': pincode,
        'paymentId': paymentId,
        'items': items,
      };

  factory OrderRecord.fromJson(Map<String, dynamic> json) => OrderRecord(
        id: json['id'] ?? 0,
        date: json['date'] ?? '',
        total: (json['total'] ?? 0).toDouble(),
        status: json['status'] ?? 'Processing',
        customerName: json['customerName'] ?? '',
        phone: json['phone'] ?? '',
        address: json['address'] ?? '',
        city: json['city'] ?? '',
        pincode: json['pincode'] ?? '',
        paymentId: json['paymentId'] ?? '',
        items: List<Map<String, dynamic>>.from(json['items'] ?? []),
      );
}

class OrderStorageService {
  static const String _key = 'user_order_history';

  static Future<void> saveOrder(OrderRecord order) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList(_key) ?? [];
    list.insert(0, jsonEncode(order.toJson()));
    await prefs.setStringList(_key, list);
  }

  static Future<List<OrderRecord>> getOrders() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList(_key) ?? [];
    return list.map((str) => OrderRecord.fromJson(jsonDecode(str))).toList();
  }
}
