import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme.dart';

class PhraseSetupScreen extends StatefulWidget {
  const PhraseSetupScreen({super.key});

  @override
  State<PhraseSetupScreen> createState() => _PhraseSetupScreenState();
}

class _PhraseSetupScreenState extends State<PhraseSetupScreen> {
  bool _isListening = false;
  double _level = 0.0;
  int _currentStep = 0;
  Timer? _timer;

  final List<String> _statusMessages = [
    'Tap the mic to begin',
    'Good, say it again',
    'Great, Echo recognizes your voice',
  ];

  final List<String> _buttonLabels = ['Record phrase or sound', 'Continue', 'Finish'];

  void _toggleListening() {
    setState(() {
      _isListening = !_isListening;
    });

    if (_isListening) {
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(milliseconds: 150), (_) {
        setState(() {
          _level = 0.15 + Random().nextDouble() * 0.7;
        });
      });
    } else {
      _timer?.cancel();
      setState(() {
        _level = 0.0;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _buildProgressDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(7, (index) {
        // Map _currentStep (0, 1, 2) to progress indices (2, 3, 4)
        final bool active = index == (_currentStep + 2);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 74 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? EchoColors.primary : Colors.white24,
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }),
    );
  }

  Widget _buildMeter() {
    const int barCount = 20;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(barCount, (index) {
        final threshold = index / barCount;
        final active = _level > threshold;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 1),
          width: 4,
          height: active ? 12 : 8,
          decoration: BoxDecoration(
            color: active ? EchoColors.primary : Colors.white24,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.6),
            radius: 1.4,
            colors: [Color(0xFF0D2763), Color(0xFF081023)],
            stops: [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.maybePop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B1C41),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    const Spacer(),
                    _buildProgressDots(),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  'Create a unique phrase or sound only you would make to activate echo',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'When Echo hears this phrase or a unique sound like a whistle, it sends help immediately. Say or make the sound three times to train the AI.',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    height: 1.7,
                    color: Colors.white70,
                  ),
                ),
                const Spacer(),
                Center(
                  child: GestureDetector(
                    onTap: _toggleListening,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: EchoColors.primary,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withOpacity(0.6),
                            blurRadius: 60,
                            spreadRadius: 10,
                          ),
                          BoxShadow(
                            color: EchoColors.primary.withOpacity(
                              _isListening ? 0.25 : 0.0,
                            ),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 92 + (_isListening ? _level * 25 : 0),
                          height: 92 + (_isListening ? _level * 25 : 0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isListening ? EchoColors.primary : const Color(0xFF0D1F45),
                          ),
                          child: const Icon(
                            Icons.mic_rounded,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                _buildMeter(),
                const SizedBox(height: 18),
                Center(
                  child: Text(
                    _isListening ? 'Listening...' : _statusMessages[_currentStep],
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentStep < 2) {
                        setState(() {
                          if (_isListening) {
                            _timer?.cancel();
                            _isListening = false;
                            _level = 0.0;
                          }
                          _currentStep += 1;
                        });
                      } else {
                        Navigator.pushNamed(context, '/tier1-inner-circle-setup');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E4CC8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(34),
                      ),
                      elevation: 8,
                      shadowColor: const Color(0xFF1E4CC8).withOpacity(0.35),
                    ),
                    child: Text(
                      _buttonLabels[_currentStep],
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.9),
                      ),
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
