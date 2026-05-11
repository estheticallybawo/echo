import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme.dart';

class RespondersScreen extends StatelessWidget {
  final String incidentId;

  const RespondersScreen({super.key, required this.incidentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF02091A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Responders', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('incidents').doc(incidentId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data == null || data['responded'] != true) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.hourglass_empty_rounded, size: 64, color: Colors.white.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  Text(
                    'No responses yet',
                    style: GoogleFonts.poppins(color: Colors.white38, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          // Currently handles single responder based on functions/index.js
          // We can expand this to a list later if needed
          final name = data['responderName'] ?? 'Unknown Responder';
          final time = data['respondedAt'] as Timestamp?;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildResponderCard(name, time),
            ],
          );
        },
      ),
    );
  }

  Widget _buildResponderCard(String name, Timestamp? time) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EchoColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [EchoColors.primaryLight, EchoColors.primaryDark]),
            ),
            child: const Center(child: Icon(Icons.person, color: Colors.white)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                Text(
                  'Confirmed Help • ${time != null ? _formatTime(time) : 'Just now'}',
                  style: GoogleFonts.poppins(fontSize: 12, color: EchoColors.switchOn),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: EchoColors.switchOn, size: 24),
        ],
      ),
    );
  }

  String _formatTime(Timestamp ts) {
    final dt = ts.toDate();
    return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
