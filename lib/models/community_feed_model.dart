/// Community Feed models for global amplification
class CommunityFeedEntry {
  final String id;
  final String victimName;
  final String victimId;
  final String location; // e.g., "Ikoyi, Lagos"
  final String state;
  final String country;
  final DateTime triggeredAt;
  final String hashTag; // e.g., #findJaneOkafor
  final int shareCount;
  final bool userAmplified;
  final String status; // "active", "resolved", "archived"
  final String? gemmaAssessment;
  final int? retweetCount;
  final int? impressions;

  CommunityFeedEntry({
    required this.id,
    required this.victimName,
    required this.victimId,
    required this.location,
    required this.state,
    required this.country,
    required this.triggeredAt,
    required this.hashTag,
    this.shareCount = 0,
    this.userAmplified = false,
    this.status = "active",
    this.gemmaAssessment,
    this.retweetCount,
    this.impressions,
  });

  /// Get time elapsed since trigger
  String getTimeElapsed() {
    final now = DateTime.now();
    final difference = now.difference(triggeredAt);

    if (difference.inSeconds < 60) {
      return "${difference.inSeconds}s ago";
    } else if (difference.inMinutes < 60) {
      return "${difference.inMinutes}m ago";
    } else if (difference.inHours < 24) {
      return "${difference.inHours}h ago";
    } else {
      return "${difference.inDays}d ago";
    }
  }

  /// Get display location
  String getDisplayLocation() {
    return "$location, $state, $country";
  }

  /// Get formatted feed message
  String getFeedMessage() {
    return "Echo was triggered at ${getDisplayLocation()} and it's been ${getTimeElapsed()}. Help amplify using $hashTag";
  }

  /// Copy with method for state management
  CommunityFeedEntry copyWith({
    String? id,
    String? victimName,
    String? victimId,
    String? location,
    String? state,
    String? country,
    DateTime? triggeredAt,
    String? hashTag,
    int? shareCount,
    bool? userAmplified,
    String? status,
    String? gemmaAssessment,
    int? retweetCount,
    int? impressions,
  }) {
    return CommunityFeedEntry(
      id: id ?? this.id,
      victimName: victimName ?? this.victimName,
      victimId: victimId ?? this.victimId,
      location: location ?? this.location,
      state: state ?? this.state,
      country: country ?? this.country,
      triggeredAt: triggeredAt ?? this.triggeredAt,
      hashTag: hashTag ?? this.hashTag,
      shareCount: shareCount ?? this.shareCount,
      userAmplified: userAmplified ?? this.userAmplified,
      status: status ?? this.status,
      gemmaAssessment: gemmaAssessment ?? this.gemmaAssessment,
      retweetCount: retweetCount ?? this.retweetCount,
      impressions: impressions ?? this.impressions,
    );
  }
}
