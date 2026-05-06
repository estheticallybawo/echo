import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme.dart';

class AiIntelScreen extends StatefulWidget {
  const AiIntelScreen({super.key});

  @override
  State<AiIntelScreen> createState() => _AiIntelScreenState();
}

class _AiIntelScreenState extends State<AiIntelScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF02091A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.5),
            radius: 1.3,
            colors: [Color(0xFF0F3169), Color(0xFF02091A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    if (Navigator.canPop(context))
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    const Spacer(),
                    Text(
                      'AI Intel',
                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    children: [
                      ScaleTransition(
                        scale: _pulse,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                EchoColors.primary.withOpacity(0.4),
                                EchoColors.primary.withOpacity(0.1),
                              ],
                            ),

                            border: Border.all(color: EchoColors.switchOn.withOpacity(0.4)),
                            boxShadow: [
                              BoxShadow(color: EchoColors.switchOn.withOpacity(0.1), blurRadius: 30, spreadRadius: 2),
                              BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: EchoColors.switchOn.withOpacity(0.15),
                                border: Border.all(color: EchoColors.switchOn.withOpacity(0.3)),
                              ),
                              child: Center(
                                child: Text(
                                  '92%',
                                  style: GoogleFonts.poppins(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Environment Safety Score',
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      Text(
                        'Calculated based on real-time data',
                        style: GoogleFonts.poppins(fontSize: 13, color: Colors.white38),
                      ),
                      const SizedBox(height: 48),
                      
                      _buildInsightItem(
                        'Audio Pattern Recognition',
                        'No threat indicators detected in background',
                        Icons.check_circle,
                        EchoColors.switchOn,
                      ),
                      _buildInsightItem(
                        'Location Stability',
                        'Moving at expected pace for current activity',
                        Icons.check_circle,
                        EchoColors.switchOn,
                      ),
                      _buildInsightItem(
                        'Contact Proximity',
                        '2 Inner Circle members within 2km radius',
                        Icons.check_circle,
                        EchoColors.switchOn,
                      ),
                      _buildInsightItem(
                        'Time Assessment',
                        'Regular routine confirmed for 9:41 AM',
                        Icons.check_circle,
                        EchoColors.switchOn,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsightItem(String title, String sub, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A).withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 4),
                Text(sub, style: GoogleFonts.poppins(fontSize: 12, color: Colors.white38, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
