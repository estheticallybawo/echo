// ignore_for_file: unnecessary_to_list_in_spreads

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import '../theme.dart';
import '../models/community_feed_model.dart';
import '../widgets/community_feed_section.dart';
import '../services/llama_threat_service.dart';
import '../services/audio_record_service.dart';
import '../services/speech_transcription_service.dart';
import '../services/voice_recognition_service.dart';
import 'emergency_active_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _orbController;
  late AnimationController _pulseController;
  bool isListening = true; // Track listening state
  bool _isAudioStackReady = false;
  bool _isBusyTogglingListening = false;
  bool _isHandlingVoiceActivation = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AudioRecorderService _audioRecorder = AudioRecorderService();
  final SpeechTranscriptionService _speechTranscriber =
      SpeechTranscriptionService();
  late VoiceRecognitionService _voiceRecognition;
  static const String _fallbackSafetyPhrase = 'echo help now';

  @override
  void initState() {
    super.initState();
    
    // Orb animation - smooth continuous rotation
    _orbController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
    
    // Pulse animation - subtle breathing
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);

    _voiceRecognition = VoiceRecognitionService(
      safetyPhrase: _fallbackSafetyPhrase,
    );

    _initializeAudioStack();
  }

  Future<void> _initializeAudioStack() async {
    final recorderReady = await _audioRecorder.initialize();
    final recognizerReady = await _voiceRecognition.initialize(
      onActivation: _handleVoiceActivation,
    );

    if (!mounted) return;

    setState(() {
      _isAudioStackReady = recorderReady && recognizerReady;
    });

    if (_isAudioStackReady && isListening) {
      await _enableBackgroundListening(showFeedback: false);
    }
  }

  Future<void> _handleVoiceActivation(VoiceActivationEvent event) async {
    if (_isHandlingVoiceActivation || !mounted) return;
    _isHandlingVoiceActivation = true;

    await _voiceRecognition.pauseListening();

    try {
      final audioData = _audioRecorder.buffer.getAudio(
        maxDuration: const Duration(seconds: 10),
      );

      final transcription = await _speechTranscriber.transcribeAndAnalyse(
        audioData: audioData,
        sampleRateHz: AudioBuffer.sampleRateHz,
        context: {'activation_phrase': event.phraseDetected},
      );

      if (!mounted) return;

      final threatAnalysis = {
        'threat': transcription.distressLevel.name,
        'confidence': (transcription.confidence * 100).clamp(0, 100),
        'threatLevel': transcription.distressLevel.name,
        'summary': transcription.audioDescription,
      };

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Safety phrase detected (${event.phraseDetected}). Emergency activated.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => EmergencyActiveScreen(
            threatAnalysis: threatAnalysis,
            emergencyDescription: 'Voice activation trigger',
            userLocation: 'Current Location',
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Voice activation failed: $error')),
        );
      }
    } finally {
      _isHandlingVoiceActivation = false;
      if (mounted && isListening) {
        await _voiceRecognition.resumeListening();
      }
    }
  }

  Future<void> _enableBackgroundListening({bool showFeedback = true}) async {
    if (!_isAudioStackReady || _isBusyTogglingListening) return;

    setState(() {
      _isBusyTogglingListening = true;
    });

    try {
      await _audioRecorder.startRecording();
      if (_voiceRecognition.status == VoiceRecognitionStatus.paused) {
        await _voiceRecognition.resumeListening();
      } else {
        await _voiceRecognition.startListening();
      }

      if (!mounted) return;
      setState(() {
        isListening = true;
      });

      if (showFeedback) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Background listening enabled. Audio monitoring is active.',
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not enable listening: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBusyTogglingListening = false;
        });
      }
    }
  }

  Future<void> _disableBackgroundListening({bool showFeedback = true}) async {
    if (!_isAudioStackReady || _isBusyTogglingListening) return;

    setState(() {
      _isBusyTogglingListening = true;
    });

    try {
      await _voiceRecognition.pauseListening();
      await _audioRecorder.stopRecording();

      if (!mounted) return;
      setState(() {
        isListening = false;
      });

      if (showFeedback) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Background listening disabled.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not disable listening: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBusyTogglingListening = false;
        });
      }
    }
  }

  Future<void> _toggleBackgroundListening() async {
    if (!_isAudioStackReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Audio stack is still initializing. Please try again in a moment.',
          ),
        ),
      );
      return;
    }

    if (isListening) {
      await _disableBackgroundListening();
    } else {
      await _enableBackgroundListening();
    }
  }

  @override
  void dispose() {
    _orbController.dispose();
    _pulseController.dispose();
    _voiceRecognition.dispose();
    _audioRecorder.dispose();
    _speechTranscriber.dispose();
    super.dispose();
  }

  /// Convert Firestore document to CommunityFeedEntry
  CommunityFeedEntry _documentToCommunityFeedEntry(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    
    return CommunityFeedEntry(
      id: doc.id,
      victimName: data['userName'] ?? 'Unknown User',
      victimId: data['userId'] ?? 'unknown',
      location: data['location'] ?? 'Unknown Location',
      state: data['state'] ?? 'Unknown State',
      country: data['country'] ?? 'Nigeria',
      triggeredAt: timestamp,
      hashTag: data['hashtag'] ?? '#echo',
      shareCount: data['shareCount'] ?? 0,
      userAmplified: false,
      status: data['status'] ?? 'active',
      gemmaAssessment: data['gemmaAssessment'] ?? 'Assessment in progress...',
      retweetCount: data['retweetCount'] as int? ?? 0,
      impressions: data['impressions'] as int? ?? 0,
    );
  }

  /// Build Community Feed with Real-time Firestore listener
  Widget _buildCommunityFeedSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('communityFeed')
          .where('status', isEqualTo: 'active')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('Error loading feed: ${snapshot.error}'),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(
                    'Loading community feed...',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          );
        }

        final feedEntries = snapshot.data?.docs ?? [];
        
        // Convert Firestore docs to CommunityFeedEntry objects
        final communityFeed = feedEntries
            .map((doc) => _documentToCommunityFeedEntry(doc))
            .toList();

        return CommunityFeedSection(
          feedEntries: communityFeed,
          onRefresh: () {
            // Real-time listener will auto-update, but allow manual refresh too
            setState(() {});
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Echo'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).pushNamed('/ai-settings');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            children: [
              // Glowing Orb - Primary CTA
              _buildGlowingOrb(),
              const SizedBox(height: 24),
              
              // Background Listening Status Card
              _buildListeningStatusCard(),
              const SizedBox(height: 48),
              
              // Feature Cards Grid (2x2)
              _buildFeatureCardGrid(),
              const SizedBox(height: 32),
              
              // Priority Contacts Row
              _buildPriorityContacts(),
              const SizedBox(height: 48),
              
              // Echo Feed Section - Real-time from Firestore
              _buildCommunityFeedSection(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Glowing Orb - Main attraction
  Widget _buildGlowingOrb() {
    return GestureDetector(
      onTap: () {
        _showEmergencyDescriptionDialog();
      },
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final scale = 1.0 + (_pulseController.value * 0.05);
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: EchoColors.primary.withOpacity(0.3),
                blurRadius: 40,
                spreadRadius: 15,
              ),
              BoxShadow(
                color: EchoColors.secondaryLight.withOpacity(0.15),
                blurRadius: 60,
                spreadRadius: 20,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Animated orb painter
              RotationTransition(
                turns: _orbController,
                child: CustomPaint(
                  painter: _OrbPainter(),
                  size: const Size(180, 180),
                ),
              ),
              
              // Center listening indicator
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.mic,
                    size: 40,
                    color: const Color.fromARGB(255, 183, 236, 250),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'TAP',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: const Color.fromARGB(255, 120, 218, 243),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Background Listening Status Card - Control and Status
  Widget _buildListeningStatusCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isListening ? EchoColors.primary.withOpacity(0.08) : EchoColors.warning.withOpacity(0.08),
        border: Border.all(
          color: isListening ? EchoColors.primary.withOpacity(0.3) : EchoColors.warning.withOpacity(0.3),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status indicator
            Row(
              children: [
                // Status Indicator Light
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isListening ? EchoColors.success : EchoColors.warning,
                    boxShadow: [
                      if (isListening)
                        BoxShadow(
                          color: EchoColors.success.withOpacity(0.6),
                          blurRadius: 8,
                          spreadRadius: 2,
                        )
                      else
                        BoxShadow(
                          color: EchoColors.warning.withOpacity(0.6),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Status Label
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Background Listening',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: EchoColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isListening ? 'Active - Gemma is listening' : 'Inactive - Tap to enable',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: EchoColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Toggle Button - Click to change state
            GestureDetector(
              onTap: () {
                _toggleBackgroundListening();
              },
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: isListening ? EchoColors.primary : EchoColors.warning,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isListening ? EchoColors.primary : EchoColors.warning,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isBusyTogglingListening
                          ? Icons.sync
                          : isListening
                          ? Icons.mic
                          : Icons.mic_off,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isBusyTogglingListening
                          ? 'Updating...'
                          : isListening
                          ? 'Turn Off Listening'
                          : 'Enable Background Listening',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Info text - Changes based on state
            Text(
              isListening 
                ? 'Gemma is ready to listen for voice prompts. Disable when you\'re in a safe location.'
                : 'Enable listening before entering an unfamiliar or unsafe area so Gemma can respond to your voice commands.',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: EchoColors.textTertiary,
                height: 1.5,
              ),
            ),
            
            // Extra info when listening is OFF
            if (!isListening) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: EchoColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: EchoColors.warning.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: EchoColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Listening is OFF. You can still use all features manually.',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: EchoColors.warning,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Feature Cards Grid - 2x2 layout (May 17 MVP only - no deferred features)
  Widget _buildFeatureCardGrid() {
    final features = [
      {
        'icon': Icons.person_add_outlined,
        'label': 'Contacts',
        'route': '/contacts',
      },
      {
        'icon': Icons.smart_toy_outlined,
        'label': 'AI Intel',
        'route': '/ai-intel',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return GestureDetector(
          onTap: () {
            Navigator.of(context).pushNamed(feature['route'] as String);
          },
          child: Container(
            decoration: BoxDecoration(
              color: EchoColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: EchoColors.primary.withOpacity(0.1),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  feature['icon'] as IconData,
                  size: 32,
                  color: EchoColors.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  feature['label'] as String,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: EchoColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Priority Contacts Row
  Widget _buildPriorityContacts() {
    final contacts = [
      {'name': 'Mom', 'icon': '👤'},
      {'name': 'Sister', 'icon': '👥'},
      {'name': 'Friend', 'icon': '👤'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Inner Circle',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...contacts.map((contact) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushNamed('/contacts');
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: EchoColors.surfaceSecondary,
                            border: Border.all(
                              color: EchoColors.primary.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              contact['icon'] as String,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          contact['name'] as String,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: EchoColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              // Add contact button
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pushNamed('/contacts');
                },
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: EchoColors.surfaceTertiary,
                        border: Border.all(
                          color: EchoColors.primary.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.add,
                          color: EchoColors.primary,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: EchoColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Show dialog to capture emergency description
  void _showEmergencyDescriptionDialog() {
    final parentContext = context;
    final TextEditingController descriptionController = TextEditingController();
    final gemmaService = LlamaThreatService();
    bool isAnalyzing = false;

    showDialog(
      context: parentContext,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, dialogSetState) => AlertDialog(
          title: const Text('Describe Your Emergency'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What\'s happening? Be specific - this helps Gemma assess the threat accurately.',
                  style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                    color: EchoColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  maxLines: 5,
                  enabled: !isAnalyzing,
                  decoration: InputDecoration(
                    hintText: 'E.g., "I\'m being forced into a car by two men"',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: EchoColors.surfaceSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                if (isAnalyzing)
                  Center(
                    child: Column(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 12),
                        Text(
                          'Gemma is analyzing...',
                          style: Theme.of(dialogContext).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            if (!isAnalyzing)
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
            if (!isAnalyzing)
              ElevatedButton(
                onPressed: () async {
                  if (descriptionController.text.isEmpty) {
                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      const SnackBar(content: Text('Please describe the emergency')),
                    );
                    return;
                  }

                  dialogSetState(() => isAnalyzing = true);

                  try {
                    // Call Gemma threat assessment
                    final threatAnalysis =
                        await gemmaService.analyzeThreat(descriptionController.text);

                    if (!parentContext.mounted || !dialogContext.mounted) {
                      return;
                    }

                    Navigator.pop(dialogContext);
                    // Navigate to emergency screen with the analysis data
                    // **PHASE 3A: PASS DESCRIPTION TO EMERGENCY SCREEN FOR AUTO-POSTING**
                    _voiceRecognition.pauseListening();
                    Navigator.of(parentContext)
                        .push(
                        MaterialPageRoute(
                          builder: (context) =>
                              EmergencyActiveScreen(
                                threatAnalysis: threatAnalysis,
                                emergencyDescription: descriptionController.text,
                                userLocation: 'Current Location', // TODO: Get actual GPS location
                              ),
                        ),
                      )
                        .then((_) {
                      if (parentContext.mounted && isListening) {
                        _voiceRecognition.resumeListening();
                      }
                    });
                  } catch (e) {
                    if (!parentContext.mounted) return;
                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                    dialogSetState(() => isAnalyzing = false);
                  }
                },
                child: const Text('Send Emergency'),
              ),
          ],
        ),
      ),
    );
  }
}

/// Custom Painter for Glowing Orb
class _OrbPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width / 2;

    // Outer glow layer 1
    final glowPaint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          EchoColors.primary.withOpacity(0.6),
          EchoColors.primary.withOpacity(0.2),
          Colors.transparent,
        ],
        stops: const [0.3, 0.7, 1.0],
      ).createShader(
        Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
      );

    canvas.drawCircle(Offset(centerX, centerY), radius, glowPaint1);

    // Main orb gradient
    final orbPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          EchoColors.primaryLight.withOpacity(0.8),
          EchoColors.primary,
          EchoColors.primaryDark,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(
        Rect.fromCircle(
          center: Offset(centerX, centerY),
          radius: radius * 0.85,
        ),
      );

    canvas.drawCircle(Offset(centerX, centerY), radius * 0.85, orbPaint);

    // Secondary color accent (swirl effect)
    final swirl = Paint()
      ..color = EchoColors.secondaryLight.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw subtle arc
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(centerX, centerY),
        radius: radius * 0.6,
      ),
      0,
      math.pi * 1.5,
      false,
      swirl,
    );

    // Highlight
    final highlightPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.4),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ).createShader(
        Rect.fromCircle(
          center: Offset(centerX * 0.7, centerY * 0.7),
          radius: radius * 0.3,
        ),
      );

    canvas.drawCircle(
      Offset(centerX * 0.7, centerY * 0.7),
      radius * 0.3,
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(_OrbPainter oldDelegate) => false;
}
