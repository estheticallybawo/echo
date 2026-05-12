import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/gemma_provider.dart';
import '../services/device_info.dart';
import '../theme.dart';

class ModelSetupScreen extends StatefulWidget {
  const ModelSetupScreen({super.key});

  @override
  State<ModelSetupScreen> createState() => _ModelSetupScreenState();
}

class _ModelSetupScreenState extends State<ModelSetupScreen> {
  final List<ModelOption> _modelOptions = [
    ModelOption(
      name: 'Gemma 3 270M (Lightweight)',
      description: '~400 MB, runs on devices with 2GB RAM or more',
      modelUrl: 'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/gemma3-1b-it-int4.task?download=true',
      minRamGB: 2,
      isRecommended: true,
    ),
    ModelOption(
      name: 'Gemma 4 E2B (Balanced)',
      description: '~2 GB, best for 4‑6GB RAM devices',
      modelUrl: 'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it-web.task?download=true',
      minRamGB: 4,
    ),
    ModelOption(
      name: 'Gemma 4 E4B (Advanced)',
      description: '~10 GB, highest quality, needs ≥12GB RAM',
      modelUrl: 'https://huggingface.co/litert-community/gemma-4-E4B-it-litert-lm/resolve/main/gemma-4-E4B-it-web.task?download=true',
      minRamGB: 8,
    ),
  ];

  ModelOption? _selectedModel;
  final TextEditingController _tokenController = TextEditingController();
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  int _deviceRamGB = 4;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _loadDeviceInfo() async {
    final ramGB = await getDeviceRAMInGB();
    setState(() => _deviceRamGB = ramGB);
  }

  Future<void> _downloadAndSwitch() async {
    if (_selectedModel == null) return;
    final token = _tokenController.text.isNotEmpty ? _tokenController.text : const String.fromEnvironment('HUGGINGFACE_TOKEN');
    if (token.isEmpty) {
      setState(() => _error = 'Missing Hugging Face token');
      return;
    }

    setState(() {
      _isDownloading = true;
      _error = null;
      _downloadProgress = 0.0;
    });

    try {
      // Install model using flutter_gemma's builder pattern
      await FlutterGemma.installModel(
        modelType: ModelType.gemmaIt,
      )
      .fromNetwork(
        _selectedModel!.modelUrl,
        token: token,
        foreground: true,
      )
      .withProgress((progress) {
        // progress is between 0 and 100
        setState(() => _downloadProgress = progress / 100);
      })
      .install();

      // Reinitialize the provider with the new model
      final gemmaProvider = context.read<GemmaProvider>();
      await gemmaProvider.initialize(modelUrl: _selectedModel!.modelUrl, manualToken: token);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_selectedModel!.name} downloaded and activated!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _error = 'Download failed: $e');
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final compatibleModels = _modelOptions.where((m) => m.minRamGB <= _deviceRamGB).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
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
              // Custom App Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'AI Model Setup',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Device RAM card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A8A).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.memory, color: Color(0xFF2563EB), size: 28),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Device RAM',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  '$_deviceRamGB GB',
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Authentication',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _tokenController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                          hintText: 'Paste Hugging Face Token (Read access)',
                          hintStyle: const TextStyle(color: Colors.white38),
                          prefixIcon: const Icon(Icons.key, color: Colors.white54),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Choose a model to download',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Larger models provide better responses but require more RAM and storage.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white60,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (compatibleModels.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.orange.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Your device has insufficient RAM for any model. The lightweight model may still work; try downloading it anyway.',
                                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (compatibleModels.isNotEmpty)
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _modelOptions.length,
                          itemBuilder: (context, index) {
                            final model = _modelOptions[index];
                            final isCompatible = model.minRamGB <= _deviceRamGB;
                            final isSelected = _selectedModel == model;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF2563EB).withOpacity(0.2)
                                    : const Color(0xFF1E3A8A).withOpacity(0.3),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF2563EB).withOpacity(0.5)
                                      : Colors.white.withOpacity(0.1),
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: isCompatible ? () => setState(() => _selectedModel = model) : null,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      model.name,
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w600,
                                                        color: isCompatible ? Colors.white : Colors.white54,
                                                      ),
                                                    ),
                                                  ),
                                                  if (model.isRecommended)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: EchoColors.primary,
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: Text(
                                                        'Recommended',
                                                        style: GoogleFonts.poppins(fontSize: 10, color: Colors.white),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                model.description,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color: isCompatible ? Colors.white70 : Colors.white38,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Requires ${model.minRamGB}GB RAM',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 11,
                                                  color: isCompatible ? Colors.greenAccent : Colors.redAccent,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isSelected)
                                          const Icon(Icons.check_circle, color: Color(0xFF2563EB), size: 28),
                                        if (!isSelected && isCompatible)
                                          const Icon(Icons.radio_button_unchecked, color: Colors.white54, size: 24),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 24),
                      if (_isDownloading) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A8A).withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              LinearProgressIndicator(
                                value: _downloadProgress,
                                backgroundColor: Colors.white24,
                                valueColor: const AlwaysStoppedAnimation<Color>(EchoColors.primary),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Downloading... ${(_downloadProgress * 100).toInt()}%',
                                style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (_selectedModel != null && !_isDownloading) ? _downloadAndSwitch : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: EchoColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            _isDownloading ? 'Downloading...' : 'Download & Activate Model',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ModelOption {
  final String name;
  final String description;
  final String modelUrl;
  final int minRamGB;
  final bool isRecommended;

  ModelOption({
    required this.name,
    required this.description,
    required this.modelUrl,
    required this.minRamGB,
    this.isRecommended = false,
  });
}