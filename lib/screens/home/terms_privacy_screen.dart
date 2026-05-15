import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsPrivacyScreen extends StatelessWidget {
  const TermsPrivacyScreen({super.key});

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
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Terms & Privacy',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('1. Privacy Commitment'),
                      _buildBodyText(
                        'At Echo, your privacy is our foundation. Echo does not share your location with advertisers or public bodies by default. Emergency sharing is limited to the contacts, bridges, and demo features you enable.',
                      ),

                      _buildSectionTitle('2. User-Controlled Sharing'),
                      _buildBodyText(
                        'Location sharing only occurs if and when you explicitly grant permission to your designated "Inner Circle" or emergency contacts. You have full control over who sees your data and for how long.',
                      ),

                      _buildSectionTitle('3. Emergency Broadcasts'),
                      _buildBodyText(
                        'In situations of imminent danger, Echo can start the escalation flow from your command, the SOS trigger, or high-risk AI analysis. The current demo escalates to trusted contacts and the Echo Feed; production integrations with official responders require local partnerships and validation.',
                      ),

                      _buildSectionTitle('4. Limitation of Liability'),
                      _buildBodyText(
                        'Echo is a safety tool designed to assist communication during emergencies. It is not a replacement for professional emergency services. Network delays, device permissions, model availability, and third-party contact responses can affect delivery.',
                      ),

                      _buildSectionTitle('5. Data Handling'),
                      _buildBodyText(
                        'Echo is designed to minimize sensitive data sharing. In the current demo, local state is stored on the device/browser, voice snippets are optional, and cloud/bridge processing is only used when explicitly configured.',
                      ),

                      const SizedBox(height: 40),
                      Center(
                        child: Text(
                          'Last updated: May 2026',
                          style: GoogleFonts.poppins(
                            color: Colors.white24,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF00A3C4),
        ),
      ),
    );
  }

  Widget _buildBodyText(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 14,
        height: 1.7,
        color: Colors.white.withOpacity(0.7),
      ),
    );
  }
}
