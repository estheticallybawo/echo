import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme.dart';

class EmergencyActiveScreen extends StatefulWidget {
  const EmergencyActiveScreen({super.key});

  @override
  State<EmergencyActiveScreen> createState() => _EmergencyActiveScreenState();
}

class _EmergencyActiveScreenState extends State<EmergencyActiveScreen> with SingleTickerProviderStateMixin {
  int _seconds = 0;
  Timer? _timer;
  String _displayText = '';
  final String _fullText = 'User location: Confirmed.\nRecording: Active (audio + metadata).\nProximity alerts: 3 contacts notified.\nPolice dispatch: Queued for operator.\nReal-time analysis: Assessing environment audio for threat patterns...';
  Timer? _typewriterTimer;
  double _emotionLevel = 0.45;
  Timer? _fluctuationTimer;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

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
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _seconds++);
    });
    _startTypewriter();
    _startFluctuation();
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
    _timer?.cancel();
    _typewriterTimer?.cancel();
    _fluctuationTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  String _formatTime() {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
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
              const SizedBox(height: 10),
              Text(
                'Emergency Active',
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
                      // Recording Timer
                      _buildTimerCircle(),
                      const SizedBox(height: 32),
                      
                      // Emotion Level
                      _buildEmotionCard(),
                      const SizedBox(height: 24),
                      
                      // Status Rows
                      _buildStatusRow(Icons.mic_rounded, 'Audio Recording', 'ACTIVE', EchoColors.switchOn),
                      _buildStatusRow(Icons.location_on_outlined, 'Location', 'LOCKED', const Color(0xFF2563EB)),
                      _buildStatusRow(Icons.notifications_active_outlined, 'Alerts Sent', '3 CONTACTS', const Color(0xFF2563EB)),
                      _buildStatusRow(Icons.phone_in_talk_outlined, 'Police Dispatch', 'PENDING', const Color(0xFFFFA500)),
                      
                      const SizedBox(height: 32),
                      
                      // Escalation Status
                      _buildEscalationCard(),
                      const SizedBox(height: 24),
                      
                      // Gemma Analysis
                      _buildAnalysisCard(),
                      const SizedBox(height: 24),
                      
                      // Emergency Alert Posted
                      _buildAlertPostedCard(),
                      const SizedBox(height: 40),
                      
                      // Stop Button
                      _buildStopButton(),
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
  }

  Widget _buildTimerCircle() {
    return ScaleTransition(
      scale: _pulseAnim,
      child: Container(
        width: 200,
        height: 200,
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
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'RECORDING',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFFFA500),
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(),
                style: GoogleFonts.poppins(
                  fontSize: 48,
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
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
          BoxShadow(color: Colors.white.withOpacity(0.05), blurRadius: 1, offset: const Offset(0, -1)),
        ],
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
          const SizedBox(height: 12),
          Text('✓ Monitoring stress levels', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white.withOpacity(0.6))),
        ],
      ),
    );
  }

  Widget _buildStatusRow(IconData icon, String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E3A8A).withOpacity(0.3),
            const Color(0xFF1E3A8A).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
        ],
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

  Widget _buildEscalationCard() {
    String t1Status = 'STANDBY';
    String t2Status = 'STANDBY';
    String t3Status = 'STANDBY';
    bool t1Active = false;
    bool t2Active = false;
    bool t3Active = false;
    
    double progress = 0;
    String countdownText = '';
    Color progressColor = const Color(0xFF2563EB);

    if (_seconds < 5) {
      t1Status = 'STANDBY';
      countdownText = '${5 - _seconds}s until Tier 1';
      progress = _seconds / 5;
    } else if (_seconds < 60) {
      t1Status = 'ACTIVE';
      t1Active = true;
      countdownText = '${60 - _seconds}s until Tier 2';
      progress = (_seconds - 5) / 55;
      progressColor = const Color(0xFF00C48C);
    } else if (_seconds < 90) {
      t1Status = 'COMPLETED';
      t2Status = 'ACTIVE';
      t2Active = true;
      countdownText = '${90 - _seconds}s until Tier 3';
      progress = (_seconds - 60) / 30;
      progressColor = const Color(0xFFFFB020);
    } else {
      t1Status = 'COMPLETED';
      t2Status = 'COMPLETED';
      t3Status = 'POSTED';
      t3Active = true;
      countdownText = 'Incident Public';
      progress = 1.0;
      progressColor = const Color(0xFFFF4D4D);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E3A8A).withOpacity(0.3),
            const Color(0xFF1E3A8A).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 6)),
        ],
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
          _tierItem('TIER 1', '3 contacts notified', t1Status, t1Active || t1Status == 'COMPLETED', statusColor: t1Status == 'ACTIVE' ? const Color(0xFF00C48C) : null),
          if (t1Status == 'COMPLETED' || t1Status == 'ACTIVE') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(width: 48),
                const Icon(Icons.bar_chart_rounded, color: Colors.white30, size: 14),
                const SizedBox(width: 6),
                Text(t2Status == 'ACTIVE' ? '1 of 3 replied' : 'Waiting for responses', style: GoogleFonts.poppins(fontSize: 11, color: Colors.white30)),
              ],
            ),
          ],
          const SizedBox(height: 12),
          _tierItem('TIER 2', '5-10 extended contacts', t2Status, t2Active || t2Status == 'COMPLETED', statusColor: t2Status == 'ACTIVE' ? const Color(0xFFFFB020) : null),
          const SizedBox(height: 12),
          _tierItem('TIER 3', 'Echo Community Post', t3Status, t3Active, statusColor: t3Status == 'POSTED' ? const Color(0xFFFF4D4D) : null),
          if (t3Status == 'POSTED') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(width: 48),
                const Icon(Icons.people_outline_rounded, color: Color(0xFFFF4D4D), size: 14),
                const SizedBox(width: 6),
                Text('14 responses so far', style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFFFF4D4D))),
              ],
            ),
          ],
          
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

  Widget _tierItem(String title, String sub, String status, bool active, {Color? statusColor}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF2563EB).withOpacity(0.1) : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: active ? const Color(0xFF2563EB).withOpacity(0.3) : Colors.transparent),
      ),
      child: Row(
        children: [
          Icon(
            active ? Icons.check_circle : Icons.circle_outlined,
            color: active ? const Color(0xFF2563EB) : Colors.white30,
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
              color: statusColor ?? (active ? EchoColors.switchOn : Colors.white30),
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E3A8A).withOpacity(0.3),
            const Color(0xFF1E3A8A).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 6)),
        ],
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
                    const Icon(Icons.notification_important_rounded, color: Colors.redAccent, size: 18),
                    const SizedBox(width: 8),
                    Text('EMERGENCY ALERT', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.redAccent)),
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
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Posted 13:47', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white38)),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF0F172A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      title: Text('Echo Feed Post', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700)),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(backgroundColor: Color(0xFF2563EB), radius: 16, child: Icon(Icons.wifi_rounded, color: Colors.white, size: 16)),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Echo Emergency', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                                  Text('@EchoFeed · Just now', style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '🆘 EMERGENCY ALERT: Ada Chukwu may be in danger near D-Line Junction, Port Harcourt.\n\nLive Tracking: echo.live/track/ada-4821',
                            style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, height: 1.5),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Close', style: GoogleFonts.poppins(color: const Color(0xFF0891B2))),
                        ),
                      ],
                    ),
                  );
                },
                child: Text('View Post', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF0891B2))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStopButton() {
    return GestureDetector(
      onTap: () {
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
                  Navigator.pop(context, true); // return to home with "stopped" result
                },
                child: Text('Cancel Emergency', style: GoogleFonts.poppins(color: const Color(0xFFFF0000), fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.orange.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.close, color: Color(0xFFEA580C), size: 20),
            const SizedBox(width: 10),
            Text(
              'STOP EMERGENCY',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFEA580C),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
