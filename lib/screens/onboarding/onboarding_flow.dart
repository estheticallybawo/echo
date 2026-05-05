import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../theme.dart';
import '../auth/auth_screen.dart';

class OnboardingState extends ChangeNotifier {
  int _currentStep = 0;
  
  double _audioLevel = 0.5;

  int get currentStep => _currentStep;
  double get audioLevel => _audioLevel;

  OnboardingState() {
    _simulateAudioInput();
  }

  void _simulateAudioInput() async {
    while (true) {
      await Future.delayed(const Duration(milliseconds: 200));
      _audioLevel = 0.3 + (0.4 * (DateTime.now().millisecondsSinceEpoch % 1000) / 1000);
      notifyListeners();
    }
  }

  void nextStep() {
    if (_currentStep < 2) {
      _currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }
}

class OnboardingFlow extends StatelessWidget {
  const OnboardingFlow({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OnboardingState(),
      child: const _OnboardingScreen(),
    );
  }
}

class _OnboardingScreen extends StatelessWidget {
  const _OnboardingScreen();

  void _showAuthBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (ctx) => const AuthBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OnboardingState>();
    final step = state.currentStep;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.2), 
            radius: 1.0,
            colors: [
              Color(0xFF0F3169),
              Color(0xFF02091A),
            ],
            stops: [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(flex: 3),
                
               
                Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutQuad,
                    transform: Matrix4.identity()..scale(1.0 + (state.audioLevel * 0.15)),
                    transformAlignment: Alignment.center,
                    child: Image.asset(
                      'assets/onboarding/Echosoundwave.png',
                      width: 260,
                      height: 260,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                
                const SizedBox(height: 26), 

                
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: RichText(
                    key: ValueKey('text_$step'),
                    textAlign: TextAlign.left,
                    text: TextSpan(
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        height: 1.4,
                        letterSpacing: 0.2,
                      ),
                      children: [
                        TextSpan(
                          text: step == 0
                              ? "You deserve to feel safe, even when you're alone. "
                              : step == 1
                                  ? "Hands-free protection wherever you are. "
                                  : "Smart safety features for the real world. ",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: step == 2 ? "With " : "Echo ",
                          style: const TextStyle(
                            color: Color(0xFF6B7A99),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: step == 0
                              ? "listens for you and alerts help instantly when something feels wrong."
                              : step == 1
                                  ? "detects signs of danger and silently notifies your emergency contacts."
                                  : "live location tracking and automatic voice recording, help is always on the way.",
                          style: const TextStyle(
                            color: Color(0xFF6B7A99),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(flex: 4),

               
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 600),
                  opacity: step >= 1 ? 1.0 : 0.0,
                  child: Center(
                    child: Text(
                      "Inspired by Iniubong Hiny Umoren · April 29, 2021\n· Uyo, Akwa Ibom",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.white70,
                        height: 1.6,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
                
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: step == 2
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 24.0, top: 16.0),
                          child: Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              color: const Color(0xFF2563EB), 
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2563EB).withOpacity(0.3),
                                  offset: const Offset(0, 4),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () => _showAuthBottomSheet(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: Text(
                                "Get Started",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.only(bottom: 24.0, top: 16.0),
                          child: Row(
                            key: const ValueKey('arrows'),
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 300),
                                opacity: step > 0 ? 1.0 : 0.0,
                                child: IgnorePointer(
                                  ignoring: step == 0,
                                  child: InkWell(
                                    onTap: () => context.read<OnboardingState>().previousStep(),
                                    borderRadius: BorderRadius.circular(50),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.2),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.arrow_back_rounded,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () => context.read<OnboardingState>().nextStep(),
                                borderRadius: BorderRadius.circular(50),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: EchoColors.primary,
                                    boxShadow: [
                                      BoxShadow(
                                        color: EchoColors.primary.withOpacity(0.4),
                                        blurRadius: 20,
                                        spreadRadius: 4,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.chevron_right_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


