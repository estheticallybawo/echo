import 'dart:typed_data';

class GemmaLocalService {
  Future<void> init() async {}
  Future<String> analyzeMultimodalAudio({
    required String address,
    required Uint8List rawAudioBuffer,
    required List<Uint8List> trainedSignatureTokens,
  }) async {
    return "Local analysis pending...";
  }
}
