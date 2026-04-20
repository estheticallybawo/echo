import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/community_feed_model.dart';

/// Individual Community Feed Card Widget
class CommunityFeedCard extends StatefulWidget {
  final CommunityFeedEntry entry;
  final VoidCallback onAmplifiedChanged;

  const CommunityFeedCard({
    super.key,
    required this.entry,
    required this.onAmplifiedChanged,
  });

  @override
  State<CommunityFeedCard> createState() => _CommunityFeedCardState();
}

class _CommunityFeedCardState extends State<CommunityFeedCard> {
  late bool _isAmplified;

  @override
  void initState() {
    super.initState();
    _isAmplified = widget.entry.userAmplified;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode
        ? EchoColors.surfaceSecondary
        : const Color(0xFFF0F7FF);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.entry.status == 'resolved'
              ? EchoColors.success.withOpacity(0.3)
              : EchoColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status and timestamp
          _buildHeader(context),
          const SizedBox(height: 12),

          // Main message
          _buildMessage(context),
          const SizedBox(height: 12),

          // Stats row
          if (widget.entry.shareCount > 0 || widget.entry.retweetCount != null)
            _buildStats(context),

          if (widget.entry.shareCount > 0 ||
              widget.entry.retweetCount != null)
            const SizedBox(height: 12),

          // Gemma assessment (if available)
          if (widget.entry.gemmaAssessment != null)
            _buildGemmaAssessment(context),

          if (widget.entry.gemmaAssessment != null)
            const SizedBox(height: 12),

          // Hashtag and action section
          _buildHashtagAndAction(context),
          const SizedBox(height: 12),

          // Amplified checkbox
          _buildAmplifiedCheckbox(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final statusColor = widget.entry.status == 'resolved'
        ? EchoColors.success
        : EchoColors.warning;
    final statusLabel =
        widget.entry.status == 'resolved' ? '✅ RESOLVED' : '🚨 ACTIVE';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                statusLabel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      inherit: false,
                    ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              widget.entry.getTimeElapsed(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: EchoColors.textSecondary,
                    inherit: false,
                  ),
            ),
          ],
        ),
        // Victim name
        Text(
          widget.entry.victimName,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                inherit: false,
              ),
        ),
      ],
    );
  }

  Widget _buildMessage(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        widget.entry.getFeedMessage(),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: EchoColors.textPrimary,
              inherit: false,
              height: 1.5,
            ),
      ),
    );
  }

  Widget _buildStats(BuildContext context) {
    return Row(
      children: [
        if (widget.entry.shareCount > 0) ...[
          Icon(Icons.share, size: 16, color: EchoColors.primary),
          const SizedBox(width: 4),
          Text(
            '${widget.entry.shareCount} amplifying',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: EchoColors.primary,
                  inherit: false,
                ),
          ),
          const SizedBox(width: 16),
        ],
        if (widget.entry.retweetCount != null) ...[
          Icon(Icons.favorite, size: 16, color: Colors.red),
          const SizedBox(width: 4),
          Text(
            '${widget.entry.retweetCount} retweets',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.red,
                  inherit: false,
                ),
          ),
        ],
      ],
    );
  }

  Widget _buildGemmaAssessment(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EchoColors.primaryLight.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: EchoColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.smart_toy_outlined,
            size: 18,
            color: EchoColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.entry.gemmaAssessment ?? '',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: EchoColors.textSecondary,
                    inherit: false,
                    fontStyle: FontStyle.italic,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHashtagAndAction(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: EchoColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.tag,
                  size: 16,
                  color: EchoColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.entry.hashTag,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: EchoColors.primary,
                          fontWeight: FontWeight.w600,
                          inherit: false,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.share_outlined, size: 16),
          label: const Text('Share', style: TextStyle(inherit: false)),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            backgroundColor: EchoColors.primary,
          ),
          onPressed: () {
            // Share functionality - can be implemented later
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Share: ${widget.entry.hashTag}',
                  style: const TextStyle(inherit: false),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAmplifiedCheckbox(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isAmplified = !_isAmplified;
        });
        widget.onAmplifiedChanged();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _isAmplified
              ? EchoColors.success.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _isAmplified
                ? EchoColors.success
                : EchoColors.textTertiary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Checkbox(
              value: _isAmplified,
              onChanged: (value) {
                setState(() {
                  _isAmplified = value ?? false;
                });
                widget.onAmplifiedChanged();
              },
              activeColor: EchoColors.success,
            ),
            Text(
              'Amplified',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _isAmplified
                        ? EchoColors.success
                        : EchoColors.textSecondary,
                    fontWeight:
                        _isAmplified ? FontWeight.w600 : FontWeight.normal,
                    inherit: false,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}