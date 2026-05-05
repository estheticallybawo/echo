
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

  factory Incident.fromJson(Map<String, dynamic> json) {
    return Incident(
      id: json['id'] as String,
      userId: json['userId'] as String,
      threatType: json['threatType'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      startTime: DateTime.parse(json['startTime'] as String),
      tier1Time: json['tier1Time'] != null ? DateTime.parse(json['tier1Time'] as String) : null,
      tier2Time: json['tier2Time'] != null ? DateTime.parse(json['tier2Time'] as String) : null,
      tier3Time: json['tier3Time'] != null ? DateTime.parse(json['tier3Time'] as String) : null,
      isResolved: json['isResolved'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'threatType': threatType,
      'confidence': confidence,
      'startTime': startTime.toIso8601String(),
      'tier1Time': tier1Time?.toIso8601String(),
      'tier2Time': tier2Time?.toIso8601String(),
      'tier3Time': tier3Time?.toIso8601String(),
      'isResolved': isResolved,
    };
  }
}
