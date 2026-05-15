import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme.dart';
import '../../widgets/echo_soundwave_orb.dart';
import '../../widgets/tutorial_overlay.dart';
import '../../services/sound/audio_record_service.dart';
import '../../services/sound/speech_transcription_service.dart';
import '../../services/sound/voice_recognition_service.dart';
import '../../services/sound/tts_service.dart';
import '../../services/sound/voice_command_router.dart';
import '../../services/sound/voice_conversation_decision.dart';
import '../../services/sound/voice_conversation_service.dart';
import '../../services/sound/voice_dictation_service.dart';

enum _EchoMode { standby, countdown, active, voice, thinking, speaking }

class _Contact {
  final String name;
  final int tier;
  _Contact(this.name, this.tier);
  String get initial => name[0].toUpperCase();
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  static const bool _enableSlowAudioFallback = bool.fromEnvironment(
    'ECHO_ENABLE_GEMMA_AUDIO_FALLBACK',
    defaultValue: false,
  );

  bool _bgListening = !kIsWeb;
  _EchoMode _mode = _EchoMode.standby;
  int _sosCountdown = 1;
  int _elapsed = 0;
  double _voiceLevel = 0.0;
  bool _showTutorial = true;
  int _tutorialStep = 1;

  Timer? _sosTimer;
  Timer? _elapsedTimer;
  Timer? _voiceTimer;
  Timer? _voiceLimitTimer;

  late AnimationController _pulseCtrl;
  late AnimationController _holdCtrl;
  late Animation<double> _pulseAnim;
  late Animation<double> _holdAnim;

  late VoiceRecognitionService _voiceRecognition;
  late final VoiceDictationService _voiceDictationService;
  late final VoiceConversationService _voiceConversationService;
  late final AudioRecorderService _audioRecorderService;
  late final SpeechTranscriptionService _speechTranscriptionService;
  final TTSService _ttsService = TTSService();
  static const String _safetyPhrase = 'echo help now';
  late final VoiceCommandRouter _voiceCommandRouter;

