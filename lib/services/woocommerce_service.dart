import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';

class WooCommerceService {
  static final String _basicAuth =
      'Basic ${base64Encode(utf8.encode('${AppConfig.consumerKey}:${AppConfig.consumerSecret}'))}';

  // Fetch Products
  static Future<List<ProductModel>> getProducts({
    int page = 1,
    int perPage = 20,
    int? categoryId,
    String? search,
  }) async {
    try {
      String endpoint =
          '${AppConfig.baseUrl}/wp-json/wc/v3/products?page=$page&per_page=$perPage&status=publish';

      if (categoryId != null && categoryId > 0) {
        endpoint += '&category=$categoryId';
      }
      if (search != null && search.trim().isNotEmpty) {
        endpoint += '&search=${Uri.encodeComponent(search.trim())}';
      }

      final response = await http.get(
        Uri.parse(endpoint),
        headers: {'Authorization': _basicAuth},
      );

      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((json) => ProductModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Fetch Categories
  static Future<List<CategoryModel>> getCategories() async {
    try {
      final endpoint =
          '${AppConfig.baseUrl}/wp-json/wc/v3/products/categories?per_page=50&hide_empty=false';
      final response = await http.get(
        Uri.parse(endpoint),
        headers: {'Authorization': _basicAuth},
      );

      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data
            .map((json) => CategoryModel.fromJson(json))
            .where((cat) => cat.count > 0)
            .toList();
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Create an Order in WooCommerce
  static Future<Map<String, dynamic>> createOrder({
    required String firstName,
    required String phone,
    required String address,
    required String city,
    required String postcode,
    required List<Map<String, dynamic>> lineItems,
    required String paymentMethod,
    required String paymentMethodTitle,
    String? transactionId,
  }) async {
    final endpoint = '${AppConfig.baseUrl}/wp-json/wc/v3/orders';

    final orderData = {
      "payment_method": paymentMethod,
      "payment_method_title": paymentMethodTitle,
      "set_paid": paymentMethod == "razorpay",
      "transaction_id": transactionId ?? "",
      "billing": {
        "first_name": firstName,
        "phone": phone,
        "address_1": address,
        "city": city.isEmpty ? "Thisayanvilai" : city,
        "state": "TN",
        "postcode": postcode.isEmpty ? "627657" : postcode,
        "country": "IN",
      },
      "shipping": {
        "first_name": firstName,
        "phone": phone,
        "address_1": address,
        "city": city.isEmpty ? "Thisayanvilai" : city,
        "state": "TN",
        "postcode": postcode.isEmpty ? "627657" : postcode,
        "country": "IN",
      },
      "line_items": lineItems,
      "status": paymentMethod == "razorpay" ? "processing" : "pending",
    };

    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Authorization': _basicAuth,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(orderData),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create order: ${response.body}');
    }
  }
}
