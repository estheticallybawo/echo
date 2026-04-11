import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../providers/auth_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late PageController _pageController;
  int _currentStep = 0; // 0: Login/Register choice, 1: Email/Phone, 2: Name

  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  bool _isNewUser = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _goToNextStep() {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitAuth(AuthProvider authProvider) async {
    bool success = false;

    if (_isNewUser) {
      // Register
      success = await authProvider.registerUser(
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim().isEmpty
            ? null
            : _lastNameController.text.trim(),
      );
    } else {
      // Login
      success = await authProvider.loginUser(
        email: _emailController.text.trim(),
      );
    }

    if (mounted) {
      if (success) {
        // Navigate to onboarding
        Navigator.of(context).pushReplacementNamed('/onboarding');
      } else {
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Authentication failed'),
            backgroundColor: EchoColors.warning,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            return PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (page) {
                setState(() {
                  _currentStep = page;
                });
              },
              children: [
                // Step 1: Login or Register Choice
                _buildChoiceStep(context, authProvider),

                // Step 2: Email & Phone
                _buildEmailPhoneStep(context, authProvider),

                // Step 3: Name (only for new users)
                if (_isNewUser)
                  _buildNameStep(context, authProvider)
                else
                  _buildNameStep(context, authProvider), // Dummy for consistency
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildChoiceStep(BuildContext context, AuthProvider authProvider) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              // Echo Logo/Title
              Text(
                'Echo',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: EchoColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your Personal Safety Network',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: EchoColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Login Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EchoColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    setState(() {
                      _isNewUser = false;
                    });
                    _goToNextStep();
                  },
                  child: const Text(
                    'Log In',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Register Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: EchoColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    setState(() {
                      _isNewUser = true;
                    });
                    _goToNextStep();
                  },
                  child: const Text(
                    'Create Account',
                    style: TextStyle(
                      color: EchoColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmailPhoneStep(
      BuildContext context, AuthProvider authProvider) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _isNewUser ? 'Create Your Account' : 'Welcome Back',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: EchoColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),

        // Form
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Email Field
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'your.email@example.com',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                // Phone Field (only show for registration)
                if (_isNewUser)
                  Column(
                    children: [
                      TextField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          hintText: '+1 (555) 123-4567',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'We use your phone for emergency verification and to confirm your location.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: EchoColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),

        // Navigation Buttons
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _goToPreviousStep,
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EchoColors.primary,
                  ),
                  onPressed: authProvider.isLoading
                      ? null
                      : () {
                          if (_isNewUser) {
                            _goToNextStep();
                          } else {
                            // For login, skip to name step or submit
                            _submitAuth(authProvider);
                          }
                        },
                  child: authProvider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(_isNewUser ? 'Next' : 'Log In'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNameStep(BuildContext context, AuthProvider authProvider) {
    if (!_isNewUser) {
      // This is a dummy for login path
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'What\'s Your Name?',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: EchoColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),

        // Form
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // First Name
                TextField(
                  controller: _firstNameController,
                  decoration: InputDecoration(
                    labelText: 'First Name',
                    hintText: 'Jane',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),

                // Last Name
                TextField(
                  controller: _lastNameController,
                  decoration: InputDecoration(
                    labelText: 'Last Name (Optional)',
                    hintText: 'Doe',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Navigation Buttons
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _goToPreviousStep,
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EchoColors.primary,
                  ),
                  onPressed: authProvider.isLoading
                      ? null
                      : () => _submitAuth(authProvider),
                  child: authProvider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('Create Account'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
