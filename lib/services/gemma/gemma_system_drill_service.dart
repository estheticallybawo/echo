import 'llama_config.dart';
import 'llama_threat_service.dart';

enum GemmaSystemDrillStep { health, warmup, inference }

enum GemmaSystemDrillStepStatus { pending, running, success, failure }

typedef GemmaHealthCheck = Future<bool> Function();

typedef GemmaWarmupCheck =
    Future<Map<String, dynamic>> Function(
      String prompt, {
      int maxTokens,
      Duration timeout,
    });

typedef GemmaInferenceCheck =
    Future<Map<String, dynamic>> Function(
      String input, {
      int maxTokens,
      Duration timeout,
    });

class GemmaSystemDrillStepState {
  final GemmaSystemDrillStep step;
  final String title;
  final String subtitle;
  final GemmaSystemDrillStepStatus status;
  final int elapsedMs;
  final String? message;

  const GemmaSystemDrillStepState({
    required this.step,
    required this.title,
    required this.subtitle,
    this.status = GemmaSystemDrillStepStatus.pending,
    this.elapsedMs = 0,
    this.message,
  });

  GemmaSystemDrillStepState copyWith({
    GemmaSystemDrillStepStatus? status,
    int? elapsedMs,
    String? message,
  }) {
    return GemmaSystemDrillStepState(
      step: step,
      title: title,
      subtitle: subtitle,
      status: status ?? this.status,
      elapsedMs: elapsedMs ?? this.elapsedMs,
      message: message ?? this.message,
    );
  }
}

class GemmaSystemDrillSnapshot {
  final Map<GemmaSystemDrillStep, GemmaSystemDrillStepState> steps;
  final bool isRunning;
  final bool isPassed;
  final String overallStatus;
  final String? errorMessage;
  final int totalElapsedMs;
  final Map<String, dynamic>? drillResult;

  const GemmaSystemDrillSnapshot({
    required this.steps,
    required this.isRunning,
    required this.isPassed,
    required this.overallStatus,
    this.errorMessage,
    this.totalElapsedMs = 0,
    this.drillResult,
  });

  GemmaSystemDrillStepState step(GemmaSystemDrillStep step) => steps[step]!;

  GemmaSystemDrillSnapshot copyWith({
    Map<GemmaSystemDrillStep, GemmaSystemDrillStepState>? steps,
    bool? isRunning,
    bool? isPassed,
    String? overallStatus,
    String? errorMessage,
    int? totalElapsedMs,
    Map<String, dynamic>? drillResult,
  }) {
    return GemmaSystemDrillSnapshot(
      steps: steps ?? this.steps,
      isRunning: isRunning ?? this.isRunning,
      isPassed: isPassed ?? this.isPassed,
      overallStatus: overallStatus ?? this.overallStatus,
      errorMessage: errorMessage,
      totalElapsedMs: totalElapsedMs ?? this.totalElapsedMs,
      drillResult: drillResult ?? this.drillResult,
    );
  }
}

class GemmaSystemDrillService {
  GemmaSystemDrillService({
    GemmaHealthCheck? healthCheck,
    GemmaWarmupCheck? warmupCheck,
    GemmaInferenceCheck? inferenceCheck,
    LlamaThreatService? llamaThreatService,
  }) : _healthCheck = healthCheck ?? (() => LlamaConfig.isServerHealthy()),
       _llamaThreatService = llamaThreatService ?? LlamaThreatService(),
       _warmupCheck = warmupCheck,
       _inferenceCheck = inferenceCheck;

  static const warmupPrompt =
      '<|turn>system\n'
      'You are Echo, a voice-first safety and emergency assistant. '
      'Echo evaluates user danger reports conservatively, supports timed '
      'escalation, and never triggers real alerts during drills. For threat '
      'assessment, return ONLY compact single-line JSON with keys: threat, '
      'confidence, threatLevel, action, summary, analyzedSituation.<turn|>\n'
      '<|turn>user\n'
      'Readiness warm-up only. Load this context and return exactly '
      '{"status":"ready"}.<turn|>\n'
      '<|turn>model\n';

