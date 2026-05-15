/// Centralized logging service for Echo development/debugging.
/// Provides consistent formatting and emoji-based categorization.
/// All logs go to terminal via print() - remove in production.
class EchoLogger {
  // Private constructor to prevent instantiation
  EchoLogger._();

  static const String _prefix = '🔔 ECHO';
  static String _redact(dynamic value) {
    final text = value?.toString() ?? '';
    if (text.isEmpty) return text;
    if (text.length <= 6) return '[REDACTED]';
    return '${text.substring(0, 2)}***${text.substring(text.length - 2)}';
  }

  /// Log feature initiation
  static void featureStart(String featureName, {Map<String, dynamic>? context}) {
    final contextStr = context != null ? ' | ${context.entries.map((e) => '${e.key}: ${e.value}').join(', ')}' : '';
    print('🚀 [$_prefix] $featureName initiated$contextStr');
  }

  /// Log feature completion
  static void featureComplete(String featureName, {dynamic result}) {
    final resultStr = result != null ? ' | Result: $result' : '';
    print('✅ [$_prefix] $featureName complete$resultStr');
  }

  /// Log feature error
  static void featureError(String featureName, Object error, {StackTrace? stackTrace}) {
    print('❌ [$_prefix] $featureName error: $error');
    if (stackTrace != null) {
      print('   Stack: $stackTrace');
    }
  }

  /// Log warning/deprecation
  static void warning(String message) {
    print('⚠️  [$_prefix] WARNING: $message');
  }

  /// Log data/input
  static void data(String label, dynamic value) {
    final piiLabel = label.toLowerCase();
    final isSensitive = piiLabel.contains('transcript') ||
        piiLabel.contains('location') ||
        piiLabel.contains('contact') ||
        piiLabel.contains('phone') ||
        piiLabel.contains('email');
    print('📝 [$_prefix] $label: ${isSensitive ? _redact(value) : value}');
  }

  /// Log analysis/result
  static void analysis(String label, dynamic value) {
    print('📊 [$_prefix] $label: $value');
  }

  /// Log timing
  static void timing(String label, int milliseconds) {
    print('⏱️  [$_prefix] $label: ${milliseconds}ms');
  }

  /// Log audio operation
  static void audio(String message) {
    print('🎙️ [$_prefix] AUDIO: $message');
  }

  /// Log location operation
  static void location(String message) {
    print('📍 [$_prefix] LOCATION: $message');
  }

  /// Log network/API operation
  static void network(String message) {
    print('📡 [$_prefix] NETWORK: $message');
  }

  /// Log Gemma/AI operation
  static void gemma(String message) {
    print('🤖 [$_prefix] GEMMA: $message');
  }

  /// Log message/notification
  static void message(String message) {
    print('💬 [$_prefix] MESSAGE: $message');
  }

  /// Log community/public operation
  static void community(String message) {
    print('🌐 [$_prefix] COMMUNITY: $message');
  }

  /// Log escalation event
  static void escalation(String tier, String event) {
    print('🚨 [$_prefix] ESCALATION [$tier]: $event');
  }

  /// Log threat assessment
  static void threatAssessment(String threatType, int confidence, String level) {
    print('🔍 [$_prefix] THREAT DETECTED');
    print('   Type: $threatType');
    print('   Confidence: $confidence%');
    print('   Level: $level');
  }

  /// Log safety instructions
  static void safetyInstructions(List<String> instructions) {
    print('📋 [$_prefix] SAFETY INSTRUCTIONS:');
    for (int i = 0; i < instructions.length; i++) {
      print('   ${i + 1}. ${instructions[i]}');
    }
  }

  /// Log incident closure
  static void incidentClosed(String incidentId, Duration duration, Map<String, dynamic> summary) {
    print('✅ [$_prefix] INCIDENT CLOSED');
    print('   ID: $incidentId');
    print('   Duration: ${duration.inMinutes}m ${duration.inSeconds % 60}s');
    print('   Summary: ${summary.entries.map((e) => '${e.key}=${e.value}').join(', ')}');
  }

  /// Log voice transcript received
  static void voiceTranscript(String transcript) {
    print('🎤 [$_prefix] VOICE TRANSCRIPT RECEIVED');
    print('   Text: [REDACTED]');
  }

  /// Log voice response generation
  static void voiceResponse(String message, {int? durationMs}) {
    print('🔊 [$_prefix] VOICE RESPONSE GENERATED');
    print('   Text: ${_redact(message)}');
    if (durationMs != null) {
      print('   Duration: ${durationMs}ms');
    }
  }

  /// Log custom multi-line message
  static void custom(String label, List<String> lines) {
    print('ℹ️  [$_prefix] $label:');
    for (final line in lines) {
      print('   $line');
    }
  }

  /// Debug: Log verbose data (only in debug mode)
  static void debug(String message, {dynamic data}) {
    // In production, this could be wrapped with:
    // if (kDebugMode) { ... }
    print('🔧 [$_prefix] DEBUG: $message');
    if (data != null) {
      print('   Data: $data');
    }
  }
}
