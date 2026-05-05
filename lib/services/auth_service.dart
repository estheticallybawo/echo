import 'package:uuid/uuid.dart';
import '../models/user_model.dart';

/// Echo Authentication Service
/// Handles user registration, login, and session management
/// For MVP: Simple email/phone authentication
/// Future: Add social media linking for auto-posting
class AuthService {
  static const _uuid = Uuid();
  
  // Simulated storage (replace with SharedPreferences/Firebase in production)
  final Map<String, EchoUser> _users = {};
  EchoUser? _currentUser;

  /// Check if user is already logged in
  bool get isAuthenticated => _currentUser != null;
  
  /// Get current user
  EchoUser? get currentUser => _currentUser;

  /// Register a new user with email and phone
  /// Returns the created user if successful
  Future<EchoUser> registerUser({
    required String email,
    required String phoneNumber,
    required String firstName,
    String? lastName,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Validate email format
    if (!_isValidEmail(email)) {
      throw Exception('Invalid email format');
    }

    // Validate phone format (basic validation)
    if (phoneNumber.isEmpty || phoneNumber.length < 10) {
      throw Exception('Invalid phone number');
    }

    // Check if user already exists
    if (_users.values.any((user) => user.email == email)) {
      throw Exception('User with this email already exists');
    }

    // Create new user
    final userId = _uuid.v4();
    final newUser = EchoUser(
      userId: userId,
      email: email,
      phoneNumber: phoneNumber,
      firstName: firstName,
      lastName: lastName,
      createdAt: DateTime.now(),
      hasCompletedOnboarding: false,
    );

    // Store user
    _users[userId] = newUser;
    _currentUser = newUser;

    return newUser;
  }

  /// Login user by email (for demo, auto-login)
  /// In production: verify via SMS OTP or email link
  Future<EchoUser> loginUser({required String email}) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final user = _users.values.firstWhere(
      (u) => u.email == email,
      orElse: () => throw Exception('User not found'),
    );

    _currentUser = user;
    return user;
  }

  /// Update user after onboarding completion
  Future<void> completeOnboarding(EchoUser user) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final updatedUser = user.copyWith(hasCompletedOnboarding: true);
    _users[user.userId] = updatedUser;
    _currentUser = updatedUser;
  }

  /// Logout current user
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Get user by ID (helper for future features)
  EchoUser? getUserById(String userId) {
    return _users[userId];
  }
}
