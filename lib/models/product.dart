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
}
