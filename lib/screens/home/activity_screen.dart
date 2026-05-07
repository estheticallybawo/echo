import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final List<Map<String, dynamic>> _feedItems = [
    {
      'id': '1',
      'risk': 'High Risk',
      'riskColor': Colors.orangeAccent,
      'time': '2 min ago',
      'location': 'D-Line Junction, Port Harcourt',
      'distance': '250m away',
      'proximityLabel': 'CRITICAL PROXIMITY',
      'date': '9:41 AM · Apr 22, 2026',
      'desc': 'Possible abduction. Phone movement irregular. Raised voices detected in background audio.',
      'amplifiedCount': 50,
      'retweets': '1000',
      'isAmplified': false,
    },
    {
      'id': '2',
      'risk': 'Medium Risk',
      'riskColor': EchoColors.secondaryLight,
      'time': '15 min ago',
      'location': 'Garrison, Port Harcourt',
      'distance': '1.2km away',
      'proximityLabel': 'NEARBY',
      'date': '9:30 AM · Apr 22, 2026',
      'desc': 'Sudden scream detected. Device orientation changed rapidly. Tracking initiated.',
      'amplifiedCount': 12,
      'retweets': '150',
      'isAmplified': false,
    },
    {
      'id': '3',
      'risk': 'Resolved',
      'riskColor': Colors.white38,
      'time': '1 hour ago',
      'location': 'Trans Amadi, Port Harcourt',
      'distance': '3.5km away',
      'proximityLabel': 'SECURE',
      'date': '8:30 AM · Apr 22, 2026',
      'desc': 'Situation resolved. User confirmed safety via secondary verification.',
      'amplifiedCount': 5,
      'retweets': '20',
      'isAmplified': false,
    }
  ];

  final List<Map<String, dynamic>> _notifications = [
    {
      'title': 'Emergency Alert',
      'sub': 'Your emergency alert was shared with 3 contacts.',
      'time': '2 hours ago',
      'icon': Icons.notification_important_rounded,
      'color': Colors.orangeAccent,
    },
    {
      'title': 'Safety Score Update',
      'sub': 'Your environment safety score increased to 92%.',
      'time': '5 hours ago',
      'icon': Icons.security_rounded,
      'color': const Color(0xFF00A3C4),
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleAmplify(int index) {
    setState(() {
      final item = _feedItems[index];
      if (item['isAmplified']) {
        item['amplifiedCount']--;
        item['isAmplified'] = false;
      } else {
        item['amplifiedCount']++;
        item['isAmplified'] = true;
      }
    });
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
              // Header
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
                      'Echo Feed',
                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 22),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              
              // Spaced & Polished Tabs
              Container(
                margin: const EdgeInsets.fromLTRB(20, 12, 20, 20), // Increased bottom margin
                height: 56,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: TabBar(
                  controller: _tabController,
                  dividerColor: Colors.transparent, // Removes the harsh white line
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: const Color(0xFF1E3A8A).withOpacity(0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8),
                    ],
                  ),
                  labelStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                  unselectedLabelStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500),
                  unselectedLabelColor: Colors.white38,
                  labelColor: Colors.white,
                  tabs: const [
                    Tab(text: 'Live Feed'),
                    Tab(text: 'Notifications'),
                  ],
                ),
              ),
              
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLiveFeed(),
                    _buildNotifications(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


Widget _buildLiveFeed() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('echo_feed')
        .orderBy('timestamp', descending: true)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(
          child: Text(
            'Error loading feed: ${snapshot.error}',
            style: const TextStyle(color: Colors.red),
          ),
        );
      }

      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }

      final entries = snapshot.data!.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final timestamp = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
        return {
          'id': doc.id,
          'risk': data['threatLevel'] == 'critical' 
              ? 'Critical Risk' 
              : data['threatLevel'] == 'high' 
                  ? 'High Risk' 
                  : 'Medium Risk',
          'riskColor': data['threatLevel'] == 'critical' 
              ? Colors.redAccent 
              : data['threatLevel'] == 'high' 
                  ? Colors.orangeAccent 
                  : EchoColors.secondaryLight,
          'time': _formatTimeAgo(timestamp),
          'location': data['location'] ?? 'Unknown',
          'distance': 'Nearby', // You can calculate real distance if you have user location
          'proximityLabel': 'ACTIVE',
          'date': _formatDate(timestamp),
          'desc': data['postText'] ?? 'Emergency reported',
          'amplifiedCount': data['shareCount'] ?? 0,
          'retweets': '0', // Not using X anymore
          'isAmplified': false,
          'victimName': data['victimName'] ?? 'Someone',
          'policeHandle': data['policeHandle'],
          'hotline': data['hotline'],
        };
      }).toList();

      if (entries.isEmpty) {
        return const Center(
          child: Text(
            'No active cases at the moment',
            style: TextStyle(color: Colors.white54),
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          return _buildFeedCardFromData(entries[index], index);
        },
      );
    },
  );
}

