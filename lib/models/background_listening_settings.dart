/// Background Listening Settings
/// User has complete control over when Echo listens in the background
class BackgroundListeningSettings {
  final bool isEnabled;
  final DateTime? lastToggleTime;
  final String? userReason; // Why they disabled it

  BackgroundListeningSettings({
    this.isEnabled = false, // Default: OFF (privacy-first)
    this.lastToggleTime,
    this.userReason,
  });

  /// Create from JSON for storage
  factory BackgroundListeningSettings.fromJson(Map<String, dynamic> json) {
    return BackgroundListeningSettings(
      isEnabled: json['isEnabled'] ?? false,
      lastToggleTime: json['lastToggleTime'] != null
          ? DateTime.parse(json['lastToggleTime'])
          : null,
      userReason: json['userReason'],
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'lastToggleTime': lastToggleTime?.toIso8601String(),
      'userReason': userReason,
    };
  }

  /// Copy with modifications
  BackgroundListeningSettings copyWith({
    bool? isEnabled,
    DateTime? lastToggleTime,
    String? userReason,
  }) {
    return BackgroundListeningSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      lastToggleTime: lastToggleTime ?? this.lastToggleTime,
      userReason: userReason ?? this.userReason,
    );
  }
}
