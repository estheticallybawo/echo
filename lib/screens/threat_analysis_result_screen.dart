import 'package:flutter/material.dart';
import '../theme.dart';

/// Screen showing Gemma's threat analysis result
/// Displays analysis in a calm, reassuring manner without anxiety-inducing language
class ThreatAnalysisResultScreen extends StatelessWidget {
  final Map<String, dynamic> threatAssessment;
  final String userName;
  final String location;
  final String postContent;
  final VoidCallback onConfirmPost;
  final VoidCallback? onCancel;

  const ThreatAnalysisResultScreen({
    super.key,
    required this.threatAssessment,
    required this.userName,
    required this.location,
    required this.postContent,
    required this.onConfirmPost,
    this.onCancel,
  });

  /// Get threat level color (teal tones, not red)
  Color _getThreatLevelColor(String threatLevel) {
    final level = threatLevel.toLowerCase();
    if (level == 'critical') {
      return EchoColors.primaryDark;
    } else if (level == 'high') {
      return EchoColors.primary;
    } else if (level == 'medium') {
      return EchoColors.primaryLight;
    }
    return EchoColors.secondary;
  }

  /// Get reassuring message based on threat level
  String _getReassuranceMessage(String threatLevel) {
    final level = threatLevel.toLowerCase();
    if (level == 'critical') {
      return 'Emergency services are being coordinated. Your network has been notified.';
    } else if (level == 'high') {
      return 'Help is being coordinated. Your trusted contacts have been alerted.';
    } else if (level == 'medium') {
      return 'Your situation is being monitored. Support is on the way.';
    }
    return 'Your network is standing by to help.';
  }

  @override
  Widget build(BuildContext context) {
    final threatLevel =
        threatAssessment['threatLevel']?.toString().toUpperCase() ?? 'ANALYZING';
    final analyzedSituation =
        threatAssessment['analyzedSituation'] ?? 'emergency situation';
    final threatType = threatAssessment['threat'] ?? 'Emergency detected';
    final confidence = threatAssessment['confidence'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Situation Analysis'),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with threat assessment
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getThreatLevelColor(threatLevel),
                    _getThreatLevelColor(threatLevel).withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Threat level badge
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                      ),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      threatLevel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Analysis title
                  Text(
                    threatType,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  // Confidence indicator
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: confidence / 100,
                            minHeight: 4,
                            backgroundColor:
                                Colors.white.withOpacity(0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$confidence%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Reassurance message
            Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                decoration: BoxDecoration(
                  color: EchoColors.primary.withOpacity(0.05),
                  border: Border.all(
                    color: EchoColors.primary.withOpacity(0.2),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: EchoColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        color: EchoColors.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _getReassuranceMessage(threatLevel),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: EchoColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Analysis Details
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Situation',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: EchoColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    analyzedSituation,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  // Location info
                  Text(
                    'Location',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: EchoColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 20,
                        color: EchoColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          location,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Recommended action
                  Text(
                    'Recommended Action',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: EchoColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    threatAssessment['action'] ?? 'Contact emergency services',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
            // Post Preview
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Public Alert',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: EchoColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: EchoColors.surfaceSecondary,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      postContent,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
            // Action Buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EchoColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: onConfirmPost,
                    child: const Text(
                      'Confirm & Post Alert',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: EchoColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed:
                        onCancel ?? () => Navigator.of(context).pop(),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: EchoColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
