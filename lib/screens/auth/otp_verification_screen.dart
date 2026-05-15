import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:echo/theme.dart';
import '../../services/local_storage_service.dart';
import 'profile_setup_screen.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const OTPVerificationScreen({required this.phoneNumber, super.key});

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  final LocalStorageService _localStorage = LocalStorageService();

  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOTP() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _error = 'OTP must be 6 digits');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    if (otp != '000000') {
      setState(() {
        _error = 'Use demo code 000000';
        _isLoading = false;
      });
      return;
    }

    final digits = widget.phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final uid = 'demo_phone_$digits';
    final returningUser = _localStorage.getUserByUid(uid);
    final returningName = returningUser?['displayName'] as String?;
    await _localStorage.setCurrentUser(
      uid: uid,
      email: widget.phoneNumber,
      displayName: returningName,
    );
    debugPrint('[DemoAuth] Local OTP accepted for ${widget.phoneNumber}');

    if (!mounted) return;
    if (returningName != null && returningName.trim().isNotEmpty) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/system-test-screen', (_) => false);
      return;
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (ctx) => const ProfileSetupScreen()));
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
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
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
                      const SizedBox(height: 48),
                      Text(
                        'Verify your phone',
                        style: GoogleFonts.poppins(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter demo code 000000 for ${widget.phoneNumber}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 48),
                      Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8EAF0),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 20),
                            const Icon(
                              Icons.security_rounded,
                              color: EchoColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _otpController,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                style: GoogleFonts.poppins(
                                  color: EchoColors.primaryDark.withOpacity(
                                    0.9,
                                  ),
                                  fontSize: 18,
                                  letterSpacing: 4,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  counterText: '',
                                  hintText: '000000',
                                  hintStyle: GoogleFonts.poppins(
                                    color: EchoColors.primaryDark.withOpacity(
                                      0.9,
                                    ),
                                    fontSize: 18,
                                    letterSpacing: 4,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: GoogleFonts.poppins(
                            color: EchoColors.primaryLight,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
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
                                EchoColors.primaryDark,
                              ),
                            ),
                          )
                        : Text(
                            'Verify Code',
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
