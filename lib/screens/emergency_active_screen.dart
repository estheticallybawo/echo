import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../providers/escalation_provider.dart';
import '../providers/gemma_provider.dart';
import '../services/local_storage_service.dart';
import '../services/sound/confirmation_sound_service.dart';
import '../services/sound/tts_service.dart';

class EmergencyActiveScreen extends StatefulWidget {
  const EmergencyActiveScreen({super.key});

  @override
  State<EmergencyActiveScreen> createState() => _EmergencyActiveScreenState();
}

class _EmergencyActiveScreenState extends State<EmergencyActiveScreen> with SingleTickerProviderStateMixin {
  String _displayText = '';
  final String _fullText = 'User location: Confirmed.\nRecording: Active (audio + metadata).\nProximity alerts: 3 contacts notified.\nPolice dispatch: Queued for operator.\nReal-time analysis: Assessing environment audio for threat patterns...';
  Timer? _typewriterTimer;
  double _emotionLevel = 0.45;
  Timer? _fluctuationTimer;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  final LocalStorageService _localStorage = LocalStorageService();
  
  List<Map<String, dynamic>> _contacts = [];
  bool _contactsLoaded = false;
  String? _summaryText;
  bool _summaryVisible = false;
  int _contactAttemptsShown = 0;

  List<String> _safetyInstructions = [];
  bool _instructionsLoaded = false;
  final ConfirmationSoundService _confirmationSoundService = ConfirmationSoundService();
  final TTSService _ttsService = TTSService();

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    
    _startTypewriter();
    _startFluctuation();
    _loadSafetyInstructions();
    _loadContacts();

