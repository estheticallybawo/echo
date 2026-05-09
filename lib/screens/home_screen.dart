import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
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

enum _EchoMode { standby, countdown, active, voice }

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
  double _voiceLevel = 0.0;
  String _displayName = 'Hiny';

  Timer? _sosTimer;
  Timer? _elapsedTimer;
  Timer? _voiceTimer;

  late AnimationController _pulseCtrl;
  late AnimationController _holdCtrl;
  late Animation<double> _pulseAnim;
  late Animation<double> _holdAnim;

  late VoiceRecognitionService _voiceRecognition;
  late final AudioRecorderService _audioRecorderService;
  late final SpeechTranscriptionService _speechTranscriptionService;
  final TTSService _ttsService = TTSService();
  static const String _safetyPhrase = 'echo help now';

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
      minConfidence: 0.60,  // Lowered from 0.75 to make triggering easier
    );
    _initializeVoiceRecognition();
    _initializeVoiceCapture();
    _loadDemoUserAndContacts();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gemmaProvider = context.read<GemmaProvider>();
      gemmaProvider.verifyModelHealth();
    });
  }

  Future<void> _loadDemoUserAndContacts() async {
    final currentUser = _localStorage.getCurrentUser();
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
      onActivation: (event) {
        if (!mounted) return;
        _triggerSOS();
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

  Future<void> _initializeVoiceCapture() async {
    await _audioRecorderService.initialize();
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
        _triggerSOS();
      }
    });
  }

  void _onSOSUp(PointerEvent e) {
    if (_mode != _EchoMode.countdown) return;
    _sosTimer?.cancel();
    _holdCtrl.reset();
    setState(() { _mode = _EchoMode.standby; _sosCountdown = 1; });
  }

  void _triggerSOS({Map<String, dynamic>? voiceAnalysis}) async {
    HapticFeedback.heavyImpact();
    _holdCtrl.reset();
    
    setState(() { _mode = _EchoMode.active; _elapsed = 0; });

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
    setState(() { _mode = _EchoMode.standby; _elapsed = 0; });
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
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
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
                  SnackBar(content: Text('$name added to Hiny\'s inner circle')),
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


  Future<void> _startVoice(PointerEvent e) async {
    HapticFeedback.mediumImpact();
    setState(() { _mode = _EchoMode.voice; _voiceLevel = 0; });
    _voiceTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) setState(() => _voiceLevel = 0.15 + Random().nextDouble() * 0.85);
    });

    try {
      final recorderReady = await _audioRecorderService.initialize();
      if (!recorderReady) {
        print('⚠️ Voice recorder is not ready; proceeding without audio capture');
        return;
      }

      await _audioRecorderService.startRecording();
      print('🎙️ Voice recording started');
    } catch (e) {
      print('⚠️ Unable to start voice recording: $e');
    }
  }

  Future<void> _endVoice(PointerEvent e) async {
    _voiceTimer?.cancel();

    if (_mode == _EchoMode.voice) {
      Map<String, dynamic>? voiceAnalysis;

      try {
        await _audioRecorderService.stopRecording();
        final audio = _audioRecorderService.buffer.getAudio(
          maxDuration: const Duration(seconds: 5),
        );

        if (audio.isNotEmpty) {
          final analysis = await _speechTranscriptionService.transcribeAndAnalyse(
            audioData: audio,
            sampleRateHz: AudioBuffer.sampleRateHz,
            context: const {'source': 'home_voice_sos'},
          );
          voiceAnalysis = analysis.toMap();
          print('📊 Voice audio analysis: ${analysis.toString()}');
        }
      } catch (e) {
        print('⚠️ Voice analysis failed, continuing SOS flow: $e');
      }

      _triggerSOS(voiceAnalysis: voiceAnalysis);
    }

    setState(() => _voiceLevel = 0);
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
                      color: (isCountdown
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
                  valueColor: const AlwaysStoppedAnimation(EchoColors.secondaryLight),
                ),
              ),
            // Main SOS circle — Listener for instant hold detection
            Listener(
              onPointerDown: isActive ? null : _onSOSDown,
              onPointerUp: isActive ? null : _onSOSUp,
              onPointerCancel: isActive ? null : _onSOSUp,
              child: GestureDetector(
                onTap: isActive ? () => Navigator.pushNamed(context, '/emergency-active') : _triggerSOS,
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
                        color: (isActive
                                ? EchoColors.primaryLight
                                : EchoColors.secondaryLight)
                            .withOpacity(0.55),
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
      Icon(Icons.mic, color: Colors.white, size: 27, semanticLabel: 'SOS Active',),
          const SizedBox(height: 18),]
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
    return Icon(Icons.mic, color: Colors.white, size: 44, semanticLabel: 'Hold to SOS',);
  }

  Widget _buildVoiceSOS() {
    final isVoice = _mode == _EchoMode.voice;
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
            color: isVoice ? const Color(0xFF2563EB).withOpacity(0.8) : Colors.white12,
            width: isVoice ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
            if (isVoice) BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.4), blurRadius: 20, spreadRadius: 2),
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
                color: isVoice ? const Color(0xFF2563EB) : Colors.white12,
                boxShadow: isVoice
                    ? [BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.5), blurRadius: 12, spreadRadius: 2)]
                    : [],
              ),
              child: Icon(
                isVoice ? Icons.mic : Icons.mic_none_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: isVoice
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 7, height: 7,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: EchoColors.secondaryLight,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text('Recording...', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF2563EB))),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _buildWaveform(),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Voice SOS', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                        Text('Hold & say you\'re in danger', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white.withOpacity(0.9))),
                      ],
                    ),
            ),
            if (!isVoice)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('HOLD', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1)),
              ),
            if (isVoice)
              Text('Release\nto send', textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 10, color: Colors.white, height: 1.3)),
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
      onTap: () async {
        HapticFeedback.lightImpact();
        final wasListening = _bgListening;
        setState(() => _bgListening = !_bgListening);
        
        if (_bgListening && !wasListening) {
          // Start listening
          await _voiceRecognition.startListening();
        } else if (!_bgListening && wasListening) {
          // Stop listening
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
            color: _bgListening
                ? EchoColors.switchOn.withOpacity(0.35)
                : EchoColors.secondaryLight.withOpacity(0.35),
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
                      BoxShadow(
                        color: (_bgListening ? EchoColors.switchOn : EchoColors.secondaryLight),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Background Listening',
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _bgListening ? 'Active — Gemma is listening' : 'Inactive — Tap to enable',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.white.withOpacity(0.9)),
            ),
            const SizedBox(height: 4),
            Text(
              _getVoiceStatusText(),
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.white.withOpacity(0.7)),
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
                    color: _bgListening ? const Color.fromARGB(255, 110, 152, 241) : EchoColors.secondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _bgListening ? 'Turn Off Listening' : 'Enable Listening',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _bgListening ? const Color.fromARGB(255, 210, 223, 250) : const Color.fromARGB(255, 223, 215, 250),
                    ),
                  ),
                ],
              ),
            ),
            if (!_bgListening) ...[
              const SizedBox(height: 10),
              Text(
                '⚠ You can still trigger SOS manually or via hold.',
                style: GoogleFonts.poppins(fontSize: 11, color: const Color.fromARGB(255, 208, 191, 247)),
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
            Text('Inner Circle', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/tier1-inner-circle-setup'),
              child: Text('Manage', style: GoogleFonts.poppins(fontSize: 12, color: EchoColors.primary, fontWeight: FontWeight.w500)),
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

  Widget _buildAddContact() {
    return GestureDetector(
      onTap: _showAddContactDialog,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 1.5),
            ),
            child: const Center(child: Icon(Icons.add, color: Colors.white, size: 24)),
          ),
          const SizedBox(height: 6),
          Text('Add', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white.withOpacity(0.8))),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final isActive = _mode == _EchoMode.active;
    final gemmaProvider = context.watch<GemmaProvider>();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A).withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? EchoColors.primaryLight.withOpacity(0.3) : Colors.white12,
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
                  color: isActive ? EchoColors.secondaryLight : EchoColors.switchOn,
                  boxShadow: [
                    BoxShadow(
                      color: (isActive ? EchoColors.secondaryLight : EchoColors.switchOn).withOpacity(0.6),
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
                  color: isActive ? EchoColors.secondaryLight : EchoColors.switchOn,
                ),
              ),
              const Spacer(),
              if (isActive) Text(_fmtElapsed(), style: GoogleFonts.poppins(fontSize: 13, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 14),
          _statusRow(Icons.mic_rounded, 'Recording surroundings', isActive || _bgListening),
          _statusRow(Icons.location_on_outlined, 'Location shared with circle', isActive),
          _statusRow(Icons.psychology_outlined, 'Analyzing with Gemma AI', isActive),
          _statusRow(Icons.public, 'Public escalation', isActive && _elapsed > 120),
          const SizedBox(height: 12),
          _statusRowText(
            Icons.memory_rounded,
            'Gemma Status',
            gemmaProvider.isCheckingModel
                ? 'Checking...'
                : gemmaProvider.modelHealthMessage,
            gemmaProvider.isModelHealthy ? Colors.greenAccent : Colors.amberAccent,
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: gemmaProvider.isCheckingModel ? null : () => gemmaProvider.verifyModelHealth(),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: gemmaProvider.isCheckingModel ? Colors.white12 : EchoColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                gemmaProvider.isCheckingModel ? 'Checking model...' : 'Verify Gemma Status',
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ),
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
              child: const Center(
                child: Icon(Icons.history_rounded, color: Color(0xFF2563EB), size: 24),
              ),
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




  Widget _statusRowText(IconData icon, String title, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Image.asset('assets/icon/gemma-color.png', width: 40, height: 40),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor),
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
            'AI Intel',
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
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
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
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Safety profile active',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.white60,
                              ),
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
                          border: Border.all(
                            color: _bgListening ? EchoColors.switchOn.withOpacity(0.4) : Colors.white24,
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
                                color: _bgListening ? EchoColors.switchOn : Colors.white38,
                                boxShadow: _bgListening
                                    ? [BoxShadow(color: EchoColors.switchOn.withOpacity(0.6), blurRadius: 6, spreadRadius: 1)]
                                    : [],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _bgListening ? 'Listening' : 'Paused',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _bgListening ? EchoColors.switchOn : Colors.white54,
                              ),
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
                                : 'Hold 1 second to send SOS',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(fontSize: 13, color: Colors.white, height: 1.4),
                      ),
                      const SizedBox(height: 28),
                      _buildListeningCard(),
                      const SizedBox(height: 20),
                      _buildInnerCircle(),
                      const SizedBox(height: 28),
                      _buildIncidentHistoryCard(),
                      const SizedBox(height: 28),
                      Text(
                        'Echo Status',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
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
    );
  }
}
