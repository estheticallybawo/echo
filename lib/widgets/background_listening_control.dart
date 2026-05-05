import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../providers/background_listening_provider.dart';

/// Background Listening Control Widget
/// Gives users explicit control over when Echo listens in the background
/// Privacy-first approach: Listening is OFF by default
class BackgroundListeningControl extends StatelessWidget {
  final bool showDetails;

  const BackgroundListeningControl({
    super.key,
    this.showDetails = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<BackgroundListeningProvider>(
      builder: (context, listeningProvider, _) {
        return Container(
          decoration: BoxDecoration(
            color: listeningProvider.isListening
                ? EchoColors.primary.withOpacity(0.05)
                : EchoColors.warning.withOpacity(0.05),
            border: Border.all(
              color: listeningProvider.isListening
                  ? EchoColors.primary.withOpacity(0.3)
                  : EchoColors.warning.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: listeningProvider.isListening
                          ? EchoColors.primary.withOpacity(0.2)
                          : EchoColors.warning.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      listeningProvider.isListening
                          ? Icons.mic
                          : Icons.mic_none,
                      color: listeningProvider.isListening
                          ? EchoColors.primary
                          : EchoColors.warning,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Background Listening',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          listeningProvider.isListening
                              ? 'Echo is listening (you have control)'
                              : 'Listening is OFF by default',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: EchoColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (!listeningProvider.isLoading)
                    Switch(
                      value: listeningProvider.isListening,
                      onChanged: (_) async {
                        await listeningProvider.toggleBackgroundListening(
                          reason: listeningProvider.isListening
                              ? 'User disabled background listening'
                              : 'User enabled background listening',
                        );
                      },
                      activeColor: EchoColors.primary,
                    )
                  else
                    SizedBox(
                      width: 35,
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              EchoColors.primary.withOpacity(0.6),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              if (showDetails) ...[
                const SizedBox(height: 16),
                // Privacy explanation
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.privacy_tip_outlined,
                            size: 16,
                            color: EchoColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Your Privacy Control',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: EchoColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        listeningProvider.isListening
                            ? 'Echo listens for your activation phrase only when you enable it. You can turn this OFF anytime - no judgment, no penalties.'
                            : 'Background listening is OFF by default. Only turn it ON if you want Echo to listen for your activation phrase. You remain in complete control.',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: EchoColors.textSecondary,
                              height: 1.5,
                            ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // What happens explanation
                if (listeningProvider.isListening)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: EchoColors.success.withOpacity(0.08),
                      border: Border.all(
                        color: EchoColors.success.withOpacity(0.2),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              size: 16,
                              color: EchoColors.success,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'What Echo Does',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: EchoColors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Listens ONLY for your activation phrase\n• Does NOT record continuously\n• Does NOT send data unless you say your phrase\n• Processes audio locally on your device\n• You can pause listening anytime',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: EchoColors.textSecondary,
                                height: 1.6,
                              ),
                        ),
                      ],
                    ),
                  ),

                if (listeningProvider.error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: EchoColors.warning.withOpacity(0.1),
                      border: Border.all(
                        color: EchoColors.warning.withOpacity(0.3),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_outlined,
                          size: 16,
                          color: EchoColors.warning,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            listeningProvider.error ?? 'Unknown error',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: EchoColors.warning,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}
