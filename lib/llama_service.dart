import 'dart:async';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';

class LlamaService {
  LlamaParent? _llama;
  StreamSubscription? _subscription;
  
  // We use a broadcast stream so we can listen to multiple messages in a row
  final StreamController<String> _tokenStream = StreamController<String>.broadcast();

  // 1. Load the model into RAM using a background isolate
  Future<void> loadModel(String modelPath) async {
    final loadCommand = LlamaLoad(
      path: modelPath,
      modelParams: ModelParams(), 
      contextParams: ContextParams(),
      samplingParams: SamplerParams(),
    );
    
    _llama = LlamaParent(loadCommand);
    await _llama!.init(); // Wait for the C++ engine to load the weights
    
    // Listen to the native C++ stream and pass the words to our Dart UI
    _subscription = _llama!.stream.listen((token) {
      _tokenStream.add(token);
    });
  }

  // 2. Send the user's prompt and stream the response
  Stream<String> generateResponse(String text) {
    if (_llama == null) throw Exception("Model not loaded");
    
    // CHANGED THIS LINE: It must be 'sendPrompt' for version 0.1.2+1
    _llama!.sendPrompt(text); 
    
    return _tokenStream.stream; // Stream words back as they are generated
  }

  // 3. Prevent memory leaks when leaving the chat screen
  void dispose() {
    _subscription?.cancel();
    _llama?.stop();
    _llama?.dispose();
    _tokenStream.close();
  }
}