  static const inferencePrompt =
      '<|turn>system\n'
      'You are Echo, a voice-first safety assistant. This is a drill, not a '
      'real emergency. Return ONLY compact single-line JSON with keys: threat, '
      'confidence, threatLevel, action, summary, analyzedSituation. No markdown.'
      '<turn|>\n'
      '<|turn>user\n'
      'SAFETY DRILL ONLY. Classify this simulated report: I think someone is '
      'following me from a black car while I walk home. Use this exact shape: '
      '{"threat":"stalking","confidence":80,"threatLevel":"high","action":"monitor and prepare escalation","summary":"Drill report parsed.","analyzedSituation":"being followed by a black car"}'
      '<turn|>\n'
      '<|turn>model\n';
  final GemmaHealthCheck _healthCheck;
  final LlamaThreatService _llamaThreatService;
  final GemmaWarmupCheck? _warmupCheck;
  final GemmaInferenceCheck? _inferenceCheck;

  GemmaSystemDrillSnapshot initialSnapshot() {
    return GemmaSystemDrillSnapshot(
      steps: _initialSteps(),
      isRunning: false,
      isPassed: false,
      overallStatus: 'Not started',
    );
  }

  Stream<GemmaSystemDrillSnapshot> run() async* {
    var snapshot = GemmaSystemDrillSnapshot(
      steps: _initialSteps(),
      isRunning: true,
      isPassed: false,
      overallStatus: 'Running live Gemma drill...',
    );
    final totalStopwatch = Stopwatch()..start();

    yield snapshot;

    Future<MapEntry<GemmaSystemDrillStepState, T?>> runStep<T>({
      required GemmaSystemDrillStep step,
      required String runningStatus,
      required Future<T> Function() action,
    }) async {
      final stepStopwatch = Stopwatch()..start();
      snapshot = _withStep(
        snapshot,
        step,
        status: GemmaSystemDrillStepStatus.running,
        message: runningStatus,
      ).copyWith(overallStatus: runningStatus);
      try {
        final result = await action();
        stepStopwatch.stop();
        final state = snapshot
            .step(step)
            .copyWith(
              status: GemmaSystemDrillStepStatus.success,
              elapsedMs: stepStopwatch.elapsedMilliseconds,
              message: 'Passed',
            );
        return MapEntry(state, result);
      } catch (e) {
        stepStopwatch.stop();
        final state = snapshot
            .step(step)
            .copyWith(
              status: GemmaSystemDrillStepStatus.failure,
              elapsedMs: stepStopwatch.elapsedMilliseconds,
              message: e.toString(),
            );
        return MapEntry(state, null);
      }
    }

    final health = await runStep<bool>(
      step: GemmaSystemDrillStep.health,
      runningStatus: 'Checking Gemma server health...',
      action: _healthCheck,
    );
    snapshot = _withStepState(snapshot, health.key);
    yield snapshot;

    if (health.value != true) {
      snapshot = _withStep(
        snapshot,
        GemmaSystemDrillStep.health,
        status: GemmaSystemDrillStepStatus.failure,
        message: 'Gemma server offline',
      );
      yield _failedSnapshot(
        snapshot,
        totalStopwatch,
        'Gemma server offline',
        'Start llama.cpp at ${LlamaConfig.activeHost} and retry.',
      );
      return;
    }

    final warmup = await runStep<Map<String, dynamic>>(
      step: GemmaSystemDrillStep.warmup,
      runningStatus: 'Warming up Gemma with Echo context...',
      action: () => (_warmupCheck ?? _llamaThreatService.warmupCheck)(
        warmupPrompt,
        maxTokens: 16,
        timeout: const Duration(seconds: 120),
      ),
    );
    snapshot = _withStepState(snapshot, warmup.key);
    yield snapshot;

    final warmupResult = warmup.value;
    if (warmupResult == null || warmupResult['status'] == 'error') {
      snapshot = _withStep(
        snapshot,
        GemmaSystemDrillStep.warmup,
        status: GemmaSystemDrillStepStatus.failure,
        message: 'Warm-up response was not accepted.',
      );
      yield _failedSnapshot(
        snapshot,
        totalStopwatch,
        'Gemma warm-up failed',
        warmupResult?['error']?.toString() ??
            'Warm-up response was not accepted.',
      );
      return;
    }

    final inference = await runStep<Map<String, dynamic>>(
      step: GemmaSystemDrillStep.inference,
      runningStatus: 'Running live drill inference...',
      action: () => (_inferenceCheck ?? _llamaThreatService.warmupCheck)(
        inferencePrompt,
        maxTokens: 64,
        timeout: const Duration(seconds: 240),
      ),
    );
    snapshot = _withStepState(snapshot, inference.key);
    yield snapshot;

    final drillResult = inference.value;
    if (!_isValidDrillResult(drillResult)) {
      snapshot = _withStep(
        snapshot,
        GemmaSystemDrillStep.inference,
        status: GemmaSystemDrillStepStatus.failure,
        message: 'Invalid drill payload.',
      );
      yield _failedSnapshot(
        snapshot,
        totalStopwatch,
        'Drill inference failed',
        'Gemma returned an invalid drill payload. Retry after the server finishes the previous request.',
      );
      return;
    }

    totalStopwatch.stop();
    yield snapshot.copyWith(
      isRunning: false,
      isPassed: true,
      overallStatus: 'Gemma active: live drill passed',
      errorMessage: null,
      totalElapsedMs: totalStopwatch.elapsedMilliseconds,
      drillResult: drillResult,
    );
  }