String _formatTimeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

String _formatDate(DateTime date) {
  return '${date.hour}:${date.minute.toString().padLeft(2, '0')} · ${date.month}/${date.day}/${date.year}';
}

  Widget _buildFeedCardFromData(Map<String, dynamic> item, int index) {
  final isAmplified = item['isAmplified'] as bool;
  
  return Container(
    margin: const EdgeInsets.only(bottom: 24),
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: const Color(0xFF1E3A8A).withOpacity(0.2),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: Colors.white.withOpacity(0.05)),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: item['riskColor']),
                ),
                const SizedBox(width: 8),
                Text(item['risk'], style: GoogleFonts.poppins(color: item['riskColor'], fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00A3C4).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF00A3C4).withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome, color: Color(0xFF00A3C4), size: 10),
                      const SizedBox(width: 4),
                      Text('Gemma Intel', style: GoogleFonts.poppins(color: const Color(0xFF00A3C4), fontSize: 9, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            Text(item['time'], style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              item['proximityLabel'],
              style: GoogleFonts.poppins(
                color: item['riskColor'].withOpacity(0.8),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '• ${item['distance']}',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF02091A).withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _feedRow(Icons.sos, '${item['victimName']} may be in danger', Colors.redAccent),
              const SizedBox(height: 12),
              _feedRow(Icons.location_on, item['location'], Colors.white70),
              const SizedBox(height: 12),
              _feedRow(Icons.access_time_filled, item['date'], Colors.white70),
              const SizedBox(height: 16),
              Text('#EchoEmergency', style: GoogleFonts.poppins(color: const Color(0xFF2563EB), fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.only(left: 12),
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: Color(0xFF2563EB), width: 2)),
          ),
          child: Text(
            item['desc'],
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14, height: 1.5),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Icon(Icons.ios_share, color: isAmplified ? const Color(0xFF00A3C4) : Colors.white38, size: 18),
            const SizedBox(width: 6),
            Text('${item['amplifiedCount']} Amplified', style: GoogleFonts.poppins(color: isAmplified ? const Color(0xFF00A3C4) : Colors.white38, fontSize: 12, fontWeight: isAmplified ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            GestureDetector(
              onTap: () => _toggleAmplifyFromData(index, item, context),
              child: _buildFeedAction(
                Icons.auto_awesome, 
                'Amplify', 
                isAmplified ? const Color(0xFF00A3C4) : Colors.white70,
              ),
            ),
            const Spacer(),
            _buildFeedAction(Icons.share_outlined, 'Share', Colors.white, isPrimary: true),
          ],
        ),
      ],
    ),
  );
}

void _toggleAmplifyFromData(int index, Map<String, dynamic> item, BuildContext context) {
  // Update Firestore shareCount
  final docRef = FirebaseFirestore.instance.collection('echo_feed').doc(item['id']);
  docRef.update({
    'shareCount': FieldValue.increment(item['isAmplified'] ? -1 : 1),
  });
  setState(() {
    item['isAmplified'] = !item['isAmplified'];
  });
}

  Widget _feedRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))),
      ],
    );
  }

  Widget _buildFeedAction(IconData icon, String label, Color color, {bool isPrimary = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isPrimary ? 24 : 12, vertical: 12),
      decoration: BoxDecoration(
        color: isPrimary ? const Color(0xFF1E3A8A) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: isPrimary ? null : Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.poppins(color: color, fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildNotifications() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final item = _notifications[index];
        return _buildNotificationItem(item);
      },
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
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
                Text(item['sub'], style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
