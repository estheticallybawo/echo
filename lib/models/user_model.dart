/// Echo User Model - Core user identity
class EchoUser {
  final String userId; // Unique identifier (can be UUID)
  final String email;
  final String phoneNumber;
  final String firstName;
  final String? lastName;
  final DateTime createdAt;
  final bool hasCompletedOnboarding;
  
  // Social media connections (optional, future)
  final bool xConnected;
  final bool enableAutoPosting;

  EchoUser({
    required this.userId,
    required this.email,
    required this.phoneNumber,
    required this.firstName,
    this.lastName,
    required this.createdAt,
    this.hasCompletedOnboarding = false,
    this.xConnected = false,
    this.enableAutoPosting = false,
  });

  /// Get display name for personalized responses
  String get displayName => firstName;

  /// Full name for formal contexts
  String get fullName => lastName != null ? '$firstName $lastName' : firstName;

  /// Convert to JSON for storage/sync
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'phoneNumber': phoneNumber,
      'firstName': firstName,
      'lastName': lastName,
      'createdAt': createdAt.toIso8601String(),
      'hasCompletedOnboarding': hasCompletedOnboarding,
      'xConnected': xConnected,
      'enableAutoPosting': enableAutoPosting,
    };
  }

  /// Create from JSON
  factory EchoUser.fromJson(Map<String, dynamic> json) {
    return EchoUser(
      userId: json['userId'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      hasCompletedOnboarding: json['hasCompletedOnboarding'] ?? false,
      xConnected: json['XConnected'] ?? false,
      enableAutoPosting: json['enableAutoPosting'] ?? false,
    );
  }

  /// Create a copy with updated fields
  EchoUser copyWith({
    String? userId,
    String? email,
    String? phoneNumber,
    String? firstName,
    String? lastName,
    DateTime? createdAt,
    bool? hasCompletedOnboarding,
    bool? xConnected,
    bool? enableAutoPosting,
  }) {
    return EchoUser(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      createdAt: createdAt ?? this.createdAt,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      xConnected: xConnected ?? this.xConnected,
      enableAutoPosting: enableAutoPosting ?? this.enableAutoPosting,
    );
  }
}