  bool _isValidDrillResult(Map<String, dynamic>? result) {
    if (result == null) return false;
    final summary = (result['summary'] ?? '').toString().toLowerCase();
    final analyzedSituation = (result['analyzedSituation'] ?? '')
        .toString()
        .toLowerCase();
    final action = (result['action'] ?? '').toString().toLowerCase();
    final hasRequiredShape =
        result['threat'] != null &&
        result['confidence'] is num &&
        result['threatLevel'] != null &&
        result['action'] != null &&
        result['summary'] != null &&
        result['analyzedSituation'] != null;
    final isFallback =
        analyzedSituation == 'fallback mode' ||
        summary.contains('ai temporarily unavailable') ||
        action.contains('manual emergency options');
    return hasRequiredShape && !isFallback;
  }

  GemmaSystemDrillSnapshot _failedSnapshot(
    GemmaSystemDrillSnapshot snapshot,
    Stopwatch totalStopwatch,
    String overallStatus,
    String errorMessage,
  ) {
    totalStopwatch.stop();
    return snapshot.copyWith(
      isRunning: false,
      isPassed: false,
      overallStatus: overallStatus,
      errorMessage: errorMessage,
      totalElapsedMs: totalStopwatch.elapsedMilliseconds,
    );
  }

  GemmaSystemDrillSnapshot _withStep(
    GemmaSystemDrillSnapshot snapshot,
    GemmaSystemDrillStep step, {
    required GemmaSystemDrillStepStatus status,
    String? message,
  }) {
    return _withStepState(
      snapshot,
      snapshot.step(step).copyWith(status: status, message: message),
    );
  }

  GemmaSystemDrillSnapshot _withStepState(
    GemmaSystemDrillSnapshot snapshot,
    GemmaSystemDrillStepState state,
  ) {
    final updated = Map<GemmaSystemDrillStep, GemmaSystemDrillStepState>.from(
      snapshot.steps,
    );
    updated[state.step] = state;
    return snapshot.copyWith(steps: updated, errorMessage: null);
  }

  Map<GemmaSystemDrillStep, GemmaSystemDrillStepState> _initialSteps() {
    return const {
      GemmaSystemDrillStep.health: GemmaSystemDrillStepState(
        step: GemmaSystemDrillStep.health,
        title: 'Server Health Check',
        subtitle: 'Verifies Gemma endpoint is reachable.',
      ),
      GemmaSystemDrillStep.warmup: GemmaSystemDrillStepState(
        step: GemmaSystemDrillStep.warmup,
        title: 'Warm up Call',
        subtitle: 'Loads Echo context and JSON response rules.',
      ),
      GemmaSystemDrillStep.inference: GemmaSystemDrillStepState(
        step: GemmaSystemDrillStep.inference,
        title: 'Live Drill Inference',
        subtitle: 'Analyzes a safe scenario and validates JSON output.',
      ),
    };
  }
}
