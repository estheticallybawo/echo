import 'package:flutter/material.dart';
import '../models/community_feed_model.dart';
import 'community_feed_card.dart';

/// Community Feed Section Widget for Home Screen
class CommunityFeedSection extends StatefulWidget {
  final List<CommunityFeedEntry> feedEntries;
  final VoidCallback onRefresh;

  const CommunityFeedSection({
    super.key,
    required this.feedEntries,
    required this.onRefresh,
  });

  @override
  State<CommunityFeedSection> createState() => _CommunityFeedSectionState();
}

class _CommunityFeedSectionState extends State<CommunityFeedSection> {
  @override
  Widget build(BuildContext context) {
    if (widget.feedEntries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'No active cases at the moment',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF888888),
              inherit: false,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.public, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Echo Feed',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  inherit: false,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.feedEntries.length} active case${widget.feedEntries.length > 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF888888),
                          inherit: false,
                        ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: widget.onRefresh,
                tooltip: 'Refresh feed',
              ),
            ],
          ),
        ),

        // Feed entries
        ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: widget.feedEntries.length,
          itemBuilder: (context, index) {
            return CommunityFeedCard(
              entry: widget.feedEntries[index],
              onAmplifiedChanged: () {
                // Handle amplification change
                // Can integrate with Firestore here
              },
            );
          },
        ),
      ],
    );
  }
}
