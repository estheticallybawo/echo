import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'model_options.dart';

const _kSelectedModelKey = 'selected_model_name';
const _kModelDirectoryName = 'gemma_models';

class ModelManager {
  static Future<Directory> _getModelDirectory() async {
    final appDoc = await getApplicationDocumentsDirectory();
    final modelDir = Directory('${appDoc.path}${Platform.pathSeparator}$_kModelDirectoryName');
    if (!await modelDir.exists()) {
      await modelDir.create(recursive: true);
    }
    return modelDir;
  }

  static String _sanitizeFilename(String name) {
    return name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_-]'), '_');
  }

  static File _modelFile(ModelOption model) {
    final filename = '${_sanitizeFilename(model.name)}.gguf';
    return File(filename);
  }

  static File _modelFileForPath(Directory dir, ModelOption model) {
    final filename = '${_sanitizeFilename(model.name)}.gguf';
    return File('${dir.path}${Platform.pathSeparator}$filename');
  }

  static File _mmprojFileForPath(Directory dir, ModelOption model) {
    final filename = '${_sanitizeFilename(model.name)}.mmproj.gguf';
    return File('${dir.path}${Platform.pathSeparator}$filename');
  }

  static Future<ModelOption?> getSelectedModel() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedName = prefs.getString(_kSelectedModelKey);
    if (selectedName == null) return null;
    for (final model in availableModels) {
      if (model.name == selectedName) {
        return model;
      }
    }
    return null;
  }

  static Future<void> setSelectedModel(ModelOption model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSelectedModelKey, model.name);
  }

  static Future<String?> getModelPath() async {
    final selectedModel = await getSelectedModel();
    if (selectedModel == null) return null;
    final modelDir = await _getModelDirectory();
    final modelFile = _modelFileForPath(modelDir, selectedModel);
    if (await modelFile.exists()) {
      return modelFile.path;
    }
    return null;
  }

  static Future<String> _downloadFile(
    Uri url,
    File destination,
    void Function(double progress) onProgress,
  ) async {
    final request = http.Request('GET', url);
    final response = await request.send();

    if (response.statusCode != 200) {
      throw Exception('Failed to download model asset: ${response.statusCode}');
    }

    final contentLength = response.contentLength ?? 0;
    var bytesReceived = 0;
    final sink = destination.openWrite();

    await for (final chunk in response.stream) {
      bytesReceived += chunk.length;
      sink.add(chunk);
      if (contentLength > 0) {
        onProgress(bytesReceived / contentLength);
      }
    }

    await sink.flush();
    await sink.close();

    if (contentLength > 0) {
      onProgress(1.0);
    }

    return destination.path;
  }

  static Future<void> downloadModel(
    ModelOption model,
    void Function(double progress) onProgress,
  ) async {
    final modelDir = await _getModelDirectory();
    final modelFile = _modelFileForPath(modelDir, model);

    if (await modelFile.exists()) {
      onProgress(1.0);
      return;
    }

    final uri = Uri.parse(model.modelUrl);
    await _downloadFile(uri, modelFile, onProgress);

    if (model.mmprojUrl != null) {
      final mmprojUri = Uri.parse(model.mmprojUrl!);
      final mmprojFile = _mmprojFileForPath(modelDir, model);
      await _downloadFile(mmprojUri, mmprojFile, (_) {});
    }
  }

  static Future<bool> isModelDownloaded(ModelOption model) async {
    final modelDir = await _getModelDirectory();
    final modelFile = _modelFileForPath(modelDir, model);
    return await modelFile.exists();
  }

  static Future<List<String>> listDownloadedModels() async {
    final modelDir = await _getModelDirectory();
    if (!await modelDir.exists()) return [];
    return modelDir
        .listSync()
        .whereType<File>()
        .map((file) => file.path)
        .toList();
  }
}
