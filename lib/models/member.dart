class Member {
  final String id;
  final String name;
  final String phone;
  final int points;

  Member({
    required this.id,
    required this.name,
    required this.phone,
    this.points = 0,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      points: json['points'] ?? 0,
    );
  }
}
