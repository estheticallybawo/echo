import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme.dart';
import '../../services/llama_config.dart';
import '../../services/llama_threat_service.dart';

class SystemTestScreen extends StatefulWidget {
  const SystemTestScreen({super.key});

  @override
  State<SystemTestScreen> createState() => _SystemTestScreenState();
}

class _SystemTestScreenState extends State<SystemTestScreen> {
  final LlamaThreatService _gemmaService = LlamaThreatService();

  bool _isRunning = false;
  bool _testComplete = false;
  bool _testPassed = false;
  String _overallStatus = 'Not started';
  String? _errorMessage;
  Map<String, dynamic>? _drillResult;

  final Map<String, String> _stepStates = {
    'health': 'pending',
    'warmup': 'pending',
    'inference': 'pending',
  };

  final Map<String, int> _stepTimingsMs = {
    'health': 0,
    'warmup': 0,
    'inference': 0,
    'total': 0,
  };

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _runSystemDrill() async {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _testComplete = false;
      _testPassed = false;
      _overallStatus = 'Running live drill...';
      _errorMessage = null;
      _drillResult = null;
      _stepStates['health'] = 'pending';
      _stepStates['warmup'] = 'pending';
      _stepStates['inference'] = 'pending';
      _stepTimingsMs['health'] = 0;
      _stepTimingsMs['warmup'] = 0;
      _stepTimingsMs['inference'] = 0;
      _stepTimingsMs['total'] = 0;
    });

    final totalStopwatch = Stopwatch()..start();

    try {
      // Step 1: Real server health check.
      setState(() {
        _stepStates['health'] = 'running';
        _overallStatus = 'Checking Gemma server health...';
      });

      final healthStopwatch = Stopwatch()..start();
      final isHealthy = await LlamaConfig.isServerHealthy();
      healthStopwatch.stop();

      if (!mounted) return;
      setState(() {
        _stepTimingsMs['health'] = healthStopwatch.elapsedMilliseconds;
      });

      if (!isHealthy) {
        setState(() {
          _stepStates['health'] = 'failure';
          _overallStatus = 'Gemma server offline';
          _errorMessage =
              'Unable to reach Gemma at ${LlamaConfig.activeHost}. Start llama-server and retry.';
        });
        return;
      }

      setState(() {
        _stepStates['health'] = 'success';
      });

      // Step 2: Warm-up call to reduce first-token latency.
      setState(() {
        _stepStates['warmup'] = 'running';
        _overallStatus = 'Warming up Gemma...';
      });

      final warmupStopwatch = Stopwatch()..start();
      final warmupPrompt =
          'Respond with JSON: {"threat":"test","confidence":50}';
      final warmupResult = await _gemmaService.assessThreat(
        warmupPrompt,
        maxTokens: 90,
        timeout: const Duration(seconds: 90),
      );
      warmupStopwatch.stop();

      if (!mounted) return;
      setState(() {
        _stepTimingsMs['warmup'] = warmupStopwatch.elapsedMilliseconds;
      });

      final warmupThreat = (warmupResult['threat'] ?? 'unknown').toString();
      if (warmupThreat == 'unknown') {
        setState(() {
          _stepStates['warmup'] = 'failure';
          _overallStatus = 'Gemma warm-up failed';
          _errorMessage = 'Warm-up response was not parseable JSON.';
        });
        return;
      }

      setState(() {
        _stepStates['warmup'] = 'success';
      });

      // Step 3: Run an actual onboarding drill inference.
      setState(() {
        _stepStates['inference'] = 'running';
        _overallStatus = 'Running live threat drill...';
      });

      final inferenceStopwatch = Stopwatch()..start();
      final drillInput =
          'Drill: Someone following me. Threat? Respond with JSON only.';
      final drillResult = await _gemmaService.assessThreat(
        drillInput,
        maxTokens: 90,
        timeout: const Duration(seconds: 90),
      );
      inferenceStopwatch.stop();

      if (!mounted) return;
      setState(() {
        _stepTimingsMs['inference'] = inferenceStopwatch.elapsedMilliseconds;
      });

      final drillThreat = (drillResult['threat'] ?? 'unknown').toString();
      final drillConfidence = drillResult['confidence'];
      final validConfidence = drillConfidence is num;

      if (drillThreat == 'unknown' || !validConfidence) {
        setState(() {
          _stepStates['inference'] = 'failure';
          _overallStatus = 'Drill inference failed';
          _errorMessage = 'Gemma returned an invalid drill payload.';
        });
        return;
      }

      setState(() {
        _stepStates['inference'] = 'success';
        _drillResult = drillResult;
        _testPassed = true;
        _overallStatus = 'Gemma active: live drill passed';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _overallStatus = 'Drill failed with exception';
        _errorMessage = e.toString();

        if (_stepStates['health'] == 'running') {
          _stepStates['health'] = 'failure';
        } else if (_stepStates['warmup'] == 'running') {
          _stepStates['warmup'] = 'failure';
        } else if (_stepStates['inference'] == 'running') {
          _stepStates['inference'] = 'failure';
        }
      });
    } finally {
      totalStopwatch.stop();

      if (!mounted) return;
      setState(() {
        _stepTimingsMs['total'] = totalStopwatch.elapsedMilliseconds;
        _testComplete = true;
        _isRunning = false;
      });
    }
  }

  IconData _statusIcon(String state) {
    switch (state) {
      case 'running':
        return Icons.autorenew;
      case 'success':
        return Icons.check_circle;
      case 'failure':
        return Icons.error;
      default:
        return Icons.radio_button_unchecked;
    }
  }

  Color _statusColor(String state) {
    switch (state) {
      case 'running':
        return EchoColors.primary;
      case 'success':
        return EchoColors.success;
      case 'failure':
        return EchoColors.warning;
      default:
        return EchoColors.textTertiary;
    }
  }

  String _statusText(String state) {
    switch (state) {
      case 'running':
        return 'Running';
      case 'success':
        return 'Passed';
      case 'failure':
        return 'Failed';
      default:
        return 'Pending';
    }
  }

  Widget _buildStepCard({
    required String stepKey,
    required String title,
    required String subtitle,
  }) {
    final state = _stepStates[stepKey] ?? 'pending';
    final timing = _stepTimingsMs[stepKey] ?? 0;
    final statusColor = _statusColor(state);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1C41),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _statusIcon(state),
            color: statusColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _statusText(state),
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                timing > 0 ? '${timing} ms' : '--',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                // Back button
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
                const SizedBox(height: 32),

                // Title & Description
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'System Test',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Live Gemma readiness report',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            height: 1.5,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Step Cards
                        _buildStepCard(
                          stepKey: 'health',
                          title: 'Step 1 - Server Health Check',
                          subtitle: 'Verifies Gemma endpoint is reachable.',
                        ),
                        _buildStepCard(
                          stepKey: 'warmup',
                          title: 'Step 2 - Warm-up Call',
                          subtitle: 'Runs a small prompt to reduce cold-start latency.',
                        ),
                        _buildStepCard(
                          stepKey: 'inference',
                          title: 'Step 3 - Live Drill Inference',
                          subtitle: 'Analyzes a drill scenario and validates JSON output.',
                        ),
                        const SizedBox(height: 16),

                        // Status Container
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B1C41),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _testPassed
                                  ? EchoColors.success
                                  : _errorMessage != null
                                      ? EchoColors.warning
                                      : EchoColors.primary,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _testPassed
                                        ? Icons.check_circle
                                        : _errorMessage != null
                                            ? Icons.error
                                            : Icons.info,
                                    color: _testPassed
                                        ? EchoColors.success
                                        : _errorMessage != null
                                            ? EchoColors.warning
                                            : EchoColors.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _overallStatus,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _testPassed
                                            ? EchoColors.success
                                            : _errorMessage != null
                                                ? EchoColors.warning
                                                : Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Total activation time: ${_stepTimingsMs['total']} ms',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                              if (_drillResult != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Gemma is now active | Confidence: ${_drillResult!['confidence']}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: EchoColors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: EchoColors.warning.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: EchoColors.warning.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    _errorMessage!,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: EchoColors.warning,
                                      fontWeight: FontWeight.w600,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Action Buttons
                if (_testPassed)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pushReplacementNamed('/home'),
                      icon: const Icon(Icons.check_circle),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EchoColors.success,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      label: Text(
                        'CONTINUE TO HOME',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isRunning ? null : _runSystemDrill,
                      icon: _isRunning
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.play_arrow),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EchoColors.primary,
                        disabledBackgroundColor:
                            EchoColors.primary.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      label: Text(
                        _isRunning
                            ? 'RUNNING LIVE DRILL...'
                            : _testComplete
                                ? 'RUN DRILL AGAIN'
                                : 'START TEST DRILL',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    _testPassed
                        ? 'Gemma is active and ready for emergency activation.'
                        : 'Run the drill to verify Gemma activity in real time.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
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
