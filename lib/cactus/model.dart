import 'package:cactus/cactus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class MultiModalAgent {
  late CactusLM _llm;
  late CactusTranscription _audioProcessor;

  Future<void> initModels() async {
    // Get the local path where models are stored
    final directory = await getApplicationDocumentsDirectory();
    final llmPath = '${"C:\llama.cpp\models\gemma-4-E2B-it-Q8_0.gguf"}/gemma-e2b.gguf';
    final audioPath = 'C:\llama.cpp\models\mmproj-gemma-4-E2B-it-Q8_0.gguf/audio-encoder.gguf';

    // 1. Initialize Audio Encoder first (Smaller, ~500MB)
    _audioProcessor = CactusTranscription(
      modelPath: audioPath,
      enableVAD: true, // Voice Activity Detection for conversational feel
    );
    await _audioProcessor.initialize();

    // 2. Initialize LLM (Larger, ~4GB)
    _llm = CactusLM(
      modelPath: llmPath,
      // Critical for hardware limitations: limit context size and threads
      contextSize: 2048, 
      threads: 4, 
    );
    await _llm.initializeModel();
  }
  
  // Example of using both for a conversational flow
  Future<void> processSpeech(String audioFilePath) async {
    final transcript = await _audioProcessor.transcribe(audioFilePath);
    
    final responseStream = _llm.generateCompletionStream(
      messages: [ChatMessage(role: 'user', content: transcript)],
    );

    await for (final chunk in responseStream) {
      // Update UI with chunk.token
    }
  }
}
