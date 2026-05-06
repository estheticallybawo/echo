
class Contact {
  final String id;
  final String name;
  final String phoneNumber;
  final int tier; // 1 or 2

  Contact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.tier,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String,
      tier: json['tier'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'tier': tier,
    };
  }
}
