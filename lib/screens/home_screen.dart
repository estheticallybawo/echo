import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/gemma_provider.dart';
import '../theme.dart';
import '../services/local_storage_service.dart';
import '../services/sound/audio_record_service.dart';
import '../services/sound/speech_transcription_service.dart';
import '../services/sound/voice_recognition_service.dart';
import '../services/sound/tts_service.dart';

enum _EchoMode { standby, countdown, active }

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
  final LocalStorageService _localStorage = LocalStorageService();
  final TextEditingController _contactNameController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  bool _bgListening = true;
  VoiceRecognitionStatus _voiceStatus = VoiceRecognitionStatus.uninitialized;
  _EchoMode _mode = _EchoMode.standby;
  int _sosCountdown = 1;
  int _elapsed = 0;
  final String _displayName = 'Hiny';

  Timer? _sosTimer;
  Timer? _elapsedTimer;

  late AnimationController _pulseCtrl;
  late AnimationController _holdCtrl;
  late Animation<double> _pulseAnim;
  late Animation<double> _holdAnim;

  late VoiceRecognitionService _voiceRecognition;
  late final AudioRecorderService _audioRecorderService;
  late final SpeechTranscriptionService _speechTranscriptionService;
  final TTSService _ttsService = TTSService();
  static const String _safetyPhrase = 'echo help now';
  static const String _introPhrase = 'echo who are you';
  static const String _capabilitiesPhrase = 'echo what can you do'; 

  List<_Contact> _contacts = [];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _holdCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _holdAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _holdCtrl, curve: Curves.linear),
    );
    _audioRecorderService = AudioRecorderService();
    _speechTranscriptionService = SpeechTranscriptionService();

    // Initialize voice recognition with hotword detection
    _voiceRecognition = VoiceRecognitionService(
      safetyPhrase: _safetyPhrase,
      introPhrase: _introPhrase,
      capabilitiesPhrase: _capabilitiesPhrase,
      minConfidence: 0.60,
    );
    _initializeVoiceRecognition();
    _initializeVoiceCapture();
    _loadDemoUserAndContacts();

    // Initialize Gemma provider on startup (silently)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gemmaProvider = context.read<GemmaProvider>();
      if (!gemmaProvider.isInitialized) {
        gemmaProvider.initialize().catchError((e) {
          print('⚠️ Gemma initialization failed: $e');
        });
      }
    });
  }

  Future<void> _loadDemoUserAndContacts() async {
    final userId = _localStorage.getCurrentUserUid() ?? 'demo-hiny';
    final contacts = _localStorage.getContacts(userId);

    final loadedContacts = contacts
        .asMap()
        .entries
        .map((entry) => _Contact(
              entry.value['name']?.toString() ?? 'Contact',
              entry.key + 1,
            ))
        .toList();

    if (!mounted) return;
    setState(() {
      _contacts = loadedContacts;
    });
  }

  Future<void> _initializeVoiceRecognition() async {
    final initialized = await _voiceRecognition.initialize(
      onActivation: (event) async {
        if (!mounted) return;

        if (event.phraseDetected == _introPhrase) {
          await _handleIntroActivation();
          return;
        }

        if (event.phraseDetected == _capabilitiesPhrase) {
          await _handleCapabilitiesActivation();
          return;
        }

        final audio = _audioRecorderService.buffer.getAudio(
          maxDuration: const Duration(seconds: 10),
        );
        final analysis = await _speechTranscriptionService.transcribeAndAnalyse(
          audioData: audio,
          sampleRateHz: 16000,
          context: {
            'phrase': event.phraseDetected,
            'confidence': event.confidence,
          },
        );
        _triggerSOS(voiceAnalysis: analysis.toMap());
      },
      onStatusChange: (status) {
        if (!mounted) return;
        setState(() => _voiceStatus = status);
      },
    );
    if (initialized) {
      setState(() => _voiceStatus = VoiceRecognitionStatus.paused);
      if (_bgListening) {
        await _voiceRecognition.startListening();
        setState(() => _voiceStatus = VoiceRecognitionStatus.listening);
      }
    } else {
      setState(() => _voiceStatus = VoiceRecognitionStatus.error);
    }
  }

  Future<void> _handleIntroActivation() async {
    const String introMessage = 
        "I am Echo, your AI safety guardian. I stay active in the background to protect you. "
        "I can detect distress in your voice, analyze threats using on-device AI, and automatically "
        "escalate alerts to your inner circle and local community. "
        "If you are in danger, say, echo help now, or long press the orb on your screen.";
    
    setState(() => _voiceStatus = VoiceRecognitionStatus.paused);
    await _ttsService.speak(introMessage);
    
    // Resume listening after speaking if background listening is still enabled
    if (_bgListening && mounted) {
      await _voiceRecognition.startListening();
      setState(() => _voiceStatus = VoiceRecognitionStatus.listening);
    }
  }

  Future<void> _handleCapabilitiesActivation() async {
    const String capabilitiesMessage = 
        "I can perform real-time threat assessments, provide step-by-step safety instructions, "
        "and generate authoritative warnings to deter threats. I also manage multi-tier escalations "
        "to notify your inner circle and the local community when you are in danger. "
        "To start an emergency, say: echo help now.";
    
    setState(() => _voiceStatus = VoiceRecognitionStatus.paused);
    await _ttsService.speak(capabilitiesMessage);
    
    // Resume listening after speaking if background listening is still enabled
    if (_bgListening && mounted) {
      await _voiceRecognition.startListening();
      setState(() => _voiceStatus = VoiceRecognitionStatus.listening);
    }
  }

  Future<void> _initializeVoiceCapture() async {
    await _audioRecorderService.initialize();
    await _audioRecorderService.startRecording();
  }

  void _onSOSDown(PointerEvent e) {
    if (_mode == _EchoMode.active) return;
    HapticFeedback.heavyImpact();
    _holdCtrl..reset()..forward();
    setState(() { _mode = _EchoMode.countdown; _sosCountdown = 3; });
    _sosTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_sosCountdown > 1) {
        setState(() => _sosCountdown--);
      } else {
        timer.cancel();
        _manualSOS();
      }
    });
  }

  void _onSOSUp(PointerEvent e) {
    if (_mode != _EchoMode.countdown) return;
    _sosTimer?.cancel();
    _holdCtrl.reset();
    setState(() { _mode = _EchoMode.standby; _sosCountdown = 1; });
  }

  Future<void> _manualSOS() async {
    await _audioRecorderService.stopRecording();
    final audio = _audioRecorderService.buffer.getAudio(
      maxDuration: const Duration(seconds: 10),
    );
    final analysis = await _speechTranscriptionService.transcribeAndAnalyse(
      audioData: audio,
      sampleRateHz: 16000,
      context: {'trigger': 'manual'},
    );
    _triggerSOS(voiceAnalysis: analysis.toMap());
  }

  void _triggerSOS({Map<String, dynamic>? voiceAnalysis}) async {
    HapticFeedback.heavyImpact();
    _holdCtrl.reset();

    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _elapsed++);
    });

    setState(() { _mode = _EchoMode.active; _elapsed = 0; });
    await Navigator.pushNamed(
      context,
      '/emergency-active',
      arguments: voiceAnalysis,
    );
    _cancelSOS();
  }

  Future<void> _cancelSOS() async {
    _elapsedTimer?.cancel();
    HapticFeedback.mediumImpact();
    setState(() { _mode = _EchoMode.standby; _elapsed = 0; });
    await _audioRecorderService.startRecording();
    if (_bgListening) {
      await _voiceRecognition.startListening();
    }
  }

  Future<void> _showAddContactDialog() async {
    _contactNameController.clear();
    _contactPhoneController.clear();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F3169),
          title: Text(
            'Add Emergency Contact',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _contactNameController,
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Contact name',
                  hintStyle: GoogleFonts.poppins(color: Colors.white54),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _contactPhoneController,
                keyboardType: TextInputType.phone,
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Phone number',
                  hintStyle: GoogleFonts.poppins(color: Colors.white54),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = _contactNameController.text.trim();
                final phone = _contactPhoneController.text.trim();
                final messenger = ScaffoldMessenger.of(context);

                if (name.isEmpty || phone.isEmpty) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Enter both a contact name and phone number')),
                  );
                  return;
                }

                final userId = _localStorage.getCurrentUserUid() ?? 'demo-hiny';
                await _localStorage.addContact(
                  userId,
                  name: name,
                  phoneNumber: phone,
                );

                final contacts = _localStorage.getContacts(userId);
                if (!mounted) return;
                setState(() {
                  _contacts = contacts
                      .asMap()
                      .entries
                      .map((entry) => _Contact(
                            entry.value['name']?.toString() ?? 'Contact',
                            entry.key + 1,
                          ))
                      .toList();
                });
                Navigator.of(dialogContext).pop();
                messenger.showSnackBar(
                  SnackBar(content: Text('$name added to your inner circle')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: EchoColors.primary),
              child: Text('Add', style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  String _getVoiceStatusText() {
    switch (_voiceStatus) {
      case VoiceRecognitionStatus.uninitialized:
        return 'Voice recognition: Not initialized';
      case VoiceRecognitionStatus.initializing:
        return 'Voice recognition: Initializing...';
      case VoiceRecognitionStatus.listening:
        return 'Voice recognition: Listening for "echo help now"';
      case VoiceRecognitionStatus.paused:
        return 'Voice recognition: Paused';
      case VoiceRecognitionStatus.error:
        return 'Voice recognition: Error - check permissions';
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

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnim, _holdAnim]),
      builder: (_, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            if (!isActive)
              Transform.scale(
                scale: isCountdown ? 1.0 : _pulseAnim.value,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (isCountdown ? const Color(0xFFFFB020) : const Color(0xFFE85D3F)).withOpacity(0.35),
                      width: 2,
                    ),
                  ),
                ),
              ),
            if (isActive)
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: EchoColors.switchOn.withOpacity(0.5), width: 2),
                  boxShadow: [
                    BoxShadow(color: EchoColors.switchOff.withOpacity(0.25), blurRadius: 40, spreadRadius: 10),
                  ],
                ),
              ),
            if (isCountdown)
              SizedBox(
                width: 196,
                height: 196,
                child: CircularProgressIndicator(
                  value: _holdAnim.value,
                  strokeWidth: 4,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation(EchoColors.secondaryLight),
                ),
              ),
            Listener(
              onPointerDown: isActive ? null : _onSOSDown,
              onPointerUp: isActive ? null : _onSOSUp,
              onPointerCancel: isActive ? null : _onSOSUp,
              child: GestureDetector(
                onTap: isActive ? () => Navigator.pushNamed(context, '/emergency-active') : _manualSOS,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isActive
                          ? [EchoColors.primaryLight, EchoColors.primaryDark]
                          : isCountdown
                              ? [const Color(0xFFFFB020), const Color(0xFFE08000)]
                              : [EchoColors.primaryLight, EchoColors.primaryDark],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isActive ? EchoColors.primaryLight : EchoColors.secondaryLight).withOpacity(0.55),
                        blurRadius: 55,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: Center(child: _buildSOSLabel()),
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
    if (isActive) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.mic, color: Colors.white, size: 27),
          const SizedBox(height: 18),
        ],
      );
    }
    if (isCountdown) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('SENDING IN', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white.withOpacity(0.9), letterSpacing: 1.5)),
          Text('$_sosCountdown', style: GoogleFonts.poppins(fontSize: 56, fontWeight: FontWeight.w800, color: Colors.white)),
          Text('release to cancel', style: GoogleFonts.poppins(fontSize: 10, color: Colors.white.withOpacity(0.8))),
        ],
      );
    }
    return Icon(Icons.mic, color: Colors.white, size: 44);
  }

  Widget _buildListeningCard() {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.lightImpact();
        final wasListening = _bgListening;
        setState(() => _bgListening = !_bgListening);
        if (_bgListening && !wasListening) {
          await _voiceRecognition.startListening();
        } else if (!_bgListening && wasListening) {
          await _voiceRecognition.pauseListening();
        }
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
            color: _bgListening ? EchoColors.switchOn.withOpacity(0.35) : EchoColors.secondaryLight.withOpacity(0.35),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
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
                    color: _bgListening ? EchoColors.switchOn : EchoColors.secondaryLight,
                    boxShadow: [
                      BoxShadow(color: (_bgListening ? EchoColors.switchOn : EchoColors.secondaryLight), blurRadius: 6, spreadRadius: 1),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text('Background Listening', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _bgListening ? 'Active — listening for "echo help now"' : 'Inactive — Tap to enable',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.white.withOpacity(0.9)),
            ),
            const SizedBox(height: 4),
            Text(_getVoiceStatusText(), style: GoogleFonts.poppins(fontSize: 11, color: Colors.white.withOpacity(0.7))),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: _bgListening ? EchoColors.switchOn.withOpacity(0.15) : EchoColors.secondary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _bgListening ? EchoColors.switchOn.withOpacity(0.4) : EchoColors.secondary.withOpacity(0.4),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_bgListening ? Icons.mic_off_rounded : Icons.mic_rounded, size: 18, color: _bgListening ? const Color.fromARGB(255, 110, 152, 241) : EchoColors.secondary),
                  const SizedBox(width: 8),
                  Text(
                    _bgListening ? 'Turn Off Listening' : 'Enable Listening',
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: _bgListening ? const Color.fromARGB(255, 210, 223, 250) : const Color.fromARGB(255, 223, 215, 250)),
                  ),
                ],
              ),
            ),
            if (!_bgListening) ...[
              const SizedBox(height: 10),
              Text('⚠ You can still trigger SOS manually via the orb.', style: GoogleFonts.poppins(fontSize: 11, color: const Color.fromARGB(255, 208, 191, 247))),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAIModeCard() {
    final gemmaProvider = context.watch<GemmaProvider>();
    final isReady = gemmaProvider.isInitialized;
    final errorMsg = gemmaProvider.error;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xB2052C66), const Color(0xB2052C66).withOpacity(0.3)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isReady ? EchoColors.switchOn.withOpacity(0.35) : Colors.white12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
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
                  color: isReady ? EchoColors.switchOn : EchoColors.secondaryLight,
                  boxShadow: [
                    BoxShadow(color: (isReady ? EchoColors.switchOn : EchoColors.secondaryLight), blurRadius: 6, spreadRadius: 1),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text('Gemma AI Status', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isReady ? 'On‑device model ready (offline capable)' : errorMsg != null ? 'Error: $errorMsg' : 'Initializing...',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.white.withOpacity(0.9)),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/model-setup'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: EchoColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: EchoColors.primary.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.download_rounded, size: 18, color: EchoColors.primaryLight),
                        const SizedBox(width: 8),
                        Text('Models', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: EchoColors.primaryLight)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/chat'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: EchoColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: EchoColors.primary.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_rounded, size: 18, color: EchoColors.primary),
                        const SizedBox(width: 8),
                        Text('Chat', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: EchoColors.primary)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInnerCircle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Inner Circle', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            const Spacer(),
            GestureDetector(
              onTap: _showAddContactDialog,
              child: Text('Add Contact', style: GoogleFonts.poppins(fontSize: 12, color: EchoColors.primary, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _contacts.map((c) => _buildContactChip(c)).toList(),
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
                  border: Border.all(color: EchoColors.primary.withOpacity(0.4), width: 1.5),
                ),
                child: Center(
                  child: Text(c.initial, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
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
                    border: Border.all(color: const Color(0xFF02091A), width: 1.5),
                  ),
                  child: Center(
                    child: Text('${c.tier}', style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(c.name, style: GoogleFonts.poppins(fontSize: 12, color: Colors.white)),
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
        border: Border.all(color: isActive ? EchoColors.primaryLight.withOpacity(0.3) : Colors.white12),
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
                  color: isActive ? EchoColors.secondaryLight : EchoColors.switchOn,
                  boxShadow: [
                    BoxShadow(color: (isActive ? EchoColors.secondaryLight : EchoColors.switchOn).withOpacity(0.6), blurRadius: 6, spreadRadius: 1),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isActive ? 'Emergency Active' : 'Protected · Standby',
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: isActive ? EchoColors.secondaryLight : EchoColors.switchOn),
              ),
              const Spacer(),
              if (isActive) Text(_fmtElapsed(), style: GoogleFonts.poppins(fontSize: 13, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 14),
          _statusRow(Icons.mic_rounded, 'Recording surroundings', isActive || _bgListening),
          _statusRow(Icons.location_on_outlined, 'Location shared with circle', isActive),
          _statusRow(Icons.psychology_outlined, 'Gemma AI ready', true),
          _statusRow(Icons.public, 'Public escalation', isActive && _elapsed > 120),
        ],
      ),
    );
  }

  Widget _buildIncidentHistoryCard() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incident library coming soon')),
        );
      },
      child: Container(
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
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2563EB).withOpacity(0.2),
              ),
              child: const Center(child: Icon(Icons.history_rounded, color: Color(0xFF2563EB), size: 24)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Incident History', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('View past analyses and saved incidents', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _statusRow(IconData icon, String label, bool active) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: active ? Colors.white : Colors.white.withOpacity(0.4)),
          const SizedBox(width: 10),
          Text(label, style: GoogleFonts.poppins(fontSize: 13, color: active ? Colors.white : Colors.white.withOpacity(0.4))),
          const Spacer(),
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? EchoColors.switchOn : Colors.white.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _mode == _EchoMode.active;
    final isCountdown = _mode == _EchoMode.countdown;

    return Scaffold(
      body: Container(
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      const SizedBox(width: 10),
                      Image.asset(
                        'assets/icon/echosplashicon.png',
                        width: 70,
                        height: 70,
                        errorBuilder: (_, _, _) => const Icon(Icons.wifi_tethering, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Welcome, $_displayName',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                            Text(
                              'Safety profile active',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(fontSize: 11, color: Colors.white60),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _bgListening ? EchoColors.switchOn.withOpacity(0.15) : Colors.white12,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _bgListening ? EchoColors.switchOn.withOpacity(0.4) : Colors.white24),
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
                                color: _bgListening ? EchoColors.switchOn : Colors.white38,
                                boxShadow: _bgListening ? [BoxShadow(color: EchoColors.switchOn.withOpacity(0.6), blurRadius: 6, spreadRadius: 1)] : [],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _bgListening ? 'Listening' : 'Paused',
                              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: _bgListening ? EchoColors.switchOn : Colors.white54),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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
                                : 'Echo is listening for "echo help now" or you can press the orb to send an SOS immediately',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(fontSize: 13, color: Colors.white, height: 1.4),
                      ),
                      const SizedBox(height: 28),
                      _buildListeningCard(),
                      const SizedBox(height: 20),
                      _buildAIModeCard(),
                      const SizedBox(height: 20),
                      _buildInnerCircle(),
                      const SizedBox(height: 28),
                      _buildIncidentHistoryCard(),
                      const SizedBox(height: 28),
                      Text('Echo Status', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
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
    );
  }
}