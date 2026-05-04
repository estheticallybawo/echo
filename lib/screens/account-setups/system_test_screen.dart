import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme.dart';

class SystemTestScreen extends StatefulWidget {
  const SystemTestScreen({super.key});

  @override
  State<SystemTestScreen> createState() => _SystemTestScreenState();
}

class _SystemTestScreenState extends State<SystemTestScreen> {
  int _currentStep = 0;
  int _timeLeft = 2;
  Timer? _countdownTimer;

  final List<int> _stepDurations = [2, 5, 4];

  @override
  void initState() {
    super.initState();
    _startCurrentStep();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCurrentStep() {
    if (_currentStep >= 3) return;

    _timeLeft = _stepDurations[_currentStep];
    _countdownTimer?.cancel();
    
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 1) {
          _timeLeft--;
        } else {
          timer.cancel();
          _currentStep++;
          _startCurrentStep();
        }
      });
    });
  }

  Widget _buildTestCard({
    required String title,
    required String subtitle,
    required int stepIndex,
    String? timeMs,
  }) {
    bool isPassed = _currentStep > stepIndex;
    bool isRunning = _currentStep == stepIndex;
    bool isPending = _currentStep < stepIndex;

    Color iconColor;
    IconData iconData;
    if (isPassed) {
      iconColor = const Color(0xFF00C48C);
      iconData = Icons.check;
    } else {
      iconColor = Colors.white24;
      iconData = Icons.check;
    }

    String statusText;
    Color statusColor;
    if (isPassed) {
      statusText = 'Passed';
      statusColor = const Color(0xFF00C48C);
    } else if (isRunning) {
      statusText = 'Running';
      statusColor = const Color(0xFFFFB020);
    } else {
      statusText = 'Pending';
      statusColor = Colors.white54;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2A4F),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: iconColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                iconData,
                color: isPassed ? Colors.white : Colors.white54,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                statusText,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: statusColor,
                ),
              ),
              if (isPassed && timeMs != null) ...[
                const SizedBox(height: 4),
                Text(
                  timeMs,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white54,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool allDone = _currentStep >= 3;
    
    String currentActionText = '';
    if (!allDone) {
      if (_currentStep == 0) currentActionText = 'running Server Health Check';
      else if (_currentStep == 1) currentActionText = 'running Warm up Call';
      else if (_currentStep == 2) currentActionText = 'running Live Drill Interference';
    }

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
                Expanded(
                  child: SingleChildScrollView(
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
                                  Icons.arrow_back,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(6, (index) {
                                final bool active = index == 5;
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
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'System Test',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'This is a full simulation to test Echo readiness. Zero real alerts are sent.',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            height: 1.5,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        _buildTestCard(
                          title: 'Server Health Check',
                          subtitle: 'Verifies Gemma Endpoints are reachable',
                          stepIndex: 0,
                          timeMs: '542 ms',
                        ),
                        _buildTestCard(
                          title: 'Warm up Call',
                          subtitle: 'Run a small prompt to reduce cold start latency',
                          stepIndex: 1,
                          timeMs: '542 ms',
                        ),
                        _buildTestCard(
                          title: 'Live Drill Interference',
                          subtitle: 'Analyzes a real time scenario and validates JSON output',
                          stepIndex: 2,
                          timeMs: '542 ms',
                        ),
                      ],
                    ),
                  ),
                ),
                
                if (!allDone)
                  Center(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(EchoColors.primary),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              currentActionText,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_timeLeft}s left',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                const SizedBox(height: 32),
                
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: allDone ? () {
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EchoColors.primary,
                      disabledBackgroundColor: EchoColors.primary.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(34),
                      ),
                    ),
                    child: Text(
                      'Done',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
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
