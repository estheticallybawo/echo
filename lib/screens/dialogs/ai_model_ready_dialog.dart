import 'package:flutter/material.dart';
import '../../theme.dart';

/// Shown after the APK model-download path preview completes.
class AIModelReadyDialog extends StatelessWidget {
  final VoidCallback onContinue;

  const AIModelReadyDialog({required this.onContinue, super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: EchoColors.success.withOpacity(0.2),
              ),
              child: const Icon(
                Icons.check_circle,
                size: 40,
                color: EchoColors.success,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Model Path Ready',
              style: Theme.of(
                context,
              ).textTheme.displayMedium?.copyWith(color: EchoColors.success),
            ),
            const SizedBox(height: 12),
            Text(
              'The model download path is ready for APK testing.\n\nChrome still uses your local Gemma server.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: EchoColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildBenefit(
              context,
              icon: Icons.psychology_outlined,
              title: 'Gemma Option',
              subtitle: 'Model selected for testing',
            ),
            const SizedBox(height: 12),
            _buildBenefit(
              context,
              icon: Icons.speed_outlined,
              title: 'Compatibility',
              subtitle: 'RAM and storage checked',
            ),
            const SizedBox(height: 12),
            _buildBenefit(
              context,
              icon: Icons.lock_outline,
              title: 'Isolated Path',
              subtitle: 'Web demo stays stable',
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: EchoColors.success,
              ),
              child: const Text('Continue to Emergency'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefit(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EchoColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: EchoColors.primary, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: EchoColors.textTertiary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
