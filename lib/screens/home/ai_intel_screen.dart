import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme.dart';
import '../../services/gemma/runtime/echo_ai_runtime.dart';
import '../../services/gemma/runtime/web_demo_runtime.dart';
import '../../services/sound/tts_service.dart';
import '../../widgets/echo_soundwave_orb.dart';

class AiIntelScreen extends StatefulWidget {
  const AiIntelScreen({super.key});

  @override
  State<AiIntelScreen> createState() => _AiIntelScreenState();
}

class _AiIntelScreenState extends State<AiIntelScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;
  final EchoAiRuntime _runtime = WebDemoRuntime();
  final TTSService _ttsService = TTSService();
  final TextEditingController _promptController = TextEditingController();
  bool _isThinking = false;
  bool _isSpeaking = false;
  EchoAiResponse? _lastResponse;

  static const List<String> _demoPrompts = [
    'Who are you?',
    'Why were you created?',
    'What can you do in an emergency?',
    'What are your future on-device possibilities?',
  ];

  @override
  void initState() {
    super.initState();
    _ttsService.configureCloudTtsSession(
      sessionToken: const String.fromEnvironment(
        'ELEVENLABS_SESSION_TOKEN',
        defaultValue: 'local-demo-session',
      ),
    );
    _ttsService.setCloudProcessingEnabled(
      const bool.fromEnvironment('ECHO_DEMO_CLOUD_TTS', defaultValue: false),
    );
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _promptController.dispose();
    unawaited(_ttsService.stop());
    super.dispose();
  }

  Future<void> _askEcho(String prompt) async {
    if (prompt.trim().isEmpty || _isThinking) return;
    setState(() => _isThinking = true);
    final response = await _runtime.respondToDemoPrompt(prompt.trim());
    if (!mounted) return;
    setState(() {
      _lastResponse = response;
      _isThinking = false;
      _isSpeaking = true;
    });
    try {
      await _ttsService.speak(response.spokenSummary);
    } finally {
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF02091A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.5),
            radius: 1.3,
            colors: [Color(0xFF0F3169), Color(0xFF02091A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    if (Navigator.canPop(context))
                      InkWell(
                        onTap: () => Navigator.pop(context),
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
                    const Spacer(),
                    Text(
                      'Gemmas Intel',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Column(
                    children: [
                      ScaleTransition(
                        scale: _pulse,
                        child: EchoSoundwaveOrb(
                          size: 146,
                          isActive: _isThinking || _isSpeaking,
                          accentColor: EchoColors.switchOn,
                          semanticLabel: _isThinking
                              ? 'Gemma is thinking'
                              : _isSpeaking
                              ? 'Echo is speaking'
                              : 'Gemma intelligence ready',
                          overlay: Center(
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(
                                  0xFF02091A,
                                ).withOpacity(0.42),
                                border: Border.all(
                                  color: EchoColors.switchOn.withOpacity(0.28),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  _isThinking || _isSpeaking ? '...' : '...',
                                  style: GoogleFonts.poppins(
                                    fontSize: _isThinking || _isSpeaking
                                        ? 26
                                        : 28,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Echo Demo Console',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Chrome-safe live Gemma server path',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.white38,
                        ),
                      ),
                      const SizedBox(height: 28),

                      _buildDemoConsole(),
                      const SizedBox(height: 28),

                      _buildInsightItem(
                        'Audio Pattern Recognition',
                        'No threat indicators detected in background',
                        Icons.check_circle,
                        EchoColors.switchOn,
                      ),
                      _buildInsightItem(
                        'Location Stability',
                        'Moving at expected pace for current activity',
                        Icons.check_circle,
                        EchoColors.switchOn,
                      ),
                      _buildInsightItem(
                        'Contact Proximity',
                        '2 Inner Circle members within 2km radius',
                        Icons.check_circle,
                        EchoColors.switchOn,
                      ),
                      _buildInsightItem(
                        'Time Assessment',
                        'Regular routine confirmed for 9:41 AM',
                        Icons.check_circle,
                        EchoColors.switchOn,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemoConsole() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A).withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _demoPrompts
                .map(
                  (prompt) => ActionChip(
                    label: Text(prompt),
                    onPressed: () => _askEcho(prompt),
                    backgroundColor: EchoColors.primaryDark,
                    labelStyle: GoogleFonts.poppins(
                      color: EchoColors.surfaceTertiary,
                      fontSize: 12,
                    ),
                    side: BorderSide(
                      color: EchoColors.primaryDark.withOpacity(0.3),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _promptController,
            style: GoogleFonts.poppins(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Ask Echo a demo question',
              hintStyle: GoogleFonts.poppins(color: Colors.white38),
              filled: true,
              fillColor: EchoColors.primary.withOpacity(0.05),
              suffixIcon: IconButton(
                icon: const Icon(Icons.send_rounded, color: EchoColors.primary),
                onPressed: () => _askEcho(_promptController.text),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: EchoColors.primaryDark.withOpacity(0.08),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: EchoColors.primaryDark.withOpacity(0.08),
                ),
              ),
            ),
            onSubmitted: _askEcho,
          ),
          const SizedBox(height: 16),
          if (_isThinking)
            Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: EchoColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Echo is preparing a response...',
                  style: GoogleFonts.poppins(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            )
          else
            Text(
              _lastResponse?.text ?? 'What is your mind?',
              style: GoogleFonts.poppins(
                color: EchoColors.surfaceTertiary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          if (_lastResponse != null) ...[
            const SizedBox(height: 10),
            Text(
              _lastResponse!.usedFallback
                  ? 'Mode: demo fallback'
                  : 'Mode: local Gemma server',
              style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInsightItem(
    String title,
    String sub,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A).withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sub,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white38,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
