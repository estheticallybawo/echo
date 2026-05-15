import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

class EchoSoundwaveOrb extends StatelessWidget {
  const EchoSoundwaveOrb({
    super.key,
    required this.isActive,
    required this.size,
    this.overlay,
    this.semanticLabel = 'Echo soundwave',
    this.accentColor = EchoColors.secondaryLight,
    this.isButton = false,
  });

  static const String idleAsset = 'assets/onboarding/Echosoundwave.png';
  static const String activeAsset = 'assets/onboarding/Echosoundwave.gif';

  final bool isActive;
  final double size;
  final Widget? overlay;
  final String semanticLabel;
  final Color accentColor;
  final bool isButton;

  @override
  Widget build(BuildContext context) {
    final asset = isActive ? activeAsset : idleAsset;
    final glowColor = isActive ? accentColor : EchoColors.primaryLight;

    return Semantics(
      button: isButton,
      label: semanticLabel,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    glowColor.withOpacity(isActive ? 0.35 : 0.2),
                    EchoColors.primaryDark.withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withOpacity(isActive ? 0.36 : 0.18),
                    blurRadius: isActive ? 44 : 26,
                    spreadRadius: isActive ? 8 : 2,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.34),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
            ),
            ClipOval(
              child: Image.asset(
                asset,
                width: size * 0.92,
                height: size * 0.92,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, _, _) => Container(
                  width: size * 0.72,
                  height: size * 0.72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: EchoColors.primaryDark.withOpacity(0.8),
                    border: Border.all(color: glowColor.withOpacity(0.42)),
                  ),
                  child: Icon(
                    isActive
                        ? Icons.graphic_eq_rounded
                        : Icons.wifi_tethering_rounded,
                    color: Colors.white,
                    size: size * 0.24,
                  ),
                ),
              ),
            ),
            CustomPaint(
              size: Size.square(size),
              painter: _EchoFracturePainter(
                color: glowColor,
                isActive: isActive,
              ),
            ),
            ?overlay,
          ],
        ),
      ),
    );
  }
}

class _EchoFracturePainter extends CustomPainter {
  const _EchoFracturePainter({required this.color, required this.isActive});

  final Color color;
  final bool isActive;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 5;
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = isActive ? 2.4 : 1.7
      ..color = color.withOpacity(isActive ? 0.82 : 0.48);

    final ringRect = Rect.fromCircle(center: center, radius: radius);
    const arcs = <(double, double)>[
      (-0.45, 0.42),
      (0.22, 0.34),
      (0.88, 0.28),
      (1.45, 0.44),
      (2.15, 0.3),
      (2.78, 0.36),
      (3.55, 0.28),
      (4.18, 0.4),
      (4.92, 0.32),
      (5.52, 0.3),
    ];

    for (final arc in arcs) {
      canvas.drawArc(ringRect, arc.$1, arc.$2, false, ringPaint);
    }

    final crackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = isActive ? 1.4 : 1
      ..color = color.withOpacity(isActive ? 0.55 : 0.28);

    const cracks = <(double, double, double)>[
      (0.1, 0.75, 1.0),
      (0.72, 0.78, 1.06),
      (1.35, 0.82, 1.0),
      (2.55, 0.76, 1.08),
      (3.28, 0.8, 1.02),
      (4.48, 0.77, 1.05),
      (5.22, 0.84, 1.0),
    ];

    for (final crack in cracks) {
      final start = Offset(
        center.dx + math.cos(crack.$1) * radius * crack.$2,
        center.dy + math.sin(crack.$1) * radius * crack.$2,
      );
      final end = Offset(
        center.dx + math.cos(crack.$1 + 0.08) * radius * crack.$3,
        center.dy + math.sin(crack.$1 + 0.08) * radius * crack.$3,
      );
      canvas.drawLine(start, end, crackPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _EchoFracturePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isActive != isActive;
  }
}
