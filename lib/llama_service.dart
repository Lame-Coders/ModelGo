import 'dart:async';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';

class LlamaService {
  // We are using the raw Llama class now, completely bypassing LlamaParent!
  Llama? _llama;
  
  final StreamController<String> _tokenStream = StreamController.broadcast();
  Stream<String> get stream => _tokenStream.stream;

  Future<void> loadModel(String modelPath) async {
    final loadCommand = LlamaLoad(
      path: modelPath,
      modelParams: ModelParams(),
      // Keep the context small to protect your RAM
      contextParams: ContextParams()..nCtx = 2048,
      samplingParams: SamplerParams(),
    );

    // NUCLEAR OPTION: Load the C++ engine directly on the main thread.
    // The screen will freeze completely for 15-30 seconds. Do not touch it.
    // It cannot timeout!
    _llama = Llama(loadCommand);
  }

  Future<void> prompt(String text) async {
    if (_llama == null) return;
    
    try {
      // The raw prompt method returns an Iterable of words.
      final responseTokens = _llama!.prompt(text);
      
      for (final token in responseTokens) {
        _tokenStream.add(token);
        // CRITICAL: We must pause for 1 millisecond so Flutter can 
        // draw the new word on your screen before the C++ engine 
        // locks the thread to calculate the next word!
        await Future.delayed(const Duration(milliseconds: 1));
      }
      _tokenStream.add("[DONE]");
      
    } catch (e) {
      _tokenStream.add("Error: $e");
    }
  }

  void dispose() {
    _llama?.dispose();
    _tokenStream.close();
  }
}