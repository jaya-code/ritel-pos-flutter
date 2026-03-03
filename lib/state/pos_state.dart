import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/member.dart';
import '../models/promo.dart';
import '../services/api_service.dart';

class PosState extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<Member> members = [];
  List<Promo> promos = [];
  List<Product> _allProducts = [];

  PosState() {
    _initData();
  }

  Future<void> _initData() async {
    _isLoading = true;
    notifyListeners();

    // Try to sync any queued offline transactions first
    await _apiService.syncPendingTransactions();

    try {
      final results = await Future.wait([
        _apiService.getProducts(),
        _apiService.getMembers(),
        _apiService.getPromos(),
      ]);

      _allProducts = results[0] as List<Product>;
      members = results[1] as List<Member>;
      promos = results[2] as List<Promo>;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading API data: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  Member? _selectedMember;
  Member? get selectedMember => _selectedMember;

  Promo? _selectedPromo;
  Promo? get selectedPromo => _selectedPromo;

  final List<String> paymentMethods = [
    'Tunai',
    'Qris Statis',
    'Qris Dinamis',
    'Debit',
  ];

  List<Product> get filteredProducts {
    if (_searchQuery.isEmpty) {
      return [];
    }

    return _allProducts.where((p) {
      return p.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.sku.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  final List<CartItem> _cart = [];
  List<CartItem> get cart => _cart;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void selectMember(Member? member) {
    _selectedMember = member;
    notifyListeners();
  }

  void selectPromo(Promo? promo) {
    _selectedPromo = promo;
    notifyListeners();
  }

  void addBySku(String sku) {
    try {
      final product = _allProducts.firstWhere(
        (p) => p.sku.toLowerCase() == sku.toLowerCase(),
      );
      addToCart(product);
    } catch (_) {
      // Product not found, ignore
    }
  }

  void addToCart(Product product) {
    final existingIndex = _cart.indexWhere(
      (item) => item.product.id == product.id,
    );
    if (existingIndex >= 0) {
      _cart[existingIndex].quantity++;
    } else {
      _cart.add(CartItem(product: product));
    }
    notifyListeners();
  }

  void updateQuantity(Product product, int delta) {
    final existingIndex = _cart.indexWhere(
      (item) => item.product.id == product.id,
    );
    if (existingIndex >= 0) {
      _cart[existingIndex].quantity += delta;
      if (_cart[existingIndex].quantity <= 0) {
        _cart.removeAt(existingIndex);
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _cart.clear();
    _selectedMember = null;
    _selectedPromo = null;
    notifyListeners();
  }

  double get subtotal => _cart.fold(0, (sum, item) => sum + item.totalPrice);

  double get discountAmount {
    if (_selectedPromo != null) {
      return subtotal * (_selectedPromo!.discountPercentage / 100);
    }
    return 0.0;
  }

  double get discountedSubtotal => subtotal - discountAmount;

  double get tax => discountedSubtotal * 0.11; // 11% tax applies after discount

  double get total => discountedSubtotal + tax;

  Future<String> checkout(double amountPaid, String paymentMethod) async {
    if (_cart.isEmpty) return 'error';

    _isLoading = true;
    notifyListeners();

    final cartData = _cart.map((item) {
      // API requires id to be int. Strip non-numeric chars if it was mock data 'p1' -> '1'.
      final numericIdStr = item.product.id.replaceAll(RegExp(r'[^0-9]'), '');
      final id = int.tryParse(numericIdStr) ?? 0;

      return {
        'id': id,
        'quantity': item.quantity,
        'discount': 0, // Using double for API 'decimal' field
      };
    }).toList();

    final status = await _apiService.processTransaction(
      cartData: cartData,
      amountPaid: amountPaid.toDouble(),
      paymentMethod: paymentMethod,
      globalDiscount: discountAmount.toDouble(),
    );

    _isLoading = false;

    if (status == 'online' || status.startsWith('offline')) {
      clearCart();
    } else {
      notifyListeners();
    }

    return status;
  }
}
