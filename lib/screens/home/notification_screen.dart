import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  final List<Map<String, dynamic>> _notifications = const [
    {
      'title': 'Emergency Alert Shared',
      'sub': 'Your SOS alert was broadcast to 5 nearby users.',
      'time': 'Just now',
      'icon': Icons.broadcast_on_personal_rounded,
      'color': Colors.orangeAccent,
    },
    {
      'title': 'Inner Circle Update',
      'sub': 'Best Friend accepted your invitation to Tier 1.',
      'time': '1 hour ago',
      'icon': Icons.check_circle_rounded,
      'color': Color(0xFF10B981),
    },
    {
      'title': 'Safety Tip',
      'sub': 'High crime reported in Port Harcourt. Stay alert.',
      'time': '3 hours ago',
      'icon': Icons.lightbulb_outline_rounded,
      'color': Color(0xFFF59E0B),
    },
    {
      'title': 'Model Synced',
      'sub': 'Gemma 4 successfully synchronized your safety patterns.',
      'time': 'Yesterday',
      'icon': Icons.sync_rounded,
      'color': Color(0xFF2563EB),
    },
  ];

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
              // Standard Echo Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Notifications',
                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final item = _notifications[index];
                    return _buildNotificationCard(item);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A).withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: item['color'].withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(item['icon'], color: item['color'], size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item['title'], style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                    Text(item['time'], style: GoogleFonts.poppins(fontSize: 11, color: Colors.white38)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item['sub'],
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
