// ignore_for_file: unnecessary_to_list_in_spreads

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../theme.dart';
import '../providers/user_preferences_provider.dart';

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
  bool isListening = true; // Track listening state

  @override
  void initState() {
    super.initState();
    
    // Load user preferences on home screen launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userPreferences = context.read<UserPreferencesProvider>();
      userPreferences.initializeUserProfile();
    });
    
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
        title: const Text('Echo'),
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
              
              // Background Listening Status Card
              _buildListeningStatusCard(),
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
                color: EchoColors.primary.withOpacity(0.3),
                blurRadius: 40,
                spreadRadius: 15,
              ),
              BoxShadow(
                color: EchoColors.secondaryLight.withOpacity(0.15),
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
                    color: const Color.fromARGB(255, 183, 236, 250),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'TAP',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: const Color.fromARGB(255, 120, 218, 243),
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

  /// Background Listening Status Card - Control and Status
  Widget _buildListeningStatusCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isListening ? EchoColors.primary.withOpacity(0.08) : EchoColors.warning.withOpacity(0.08),
        border: Border.all(
          color: isListening ? EchoColors.primary.withOpacity(0.3) : EchoColors.warning.withOpacity(0.3),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status indicator
            Row(
              children: [
                // Status Indicator Light
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isListening ? EchoColors.success : EchoColors.warning,
                    boxShadow: [
                      if (isListening)
                        BoxShadow(
                          color: EchoColors.success.withOpacity(0.6),
                          blurRadius: 8,
                          spreadRadius: 2,
                        )
                      else
                        BoxShadow(
                          color: EchoColors.warning.withOpacity(0.6),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Status Label
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Background Listening',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: EchoColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isListening ? 'Active - Gemma is listening' : 'Inactive - Tap to enable',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: EchoColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Toggle Button - Click to change state
            GestureDetector(
              onTap: () {
                setState(() {
                  isListening = !isListening;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isListening 
                        ? 'Background listening enabled - Gemma is now listening' 
                        : 'Background listening disabled - Gemma is no longer listening',
                    ),
                    duration: const Duration(seconds: 2),
                    backgroundColor: EchoColors.surface,
                  ),
                );
              },
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: isListening ? EchoColors.primary : EchoColors.warning,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isListening ? EchoColors.primary : EchoColors.warning,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isListening ? Icons.mic : Icons.mic_off,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isListening ? 'Turn Off Listening' : 'Enable Background Listening',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Info text - Changes based on state
            Text(
              isListening 
                ? 'Gemma is ready to listen for voice prompts. Disable when you\'re in a safe location.'
                : 'Enable listening before entering an unfamiliar or unsafe area so Gemma can respond to your voice commands.',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: EchoColors.textTertiary,
                height: 1.5,
              ),
            ),
            
            // Extra info when listening is OFF
            if (!isListening) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: EchoColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: EchoColors.warning.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: EchoColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Listening is OFF. You can still use all features manually.',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: EchoColors.warning,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Feature Cards Grid - 2x2 layout (May 17 MVP only - no deferred features)
  Widget _buildFeatureCardGrid() {
    final features = [
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
              color: EchoColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: EchoColors.primary.withOpacity(0.1),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  feature['icon'] as IconData,
                  size: 32,
                  color: EchoColors.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  feature['label'] as String,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: EchoColors.textPrimary,
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
                            color: EchoColors.surfaceSecondary,
                            border: Border.all(
                              color: EchoColors.primary.withOpacity(0.3),
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
                            color: EchoColors.textSecondary,
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
                        color: EchoColors.surfaceTertiary,
                        border: Border.all(
                          color: EchoColors.primary.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.add,
                          color: EchoColors.primary,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: EchoColors.textTertiary,
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
          EchoColors.primary.withOpacity(0.6),
          EchoColors.primary.withOpacity(0.2),
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
          EchoColors.primaryLight.withOpacity(0.8),
          EchoColors.primary,
          EchoColors.primaryDark,
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
      ..color = EchoColors.secondaryLight.withOpacity(0.3)
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
