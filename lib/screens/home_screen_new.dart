// ignore_for_file: unnecessary_to_list_in_spreads

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _orbController;
  late AnimationController _pulseController;
  late AnimationController _waveformController;

  @override
  void initState() {
    super.initState();
    
    // Orb animation - smooth continuous rotation
    _orbController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
    
    // Pulse animation - subtle breathing
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);
    
    // Waveform animation
    _waveformController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _orbController.dispose();
    _pulseController.dispose();
    _waveformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guardian'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            children: [
              // Glowing Orb - Primary CTA
              _buildGlowingOrb(),
              const SizedBox(height: 24),
              
              // "Gemma is listening" status
              Text(
                'Gemma is listening',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: GuardianColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 48),
              
              // Feature Cards Grid (2x2)
              _buildFeatureCardGrid(),
              const SizedBox(height: 32),
              
              // Priority Contacts Row
              _buildPriorityContacts(),
            ],
          ),
        ),
      ),
    );
  }

  /// Glowing Orb - Main attraction
  Widget _buildGlowingOrb() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed('/emergency-active');
      },
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final scale = 1.0 + (_pulseController.value * 0.05);
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: GuardianColors.primary.withOpacity(0.3),
                blurRadius: 40,
                spreadRadius: 15,
              ),
              BoxShadow(
                color: GuardianColors.secondaryLight.withOpacity(0.15),
                blurRadius: 60,
                spreadRadius: 20,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Animated orb painter
              RotationTransition(
                turns: _orbController,
                child: CustomPaint(
                  painter: _OrbPainter(),
                  size: const Size(180, 180),
                ),
              ),
              
              // Center listening indicator
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.mic,
                    size: 40,
                    color: GuardianColors.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'TAP',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: GuardianColors.primary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Feature Cards Grid - 2x2 layout
  Widget _buildFeatureCardGrid() {
    final features = [
      {
        'icon': Icons.phone_in_talk_outlined,
        'label': 'Fake Call',
        'route': '/fake-call',
      },
      {
        'icon': Icons.person_add_outlined,
        'label': 'Contacts',
        'route': '/contacts',
      },
      {
        'icon': Icons.smart_toy_outlined,
        'label': 'AI Intel',
        'route': '/ai-intel',
      },
      {
        'icon': Icons.history_outlined,
        'label': 'Incident Log',
        'route': '/incident-log',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return GestureDetector(
          onTap: () {
            Navigator.of(context).pushNamed(feature['route'] as String);
          },
          child: Container(
            decoration: BoxDecoration(
              color: GuardianColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: GuardianColors.primary.withOpacity(0.1),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  feature['icon'] as IconData,
                  size: 32,
                  color: GuardianColors.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  feature['label'] as String,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: GuardianColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Priority Contacts Row
  Widget _buildPriorityContacts() {
    final contacts = [
      {'name': 'Mom', 'icon': '👤'},
      {'name': 'Sister', 'icon': '👥'},
      {'name': 'Friend', 'icon': '👤'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Inner Circle',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...contacts.map((contact) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushNamed('/contacts');
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: GuardianColors.surfaceSecondary,
                            border: Border.all(
                              color: GuardianColors.primary.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              contact['icon'] as String,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          contact['name'] as String,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: GuardianColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              // Add contact button
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pushNamed('/contacts');
                },
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: GuardianColors.surfaceTertiary,
                        border: Border.all(
                          color: GuardianColors.primary.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.add,
                          color: GuardianColors.primary,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: GuardianColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Custom Painter for Glowing Orb
class _OrbPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width / 2;

    // Outer glow layer 1
    final glowPaint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          GuardianColors.primary.withOpacity(0.6),
          GuardianColors.primary.withOpacity(0.2),
          Colors.transparent,
        ],
        stops: const [0.3, 0.7, 1.0],
      ).createShader(
        Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
      );

    canvas.drawCircle(Offset(centerX, centerY), radius, glowPaint1);

    // Main orb gradient
    final orbPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          GuardianColors.primaryLight.withOpacity(0.8),
          GuardianColors.primary,
          GuardianColors.primaryDark,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(
        Rect.fromCircle(
          center: Offset(centerX, centerY),
          radius: radius * 0.85,
        ),
      );

    canvas.drawCircle(Offset(centerX, centerY), radius * 0.85, orbPaint);

    // Secondary color accent (swirl effect)
    final swirl = Paint()
      ..color = GuardianColors.secondaryLight.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw subtle arc
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(centerX, centerY),
        radius: radius * 0.6,
      ),
      0,
      math.pi * 1.5,
      false,
      swirl,
    );

    // Highlight
    final highlightPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.4),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ).createShader(
        Rect.fromCircle(
          center: Offset(centerX * 0.7, centerY * 0.7),
          radius: radius * 0.3,
        ),
      );

    canvas.drawCircle(
      Offset(centerX * 0.7, centerY * 0.7),
      radius * 0.3,
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(_OrbPainter oldDelegate) => false;
}
