import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme.dart';

class AccountSetupsScreen extends StatefulWidget {
  const AccountSetupsScreen({super.key});

  @override
  State<AccountSetupsScreen> createState() => _AccountSetupsScreenState();
}

class _AccountSetupsScreenState extends State<AccountSetupsScreen> {
  bool microphoneEnabled = false;
  bool locationEnabled = false;
  bool contactsEnabled = false;
  bool notificationsEnabled = false;
  bool shakeEnabled = false;
  bool volumeLongPressEnabled = false;

  Widget _buildProgressBar() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(7, (index) {
        final bool active = index == 1;
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
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool enabled,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!enabled),
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF12284A),
          borderRadius: BorderRadius.circular(26),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: EchoColors.primary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      height: 1.6,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Transform.scale(
              scale: 0.95,
              child: Switch.adaptive(
                value: enabled,
                activeColor: Colors.white,
                activeTrackColor: Colors.green,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: EchoColors.switchOff,
                onChanged: onChanged,
              ),
            ),
          ],
        ),
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
            center: Alignment(0, -0.5),
            radius: 1.3,
            colors: [Color(0xFF0E2F6A), Color(0xFF07131F)],
            stops: [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                      InkWell(
                        onTap: () => Navigator.maybePop(context),
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
                    _buildProgressBar(),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  'To protect you, Echo needs a few things',
                  style: GoogleFonts.poppins(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildPermissionItem(
                          icon: Icons.mic_rounded,
                          title: 'Microphone',
                          subtitle:
                              'Used for background listening only when Echo is active to detect distress and record audio.',
                          enabled: microphoneEnabled,
                          onChanged: (value) =>
                              setState(() => microphoneEnabled = value),
                        ),
                        _buildPermissionItem(
                          icon: Icons.location_on_rounded,
                          title: 'Location',
                          subtitle:
                              'So your contacts know exactly where to find you in an emergency.',
                          enabled: locationEnabled,
                          onChanged: (value) =>
                              setState(() => locationEnabled = value),
                        ),
                        _buildPermissionItem(
                          icon: Icons.contacts_rounded,
                          title: 'Contacts',
                          subtitle:
                              'Lets you choose people who should be alerted when you need help.',
                          enabled: contactsEnabled,
                          onChanged: (value) =>
                              setState(() => contactsEnabled = value),
                        ),
                        _buildPermissionItem(
                          icon: Icons.notifications_rounded,
                          title: 'Notifications',
                          subtitle:
                              'So you receive updates when someone is checking on your safety.',
                          enabled: notificationsEnabled,
                          onChanged: (value) =>
                              setState(() => notificationsEnabled = value),
                        ),
                        _buildPermissionItem(
                          icon: Icons.vibration_rounded,
                          title: 'Panic Shake Your Phone',
                          subtitle:
                              'Trigger SOS by aggressively shaking the phone. Lets you activate help without looking.',
                          enabled: shakeEnabled,
                          onChanged: (value) =>
                              setState(() => shakeEnabled = value),
                        ),
                        _buildPermissionItem(
                          icon: Icons.volume_up_rounded,
                          title: 'Long Press Volume Button',
                          subtitle:
                              'Trigger SOS by holding any volume button. Perfect for discreet activation in your pocket.',
                          enabled: volumeLongPressEnabled,
                          onChanged: (value) =>
                              setState(() => volumeLongPressEnabled = value),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'You can change these later in Settings > Permissions',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    height: 1.6,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 62,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/tier1-inner-circle-setup');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EchoColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 10,
                      shadowColor: EchoColors.primary.withOpacity(0.35),
                    ),
                    child: Text(
                      'Continue',
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
