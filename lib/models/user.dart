class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final int storeId;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.storeId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      storeId: json['store_id'] ?? 0,
    );
  }
}
