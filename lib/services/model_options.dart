import 'package:cactus/cactus.dart';

class ModelOption {
  final String name;
  final String description;
  final String modelUrl;
  final String? mmprojUrl;
  final int minRamGB;
  final bool isRecommended;

  ModelOption({
    required this.name,
    required this.description,
    required this.modelUrl,
    this.mmprojUrl,
    required this.minRamGB,
    this.isRecommended = false,
  });
}

final List<ModelOption> availableModels = [
  ModelOption(
    name: "Gemma 2 2B (Ultra‑light)",
    description: "~1.7GB, text only, runs on any device.",
    modelUrl: "https://huggingface.co/lm-kit/gemma-2-2b-gguf/resolve/main/gemma-2-2b-it-Q4_K_M.gguf",
    mmprojUrl: null,
    minRamGB: 2,
    isRecommended: true,
  ),
  ModelOption(
    name: "Gemma 4 E2B (Balanced)",
    description: "~3.6GB, audio support, recommended for 4‑6GB RAM.",
    modelUrl: "https://huggingface.co/bartowski/google_gemma-4-E2B-it-GGUF/resolve/main/google_gemma-4-E2B-it-Q5_K_L.gguf",
    mmprojUrl: null, // bartowski models embed projector
    minRamGB: 4,
    isRecommended: true,
  ),
  ModelOption(
    name: "Gemma 4 E4B (Advanced)",
    description: "~5GB, higher quality, needs 8‑12GB RAM.",
    modelUrl: "https://huggingface.co/CQSystems/Google-Gemma-4-E4B-It-GGUF/resolve/main/Gemma_4_E4B_it_Q4_K_M.gguf",
    mmprojUrl: "https://huggingface.co/CQSystems/Google-Gemma-4-E4B-It-GGUF/resolve/main/mmproj-gemma-4-E4B-it-f16.gguf",
    minRamGB: 8,
  ),
];