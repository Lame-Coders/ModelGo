import 'package:flutter/material.dart';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class HuggingFacePage extends StatefulWidget {
  @override
  _HuggingFacePageState createState() => _HuggingFacePageState();
}

class _HuggingFacePageState extends State<HuggingFacePage> {
  final ReceivePort _port = ReceivePort();
  final TextEditingController _searchController = TextEditingController();
  
  List<dynamic> _models = [];
  bool _isLoading = false;
  bool _isDownloading = false;
  String? _currentTaskId;
  double _downloadProgress = 0.0;

  // MUST be 'int status' for the native compiler
  @pragma('vm:entry-point')
  static void downloadCallback(String id, int status, int progress) {
    final SendPort? send = IsolateNameServer.lookupPortByName('downloader_send_port');
    send?.send([id, status, progress]);
  }

  @override
  void initState() {
    super.initState();

    // 1. Show the educational warning right after the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showOptimizationWarning();
    });

    // 2. Setup the downloader port exactly as we fixed it before
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    IsolateNameServer.registerPortWithName(_port.sendPort, 'downloader_send_port');
    
    _port.listen((dynamic data) {
      String id = data[0];
      int statusInt = data[1] as int;
      int progress = data[2] as int;

      DownloadTaskStatus status = DownloadTaskStatus.fromInt(statusInt);

      if (_currentTaskId == id || _currentTaskId == null) {
        setState(() {
          _isDownloading = true;
          _currentTaskId = id;
          _downloadProgress = progress / 100.0;
        });

        if (status == DownloadTaskStatus.complete) {
          setState(() {
            _isDownloading = false;
            _currentTaskId = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Model downloaded successfully!')),
          );
        } else if (status == DownloadTaskStatus.failed || status == DownloadTaskStatus.canceled) {
          setState(() {
            _isDownloading = false;
            _currentTaskId = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Download failed or canceled.')),
          );
        }
      }
    });

    FlutterDownloader.registerCallback(downloadCallback);

    // Fetch initial default models
    _searchModels("Qwen2.5-1.5B"); 
  }

  // The new dynamic search function
  Future<void> _searchModels(String query) async {
    if (query.isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _models = [];
    });

    try {
      // Adding 'gguf' to the search query helps filter out raw tensor files automatically
      final response = await Dio().get('https://huggingface.co/api/models?search=$query gguf&limit=15');
      setState(() {
        _models = response.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to search models.')),
      );
    }
  }

  // The Educational Pop-Up
  void _showOptimizationWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text("Hardware Limits", style: TextStyle(fontSize: 18)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("To prevent your phone from crashing, please only download models that match these rules:"),
              SizedBox(height: 12),
              Text("• Format: Must be a .GGUF file.", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text("• Size: Keep it between 1B and 3B parameters (e.g., 1.5B, 2B)."),
              SizedBox(height: 8),
              Text("• Quantization: Look for 'Q4_K_M' or 'Q8_0' in the filename. (Raw BF16 files will crash)."),
              SizedBox(height: 8),
              Text("• Avoid: Do not download Vision (VL) models or Gemma 3 architectures yet."),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("I UNDERSTAND"),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadFile(String modelRepo) async {
    setState(() => _isLoading = true);

    try {
      // 1. Ask Hugging Face what files are inside this specific repository folder
      final response = await Dio().get('https://huggingface.co/api/models/$modelRepo/tree/main');
      final files = response.data as List;
      
      // 2. Hunt for the best mobile file (Q4_K_M is the gold standard, fallback to any .gguf)
      String? targetFilename;
      for (var file in files) {
        final path = file['path'] as String;
        if (path.toLowerCase().endsWith('.gguf')) {
          targetFilename = path;
          // If we find the highly optimized Q4 version, stop looking!
          if (path.toLowerCase().contains('q4_k_m')) break; 
        }
      }

      if (targetFilename == null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No suitable .gguf file found in this repository!')),
        );
        return;
      }

      // 3. Construct the direct, raw download link
      final downloadUrl = 'https://huggingface.co/$modelRepo/resolve/main/$targetFilename';
      
      // 4. Get the ultra-safe internal app directory so Android won't block it
      final dir = await getApplicationDocumentsDirectory();

      // 5. Fire up the native Android Downloader!
      final taskId = await FlutterDownloader.enqueue(
        url: downloadUrl,
        savedDir: dir.path,
        fileName: targetFilename.split('/').last,
        showNotification: true,
        openFileFromNotification: false,
      );

      setState(() {
        _isLoading = false;
        if (taskId != null) {
          _isDownloading = true;
          _currentTaskId = taskId;
        }
      });

    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start download: $e')),
      );
    }
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    _port.close();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hugging Face Models'),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: _showOptimizationWarning, // Let users read it again if they forget
          )
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search models (e.g., Llama-3.2-1B)',
                filled: true,
                fillColor: Colors.white,
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () => _searchModels(_searchController.text),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                contentPadding: EdgeInsets.symmetric(horizontal: 20),
              ),
              onSubmitted: _searchModels,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (_isDownloading)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text('Downloading Model...'),
                  SizedBox(height: 8),
                  LinearProgressIndicator(value: _downloadProgress),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _models.isEmpty
                    ? Center(child: Text('Search for a GGUF model to begin.'))
                    : ListView.builder(
                        itemCount: _models.length,
                        itemBuilder: (context, index) {
                          final model = _models[index];
                          return ListTile(
                            leading: Icon(Icons.download, color: Colors.blue),
                            title: Text(model['id']),
                            subtitle: Text('Downloads: ${model['downloads']}'),
                            onTap: () {
                              // Ensure you have your download logic connected here!
                              _downloadFile(model['id']); 
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}