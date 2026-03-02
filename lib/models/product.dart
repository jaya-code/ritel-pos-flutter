class Product {
  final String id;
  final String sku;
  final String title;
  final double price;
  final String categoryId;
  final String imageUrl;
  final int stock;

  Product({
    required this.id,
    required this.sku,
    required this.title,
    required this.price,
    required this.categoryId,
    required this.imageUrl,
    this.stock = 0,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      sku: json['product_code'] ?? json['sku'] ?? '',
      title: json['product_name'] ?? json['title'] ?? '',
      price: (json['selling_price'] != null)
          ? double.tryParse(json['selling_price'].toString()) ?? 0.0
          : ((json['price'] as num?)?.toDouble() ?? 0.0),
      categoryId:
          json['category_id']?.toString() ??
          json['categoryId']?.toString() ??
          '',
      imageUrl: json['imageUrl'] ?? '📦', // Default placeholder if empty
      stock: json['stock'] ?? 0,
    );
  }
}
