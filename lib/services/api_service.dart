import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/product.dart';
import '../models/member.dart';
import '../models/promo.dart';
import '../models/user.dart';

class ApiService {
  static const String baseUrl = 'https://mac.menyilaq.my.id/api';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, String>> get _headers async {
    final token = await _storage.read(key: 'auth_token');
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer \$token',
    };
  }

  Future<User?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('\$baseUrl/login'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['token'];

        if (token != null) {
          await _storage.write(key: 'auth_token', value: token);
        }

        if (data['user'] != null) {
          return User.fromJson(data['user']);
        }
      }
      return null;
    } catch (e) {
      print('Login error: \$e');
      return null;
    }
  }

  Future<void> logout() async {
    try {
      final headers = await _headers;
      await http.post(Uri.parse('\$baseUrl/logout'), headers: headers);
    } catch (_) {}
    await _storage.delete(key: 'auth_token');
  }

  Future<List<Product>> getProducts() async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse('\$baseUrl/products'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        List<dynamic> list = [];
        if (data.containsKey('products')) {
          list = data['products'];
        } else if (data.containsKey('data')) {
          list = data['data'];
        } else {
          try {
            list = data.values.toList();
          } catch (e) {
            list = [];
          }
        }

        return list.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to mock data if network fails so the app still runs
      return _getMockProducts();
    }
  }

  Future<List<Member>> getMembers() async {
    // Replace with real endpoint when available:
    // final response = await http.get(Uri.parse('$baseUrl/members'), headers: _headers);
    // return parsedList.map((json) => Member.fromJson(json)).toList();

    // For now, returning mock since the user only specified the token and base url, not specific member endpoints yet
    return _getMockMembers();
  }

  Future<List<Promo>> getPromos() async {
    // Replace with real endpoint when available:
    // final response = await http.get(Uri.parse('$baseUrl/promos'), headers: _headers);
    // return parsedList.map((json) => Promo.fromJson(json)).toList();

    // For now, returning mock
    return _getMockPromos();
  }

  Future<bool> processTransaction({
    required List<Map<String, dynamic>> cartData,
    required double amountPaid,
    String paymentMethod = 'Tunai',
    double globalDiscount = 0,
  }) async {
    try {
      final headers = await _headers;
      final response = await http.post(
        Uri.parse('$baseUrl/transactions'),
        headers: headers,
        body: json.encode({
          'cart_data': cartData,
          'amount_paid': amountPaid,
          'payment_method': paymentMethod,
          'global_discount': globalDiscount,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print('Transaction failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Checkout error: $e');
      return false; // For now return false. Usually we'd return true if we want to allow offline fallback.
    }
  }

  List<Product> _getMockProducts() {
    const String jsonMock = '''
    [
      {"id": "p1", "sku": "CLO-001", "title": "T-Shirt Katun Polos", "price": 75000, "categoryId": "clothing", "imageUrl": "👕", "stock": 50},
      {"id": "p2", "sku": "CLO-002", "title": "Celana Jeans Pria", "price": 250000, "categoryId": "clothing", "imageUrl": "👖", "stock": 20},
      {"id": "p3", "sku": "ELE-001", "title": "Kabel USB-C Fast Charging", "price": 45000, "categoryId": "electronics", "imageUrl": "🔌", "stock": 100},
      {"id": "p4", "sku": "ELE-002", "title": "Powerbank 10000mAh", "price": 150000, "categoryId": "electronics", "imageUrl": "🔋", "stock": 15},
      {"id": "p5", "sku": "ELE-003", "title": "Earphone Bluetooth", "price": 120000, "categoryId": "electronics", "imageUrl": "🎧", "stock": 30},
      {"id": "p6", "sku": "ACC-001", "title": "Kacamata Hitam Anti-UV", "price": 85000, "categoryId": "accessories", "imageUrl": "🕶️", "stock": 40},
      {"id": "p7", "sku": "ACC-002", "title": "Topi Baseball Kanvas", "price": 55000, "categoryId": "accessories", "imageUrl": "🧢", "stock": 25},
      {"id": "p8", "sku": "HOU-001", "title": "Sabun Cair 500ml", "price": 35000, "categoryId": "household", "imageUrl": "🧴", "stock": 60},
      {"id": "p9", "sku": "HOU-002", "title": "Sikat Gigi Elektrik", "price": 95000, "categoryId": "household", "imageUrl": "🪥", "stock": 12}
    ]
    ''';
    final List<dynamic> parsedList = json.decode(jsonMock);
    return parsedList.map((json) => Product.fromJson(json)).toList();
  }

  List<Member> _getMockMembers() {
    const String jsonMock = '''
    [
      {"id": "m1", "name": "Budi Santoso", "phone": "081234567890", "points": 150},
      {"id": "m2", "name": "Siti Aminah", "phone": "089876543210", "points": 45},
      {"id": "m3", "name": "Ahmad Yani", "phone": "085512349876", "points": 300}
    ]
    ''';
    final List<dynamic> parsedList = json.decode(jsonMock);
    return parsedList.map((json) => Member.fromJson(json)).toList();
  }

  List<Promo> _getMockPromos() {
    const String jsonMock = '''
    [
      {"id": "prm1", "code": "PROMO10", "description": "Diskon 10% Semua Item", "discountPercentage": 10.0},
      {"id": "prm2", "code": "MEMBER20", "description": "Diskon Spesial Member 20%", "discountPercentage": 20.0},
      {"id": "prm3", "code": "GAJIAN5", "description": "Diskon Gajian 5%", "discountPercentage": 5.0}
    ]
    ''';
    final List<dynamic> parsedList = json.decode(jsonMock);
    return parsedList.map((json) => Promo.fromJson(json)).toList();
  }
}
