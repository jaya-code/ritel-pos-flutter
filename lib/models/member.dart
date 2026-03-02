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
}
