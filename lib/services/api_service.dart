import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/product.dart';
import '../models/member.dart';
import '../models/promo.dart';
import '../models/user.dart';
import 'db_helper.dart';

class ApiService {
  static const String baseUrl = 'http://mac.menyilaq.my.id/api';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, String>> get _headers async {
    final token = await _storage.read(key: 'auth_token');
    print(
      'ApiService _headers token check: ${token != null ? "Found" : "NULL"}',
    );
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<User?> login(String email, String password) async {
    try {
      print('=== MENCOBA LOGIN ===');
      print('URL: $baseUrl/login');
      print('Email: $email');

      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({'email': email, 'password': password}),
      );

      print('=== RESPONSE DARI SERVER ===');
      print('Status Code: ${response.statusCode}');
      print('Body: ${response.body}');
      print('============================');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['token'];

        if (token != null) {
          await _storage.write(key: 'auth_token', value: token);
          print('Token berhasil disimpan!');
        }

        if (data['user'] != null) {
          return User.fromJson(data['user']);
        }
      }
      return null;
    } catch (e) {
      print('=== LOGIN ERROR ===');
      print(e);
      return null;
    }
  }

  Future<void> logout() async {
    try {
      final headers = await _headers;
      await http.post(Uri.parse('$baseUrl/logout'), headers: headers);
    } catch (_) {}
    await _storage.delete(key: 'auth_token');
  }

  Future<List<Product>> getProducts() async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse('$baseUrl/products'),
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

        await DatabaseHelper().saveCache('products', list);

        return list.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      // Offline fallback
      final cachedList =
          await DatabaseHelper().getCache('products') as List<dynamic>?;
      if (cachedList != null) {
        return cachedList.map((json) => Product.fromJson(json)).toList();
      }
      return _getMockProducts();
    }
  }

  Future<List<Member>> getMembers() async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse('$baseUrl/members'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = data['members'] ?? data['data'] ?? [];
        await DatabaseHelper().saveCache('members', list);
        return (list as List).map((json) => Member.fromJson(json)).toList();
      }
      throw Exception();
    } catch (e) {
      final cachedList =
          await DatabaseHelper().getCache('members') as List<dynamic>?;
      if (cachedList != null) {
        return cachedList.map((json) => Member.fromJson(json)).toList();
      }
      return _getMockMembers();
    }
  }

  Future<List<Promo>> getPromos() async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse('$baseUrl/promos'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = data['promos'] ?? data['data'] ?? [];
        await DatabaseHelper().saveCache('promos', list);
        return (list as List).map((json) => Promo.fromJson(json)).toList();
      }
      throw Exception();
    } catch (e) {
      final cachedList =
          await DatabaseHelper().getCache('promos') as List<dynamic>?;
      if (cachedList != null) {
        return cachedList.map((json) => Promo.fromJson(json)).toList();
      }
      return _getMockPromos();
    }
  }

  Future<String> processTransaction({
    required List<Map<String, dynamic>> cartData,
    required double amountPaid,
    String paymentMethod = 'Tunai',
    double globalDiscount = 0,
  }) async {
    final payload = {
      'cart_data': cartData,
      'amount_paid': amountPaid,
      'payment_method': paymentMethod,
      'global_discount': globalDiscount,
    };

    try {
      final headers = await _headers;
      final response = await http.post(
        Uri.parse('$baseUrl/transactions'),
        headers: headers,
        body: json.encode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return 'online';
      } else if (response.statusCode >= 400 && response.statusCode < 500) {
        print('Transaction Validation/Auth Error: ${response.body}');
        return 'error: ${response.body}';
      } else {
        print(
          'Transaction Server Error: ${response.statusCode} - ${response.body}',
        );
        await DatabaseHelper().savePendingTransaction(payload);
        return 'offline_500: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      print('Network off, queuing transaction offline: $e');
      await DatabaseHelper().savePendingTransaction(payload);
      return 'offline_catch: $e';
    }
  }

  Future<List<Map<String, dynamic>>> getTransactions() async {
    try {
      final headers = await _headers;
      final response = await http
          .get(
            Uri.parse('$baseUrl/transactions'),
            headers: headers,
            // timeout after 5 seconds to fallback quickly
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data['data'] is List) {
          // Sometimes Laravel pagination uses ['data']
          return List<Map<String, dynamic>>.from(data['data']);
        }
      } else {
        return [
          {'error': 'status_${response.statusCode}'},
        ];
      }
    } catch (e) {
      print('Failed to get online transactions: $e');
      return [
        {'error': 'catch_$e'},
      ];
    }
    return [];
  }

  Future<void> syncPendingTransactions() async {
    final db = DatabaseHelper();
    final pending = await db.getPendingTransactions();

    if (pending.isEmpty) return;

    final headers = await _headers;

    for (var tx in pending) {
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/transactions'),
          headers: headers,
          body: json.encode({
            'cart_data': tx['cart_data'],
            'amount_paid': tx['amount_paid'],
            'payment_method': tx['payment_method'],
            'global_discount': tx['global_discount'],
          }),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          await db.deletePendingTransaction(tx['id']);
        }
      } catch (e) {
        // Stop retrying this batch if internet is still down
        break;
      }
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
