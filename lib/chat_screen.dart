import 'package:flutter/material.dart';
import 'llama_service.dart'; // Ensure you have created this

class ChatScreen extends StatefulWidget {
  final String modelName;
  final String modelPath;

  const ChatScreen({required this.modelName, required this.modelPath});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final LlamaService _llamaService = LlamaService();
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeModel();
  }

  Future<void> _initializeModel() async {
    try {
      await _llamaService.loadModel(widget.modelPath);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text("Engine Crash", style: TextStyle(color: Colors.red)),
            content: Text("The C++ engine failed to load this model. It likely uses an unsupported architecture (like Gemma 3 or Qwen 3.5).\n\nError details: $e"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to manage models screen
                },
                child: Text("GO BACK"),
              )
            ],
          )
        );
      }
    }
  }

  void _sendMessage(String text) async {
    if (text.isEmpty) return;
    
    setState(() {
      _messages.add({"role": "user", "content": text});
      _messages.add({"role": "assistant", "content": ""}); // Placeholder
    });
    _controller.clear();

    // Stream tokens one by one
    await for (final token in _llamaService.generateResponse(text)) {
      setState(() {
        _messages.last["content"] = _messages.last["content"]! + token;
      });
    }
  }

  @override
  void dispose() {
    _llamaService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.modelName)),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _messages.length,
                    itemBuilder: (context, index) => ListTile(
                      title: Text(_messages[index]["role"]!),
                      subtitle: Text(_messages[index]["content"]!),
                    ),
                  ),
                ),
                TextField(
                  controller: _controller,
                  onSubmitted: _sendMessage,
                  decoration: InputDecoration(hintText: "Type a message..."),
                ),
              ],
            ),
    );
  }
}