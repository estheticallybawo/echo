import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool micEnabled = true;
  bool locationEnabled = true;
  bool contactsEnabled = true;
  bool notificationsEnabled = true;

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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (Navigator.canPop(context))
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    Text(
                      'Settings',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                _buildSectionHeader('Account'),
                const SizedBox(height: 16),
                _buildProfileCard(),
                const SizedBox(height: 40),
                
                _buildSectionHeader('Updates'),
                const SizedBox(height: 16),
                _buildAiUpdateCard(),
                
                const SizedBox(height: 40),
                _buildSectionHeader('Background Protection'),
                const SizedBox(height: 16),
                _buildToggleCard(Icons.mic_none_rounded, 'Microphone', 'Used for background listening only when Echo is active to detect distress.', micEnabled, (v) => setState(() => micEnabled = v)),
                _buildToggleCard(Icons.location_on_outlined, 'Location', 'So your contacts know exactly where to find you in an emergency.', locationEnabled, (v) => setState(() => locationEnabled = v)),
                _buildToggleCard(Icons.contacts_outlined, 'Contacts', 'Lets you choose people who should be alerted when you need help.', contactsEnabled, (v) => setState(() => contactsEnabled = v)),
                _buildToggleCard(Icons.notifications_none_rounded, 'Notifications', 'So you receive updates when someone responds to your alert.', notificationsEnabled, (v) => setState(() => notificationsEnabled = v)),
                
                const SizedBox(height: 40),
                _buildSectionHeader('Emergency Phase'),
                const SizedBox(height: 16),
                _buildPhaseCard(),

                const SizedBox(height: 40),
                _buildSectionHeader('Legal'),
                const SizedBox(height: 16),
                _buildActionCard(Icons.privacy_tip_outlined, 'Terms & Privacy', 'Read our commitment to your security.', () {
                  Navigator.pushNamed(context, '/terms-privacy');
                }),
                
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }

  Widget _buildAiUpdateCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A).withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Why Download Latest AI Model?',
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 12),
          _bulletPoint('Faster threat detection (offline = no network required).'),
          _bulletPoint('Works anywhere, even without internet.'),
          _bulletPoint('Better accuracy with local processing.'),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Enhanced AI (E4B)', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700)),
                    Text('3.5 GB', style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Version: Not Installed', style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12)),
                const SizedBox(height: 12),
                Text('Better Pattern Recognition (Requires 12GB RAM)', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                Text('May impact battery life', style: GoogleFonts.poppins(color: Colors.amber.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.w500)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('Download Now', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Colors.white, fontSize: 16)),
          Expanded(child: Text(text, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildToggleCard(IconData icon, String title, String sub, bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF1E3A8A).withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(sub, style: GoogleFonts.poppins(fontSize: 12, color: Colors.white38, height: 1.4)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.white,
              activeTrackColor: EchoColors.switchOn,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: EchoColors.switchOff,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/profile'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E3A8A).withOpacity(0.2),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: Color(0xFF2563EB),
              child: Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ada Chukwu', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  Text('Edit profile & preferences', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white38)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('"Ditto"', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
              IconButton(
                onPressed: () => _showDittoInfo(),
                icon: const Icon(Icons.info_outline_rounded, color: Colors.white38, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your active emergency duress code. Enter this if you are forced to deactivate Echo.',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white54, height: 1.4),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text('Change Phase', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _showDittoInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F3169),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('What is Ditto?', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(
          'Ditto is your secret duress code. If an attacker forces you to turn off Echo, enter "Ditto" instead of your real code. The app will look like it turned off, but it will silently alert your Inner Circle and the police that you are acting under pressure.',
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it', style: GoogleFonts.poppins(color: const Color(0xFF2563EB), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(IconData icon, String title, String sub, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF1E3A8A).withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(sub, style: GoogleFonts.poppins(fontSize: 12, color: Colors.white38, height: 1.4)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }
}
