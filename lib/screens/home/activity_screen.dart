import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme.dart';
import '../../services/demo/demo_emergency_service.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<String> _amplifiedFeedIds = {};

  final List<Map<String, dynamic>> _feedItems = [
    {
      'id': '1',
      'risk': 'Missing Person',
      'riskColor': Colors.orangeAccent,
      'time': '2 min ago',
      'location': 'Port Harcourt area',
      'distance': 'Area only',
      'proximityLabel': 'COMMUNITY CASE',
      'date': '9:41 AM · Apr 22, 2026',
      'desc':
          'Community report: Tonia has not been reachable since leaving a campus interview. Please amplify with the same details and direct verified updates to her trusted contact.',
      'amplifiedCount': 50,
      'retweets': '1000',
      'isAmplified': false,
      'victimName': 'Tonia A.',
      'hashTag': '#FindToniaA',
      'privacyNote': 'Exact location link hidden from public feed.',
    },
    {
      'id': '2',
      'risk': 'Unresolved Alert',
      'riskColor': EchoColors.secondaryLight,
      'time': '15 min ago',
      'location': 'Garrison axis',
      'distance': 'Area only',
      'proximityLabel': 'NEEDS AMPLIFICATION',
      'date': '9:30 AM · Apr 22, 2026',
      'desc':
          'Echo SOS was triggered and contacts have not marked the user safe. Public feed shows only a coarse area while private contacts keep sensitive details.',
      'amplifiedCount': 12,
      'retweets': '150',
      'isAmplified': false,
      'victimName': 'Echo User',
      'hashTag': '#EchoHelpNow',
      'privacyNote': 'Exact location link hidden from public feed.',
    },
    {
      'id': '3',
      'risk': 'Resolved',
      'riskColor': Colors.white38,
      'time': '1 hour ago',
      'location': 'Trans Amadi area',
      'distance': 'Area only',
      'proximityLabel': 'SECURE',
      'date': '8:30 AM · Apr 22, 2026',
      'desc':
          'Situation resolved. User confirmed safety via secondary verification.',
      'amplifiedCount': 5,
      'retweets': '20',
      'isAmplified': false,
      'victimName': 'Ada C.',
      'hashTag': '#AdaIsSafe',
      'privacyNote': 'Exact location link hidden from public feed.',
    },
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

  Future<void> _showPostCaseSheet() async {
    final nameController = TextEditingController();
    final areaController = TextEditingController();
    final detailsController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF02091A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withOpacity(0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.person_search_rounded,
                      color: Color(0xFF9EC5FF),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Post a missing person case',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Demo-safe public post. Use a broad area only. Exact map links stay private with trusted contacts.',
                style: GoogleFonts.poppins(
                  color: Colors.white60,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              _buildCaseField(
                controller: nameController,
                label: 'Name or initials',
                hint: 'e.g. Ada C.',
              ),
              const SizedBox(height: 12),
              _buildCaseField(
                controller: areaController,
                label: 'Last-known public area',
                hint: 'e.g. Ikoyi area, Lagos',
              ),
              const SizedBox(height: 12),
              _buildCaseField(
                controller: detailsController,
                label: 'Public details to amplify',
                hint: 'What should the community know?',
                maxLines: 4,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _submitMissingCase(
                    sheetContext,
                    nameController.text,
                    areaController.text,
                    detailsController.text,
                  ),
                  icon: const Icon(Icons.campaign_rounded),
                  label: const Text('Post to Echo Feed'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    nameController.dispose();
    areaController.dispose();
    detailsController.dispose();
  }

  Widget _buildCaseField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.poppins(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.poppins(color: Colors.white70),
        hintStyle: GoogleFonts.poppins(color: Colors.white30),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF2563EB)),
        ),
      ),
    );
  }

  void _submitMissingCase(
    BuildContext sheetContext,
    String rawName,
    String rawArea,
    String rawDetails,
  ) {
    final name = rawName.trim();
    final area = rawArea.trim();
    final details = rawDetails.trim();

    if (name.isEmpty || area.isEmpty || details.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a name, broad area, and details.')),
      );
      return;
    }

    final now = DateTime.now();
    final hashTag = _buildMissingCaseHashTag(name);
    setState(() {
      _feedItems.insert(0, {
        'id': 'manual_${now.millisecondsSinceEpoch}',
        'risk': 'Missing Person',
        'riskColor': const Color.fromARGB(255, 255, 194, 82),
        'time': 'Just now',
        'location': area,
        'distance': 'Area only',
        'proximityLabel': 'COMMUNITY CASE',
        'date': _formatDate(now),
        'desc':
            'Community report: $details\n\nExact map links are hidden from the public feed. Share this post to amplify the same verified details.',
        'amplifiedCount': 0,
        'retweets': '0',
        'isAmplified': false,
        'victimName': name,
        'hashTag': hashTag,
        'privacyNote': 'Exact location link hidden from public feed.',
      });
    });

    Navigator.pop(sheetContext);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$name posted to Echo Feed for amplification.')),
    );
  }

  String _buildMissingCaseHashTag(String name) {
    final safe = name
        .replaceAll(RegExp(r'[^A-Za-z0-9 ]'), '')
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join();
    return safe.isEmpty ? '#FindWithEcho' : '#Find$safe';
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
                      'Echo Feed',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Post missing person case',
                      onPressed: _showPostCaseSheet,
                      icon: const Icon(
                        Icons.post_add_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),

              // Spaced & Polished Tabs
              Container(
                margin: const EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  20,
                ), // Increased bottom margin
                height: 56,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: TabBar(
                  controller: _tabController,
                  dividerColor:
                      Colors.transparent, // Removes the harsh white line
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: const Color(0xFF1E3A8A).withOpacity(0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  labelStyle: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                  unselectedLabelStyle: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
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
                  children: [_buildLiveFeed(), _buildNotifications()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveFeed() {
    return StreamBuilder<DemoIncident?>(
      stream: DemoEmergencyService().incidentStream,
      initialData: DemoEmergencyService().activeIncident,
      builder: (context, snapshot) {
        final incident = snapshot.data;
        final entries = <Map<String, dynamic>>[
          if (incident != null)
            {
              'id': incident.id,
              'risk': incident.tier >= 3
                  ? 'Critical Risk'
                  : incident.tier >= 2
                  ? 'High Risk'
                  : 'Medium Risk',
              'riskColor': incident.tier >= 3
                  ? const Color.fromARGB(255, 255, 186, 82)
                  : incident.tier >= 2
                  ? Colors.orangeAccent
                  : EchoColors.secondaryLight,
              'time': _formatTimeAgo(incident.updatedAt),
              'location': incident.locationText,
              'distance': 'Area only',
              'proximityLabel': incident.isSafe ? 'RESOLVED' : 'ACTIVE',
              'date': _formatDate(incident.updatedAt),
              'desc':
                  '${incident.summary}\n\nLatest: ${incident.events.isNotEmpty ? incident.events.last.detail : 'Waiting for contact response.'}\n\nExact map links are hidden from the public feed and shared only with trusted responders.',
              'amplifiedCount':
                  incident.events.length +
                  (_amplifiedFeedIds.contains(incident.id) ? 1 : 0),
              'retweets': '${incident.tier}',
              'isAmplified': _amplifiedFeedIds.contains(incident.id),
              'victimName': 'Echo Demo User',
              'hashTag': '#EchoHelpNow',
              'privacyNote': 'Exact location link hidden from public feed.',
            },
          ..._feedItems,
        ];

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
    final victimName = (item['victimName'] as String?) ?? 'Echo user';
    final location = (item['location'] as String?) ?? 'Area withheld';
    final hashTag = (item['hashTag'] as String?) ?? '#EchoEmergency';
    final privacyNote =
        (item['privacyNote'] as String?) ??
        'Exact location link hidden from public feed.';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A).withOpacity(0.2),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
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
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: item['riskColor'],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item['risk'],
                    style: GoogleFonts.poppins(
                      color: item['riskColor'],
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00A3C4).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: const Color(0xFF00A3C4).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          color: Color(0xFF00A3C4),
                          size: 10,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Gemma Intel',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF00A3C4),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Text(
                item['time'],
                style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12),
              ),
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
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
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
                _feedRow(
                  Icons.sos,
                  '$victimName may be in danger',
                  const Color.fromARGB(255, 255, 194, 82),
                ),
                const SizedBox(height: 12),
                _feedRow(
                  Icons.public_rounded,
                  'Public area: $location',
                  Colors.white70,
                ),
                const SizedBox(height: 12),
                _feedRow(
                  Icons.privacy_tip_outlined,
                  privacyNote,
                  Colors.white54,
                ),
                const SizedBox(height: 12),
                _feedRow(
                  Icons.access_time_filled,
                  item['date'],
                  Colors.white70,
                ),
                const SizedBox(height: 16),
                Text(
                  hashTag,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF2563EB),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.only(left: 12),
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: Color(0xFF2563EB), width: 2),
              ),
            ),
            child: Text(
              item['desc'],
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(
                Icons.ios_share,
                color: isAmplified ? const Color(0xFF00A3C4) : Colors.white38,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                '${item['amplifiedCount']} Amplified',
                style: GoogleFonts.poppins(
                  color: isAmplified ? const Color(0xFF00A3C4) : Colors.white38,
                  fontSize: 12,
                  fontWeight: isAmplified ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              GestureDetector(
                onTap: () => _toggleAmplifyFromData(item),
                child: _buildFeedAction(
                  Icons.auto_awesome,
                  'Amplify',
                  isAmplified ? const Color(0xFF00A3C4) : Colors.white70,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _shareFeedCase(item),
                child: _buildFeedAction(
                  Icons.share_outlined,
                  'Share',
                  Colors.white,
                  isPrimary: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _toggleAmplifyFromData(Map<String, dynamic> item) {
    final id = item['id'].toString();
    final wasAmplified =
        _amplifiedFeedIds.contains(id) || item['isAmplified'] == true;
    setState(() {
      if (wasAmplified) {
        _amplifiedFeedIds.remove(id);
        item['amplifiedCount'] = ((item['amplifiedCount'] as num?) ?? 1) - 1;
      } else {
        _amplifiedFeedIds.add(id);
        item['amplifiedCount'] = ((item['amplifiedCount'] as num?) ?? 0) + 1;
      }
      item['isAmplified'] = !wasAmplified;
    });
  }

  void _shareFeedCase(Map<String, dynamic> item) {
    final victimName = (item['victimName'] as String?) ?? 'Echo user';
    final location = (item['location'] as String?) ?? 'area withheld';
    final hashTag = (item['hashTag'] as String?) ?? '#EchoEmergency';
    final shareText =
        'Missing person alert: $victimName was last reported around $location. '
        'Exact map links are hidden for privacy. Please amplify verified updates through Echo. '
        '$hashTag';

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF02091A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Share-ready Echo post',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SelectableText(
            shareText,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Copy'),
            ),
          ],
        );
      },
    );
  }

  Widget _feedRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedAction(
    IconData icon,
    String label,
    Color color, {
    bool isPrimary = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isPrimary ? 24 : 12,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: isPrimary ? const Color(0xFF1E3A8A) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: isPrimary
            ? null
            : Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
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
            decoration: BoxDecoration(
              color: item['color'].withOpacity(0.1),
              shape: BoxShape.circle,
            ),
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
                    Text(
                      item['title'],
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      item['time'],
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item['sub'],
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
