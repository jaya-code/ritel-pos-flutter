class Promo {
  final String id;
  final String code;
  final String description;
  final double discountPercentage;

  Promo({
    required this.id,
    required this.code,
    required this.description,
    required this.discountPercentage,
  });

  factory Promo.fromJson(Map<String, dynamic> json) {
    return Promo(
      id: json['id'],
      code: json['code'],
      description: json['description'],
      discountPercentage: (json['discountPercentage'] as num).toDouble(),
    );
  }
}
