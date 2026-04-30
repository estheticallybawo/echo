import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme.dart';
import '../services/share_helper.dart';

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Safety Feed'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: EchoColors.surface,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('communityFeed')
            .where('status', isEqualTo: 'active')
            .orderBy('timestamp', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final incidents = snapshot.data?.docs ?? [];

          if (incidents.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 64,
                    color: EchoColors.primary.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'All Clear',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text('No active incidents in your area'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: incidents.length,
              itemBuilder: (context, index) {
                final incident = incidents[index];
                final data = incident.data() as Map<String, dynamic>;
                final timestamp = (data['timestamp'] as Timestamp?)?.toDate() ??
                    DateTime.now();
                final userId = data['userId'] as String? ?? 'Unknown User';
                final state = data['state'] as String? ?? 'Unknown State';
                final hashtag = data['hashtag'] as String? ?? '#echo';
                final shareCount = data['shareCount'] as int? ?? 0;

                return _IncidentCard(
                  userId: userId,
                  state: state,
                  hashtag: hashtag,
                  timestamp: timestamp,
                  shareCount: shareCount,
                  incidentId: incident.id,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _IncidentCard extends StatelessWidget {
  final String userId;
  final String state;
  final String hashtag;
  final DateTime timestamp;
  final int shareCount;
  final String incidentId;

  const _IncidentCard({
    required this.userId,
    required this.state,
    required this.hashtag,
    required this.timestamp,
    required this.shareCount,
    required this.incidentId,
  });

  Future<void> _handleShare(BuildContext context) async {
    try {
      await ShareHelper.shareIncident(
        userId: userId,
        state: state,
        hashtag: hashtag,
        triggeredAt: timestamp,
      );

      // Optionally log share attempt
      await FirebaseFirestore.instance
          .collection('communityFeed')
          .doc(incidentId)
          .update({
            'shareCount': FieldValue.increment(1),
          });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Sharing incident...'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeAgo = ShareHelper.timeAgo(timestamp);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: EchoColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and user info
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: EchoColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.emergency_share,
                    color: EchoColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Looking for $userId',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '$state • $timeAgo',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: EchoColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Hashtag display
            Container(
              decoration: BoxDecoration(
                color: EchoColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.tag,
                    size: 16,
                    color: EchoColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    hashtag,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: EchoColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                // Share count
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: EchoColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.share,
                          size: 16,
                          color: EchoColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$shareCount shared',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: EchoColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Share button
                ElevatedButton.icon(
                  onPressed: () => _handleShare(context),
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Share'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EchoColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
