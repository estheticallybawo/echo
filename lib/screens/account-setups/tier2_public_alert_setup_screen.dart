import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme.dart';

class Tier2PublicAlertSetupScreen extends StatefulWidget {
  const Tier2PublicAlertSetupScreen({super.key});

  @override
  State<Tier2PublicAlertSetupScreen> createState() => _Tier2PublicAlertSetupScreenState();
}

class _Tier2PublicAlertSetupScreenState extends State<Tier2PublicAlertSetupScreen> {
  bool shareName = true;
  bool shareLocation = true;
  bool shareTime = true;
  bool shareLink = true;
  bool consented = false;

  Widget _buildToggleItem(String title, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1F45).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w400,
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF34C759), // Green like in screenshot
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.white12,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.6),
            radius: 1.4,
            colors: [Color(0xFF0D2763), Color(0xFF081023)],
            stops: [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => Navigator.maybePop(context),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0B1C41),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(7, (index) {
                              final bool active = index == 6;
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: active ? 74 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: active ? EchoColors.primary : Colors.white24,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Let Echo reach more people',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "If your contacts don't respond quickly, Echo can share your emergency publicly so others nearby can help.",
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          height: 1.6,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'What gets posted',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Column(
                        children: [
                          _buildToggleItem('First Name', shareName, (v) => setState(() => shareName = v)),
                          _buildToggleItem('Your Location', shareLocation, (v) => setState(() => shareLocation = v)),
                          _buildToggleItem('Time of Alert', shareTime, (v) => setState(() => shareTime = v)),
                          _buildToggleItem('Live Tracking Link', shareLink, (v) => setState(() => shareLink = v)),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Image.asset(
                            'assets/onboarding/echo_alert_logo.png',
                            height: 24,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.wifi_rounded, color: Colors.white70, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Echo Alert',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '@EchoEmergency',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white24, width: 1),
                            ),
                            child: Center(
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/onboarding/x_logo.png',
                                  width: 24,
                                  height: 24,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) => const Text('𝕏', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B1C41).withOpacity(0.4),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: EchoColors.primary.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('🆘', style: TextStyle(fontSize: 14)),
                                const SizedBox(width: 8),
                                Text(
                                  'Ada Chukwu may be in danger',
                                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text('📍', style: TextStyle(fontSize: 14)),
                                const SizedBox(width: 8),
                                Text(
                                  'D-Line Junction, Port Harcourt',
                                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text('🕒', style: TextStyle(fontSize: 14)),
                                const SizedBox(width: 8),
                                Text(
                                  '9:41 AM · Apr 22, 2026',
                                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "If you're nearby or can help, please share",
                              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'echo.live/track/ada-4821 ↗',
                              style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF2563EB), fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              height: 100,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFF081023),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2563EB),
                                        shape: BoxShape.circle,
                                        boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.5), blurRadius: 10, spreadRadius: 4)],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Last known location',
                                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.white54),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '@policeNG @NPF_PRO',
                              style: GoogleFonts.poppins(fontSize: 13, color: Colors.white54),
                            ),
                            Text(
                              '#Echoemergency',
                              style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF2563EB)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: () => setState(() => consented = !consented),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              margin: const EdgeInsets.only(top: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: consented ? EchoColors.primary : Colors.white24, width: 2),
                                color: consented ? EchoColors.primary : Colors.transparent,
                              ),
                              child: consented ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Your Consent',
                                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "I agree to share this information publicly during an emergency, only if my contacts don't respond within 2 minutes. I can change this anytime in Settings.",
                                    style: GoogleFonts.poppins(fontSize: 14, height: 1.5, color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: consented ? () {
                          Navigator.pushNamed(context, '/system-test');
                        } : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: EchoColors.primary,
                          disabledBackgroundColor: EchoColors.primary.withOpacity(0.3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(34)),
                        ),
                        child: Text(
                          'Activate Tier 2 Protection',
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: OutlinedButton(
                        onPressed: () => Navigator.maybePop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white24),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(34)),
                        ),
                        child: Text(
                          'Not Now',
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
