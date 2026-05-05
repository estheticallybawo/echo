import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VoiceSetupScreen extends StatefulWidget {
  const VoiceSetupScreen({super.key});

  @override
  State<VoiceSetupScreen> createState() => _VoiceSetupScreenState();
}

class _VoiceSetupScreenState extends State<VoiceSetupScreen> {
  final TextEditingController _phraseController = TextEditingController();
  int _recordingStep = 0; // 0: initial, 1: first done, 2: second done, 3: complete
  bool _isRecording = false;

  void _handleMicTap() async {
    if (_phraseController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please type your secret phrase first")),
      );
      return;
    }

    if (_recordingStep >= 3) return;

    setState(() {
      _isRecording = true;
    });

    // Simulate recording/processing duration
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isRecording = false;
        _recordingStep++;
      });
    }
  }

  String _getStatusText() {
    if (_phraseController.text.trim().isEmpty) {
      return "Type your phrase above to begin";
    }
    switch (_recordingStep) {
      case 0:
        return "Tap the mic to begin";
      case 1:
      case 2:
        return "Good, say it again";
      case 3:
        return "Great, Echo recognizes your voice";
      default:
        return "";
    }
  }

  @override
  void dispose() {
    _phraseController.dispose();
    super.dispose();
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                    ),
                    Row(
                      children: [
                        ...List.generate(4, (index) => Container(
                          width: index == 2 ? 32 : 6,
                          height: 6,
                          margin: const EdgeInsets.only(left: 4),
                          decoration: BoxDecoration(
                            color: index <= 2 ? const Color(0xFF2563EB) : Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        )),
                      ],
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),
                      Text(
                        "Choose a phrase only you would say",
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "When Echo hears this phrase, it sends help immediately. No taps needed.",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white70,
                          height: 1.5,
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Phrase Input Field
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: TextField(
                          controller: _phraseController,
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 18),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Enter your secret phrase...",
                            hintStyle: GoogleFonts.poppins(color: Colors.white24),
                            icon: const Icon(Icons.edit_note, color: Color(0xFF2563EB)),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      
                      const SizedBox(height: 64),
                      
                      Center(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: _handleMicTap,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isRecording ? const Color(0xFF2563EB).withOpacity(0.2) : Colors.white.withOpacity(0.05),
                                  border: Border.all(
                                    color: _isRecording ? const Color(0xFF2563EB) : Colors.white24,
                                    width: 2,
                                  ),
                                  boxShadow: _isRecording ? [
                                    BoxShadow(
                                      color: const Color(0xFF2563EB).withOpacity(0.3),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    )
                                  ] : [],
                                ),
                                child: Icon(
                                  _isRecording ? Icons.graphic_eq : Icons.mic_none,
                                  color: _isRecording ? const Color(0xFF2563EB) : Colors.white,
                                  size: 40,
                                ),
                              ),
                            ),
                            const SizedBox(height: 48),
                            
                            // Waveform Visualizer
                            SizedBox(
                              height: 40,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(24, (index) {
                                  final barHeight = _isRecording 
                                    ? (8 + (index % 4 * 10) + (index % 3 * 5)).toDouble()
                                    : 4.0;
                                    
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    margin: const EdgeInsets.symmetric(horizontal: 2),
                                    width: 3,
                                    height: barHeight,
                                    decoration: BoxDecoration(
                                      color: _isRecording ? const Color(0xFF2563EB) : Colors.white24,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  );
                                }),
                              ),
                            ),
                            
                            const SizedBox(height: 32),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Text(
                                _getStatusText(),
                                key: ValueKey(_recordingStep + (_phraseController.text.isEmpty ? 10 : 0)),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: _recordingStep == 3 ? const Color(0xFF2563EB) : Colors.white,
                                  fontWeight: _recordingStep == 3 ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
                    color: _recordingStep == 3 ? const Color(0xFF2563EB) : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(28),
                    border: _recordingStep == 3 ? null : Border.all(color: Colors.white10),
                  ),
                  child: ElevatedButton(
                    onPressed: _recordingStep == 3 ? () {
                      // Final Step - go to home or success screen
                      Navigator.of(context).pushReplacementNamed('/home');
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    ),
                    child: Text(
                      _recordingStep == 3 ? "Complete Setup" : "Finish recording to continue",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: _recordingStep == 3 ? Colors.white : Colors.white38,
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