    // Play diversion message immediately on emergency start
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final gemmaProvider = Provider.of<GemmaProvider>(context, listen: false);
      try {
        final diversion = await gemmaProvider.getDiversionMessage();
        await _ttsService.speak(diversion);
      } catch (e) {
        debugPrint('❌ Failed to generate diversion message: $e');
        // Fallback message
        await _ttsService.speak('Alert: Authorities have been notified. This location is being tracked.');
      }
    });
  }

  Future<void> _loadContacts() async {
    final userId = _localStorage.getCurrentUserUid() ?? 'demo-hiny';
    final contacts = _localStorage.getContacts(userId);
    if (mounted) {
      setState(() {
        _contacts = contacts;
        _contactsLoaded = true;
      });
    }
  }

  void _buildSummary(EscalationProvider escalation) {
    final incident = escalation.currentIncident;
    if (incident == null) return;

    final threatLabel = incident.threatType.isEmpty ? 'unknown situation' : incident.threatType;
    final contactNames = _contacts.isEmpty
        ? 'Mom, Sister'
        : _contacts.take(3).map((contact) => contact['name']?.toString() ?? 'Contact').join(', ');

    _summaryText = 'Hiny triggered an emergency for $threatLabel. '
        'Echo escalated through Tier 1 to Tier 3, attempted contact with $contactNames, '
        'and recorded safety instructions for the incident summary.';
  }

  Widget _buildContactAttemptsCard(List<Map<String, dynamic>> attemptedContacts, int seconds, int currentTier, bool isResolved) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A).withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.contacts_outlined, color: Color(0xFF00C48C), size: 20),
              const SizedBox(width: 8),
              Text('Contact Attempts', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Status flow: queued → sent → no response → escalated',
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.white38),
          ),
          const SizedBox(height: 12),
          if (!_contactsLoaded)
            Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.4)),
                ),
              ),
            )
          else if (_contacts.isEmpty)
            Text(
              'No local contacts yet. Add one from Home to show real escalation attempts.',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.white54),
            )
          else
            Column(
              children: _contacts.asMap().entries.map((entry) {
                final index = entry.key;
                final contact = entry.value;
                final statusLabel = escalationStatusLabel(index, seconds, currentTier, isResolved);
                final attempted = statusLabel != 'queued';
                final statusColor = statusLabel == 'queued'
                    ? Colors.white38
                    : statusLabel == 'sent'
                        ? const Color(0xFF00C48C)
                        : statusLabel == 'no response'
                            ? const Color(0xFFFFB020)
                            : const Color(0xFFFF4D4D);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: attempted ? statusColor.withOpacity(0.12) : Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: attempted ? statusColor.withOpacity(0.3) : Colors.white.withOpacity(0.05)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: attempted ? statusColor.withOpacity(0.2) : EchoColors.primary.withOpacity(0.18),
                          ),
                          child: Icon(
                            statusLabel == 'queued'
                                ? Icons.schedule_rounded
                                : statusLabel == 'sent'
                                    ? Icons.check_rounded
                                    : statusLabel == 'no response'
                                        ? Icons.hourglass_bottom_rounded
                                        : Icons.trending_up_rounded,
                            color: attempted ? statusColor : Colors.white54,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                contact['name']?.toString() ?? 'Contact',
                                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                              Text(
                                contact['phoneNumber']?.toString() ?? 'Phone hidden',
                                style: GoogleFonts.poppins(fontSize: 12, color: Colors.white54),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          statusLabel,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  String escalationStatusLabel(int index, int seconds, int currentTier, bool isResolved) {
    final sendAtSecond = 5 + (index * 8);

    if (seconds < sendAtSecond) {
      return 'queued';
    }

    if (seconds < 60) {
      return 'sent';
    }

    if (seconds < 90) {
      return 'no response';
    }

    if (currentTier >= 3 || isResolved) {
      return 'escalated';
    }

    return 'no response';
  }

  Widget _buildIncidentSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF00C48C).withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF00C48C).withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.summarize_outlined, color: Color(0xFF00C48C), size: 20),
              const SizedBox(width: 8),
              Text('Incident Summary', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _summaryText ?? 'Emergency resolved and stored locally for Hiny.',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70, height: 1.6),
          ),
          const SizedBox(height: 12),
          Text(
            'Saved locally on-device for offline review.',
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  /// Load safety instructions from Gemma provider
  Future<void> _loadSafetyInstructions() async {
    try {
      final gemmaProvider = context.read<GemmaProvider>();
      final instructions = await gemmaProvider.getSafetyInstructions();
      if (mounted) {
        setState(() {
          _safetyInstructions = instructions;
          _instructionsLoaded = true;
        });
        print('✅ Safety instructions loaded: ${instructions.length} items');
        if (instructions.isNotEmpty) {
          unawaited(_ttsService.speak('Echo is active. Your location locked. Audio is being recorded. Offline mode fully enabled ${instructions.join('. ')}'));
        }
      }
    } catch (e) {
      print('⚠️ Failed to load safety instructions: $e');
      if (mounted) {
        setState(() {
          _safetyInstructions = ['Stay calm', 'Help is on the way'];
          _instructionsLoaded = true;
        });
      }
    }
  }

  void _startFluctuation() {
    _fluctuationTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (mounted) {
        setState(() {
          _emotionLevel = (0.4 + (0.1 * (DateTime.now().millisecond / 1000))).clamp(0.0, 1.0);
        });
      }
    });
  }

  void _startTypewriter() {
    int i = 0;
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (i < _fullText.length) {
        if (mounted) setState(() => _displayText += _fullText[i]);
        i++;
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
    _fluctuationTimer?.cancel();
    _pulseCtrl.dispose();
    unawaited(_ttsService.stop());
    super.dispose();
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EscalationProvider>(
      builder: (context, escalation, child) {
        final incident = escalation.currentIncident;
        final isResolved = incident?.isResolved ?? false;
        final seconds = escalation.elapsedSeconds;
        final showSummary = isResolved || _summaryVisible;
        final attemptedContacts = _contacts.isEmpty
            ? const <Map<String, dynamic>>[]
            : _contacts.take((seconds / 10).ceil().clamp(0, _contacts.length)).toList();

        if (_contactAttemptsShown != attemptedContacts.length) {
          _contactAttemptsShown = attemptedContacts.length;
        }

        if (!showSummary && escalation.currentTier >= 3 && _summaryText == null) {
          _buildSummary(escalation);
        }

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
                  const SizedBox(height: 10),
                  Text(
                    isResolved ? 'Emergency Resolved' : 'Emergency Active',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          if (showSummary)
                            _buildResolvedHeader(escalation)
                          else ...[

                            _buildTimerCircle(seconds),
                            const SizedBox(height: 32),
                            

                            _buildEmotionCard(),
                            const SizedBox(height: 24),

                            _buildContactAttemptsCard(attemptedContacts, seconds, escalation.currentTier, isResolved),
                            const SizedBox(height: 24),
                            
                            // Safety instructions
                            _buildSafetyInstructionsCard(),
                            const SizedBox(height: 24),
                            

                            _buildStatusRow(Icons.mic_rounded, 'Audio Recording', 'ACTIVE', EchoColors.switchOn),
                            _buildStatusRow(Icons.location_on_outlined, 'Location', 'LOCKED', const Color(0xFF2563EB)),
                            _buildStatusRow(Icons.notifications_active_outlined, 'Alerts Sent', '3 CONTACTS', const Color(0xFF2563EB)),
                            _buildStatusRow(Icons.phone_in_talk_outlined, 'Police Dispatch', 'PENDING', const Color(0xFFFFA500)),
                          ],
                          
                          const SizedBox(height: 32),
                          

                          _buildEscalationCard(escalation),
                          const SizedBox(height: 24),
                          
                          if (!showSummary) ...[

                            _buildAnalysisCard(),
                            const SizedBox(height: 24),
                            

                            if (escalation.currentTier >= 3)
                              _buildAlertPostedCard(),
                            
                            const SizedBox(height: 40),
                            

                            _buildActionButtons(context, escalation),
                          ] else ...[
                            const SizedBox(height: 40),
                            _buildIncidentSummaryCard(),
                            const SizedBox(height: 24),
                            _buildResolvedActions(context, escalation),
                          ],
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResolvedHeader(EscalationProvider escalation) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF00C48C).withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF00C48C).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF00C48C), size: 64),
          const SizedBox(height: 16),
          Text(
            'RESOLVED',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF00C48C),
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Total Duration: ${_formatTime(escalation.elapsedSeconds)}',
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            '1,250+ people notified · 23 responders',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerCircle(int seconds) {
    return ScaleTransition(
      scale: _pulseAnim,
      child: Container(
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFFFA500).withOpacity(0.3), width: 8),
          boxShadow: [
            BoxShadow(color: const Color(0xFFFFA500).withOpacity(0.2), blurRadius: 40, spreadRadius: 5),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: Colors.orangeAccent, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'RECORDING',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFFFA500),
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(seconds),
                style: GoogleFonts.poppins(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFFFA500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmotionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.show_chart_rounded, color: Color(0xFF2563EB), size: 20),
                  const SizedBox(width: 8),
                  Text('Emotion Level', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                ],
              ),
              Text('${(_emotionLevel * 100).toInt()}%', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: const Color(0xFF2563EB))),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _emotionLevel,
              minHeight: 12,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0891B2)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(IconData icon, String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A).withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color.withOpacity(0.8)),
          const SizedBox(width: 16),
          Text(label, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white)),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Build safety instructions card
  Widget _buildSafetyInstructionsCard() {
    if (!_instructionsLoaded) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E3A8A).withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.5)),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            EchoColors.primary.withOpacity(0.2),
            EchoColors.primary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EchoColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outlined, color: EchoColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Safety Instructions',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._safetyInstructions.asMap().entries.map((entry) {
            final index = entry.key + 1;
            final instruction = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: EchoColors.primary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '$index',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: EchoColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      instruction,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEscalationCard(EscalationProvider escalation) {
    final seconds = escalation.elapsedSeconds;
    final currentTier = escalation.currentTier;
    final isResolved = escalation.currentIncident?.isResolved ?? false;

    String t1Status = 'STANDBY';
    String t2Status = 'STANDBY';
    String t3Status = 'STANDBY';
    
    double progress = 0;
    String countdownText = '';
    Color progressColor = const Color(0xFF2563EB);

    if (currentTier == 0) {
      t1Status = 'STANDBY';
      countdownText = '${5 - seconds}s until Tier 1';
      progress = seconds / 5;
    } else if (currentTier == 1) {
      t1Status = 'ACTIVE';
      countdownText = '${60 - seconds}s until Tier 2';
      progress = (seconds - 5) / 55;
      progressColor = const Color(0xFF00C48C);
    } else if (currentTier == 2) {
      t1Status = 'COMPLETED';
      t2Status = 'ACTIVE';
      countdownText = '${90 - seconds}s until Tier 3';
      progress = (seconds - 60) / 30;
      progressColor = const Color(0xFFFFB020);
    } else {
      t1Status = 'COMPLETED';
      t2Status = 'COMPLETED';
      t3Status = isResolved ? 'COMPLETED' : 'POSTED';
      countdownText = isResolved ? 'Emergency Resolved' : 'Incident Public';
      progress = 1.0;
      progressColor = isResolved ? const Color(0xFF00C48C) : const Color(0xFFFF4D4D);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A).withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.groups_outlined, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Text('Escalation Status', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 20),
          _tierItem('TIER 1', '3 contacts notified', t1Status, currentTier >= 1, statusColor: t1Status == 'ACTIVE' ? const Color(0xFF00C48C) : null),
          if (currentTier >= 1 && !isResolved) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(width: 48),
                const Icon(Icons.bar_chart_rounded, color: Colors.white30, size: 14),
                const SizedBox(width: 6),
                Text(currentTier == 2 ? '1 of 3 replied' : 'Waiting for responses', style: GoogleFonts.poppins(fontSize: 11, color: Colors.white30)),
              ],
            ),
          ],
          const SizedBox(height: 12),
          _tierItem('TIER 2', '5-10 extended contacts', t2Status, currentTier >= 2, statusColor: t2Status == 'ACTIVE' ? const Color(0xFFFFB020) : null),
          const SizedBox(height: 12),
          _tierItem('TIER 3', 'Echo Community Post', t3Status, currentTier >= 3, statusColor: t3Status == 'POSTED' ? const Color(0xFFFF4D4D) : (t3Status == 'COMPLETED' ? const Color(0xFF00C48C) : null)),
          
          if (!isResolved)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(countdownText, style: GoogleFonts.poppins(fontSize: 12, color: progressColor, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _tierItem(String title, String sub, String status, bool activeOrCompleted, {Color? statusColor}) {
    final isCompleted = status == 'COMPLETED';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: activeOrCompleted ? const Color(0xFF2563EB).withOpacity(0.1) : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: activeOrCompleted ? const Color(0xFF2563EB).withOpacity(0.3) : Colors.transparent),
      ),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : (activeOrCompleted ? Icons.radio_button_checked : Icons.circle_outlined),
            color: activeOrCompleted ? (isCompleted ? const Color(0xFF00C48C) : const Color(0xFF2563EB)) : Colors.white30,
            size: 20,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
              Text(sub, style: GoogleFonts.poppins(fontSize: 12, color: Colors.white54)),
            ],
          ),
          const Spacer(),
          Text(
            status,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: statusColor ?? (isCompleted ? const Color(0xFF00C48C) : (activeOrCompleted ? EchoColors.switchOn : Colors.white30)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A).withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.smart_toy_outlined, color: Color(0xFF0891B2), size: 20),
              const SizedBox(width: 8),
              Text('Gemma 4 Analysis', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _displayText,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white.withOpacity(0.9), height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertPostedCard() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EchoColors.switchOn.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EchoColors.switchOn.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF00C48C), size: 20),
              const SizedBox(width: 8),
              Text('Emergency Alert Posted', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.notification_important_rounded, color: Colors.orangeAccent, size: 18),
                    const SizedBox(width: 8),
                    Text('EMERGENCY ALERT', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.orangeAccent)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Posted to SMS and Echo Feed • Emergency services notified • Help needed',
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, EscalationProvider escalation) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildButton(
                'CANCEL',
                Icons.close,
                Colors.white.withOpacity(0.1),
                Colors.white60,
                () => _showCancelDialog(context, escalation),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildButton(
                'I AM SAFE',
                Icons.check_circle_outline,
                const Color(0xFF00C48C).withOpacity(0.2),
                const Color(0xFF00C48C),
                () => _showSafeDialog(context, escalation),
              ),
            ),
          ],
        ),
        if (escalation.currentTier >= 3) ...[
          const SizedBox(height: 16),
          _buildButton(
            'GET HELP',
            Icons.diversity_3_outlined,
            const Color(0xFF2563EB),
            Colors.white,
            () {
              HapticFeedback.heavyImpact();
              // Logic to show responders/map
            },
            isFullWidth: true,
          ),
        ],
      ],
    );
  }

  Widget _buildButton(String label, IconData icon, Color bg, Color text, VoidCallback onTap, {bool isFullWidth = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isFullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: text, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: text,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResolvedActions(BuildContext context, EscalationProvider escalation) {
    return Column(
      children: [
        _buildButton(
          'SAVE TO LIBRARY',
          Icons.bookmark_outline_rounded,
          const Color(0xFF2563EB),
          Colors.white,
          () {
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Incident saved to library')),
            );
          },
          isFullWidth: true,
        ),
        const SizedBox(height: 16),
        _buildButton(
          'BACK TO HOME',
          Icons.home_outlined,
          Colors.white.withOpacity(0.05),
          Colors.white60,
          () {
            escalation.stopEscalation();
            Navigator.pop(context, true);
          },
          isFullWidth: true,
        ),
      ],
    );
  }

  void _showSafeDialog(BuildContext context, EscalationProvider escalation) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Are you safe?', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('Confirming your safety will resolve this emergency and notify your contacts.', style: GoogleFonts.poppins(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Still in danger', style: GoogleFonts.poppins(color: const Color(0xFFFF0000), fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              unawaited(_ttsService.stop());  // Stop any ongoing TTS first
              unawaited(_confirmationSoundService.confirmContactAction());
              unawaited(_ttsService.speak('Emergency situation resolved. Stay safe and contact support if needed.'));
              escalation.resolveEmergency();
              setState(() {
                _summaryVisible = true;
                _summaryText ??= 'Hiny marked herself safe. Echo recorded the incident locally and stopped escalation.';
              });
            },
            child: Text('I am safe', style: GoogleFonts.poppins(color: const Color(0xFF00C48C), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, EscalationProvider escalation) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Cancel Emergency?', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('Are you sure? Recording and alerts will stop.', style: GoogleFonts.poppins(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Keep Recording', style: GoogleFonts.poppins(color: const Color(0xFF0891B2), fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              unawaited(_ttsService.stop());  // Stop any ongoing TTS first
              unawaited(_ttsService.speak('Emergency alert cancelled. If you need help, trigger Echo again.'));
              escalation.stopEscalation();
              Navigator.pop(context, true); // return to home
            },
            child: Text('Cancel Emergency', style: GoogleFonts.poppins(color: const Color(0xFFFF0000), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
