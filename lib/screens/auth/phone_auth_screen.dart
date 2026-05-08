import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_setup_screen.dart';
import 'otp_verification_screen.dart';
import '../../services/local_storage_service.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocalStorageService _localStorage = LocalStorageService();
  
  String? _verificationId;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handlePhoneAuth() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      try {
        final phone = _phoneController.text.trim();
        print('🔐 Starting Firebase phone auth for: $phone');

        await _auth.verifyPhoneNumber(
          phoneNumber: phone,
          verificationCompleted: (PhoneAuthCredential credential) async {
            print('✅ Phone auto-verified: $phone');
            // Auto sign-in for instant verification (rare, mostly for testing)
            try {
              final userCredential = await _auth.signInWithCredential(credential);
              final user = userCredential.user;
              if (user != null && mounted) {
                // Save UID locally
                await _localStorage.setCurrentUser(
                  uid: user.uid,
                  email: user.phoneNumber ?? '',
                  displayName: null,
                );
                print('✅ UID saved locally: ${user.uid}');
                
                if (mounted) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => const ProfileSetupScreen(),
                    ),
                  );
                }
              }
            } catch (e) {
              print('❌ Auto-sign-in failed: $e');
              setState(() {
                _error = 'Authentication failed. Please try again.';
                _isLoading = false;
              });
            }
          },
          verificationFailed: (FirebaseAuthException e) {
            print('❌ Phone verification failed: ${e.message}');
            setState(() {
              _error = 'Verification failed: ${e.message}';
              _isLoading = false;
            });
          },
          codeSent: (String verificationId, int? resendToken) {
            print('📱 OTP sent to: $phone');
            _verificationId = verificationId;
            setState(() {
              _isLoading = false;
            });
            
            // Navigate to OTP verification screen
            if (mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => OTPVerificationScreen(
                    phoneNumber: phone,
                    verificationId: verificationId,
                  ),
                ),
              );
            }
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            print('⏱️ Auto-retrieval timeout for: $phone');
            _verificationId = verificationId;
          },
          timeout: const Duration(minutes: 2),
        );
      } catch (e) {
        print('❌ Phone auth error: $e');
        setState(() {
          _error = 'Failed to send code: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.3),
            radius: 1.2,
            colors: [Color(0xFF0F3169), Color(0xFF02091A)],
            stops: [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          InkWell(
                            onTap: () => Navigator.of(context).pop(),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 48),

                      Text(
                        "Create your Echo account",
                        style: GoogleFonts.poppins(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Set up your safety network in minutes",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      const SizedBox(height: 48),

                      Form(
                        key: _formKey,
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E3D5E),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 20),
                              const Icon(
                                Icons.phone_outlined,
                                color: Colors.blue,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                  decoration: InputDecoration(
                                    filled: false,
                                    fillColor: Colors.transparent,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    hintText: 'Enter phone number',
                                    hintStyle: GoogleFonts.poppins(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Enter your phone number';
                                    }
                                    final digits = value.replaceAll(
                                      RegExp(r'[^0-9]'),
                                      '',
                                    );
                                    if (digits.length < 7 ||
                                        digits.length > 15) {
                                      return 'Enter a valid phone number';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      Center(
                        child: Text(
                          "We'll send a code to verify your number",
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                          ),
                        ),
                      ),

                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.withOpacity(0.5)),
                          ),
                          child: Text(
                            _error!,
                            style: GoogleFonts.poppins(
                              color: Colors.red.shade300,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handlePhoneAuth,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: _isLoading
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
                        : Text(
                            "Continue",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
