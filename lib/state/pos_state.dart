import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/member.dart';
import '../models/promo.dart';

class PosState extends ChangeNotifier {
  final List<Member> members = [
    Member(id: 'm1', name: 'Budi Santoso', phone: '081234567890', points: 150),
    Member(id: 'm2', name: 'Siti Aminah', phone: '089876543210', points: 45),
    Member(id: 'm3', name: 'Ahmad Yani', phone: '085512349876', points: 300),
  ];

  final List<Promo> promos = [
    Promo(
      id: 'prm1',
      code: 'PROMO10',
      description: 'Diskon 10% Semua Item',
      discountPercentage: 10.0,
    ),
    Promo(
      id: 'prm2',
      code: 'MEMBER20',
      description: 'Diskon Spesial Member 20%',
      discountPercentage: 20.0,
    ),
    Promo(
      id: 'prm3',
      code: 'GAJIAN5',
      description: 'Diskon Gajian 5%',
      discountPercentage: 5.0,
    ),
  ];

  final List<Product> _allProducts = [
    Product(
      id: 'p1',
      sku: 'CLO-001',
      title: 'T-Shirt Katun Polos',
      price: 75000,
      categoryId: 'clothing',
      imageUrl: '👕',
      stock: 50,
    ),
    Product(
      id: 'p2',
      sku: 'CLO-002',
      title: 'Celana Jeans Pria',
      price: 250000,
      categoryId: 'clothing',
      imageUrl: '👖',
      stock: 20,
    ),
    Product(
      id: 'p3',
      sku: 'ELE-001',
      title: 'Kabel USB-C Fast Charging',
      price: 45000,
      categoryId: 'electronics',
      imageUrl: '🔌',
      stock: 100,
    ),
    Product(
      id: 'p4',
      sku: 'ELE-002',
      title: 'Powerbank 10000mAh',
      price: 150000,
      categoryId: 'electronics',
      imageUrl: '🔋',
      stock: 15,
    ),
    Product(
      id: 'p5',
      sku: 'ELE-003',
      title: 'Earphone Bluetooth',
      price: 120000,
      categoryId: 'electronics',
      imageUrl: '🎧',
      stock: 30,
    ),
    Product(
      id: 'p6',
      sku: 'ACC-001',
      title: 'Kacamata Hitam Anti-UV',
      price: 85000,
      categoryId: 'accessories',
      imageUrl: '🕶️',
      stock: 40,
    ),
    Product(
      id: 'p7',
      sku: 'ACC-002',
      title: 'Topi Baseball Kanvas',
      price: 55000,
      categoryId: 'accessories',
      imageUrl: '🧢',
      stock: 25,
    ),
    Product(
      id: 'p8',
      sku: 'HOU-001',
      title: 'Sabun Cair 500ml',
      price: 35000,
      categoryId: 'household',
      imageUrl: '🧴',
      stock: 60,
    ),
    Product(
      id: 'p9',
      sku: 'HOU-002',
      title: 'Sikat Gigi Elektrik',
      price: 95000,
      categoryId: 'household',
      imageUrl: '🪥',
      stock: 12,
    ),
  ];

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  Member? _selectedMember;
  Member? get selectedMember => _selectedMember;

  Promo? _selectedPromo;
  Promo? get selectedPromo => _selectedPromo;

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
}
