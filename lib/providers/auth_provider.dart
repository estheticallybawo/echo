import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Echo Authentication Provider
/// Manages authentication state for the app
/// Provides user identity for personalized responses
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  EchoUser? _currentUser;
  bool _isLoading = false;
  String? _error;

  AuthProvider({required AuthService authService}) : _authService = authService;

  // Getters
  EchoUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Register a new user
  Future<bool> registerUser({
    required String email,
    required String phoneNumber,
    required String firstName,
    String? lastName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _authService.registerUser(
        email: email,
        phoneNumber: phoneNumber,
        firstName: firstName,
        lastName: lastName,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Login user
  Future<bool> loginUser({required String email}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _authService.loginUser(email: email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Complete onboarding
  Future<bool> completeOnboarding() async {
    if (_currentUser == null) {
      _error = 'No user logged in';
      notifyListeners();
      return false;
    }

    try {
      await _authService.completeOnboarding(_currentUser!);
      _currentUser = _currentUser!.copyWith(hasCompletedOnboarding: true);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    
    await _authService.logout();
    _currentUser = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Clear errors
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
