import 'package:json_annotation/json_annotation.dart';

part 'incident.g.dart';

@JsonSerializable()
class Incident {
  final String id;
  final String userId;
  final String threatType;
  final double confidence;
  final DateTime startTime;
  final DateTime? tier1Time;
  final DateTime? tier2Time;
  final DateTime? tier3Time;
  final bool isResolved;

  Incident({
    required this.id,
    required this.userId,
    required this.threatType,
    required this.confidence,
    required this.startTime,
    this.tier1Time,
    this.tier2Time,
    this.tier3Time,
    this.isResolved = false,
  });

  factory Incident.fromJson(Map<String, dynamic> json) => _$IncidentFromJson(json);
  Map<String, dynamic> toJson() => _$IncidentToJson(this);
}
