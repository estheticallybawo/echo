import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/gemma_provider.dart';
import '../services/model_options.dart';
import '../services/model_manager.dart';
import '../services/device_info.dart';

class ModelSetupScreen extends StatefulWidget {
  const ModelSetupScreen({super.key});

  @override
  State<ModelSetupScreen> createState() => _ModelSetupScreenState();
}

class _ModelSetupScreenState extends State<ModelSetupScreen> {
  ModelOption? _selectedModel;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  int _deviceRamGB = 4;

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
    _loadSelectedModel();
  }

  Future<void> _loadDeviceInfo() async {
    final ramGB = await getDeviceRAMInGB();
    setState(() => _deviceRamGB = ramGB);
  }

  Future<void> _loadSelectedModel() async {
    final model = await ModelManager.getSelectedModel();
    setState(() => _selectedModel = model);
  }

  Future<void> _downloadModel() async {
    if (_selectedModel == null) return;

    setState(() => _isDownloading = true);

    try {
      await ModelManager.downloadModel(
        _selectedModel!,
        (progress) => setState(() => _downloadProgress = progress),
      );

      await ModelManager.setSelectedModel(_selectedModel!);
      await context.read<GemmaProvider>().switchToOnDevice();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Model downloaded successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup AI Model'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Device RAM: $_deviceRamGB GB',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            const Text(
              'Choose a model to download for on-device AI:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: availableModels.length,
                itemBuilder: (context, index) {
                  final model = availableModels[index];
                  final isCompatible = model.minRamGB <= _deviceRamGB;
                  final isSelected = _selectedModel == model;

                  return Card(
                    color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
                    child: ListTile(
                      title: Text(model.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(model.description),
                          Text(
                            'Requires ${model.minRamGB}GB RAM',
                            style: TextStyle(
                              color: isCompatible ? Colors.green : Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      trailing: isSelected ? const Icon(Icons.check) : null,
                      onTap: isCompatible ? () => setState(() => _selectedModel = model) : null,
                      enabled: isCompatible,
                    ),
                  );
                },
              ),
            ),
            if (_isDownloading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: _downloadProgress),
              const SizedBox(height: 8),
              Text('Downloading... ${( _downloadProgress * 100).toInt()}%'),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_selectedModel != null && !_isDownloading) ? _downloadModel : null,
                child: Text(_isDownloading ? 'Downloading...' : 'Download & Switch to On-Device'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}