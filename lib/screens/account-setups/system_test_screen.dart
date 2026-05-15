import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/gemma/gemma_system_drill_service.dart';
import '../../theme.dart';

class SystemTestScreen extends StatefulWidget {
  const SystemTestScreen({super.key});

  @override
  State<SystemTestScreen> createState() => _SystemTestScreenState();
}

class _SystemTestScreenState extends State<SystemTestScreen> {
  late final GemmaSystemDrillService _drillService;
  late GemmaSystemDrillSnapshot _snapshot;
  StreamSubscription<GemmaSystemDrillSnapshot>? _drillSubscription;

  @override
  void initState() {
    super.initState();
    _drillService = GemmaSystemDrillService();
    _snapshot = _drillService.initialSnapshot();
    _runSystemDrill();
  }

  @override
  void dispose() {
    _drillSubscription?.cancel();
    super.dispose();
  }

  void _runSystemDrill() {
    if (_snapshot.isRunning) return;

    _drillSubscription?.cancel();
    setState(() {
      _snapshot = _drillService.initialSnapshot().copyWith(
        isRunning: true,
        overallStatus: 'Starting live Gemma drill...',
      );
    });

    _drillSubscription = _drillService.run().listen((snapshot) {
      if (!mounted) return;
      setState(() => _snapshot = snapshot);
    });
  }

  IconData _statusIcon(GemmaSystemDrillStepStatus status) {
    switch (status) {
      case GemmaSystemDrillStepStatus.running:
        return Icons.autorenew_rounded;
      case GemmaSystemDrillStepStatus.success:
        return Icons.check_rounded;
      case GemmaSystemDrillStepStatus.failure:
        return Icons.error_outline_rounded;
      case GemmaSystemDrillStepStatus.pending:
        return Icons.check_rounded;
    }
  }

  Color _statusColor(GemmaSystemDrillStepStatus status) {
    switch (status) {
      case GemmaSystemDrillStepStatus.running:
        return const Color(0xFFFFB020);
      case GemmaSystemDrillStepStatus.success:
        return const Color(0xFF00C48C);
      case GemmaSystemDrillStepStatus.failure:
        return EchoColors.warning;
      case GemmaSystemDrillStepStatus.pending:
        return Colors.white54;
    }
  }

  String _statusText(GemmaSystemDrillStepStatus status) {
    switch (status) {
      case GemmaSystemDrillStepStatus.running:
        return 'Running';
      case GemmaSystemDrillStepStatus.success:
        return 'Passed';
      case GemmaSystemDrillStepStatus.failure:
        return 'Failed';
      case GemmaSystemDrillStepStatus.pending:
        return 'Pending';
    }
  }

  Widget _buildTestCard(GemmaSystemDrillStepState step) {
    final color = _statusColor(step.status);
    final passed = step.status == GemmaSystemDrillStepStatus.success;
    final pending = step.status == GemmaSystemDrillStepStatus.pending;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2A4F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: step.status == GemmaSystemDrillStepStatus.failure
              ? EchoColors.warning.withOpacity(0.55)
              : Colors.white.withOpacity(0.04),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: pending ? Colors.white24 : color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                _statusIcon(step.status),
                color: passed ? Colors.white : Colors.white70,
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
                  step.title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step.message ?? step.subtitle,
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
                _statusText(step.status),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                step.elapsedMs > 0 ? '${step.elapsedMs} ms' : '--',
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.white54),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allDone = _snapshot.isPassed;
    final hasFailed =
        !_snapshot.isRunning && !allDone && _snapshot.errorMessage != null;
    final steps = GemmaSystemDrillStep.values
        .map((step) => _snapshot.step(step))
        .toList();

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
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(6, (index) {
                                final active = index == 5;
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  width: active ? 74 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: active
                                        ? EchoColors.primary
                                        : Colors.white24,
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
                          'Live Gemma readiness drill. Zero real alerts are sent.',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            height: 1.5,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 32),
                        ...steps.map(_buildTestCard),
                        if (_snapshot.errorMessage != null) ...[
                          const SizedBox(height: 4),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: EchoColors.warning.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: EchoColors.warning.withOpacity(0.35),
                              ),
                            ),
                            child: Text(
                              _snapshot.errorMessage!,
                              style: GoogleFonts.poppins(
                                color: EchoColors.warning,
                                fontSize: 13,
                                height: 1.45,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (_snapshot.isRunning)
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
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  EchoColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                _snapshot.overallStatus,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Gemma may take longer after a fresh server start',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Center(
                    child: Text(
                      allDone
                          ? 'Gemma is active | Total: ${_snapshot.totalElapsedMs} ms'
                          : _snapshot.overallStatus,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: allDone
                            ? const Color(0xFF00C48C)
                            : EchoColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: allDone
                        ? () {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/home',
                              (route) => false,
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EchoColors.primary,
                      disabledBackgroundColor: EchoColors.primary.withOpacity(
                        0.3,
                      ),
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
                if (hasFailed || allDone) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: OutlinedButton(
                      onPressed: _snapshot.isRunning ? null : _runSystemDrill,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(34),
                        ),
                      ),
                      child: Text(
                        allDone ? 'Run Drill Again' : 'Retry Test',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
