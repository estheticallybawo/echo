import 'package:share_plus/share_plus.dart';

/// Share helper for community feed incidents
/// Uses native share dialog (iOS/Android/Web)
class ShareHelper {
  /// Format timestamp to human-readable "X ago"
  static String timeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} seconds ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    }
  }

  /// Build share text for community feed incident
  static String buildShareText({
    required String userId,
    required String state,
    required String hashtag,
    required DateTime triggeredAt,
    String? userName,
  }) {
    final timeInfo = timeAgo(triggeredAt);
    
    return '''🚨 Looking for $userId in $state
Last triggered Echo $timeInfo ago
Status: Needs community support

Help spread awareness: $hashtag
#EchoEmergency''';
  }

  /// Open native share dialog for incident
  static Future<void> shareIncident({
    required String userId,
    required String state,
    required String hashtag,
    required DateTime triggeredAt,
    String? userName,
  }) async {
    final shareText = buildShareText(
      userId: userId,
      state: state,
      hashtag: hashtag,
      triggeredAt: triggeredAt,
      userName: userName,
    );

    try {
      // Open native share sheet
      // User can select: Twitter, WhatsApp, Email, SMS, Telegram, etc.
      await Share.share(
        shareText,
        subject: 'Echo Emergency Alert - Help Needed',
      );
      
      print('✅ Share sheet opened for incident: $userId');
    } catch (e) {
      print('❌ Share error: $e');
      rethrow;
    }
  }

  /// Copy hashtag to clipboard only
  static Future<void> copyHashtagToClipboard(String hashtag) async {
    try {
      await Share.share(
        hashtag,
      );
      print('✅ Hashtag copied: $hashtag');
    } catch (e) {
      print('❌ Copy error: $e');
      rethrow;
    }
  }

  /// Build minimal share text (just for Twitter)
  static String buildTwitterShareText({
    required String userId,
    required String hashtag,
  }) {
    return 'Help find $userId: $hashtag #EchoEmergency';
  }
}
