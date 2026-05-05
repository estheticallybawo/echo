import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/permission_service.dart';
// Removed voice_setup_screen import

class PermissionsSetupScreen extends StatefulWidget {
  const PermissionsSetupScreen({super.key});

  @override
  State<PermissionsSetupScreen> createState() => _PermissionsSetupScreenState();
}

class _PermissionsSetupScreenState extends State<PermissionsSetupScreen> with WidgetsBindingObserver {
  bool _locationGranted = false;
  bool _microphoneGranted = false;
  bool _contactsGranted = false;
  bool _notificationsGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkInitialStatuses();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkInitialStatuses();
    }
  }

  Future<void> _checkInitialStatuses() async {
    _locationGranted = await PermissionService.isGranted(Permission.location);
    _microphoneGranted = await PermissionService.isGranted(Permission.microphone);
    _contactsGranted = await PermissionService.isGranted(Permission.contacts);
    _notificationsGranted = await PermissionService.isGranted(Permission.notification);
    if (mounted) setState(() {});
  }

  Future<void> _handlePermission(Permission permission, Function(bool) update) async {
    final status = await permission.status;

    if (status.isPermanentlyDenied) {
      await openAppSettings();
    } else {
      final result = await permission.request();
      update(result.isGranted);
    }

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.3),
            radius: 1.2,
            colors: [Color(0xFF0F3169), Color(0xFF02091A)],
            stops: [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                    ),
                    Row(
                      children: [
                        ...List.generate(3, (index) => Container(
                          width: index == 1 ? 32 : 6,
                          height: 6,
                          margin: const EdgeInsets.only(left: 4),
                          decoration: BoxDecoration(
                            color: index <= 1 ? const Color(0xFF2563EB) : Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        )),
                      ],
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),
                      Text(
                        "To protect you, Echo needs a few things",
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 40),

                      _PermissionTile(
                        title: "Microphone",
                        subtitle: "Used for background listening only when Echo is active to detect distress.",
                        icon: Icons.mic_none_outlined,
                        isGranted: _microphoneGranted,
                        onTap: () => _handlePermission(
                          Permission.microphone,
                          (val) => _microphoneGranted = val,
                        ),
                      ),

                      _PermissionTile(
                        title: "Location",
                        subtitle: "So your contacts know exactly where to find you in an emergency.",
                        icon: Icons.location_on_outlined,
                        isGranted: _locationGranted,
                        onTap: () => _handlePermission(
                          Permission.location,
                          (val) => _locationGranted = val,
                        ),
                      ),

                      _PermissionTile(
                        title: "Contacts",
                        subtitle: "Lets you choose people who should be alerted when you need help.",
                        icon: Icons.people_outline,
                        isGranted: _contactsGranted,
                        onTap: () => _handlePermission(
                          Permission.contacts,
                          (val) => _contactsGranted = val,
                        ),
                      ),

                      _PermissionTile(
                        title: "Notifications",
                        subtitle: "So you receive updates when someone responds to your alert.",
                        icon: Icons.notifications_none_outlined,
                        isGranted: _notificationsGranted,
                        onTap: () => _handlePermission(
                          Permission.notification,
                          (val) => _notificationsGranted = val,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: (_locationGranted && _microphoneGranted)
                        ? const Color(0xFF2563EB)
                        : Colors.white12,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: ElevatedButton(
                    onPressed: (_locationGranted && _microphoneGranted)
                        ? () {
                            Navigator.of(context).pushReplacementNamed('/home');
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: Text(
                      "Continue",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: (_locationGranted && _microphoneGranted) ? Colors.white : Colors.white38,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isGranted;
  final VoidCallback onTap;

  const _PermissionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isGranted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted ? const Color(0xFF2563EB).withOpacity(0.5) : Colors.white10,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isGranted ? const Color(0xFF2563EB).withOpacity(0.2) : Colors.white10,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isGranted ? const Color(0xFF2563EB) : Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: isGranted,
            onChanged: (val) {
              if (val) {
                onTap();
              } else {
                openAppSettings();
              }
            },
            activeColor: const Color(0xFFFFFFFF),
            activeTrackColor: const Color(0xFF2563EB).withOpacity(0.3),
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.white10,
          ),
        ],
      ),
    );
  }
}
