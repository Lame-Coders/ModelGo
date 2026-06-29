import 'package:llama_cpp_dart/llama_cpp_dart.dart';
import 'dart:async';

class LlamaService {
  LlamaCpp? _llama;

  // 1. Load the model into RAM
  Future<void> loadModel(String modelPath) async {
    _llama = LlamaCpp(
      modelPath: modelPath,
      contextSize: 2048, // Adjust based on your phone's RAM (2048 is safe for most)
    );
    await _llama!.load();
  }

  // 2. Stream the text response
  Stream<String> generateResponse(String prompt) {
    if (_llama == null) throw Exception("Model not loaded");
    
    // This streams tokens as they are generated
    return _llama!.predict(prompt);
  }

  // 3. Clean up memory when switching models
  void dispose() {
    _llama?.dispose();
    _llama = null;
  }
}