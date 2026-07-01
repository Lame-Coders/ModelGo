import 'dart:async';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';

class LlamaService {
  LlamaParent? _llama;

  // 1. Safely load the model in the background
  Future<void> loadModel(String modelPath) async {
    final loadCommand = LlamaLoad(
      path: modelPath,
      modelParams: ModelParams(),
      // CRITICAL: Protects your phone's RAM so it doesn't crash
      contextParams: ContextParams()..nCtx = 2048,
      samplingParams: SamplerParams(),
    );

    _llama = LlamaParent(loadCommand);
    await _llama!.init(); 
  }

  // 2. Your chat_screen.dart is specifically begging for this method!
  Stream<String> generateResponse(String text) {
    if (_llama == null) {
      throw Exception("Engine not loaded!");
    }
    
    // FIXED: In version 0.1.2+1, it is sendPrompt, not prompt!
    _llama!.sendPrompt(text);
    
    // Return the stream of words directly to your UI so your 'await for' loop works
    return _llama!.stream;
  }

  void dispose() {
    _llama?.stop();
  }
}