import 'package:flutter/material.dart';
import '../theme.dart';

class AIIntelScreen extends StatefulWidget {
  const AIIntelScreen({super.key});

  @override
  State<AIIntelScreen> createState() => _AIIntelScreenState();
}

class _AIIntelScreenState extends State<AIIntelScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Intel'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gemma 4 Safety Analysis',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Real-time threat detection and safety insights',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: EchoColors.textTertiary,
              ),
            ),
            const SizedBox(height: 32),

            // Safety Score Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: EchoColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: EchoColors.success.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: EchoColors.success.withOpacity(0.1),
                        ),
                        child: Center(
                          child: Text(
                            '92',
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(
                                  color: EchoColors.success,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Safety Score',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Current Environment Assessment',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: EchoColors.textTertiary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  LinearProgressIndicator(
                    value: 0.92,
                    minHeight: 6,
                    backgroundColor:
                        EchoColors.success.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                        EchoColors.success),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // AI Analysis Insights
            Text(
              'Analysis Insights',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ...[
              {
                'title': 'Audio Pattern Recognition',
                'desc': 'No threat indicators detected in background',
                'status': EchoColors.success,
              },
              {
                'title': 'Location Stability',
                'desc': 'Stationary. Same location for 2 hours',
                'status': EchoColors.success,
              },
              {
                'title': 'Contact Proximity',
                'desc': '3 inner circle contacts within 5km',
                'status': EchoColors.success,
              },
              {
                'title': 'Time Assessment',
                'desc': 'Daytime: Lower risk context',
                'status': EchoColors.primary,
              },
            ].map((insight) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: EchoColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: EchoColors.textPrimary.withOpacity(0.08),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (insight['status'] as Color)
                              .withOpacity(0.1),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.check_circle,
                            size: 18,
                            color: insight['status'] as Color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              insight['title'] as String,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: EchoColors.textPrimary,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              insight['desc'] as String,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: EchoColors.textTertiary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
