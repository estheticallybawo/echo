import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/escalation_provider.dart';
import '../../theme.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/escalation_provider.dart';
import '../../providers/gemma_provider.dart';
import '../../services/sound/confirmation_sound_service.dart';
import '../../services/sound/tts_service.dart';
import '../../theme.dart';

class ThreatAnalysisResultScreen extends StatefulWidget {
  const ThreatAnalysisResultScreen({super.key});

  @override
  State<ThreatAnalysisResultScreen> createState() => _ThreatAnalysisResultScreenState();
}

class _ThreatAnalysisResultScreenState extends State<ThreatAnalysisResultScreen> {
  final TTSService _ttsService = TTSService();
  final ConfirmationSoundService _confirmationSoundService = ConfirmationSoundService();
  Map<String, dynamic>? _voiceAnalysis;
  bool _hasAnnouncedSummary = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments;
    if (_voiceAnalysis == null && args is Map) {
      _voiceAnalysis = Map<String, dynamic>.from(args as Map);
    }

    if (!_hasAnnouncedSummary) {
      _hasAnnouncedSummary = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _announceSummary();
      });
    }
  }

  Future<void> _announceSummary() async {
    final summary = _buildSpokenSummary();
    if (summary.isNotEmpty) {
      await _ttsService.speak(summary);
    }
  }

  Map<String, dynamic> _analysisFor(GemmaProvider gemma) {
    if (gemma.lastThreatAssessment != null) {
      return gemma.lastThreatAssessment!;
    }
    if (_voiceAnalysis != null) {
      return _voiceAnalysis!;
    }
    return const {
      'threat': 'Voice distress',
      'confidence': 0.75,
      'threatLevel': 'HIGH',
      'summary': 'Voice input suggests distress. Continue with emergency flow.',
    };
  }

  String _analysisLabel(Map<String, dynamic> analysis) {
    return (analysis['threat'] ?? analysis['emotional_state'] ?? 'Voice distress').toString();
  }

  String _analysisLevel(Map<String, dynamic> analysis) {
    final level = analysis['threatLevel'] ?? analysis['distress_level'] ?? 'HIGH';
    return level.toString().toUpperCase();
  }

  int _analysisConfidence(Map<String, dynamic> analysis) {
    final confidence = (analysis['confidence'] as num?)?.toDouble() ?? 0.0;
    if (confidence <= 1.0) {
      return (confidence * 100).round();
    }
    return confidence.round();
  }

  String _analysisSummary(Map<String, dynamic> analysis) {
    return (analysis['summary'] ?? analysis['audio_description'] ?? 'Emergency response flow ready.').toString();
  }

  String _buildSpokenSummary() {
    final analysis = _voiceAnalysis;
    if (analysis == null) {
      return 'Threat analysis screen opened. No voice analysis data was attached.';
    }

    final label = _analysisLabel(analysis);
    final level = _analysisLevel(analysis);
    final confidence = _analysisConfidence(analysis);
    return 'Voice analysis complete. $label detected with $confidence percent confidence. Threat level $level. ${_analysisSummary(analysis)}';
  }

  Future<void> _startEscalation(BuildContext context, Map<String, dynamic> analysis) async {
    await _confirmationSoundService.confirmTierCompletion(1);

    final escalation = Provider.of<EscalationProvider>(context, listen: false);
    escalation.startEscalation(
      userId: 'user_123',
      threatType: _analysisLabel(analysis),
      confidence: (_analysisConfidence(analysis) / 100).clamp(0.0, 1.0),
    );

    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, '/emergency-active');
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GemmaProvider>(
      builder: (context, gemma, child) {
        final analysis = _analysisFor(gemma);
        final label = _analysisLabel(analysis);
        final level = _analysisLevel(analysis);
        final confidence = _analysisConfidence(analysis);
        final summary = _analysisSummary(analysis);

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
              const SizedBox(height: 20),
              Text(
                'Threat Analysis Result',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Analysis by LlamaThreatService',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white60,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAnalysisCard(label, level, confidence, summary),
                      const SizedBox(height: 32),
                      Text(
                        'Escalation Timeline',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTimeline(),
                      const SizedBox(height: 40),
                      _buildConfirmButton(context, analysis),
                      const SizedBox(height: 16),
                      _buildCancelButton(context),
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

  Widget _buildAnalysisCard(String label, String level, int confidence, String summary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_outlined, color: Color(0xFF2563EB), size: 24),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: EchoColors.secondaryLight.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: EchoColors.secondaryLight.withOpacity(0.5)),
                ),
                child: Text(
                  level,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: EchoColors.secondaryLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            summary,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF00C48C), size: 16),
              const SizedBox(width: 8),
              Text('Confidence: $confidence%', style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    return Column(
      children: [
        _timelineItem(
          'T+5s',
          'Tier 1: Inner Circle',
          'SMS & Push sent to 3 emergency contacts.',
          const Color(0xFF00C48C),
          true,
        ),
        _timelineItem(
          'T+60s',
          'Tier 2: Extended Network',
          'Alerting 5-10 extended community members.',
          const Color(0xFFFFB020),
          false,
        ),
        _timelineItem(
          'T+90s',
          'Tier 3: Echo Community',
          'Public post to Echo Feed with live location.',
          const Color(0xFFFF4D4D),
          false,
          isLast: true,
        ),
      ],
    );
  }

  Widget _timelineItem(String time, String title, String sub, Color color, bool active, {bool isLast = false}) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [
                    BoxShadow(color: color.withOpacity(0.4), blurRadius: 6, spreadRadius: 1),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.white10,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      time,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  sub,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton(BuildContext context, Map<String, dynamic> analysis) {
    return GestureDetector(
      onTap: () async {
        await _startEscalation(context, analysis);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [EchoColors.primaryLight, EchoColors.primaryDark],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: EchoColors.primaryLight.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                'CONFIRM & START',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCancelButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Center(
          child: Text(
            'CANCEL',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white60,
            ),
          ),
        ),
      ),
    );
  }
}
