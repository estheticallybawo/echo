import 'package:json_annotation/json_annotation.dart';

part 'contact.g.dart';

@JsonSerializable()
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

  factory Contact.fromJson(Map<String, dynamic> json) => _$ContactFromJson(json);
  Map<String, dynamic> toJson() => _$ContactToJson(this);
}
