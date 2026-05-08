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
  bool _phraseRecognized = false;
  double _level = 0.0;
  Timer? _timer;

  static const String echoPhrase = 'Echo Help Now';

  void _toggleListening() {
    setState(() {
      _isListening = !_isListening;
      _phraseRecognized = false;
    });

    if (_isListening) {
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(milliseconds: 150), (_) {
        setState(() {
          _level = 0.15 + Random().nextDouble() * 0.7;
        });
      });
      
      // Simulate phrase recognition after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (_isListening && mounted) {
          setState(() {
            _phraseRecognized = true;
            _isListening = false;
            _timer?.cancel();
            _level = 0.0;
          });
        }
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
        final bool active = index == 2;
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
                  'Your Emergency Activation Phrase',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: EchoColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: EchoColors.primary, width: 1),
                  ),
                  child: Text(
                    echoPhrase,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: EchoColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Say "$echoPhrase" clearly to activate the emergency system. Test it below to make sure your voice is recognized.',
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
                          color: _phraseRecognized ? Colors.greenAccent : EchoColors.primary,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_phraseRecognized ? Colors.greenAccent : EchoColors.primary)
                                .withOpacity(_isListening ? 0.25 : 0.0),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF0D1F45),
                          ),
                          child: Icon(
                            _phraseRecognized ? Icons.check_rounded : Icons.mic_rounded,
                            color: _phraseRecognized ? Colors.greenAccent : Colors.white,
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
                    _isListening
                        ? 'Listening...'
                        : _phraseRecognized
                            ? '✓ Phrase recognized!'
                            : 'Tap mic to test',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: _phraseRecognized ? Colors.greenAccent : Colors.white70,
                      fontWeight: _phraseRecognized ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/tier1-inner-circle-setup');
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
                      'Continue',
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
