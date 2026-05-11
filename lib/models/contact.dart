
class Contact {
  final String id;
  final String name;
  final String phoneNumber;
  final String? telegramChatId;
  final int tier; // 1 or 2

  Contact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.telegramChatId,
    required this.tier,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String,
      telegramChatId: json['telegramChatId'] as String?,
      tier: json['tier'] as int,
    );
  }

  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '?';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'telegramChatId': telegramChatId,
      'tier': tier,
    };
  }
}
