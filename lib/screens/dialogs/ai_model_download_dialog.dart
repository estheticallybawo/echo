import 'package:flutter/material.dart';
import '../../theme.dart';

/// First-launch dialog for downloading offline AI model
/// Shown when user first taps Emergency without AI downloaded
class AIModelDownloadDialog extends StatelessWidget {
  final VoidCallback onDownload;
  final VoidCallback onSkip;
  final VoidCallback onCancel;

  const AIModelDownloadDialog({
    required this.onDownload,
    required this.onSkip,
    required this.onCancel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: EchoColors.primaryLight.withOpacity(0.2),
                ),
                child: const Icon(
                  Icons.cloud_download_outlined,
                  size: 40,
                  color: EchoColors.primary,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                '🚀 First Time Setup',
                style: Theme.of(context).textTheme.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                'Download the offline AI assistant for better threat assessment?',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: EchoColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Info cards
              _buildInfoCard(
                icon: Icons.storage_outlined,
                label: 'Size',
                value: '2.6 GB',
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                icon: Icons.schedule_outlined,
                label: 'Download Time',
                value: '~3-5 minutes',
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                icon: Icons.check_circle_outline_rounded,
                label: 'Benefit',
                value: 'Better accuracy',
              ),
              const SizedBox(height: 32),

              // Buttons
              ElevatedButton(
                onPressed: onDownload,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: EchoColors.primary,
                ),
                child: const Text('Download'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onSkip,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  side: const BorderSide(color: EchoColors.primary),
                ),
                child: const Text('Skip for Now'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: onCancel,
                child: Text(
                  'Cancel',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: EchoColors.textTertiary,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
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
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: EchoColors.textTertiary,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: EchoColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
