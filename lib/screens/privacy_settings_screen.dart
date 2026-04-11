import 'package:flutter/material.dart';
import '../theme.dart';


/// Privacy & Listening Settings Screen (For Onboarding or Settings)
/// Gives users transparent control over background listening
class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Control'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Your Privacy Comes First',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: EchoColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Echo is built on the principle that you have complete autonomy over when we listen. Unlike other assistants, you decide when Echo can hear you.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: EchoColors.textSecondary,
                      height: 1.6,
                    ),
              ),
              const SizedBox(height: 32),

              // Background Listening Control
              Text(
                'Background Listening Control',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: EchoColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 12),
              const SizedBox(height: 32),

              // Privacy Points
              Text(
                'Why This Matters',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: EchoColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 16),

              // Point 1
              _buildPrivacyPoint(
                context,
                icon: Icons.gavel,
                title: 'Legal Precedent',
                description:
                    'Siri, Alexa, and Google Assistant have faced lawsuits over always-listening concerns. We\'re different.',
              ),
              const SizedBox(height: 16),

              // Point 2
              _buildPrivacyPoint(
                context,
                icon: Icons.security,
                title: 'Your Control',
                description:
                    'Listening is OFF by default. You explicitly enable it when you choose. Turn it off anytime.',
              ),
              const SizedBox(height: 16),

              // Point 3
              _buildPrivacyPoint(
                context,
                icon: Icons.smartphone,
                title: 'Local Processing',
                description:
                    'Audio is processed on your device first. Nothing leaves until you say your activation phrase.',
              ),
              const SizedBox(height: 16),

              // Point 4
              _buildPrivacyPoint(
                context,
                icon: Icons.visibility_off,
                title: 'Phrase Detection Only',
                description:
                    'Echo only listens for your specific phrase. No continuous recording. No background analysis.',
              ),
              const SizedBox(height: 32),

              // Settings Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: EchoColors.secondary.withOpacity(0.08),
                  border: Border.all(
                    color: EchoColors.secondary.withOpacity(0.2),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 20,
                          color: EchoColors.secondary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'You Can Change This Anytime',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: EchoColors.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This setting is in app Settings anytime. No judgment if you choose to disable listening - your safety and privacy matter more than convenience.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: EchoColors.textSecondary,
                            height: 1.5,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EchoColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Got It',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyPoint(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: EchoColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: EchoColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: EchoColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: EchoColors.textSecondary,
                      height: 1.4,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