  final List<_Contact> _contacts = [
    _Contact('Mom', 1),
    _Contact('Sister', 2),
    _Contact('Best Friend', 3),
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.82,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _holdCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _holdAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _holdCtrl, curve: Curves.linear));
    _audioRecorderService = AudioRecorderService();
    _speechTranscriptionService = SpeechTranscriptionService();
    _voiceDictationService = VoiceDictationService();
    _voiceConversationService = VoiceConversationService();
    _ttsService.configureCloudTtsSession(
      sessionToken: const String.fromEnvironment(
        'ELEVENLABS_SESSION_TOKEN',
        defaultValue: 'local-demo-session',
      ),
    );
    _ttsService.setCloudProcessingEnabled(
      const bool.fromEnvironment('ECHO_DEMO_CLOUD_TTS', defaultValue: false),
    );

    // Initialize voice recognition with hotword detection
    _voiceRecognition = VoiceRecognitionService(
      safetyPhrase: _safetyPhrase,
      minConfidence: 0.75,
    );
    _voiceCommandRouter = VoiceCommandRouter(
      ttsService: _ttsService,
      onTriggerAlert: () async => _triggerSOS(),
      onCancelAlert: () async => _cancelSOS(),
      onShareLocation: (entities) async =>
          debugPrint('📍 Share location intent: $entities'),
      onCallContact: (entities) async =>
          debugPrint('📞 Call contact intent: $entities'),
      onSetMode: (entities) async =>
          debugPrint('🛠️ Set mode intent: $entities'),
    );

    _initializeVoiceRecognition();
    _initializeVoiceCapture();
  }

  /// Initialize voice recognition and start listening
  Future<void> _initializeVoiceRecognition() async {
    if (kIsWeb) {
      debugPrint(
        'ℹ️ Web demo mode: continuous hotword listening is disabled to avoid Chrome SpeechRecognition restart loops.',
      );
      return;
    }

    final initialized = await _voiceRecognition.initialize(
      onActivation: _handleVoiceActivation,
    );
    if (initialized && _bgListening && mounted) {
      await _voiceRecognition.startListening();
      debugPrint(
        '✅ Voice recognition initialized and listening for "$_safetyPhrase"',
      );
    } else if (!initialized && mounted) {
      debugPrint(
        '⚠️ Voice recognition initialization failed; hotword will be unavailable',
      );
    }
  }

  Future<void> _initializeVoiceCapture() async {
    final recorderReady = await _audioRecorderService.initialize();
    await _speechTranscriptionService.initialize();
    if (!recorderReady && mounted) {
      debugPrint(
        '⚠️ Voice capture unavailable; voice SOS will fall back to direct SOS flow',
      );
    }
  }

  /// Handle voice hotword activation (same flow as manual SOS)
  Future<void> _handleVoiceActivation(VoiceActivationEvent event) async {
    debugPrint(
      '🎤 Voice hotword detected: "${event.phraseDetected}" (confidence: ${(event.confidence * 100).toStringAsFixed(0)}%)',
    );
    await _voiceCommandRouter.parseAndDispatch(event.phraseDetected);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _holdCtrl.dispose();
    _sosTimer?.cancel();
    _elapsedTimer?.cancel();
    _voiceTimer?.cancel();
    _voiceLimitTimer?.cancel();
    unawaited(_audioRecorderService.dispose());
    unawaited(_voiceDictationService.dispose());
    _speechTranscriptionService.dispose();
    _voiceConversationService.dispose();
    unawaited(_ttsService.stop());
    _voiceRecognition.dispose();
    super.dispose();
  }

  void _onSOSDown(PointerEvent e) {
    if (_mode == _EchoMode.active) return;
    HapticFeedback.heavyImpact();
    _holdCtrl
      ..reset()
      ..forward();
    setState(() {
      _mode = _EchoMode.countdown;
      _sosCountdown = 3;
    });
    _sosTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_sosCountdown > 1) {
        setState(() => _sosCountdown--);
      } else {
        timer.cancel();
        _triggerSOS();
      }
    });
  }

  void _onSOSUp(PointerEvent e) {
    if (_mode != _EchoMode.countdown) return;
    _sosTimer?.cancel();
    _holdCtrl.reset();
    setState(() {
      _mode = _EchoMode.standby;
      _sosCountdown = 1;
    });
  }

  void _triggerSOS({Map<String, dynamic>? voiceAnalysis}) async {
    HapticFeedback.heavyImpact();
    _holdCtrl.reset();

    setState(() {
      _mode = _EchoMode.active;
      _elapsed = 0;
    });

    // Phase 1 Update: Skip threat analysis result screen
    // Go directly to emergency-active screen
    // Voice analysis will be processed post-incident, not before escalation
    final result = await Navigator.pushNamed(
      context,
      '/emergency-active',
      arguments: voiceAnalysis,
    );

    if (result == true) {
      _cancelSOS();
    }
  }

  void _cancelSOS() {
    _elapsedTimer?.cancel();
    HapticFeedback.mediumImpact();
    setState(() {
      _mode = _EchoMode.standby;
      _elapsed = 0;
    });
  }

  Future<void> _startVoice(PointerEvent e) async {
    if (_mode == _EchoMode.thinking || _mode == _EchoMode.speaking) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _mode = _EchoMode.voice;
      _voiceLevel = 0;
    });
    _voiceTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) {
        setState(() => _voiceLevel = 0.15 + Random().nextDouble() * 0.85);
      }
    });

    try {
      final recorderReady = await _audioRecorderService.initialize();
      if (!recorderReady) {
        debugPrint(
          '⚠️ Voice recorder is not ready; proceeding without audio capture',
        );
        return;
      }

      await _audioRecorderService.startRecording();
      await _voiceDictationService.start();
      _voiceLimitTimer?.cancel();
      _voiceLimitTimer = Timer(const Duration(seconds: 30), () {
        if (mounted && _mode == _EchoMode.voice) {
          unawaited(_endVoice(const PointerCancelEvent()));
        }
      });
      debugPrint('🎙️ Voice recording started');
    } catch (e) {
      debugPrint('⚠️ Unable to start voice recording: $e');
    }
  }

  Future<void> _endVoice(PointerEvent e) async {
    _voiceTimer?.cancel();
    _voiceLimitTimer?.cancel();

    if (_mode == _EchoMode.voice) {
      Map<String, dynamic>? voiceAnalysis;

      try {
        if (mounted) {
          setState(() {
            _mode = _EchoMode.thinking;
            _voiceLevel = 0.45;
          });
        }
        await _audioRecorderService.stopRecording();
        final transcript = await _voiceDictationService.stop();
        final audio = _audioRecorderService.buffer.getAudio(
          maxDuration: const Duration(seconds: 30),
        );

        if (transcript.isNotEmpty) {
          voiceAnalysis = await _voiceConversationService.analyzeTranscript(
            transcript,
          );
          debugPrint('Voice transcript analysis: $voiceAnalysis');
        } else if (_enableSlowAudioFallback && audio.isNotEmpty) {
          final analysis = await _speechTranscriptionService.transcribeAndAnalyse(
            audioData: audio,
            sampleRateHz: AudioBuffer.sampleRateHz,
            context: const {
              'source': 'home_voice_sos',
              'gemma_audio_prompt':
                  'This is Echo emergency audio from a user holding the SOS voice control. Listen for distress, unsafe surroundings, spoken requests, or silence. Return concise JSON with transcript, summary, threatLevel, confidence, and action.',
            },
          );
          voiceAnalysis = analysis.toMap();
          debugPrint('📊 Voice audio analysis: ${analysis.toString()}');
        } else {
          voiceAnalysis = {
            'transcript': '',
            'summary': 'I did not catch that clearly. Please try again.',
            'reply': 'I did not catch that clearly. Please try again.',
            'threatLevel': 'unknown',
            'confidence': 0,
            'action': 'Ask the user to try again',
          };
        }
      } catch (e) {
        debugPrint('⚠️ Voice analysis failed, continuing SOS flow: $e');
      }

      if (voiceAnalysis == null) {
        if (mounted) setState(() => _mode = _EchoMode.standby);
        return;
      }

      final decision = VoiceConversationDecision.fromAnalysis(voiceAnalysis);
      if (decision.shouldEscalate) {
        await _ttsService.speak(decision.responseText);
        _triggerSOS(voiceAnalysis: voiceAnalysis);
      } else {
        if (mounted) {
          setState(() {
            _mode = _EchoMode.speaking;
            _voiceLevel = 0.8;
          });
        }
        await _ttsService.speak(decision.responseText);
        if (mounted) {
          setState(() {
            _mode = _EchoMode.standby;
            _voiceLevel = 0;
          });
        }
      }
    }

    if (mounted && _mode != _EchoMode.active) {
      setState(() => _voiceLevel = 0);
    }
  }

  String _fmtElapsed() {
    final m = (_elapsed ~/ 60).toString().padLeft(2, '0');
    final s = (_elapsed % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Widget _buildSOSButton() {
    final isActive = _mode == _EchoMode.active;
    final isCountdown = _mode == _EchoMode.countdown;
    final isVoice = _mode == _EchoMode.voice;
    final isThinking = _mode == _EchoMode.thinking;
    final isSpeaking = _mode == _EchoMode.speaking;
    final isSoundwaveActive =
        isActive || isCountdown || isVoice || isThinking || isSpeaking;

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnim, _holdAnim]),
      builder: (_, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer pulse ring
            if (!isActive)
              Transform.scale(
                scale: isCountdown ? 1.0 : _pulseAnim.value,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          (isCountdown
                                  ? const Color(0xFFFFB020)
                                  : const Color(0xFFE85D3F))
                              .withOpacity(0.35),
                      width: 2,
                    ),
                  ),
                ),
              ),
            // Active emergency ring
            if (isActive)
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: EchoColors.switchOn.withOpacity(0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: EchoColors.switchOff.withOpacity(0.25),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
            // Hold progress ring
            if (isCountdown)
              SizedBox(
                width: 196,
                height: 196,
                child: CircularProgressIndicator(
                  value: _holdAnim.value,
                  strokeWidth: 4,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation(
                    EchoColors.secondaryLight,
                  ),
                ),
              ),
            // Main SOS circle — Listener for instant hold detection
            Listener(
              onPointerDown: isActive ? null : _onSOSDown,
              onPointerUp: isActive ? null : _onSOSUp,
              onPointerCancel: isActive ? null : _onSOSUp,
              child: GestureDetector(
                onTap: isActive
                    ? () => Navigator.pushNamed(context, '/emergency-active')
                    : _triggerSOS,
                child: EchoSoundwaveOrb(
                  size: 174,
                  isActive: isSoundwaveActive,
                  accentColor: isCountdown
                      ? const Color(0xFFFFB020)
                      : isActive
                      ? EchoColors.switchOn
                      : EchoColors.secondaryLight,
                  semanticLabel: isActive
                      ? 'SOS active'
                      : isCountdown
                      ? 'Release to cancel SOS'
                      : isVoice
                      ? 'Echo is listening'
                      : isThinking
                      ? 'Echo is thinking'
                      : isSpeaking
                      ? 'Echo is speaking'
                      : 'Hold to send SOS',
                  isButton: true,
                  overlay: Center(child: _buildSOSLabel()),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSOSLabel() {
    final isActive = _mode == _EchoMode.active;
    final isCountdown = _mode == _EchoMode.countdown;
    final isVoice = _mode == _EchoMode.voice;
    final isThinking = _mode == _EchoMode.thinking;
    final isSpeaking = _mode == _EchoMode.speaking;
    if (isActive) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.mic,
            color: Colors.white,
            size: 27,
            semanticLabel: 'SOS Active',
          ),
          const SizedBox(height: 18),
        ],
      );
    }
    if (isCountdown) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'SENDING IN',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
              letterSpacing: 1.5,
            ),
          ),
          Text(
            '$_sosCountdown',
            style: GoogleFonts.poppins(
              fontSize: 56,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            'release to cancel',
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      );
    }
    if (isVoice || isThinking || isSpeaking) {
      return Icon(
        isThinking
            ? Icons.psychology_alt_outlined
            : isSpeaking
            ? Icons.graphic_eq_rounded
            : Icons.mic,
        color: Colors.white,
        size: 42,
        semanticLabel: isThinking
            ? 'Echo is thinking'
            : isSpeaking
            ? 'Echo is speaking'
            : 'Echo is listening',
      );
    }
    return Icon(
      Icons.mic,
      color: Colors.white,
      size: 44,
      semanticLabel: 'Hold to SOS',
    );
  }

  Widget _buildVoiceSOS() {
    final isVoice = _mode == _EchoMode.voice;
    final isThinking = _mode == _EchoMode.thinking;
    final isSpeaking = _mode == _EchoMode.speaking;
    final isBusy = isVoice || isThinking || isSpeaking;
    final statusText = isVoice
        ? 'Listening... release to ask Echo'
        : isThinking
        ? 'Echo is thinking...'
        : isSpeaking
        ? 'Echo is speaking...'
        : 'Hold to talk with Echo';
    final helperText = isVoice
        ? 'Max 30 seconds'
        : isThinking
        ? 'Emergency tools remain active'
        : isSpeaking
        ? 'Listen for guidance'
        : 'Ask a safety question or request help';
    return Listener(
      onPointerDown: _startVoice,
      onPointerUp: _endVoice,
      onPointerCancel: _endVoice,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1E3A8A).withOpacity(0.5),
              const Color(0xFF1E3A8A).withOpacity(0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isBusy
                ? const Color(0xFF2563EB).withOpacity(0.8)
                : Colors.white12,
            width: isBusy ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
            if (isBusy)
              BoxShadow(
                color: const Color(0xFF2563EB).withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isBusy ? const Color(0xFF2563EB) : Colors.white12,
                boxShadow: isBusy
                    ? [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withOpacity(0.5),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                isThinking
                    ? Icons.psychology_alt_outlined
                    : isSpeaking
                    ? Icons.graphic_eq_rounded
                    : isVoice
                    ? Icons.mic
                    : Icons.mic_none_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: isBusy
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: EchoColors.secondaryLight,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              statusText,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _buildWaveform(),
                        const SizedBox(height: 4),
                        Text(
                          helperText,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.white.withOpacity(0.72),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Talk to Echo',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          helperText,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
            ),
            if (!isBusy)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'HOLD',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
            if (isVoice)
              Text(
                'Release\nto send',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaveform() {
    return Row(
      children: List.generate(28, (i) {
        final threshold = i / 28;
        final active = _voiceLevel > threshold;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          margin: const EdgeInsets.symmetric(horizontal: 1),
          width: 3,
          height: active ? 6 + (_voiceLevel * 20) : 5,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white24,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  Widget _buildListeningCard() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _bgListening = !_bgListening);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1E3A8A).withOpacity(0.5),
              const Color(0xFF1E3A8A).withOpacity(0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _bgListening
                ? EchoColors.switchOn.withOpacity(0.35)
                : EchoColors.secondaryLight.withOpacity(0.35),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _bgListening
                        ? EchoColors.switchOn
                        : EchoColors.secondaryLight,
                    boxShadow: [
                      BoxShadow(
                        color: (_bgListening
                            ? EchoColors.switchOn
                            : EchoColors.secondaryLight),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Background Listening',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _bgListening
                  ? 'Active — Gemma is listening'
                  : 'Inactive — Tap to enable',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: _bgListening
                    ? EchoColors.switchOn.withOpacity(0.15)
                    : EchoColors.secondary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _bgListening
                      ? EchoColors.switchOn.withOpacity(0.4)
                      : EchoColors.secondary.withOpacity(0.4),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _bgListening ? Icons.mic_off_rounded : Icons.mic_rounded,
                    size: 18,
                    color: _bgListening
                        ? const Color.fromARGB(255, 110, 152, 241)
                        : EchoColors.secondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _bgListening ? 'Turn Off Listening' : 'Enable Listening',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _bgListening
                          ? const Color.fromARGB(255, 210, 223, 250)
                          : const Color.fromARGB(255, 223, 215, 250),
                    ),
                  ),
                ],
              ),
            ),
            if (!_bgListening) ...[
              const SizedBox(height: 10),
              Text(
                '⚠ You can still trigger SOS manually or via hold.',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: const Color.fromARGB(255, 208, 191, 247),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInnerCircle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Inner Circle',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () =>
                  Navigator.pushNamed(context, '/tier1-inner-circle-setup'),
              child: Text(
                'Manage',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: EchoColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ..._contacts.map((c) => _buildContactChip(c)),
              _buildAddContact(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactChip(_Contact c) {
    return Padding(
      padding: const EdgeInsets.only(right: 18),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: EchoColors.primary.withOpacity(0.15),
                  border: Border.all(
                    color: EchoColors.primary.withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    c.initial,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: EchoColors.primary,
                    border: Border.all(
                      color: const Color(0xFF02091A),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${c.tier}',
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            c.name,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildAddContact() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/contacts'),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 1.5),
            ),
            child: const Center(
              child: Icon(Icons.add, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final isActive = _mode == _EchoMode.active;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A).withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? EchoColors.primaryLight.withOpacity(0.3)
              : Colors.white12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? EchoColors.secondaryLight
                      : EchoColors.switchOn,
                  boxShadow: [
                    BoxShadow(
                      color:
                          (isActive
                                  ? EchoColors.secondaryLight
                                  : EchoColors.switchOn)
                              .withOpacity(0.6),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isActive ? 'Emergency Active' : 'Protected · Standby',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isActive
                      ? EchoColors.secondaryLight
                      : EchoColors.switchOn,
                ),
              ),
              const Spacer(),
              if (isActive)
                Text(
                  _fmtElapsed(),
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.white),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _statusRow(
            Icons.mic_rounded,
            'Recording surroundings',
            isActive || _bgListening,
          ),
          _statusRow(
            Icons.location_on_outlined,
            'Location shared with circle',
            isActive,
          ),
          _statusRow(
            Icons.psychology_outlined,
            'Analyzing with Gemma AI',
            isActive,
          ),
          _statusRow(
            Icons.public,
            'Public escalation',
            isActive && _elapsed > 120,
          ),
        ],
      ),
    );
  }

  Widget _statusRow(IconData icon, String label, bool active) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: active ? Colors.white : Colors.white.withOpacity(0.4),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: active ? Colors.white : Colors.white.withOpacity(0.4),
            ),
          ),
          const Spacer(),
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active
                  ? EchoColors.switchOn
                  : Colors.white.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCards() {
    return Row(
      children: [
        Expanded(
          child: _actionCard(
            Icons.group_add_outlined,
            'Contacts',
            () => Navigator.pushNamed(context, '/contacts'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _actionCard(
            Icons.smart_toy_outlined,
            'Gemmas Intel',
            () => Navigator.pushNamed(context, '/ai-intel'),
          ),
        ),
      ],
    );
  }

  Widget _actionCard(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1E3A8A).withOpacity(0.5),
              const Color(0xFF1E3A8A).withOpacity(0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: EchoColors.primary, size: 32),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _mode == _EchoMode.active;
    final isCountdown = _mode == _EchoMode.countdown;

    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.5),
              radius: 1.3,
              colors: [Color(0xFF0F3169), Color(0xFF02091A)],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // ── Top bar ──
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 10),
                        Image.asset(
                          'assets/icon/echosplashicon.png',
                          width: 70,
                          height: 70,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.wifi_tethering,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Spacer(),
                        // Listening badge
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _bgListening
                                ? EchoColors.switchOn.withOpacity(0.15)
                                : Colors.white12,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _bgListening
                                  ? EchoColors.switchOn.withOpacity(0.4)
                                  : Colors.white24,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _bgListening
                                      ? EchoColors.switchOn
                                      : Colors.white38,
                                  boxShadow: _bgListening
                                      ? [
                                          BoxShadow(
                                            color: EchoColors.switchOn
                                                .withOpacity(0.6),
                                            blurRadius: 6,
                                            spreadRadius: 1,
                                          ),
                                        ]
                                      : [],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _bgListening ? 'Listening' : 'Paused',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _bgListening
                                      ? EchoColors.switchOn
                                      : Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/notifications'),
                          icon: Stack(
                            children: [
                              const Icon(
                                Icons.notifications_none_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                              Positioned(
                                right: 2,
                                top: 2,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF2563EB),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/settings'),
                          icon: const Icon(
                            Icons.settings_outlined,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/profile'),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white24,
                                width: 1.5,
                              ),
                            ),
                            child: const CircleAvatar(
                              backgroundColor: Color(0xFF1E3A8A),
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Main Content ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        _buildSOSButton(),
                        const SizedBox(height: 16),
                        Text(
                          isActive
                              ? 'SOS Active — contacts & emergency services notified'
                              : isCountdown
                              ? 'Release to cancel'
                              : 'Hold 1 second to send SOS',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.white,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 28),
                        _buildVoiceSOS(),
                        const SizedBox(height: 20),
                        _buildListeningCard(),
                        const SizedBox(height: 20),
                        _buildActionCards(),
                        const SizedBox(height: 28),
                        _buildInnerCircle(),
                        const SizedBox(height: 28),
                        Text(
                          'Echo Status',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildStatusCard(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Comprehensive Tutorial Layer ──
        if (_showTutorial)
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: Container(
                color: Colors.black.withOpacity(0.4),
                child: Stack(
                  children: [
                    if (_tutorialStep == 1)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            bottom: 120,
                            left: 24,
                            right: 24,
                          ),
                          child: TutorialOverlay(
                            step: 1,
                            totalSteps: 5,
                            title: 'Trigger 1: Manual SOS',
                            description:
                                'Hold the center SOS button for 3 seconds. The countdown gives you a moment to cancel if it was an accident.',
                            onNext: () => setState(() => _tutorialStep = 2),
                            onSkip: () => setState(() => _showTutorial = false),
                          ),
                        ),
                      ),
                    if (_tutorialStep == 2)
                      Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            top: 100,
                            left: 40,
                            right: 24,
                          ),
                          child: TutorialOverlay(
                            step: 2,
                            totalSteps: 5,
                            title: 'Trigger 2: Silent SOS',
                            description:
                                'Rapidly press the Volume Down button 3 times to trigger a silent SOS. Discreet and effective.',
                            onNext: () => setState(() => _tutorialStep = 3),
                            onSkip: () => setState(() => _showTutorial = false),
                          ),
                        ),
                      ),
                    if (_tutorialStep == 3)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 24, right: 40),
                          child: TutorialOverlay(
                            step: 3,
                            totalSteps: 5,
                            title: 'Trigger 3: Gemma AI',
                            description:
                                'Gemma triggers automatically if she detects distress sounds or sudden falls while you’re in danger.',
                            onNext: () => setState(() => _tutorialStep = 4),
                            onSkip: () => setState(() => _showTutorial = false),
                          ),
                        ),
                      ),
                    if (_tutorialStep == 4)
                      Align(
                        alignment: Alignment.topLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            top: 120,
                            left: 24,
                            right: 40,
                          ),
                          child: TutorialOverlay(
                            step: 4,
                            totalSteps: 5,
                            title: 'The "Ditto" Code',
                            description:
                                'Enter "DITTO" instead of your PIN to silently signal duress while appearing to disable the app.',
                            onNext: () => setState(() => _tutorialStep = 5),
                            onSkip: () => setState(() => _showTutorial = false),
                          ),
                        ),
                      ),
                    if (_tutorialStep == 5)
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            bottom: 100,
                            left: 40,
                            right: 24,
                          ),
                          child: TutorialOverlay(
                            step: 5,
                            totalSteps: 5,
                            title: 'Your Network',

                            description:
                                'Check the Feed for nearby alerts. You are now protected by the Echo community.',
                            onNext: () => setState(() => _showTutorial = false),
                            onSkip: () => setState(() => _showTutorial = false),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
