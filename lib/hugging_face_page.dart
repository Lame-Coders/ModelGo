import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'model_dao.dart';

class HuggingFacePage extends StatefulWidget {
  @override
  _HuggingFacePageState createState() => _HuggingFacePageState();
}

class _HuggingFacePageState extends State<HuggingFacePage> {
  final TextEditingController _searchController = TextEditingController();
  final Dio _dio = Dio();
  
  List<dynamic> _models = [];
  bool _isLoading = false;
  
  // Download State
  String? _downloadingFileName;
  double _downloadProgress = 0.0;
  bool _isDownloading = false;
  
  // NEW: Token to control cancellation
  CancelToken? _cancelToken; 

  Future<void> _searchModels(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _dio.get(
        'https://huggingface.co/api/models',
        queryParameters: {
          'search': query,
          'filter': 'gguf',
          'limit': 15,
        },
      );

      setState(() {
        _models = response.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch models: $e')),
      );
    }
  }

  Future<void> _showModelFiles(String modelId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await _dio.get('https://huggingface.co/api/models/$modelId');
      Navigator.pop(context); 

      final siblings = response.data['siblings'] as List<dynamic>;
      final ggufFiles = siblings
          .map((s) => s['rfilename'] as String)
          .where((name) => name.endsWith('.gguf'))
          .toList();

      if (ggufFiles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No .gguf files found in this repository.')),
        );
        return;
      }

      _showFileSelectionBottomSheet(modelId, ggufFiles);
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch files.')),
      );
    }
  }

  void _showFileSelectionBottomSheet(String modelId, List<String> files) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView.builder(
          itemCount: files.length,
          itemBuilder: (context, index) {
            final fileName = files[index];
            return ListTile(
              leading: Icon(Icons.download),
              title: Text(fileName),
              onTap: () {
                Navigator.pop(context);
                _downloadModelFile(modelId, fileName);
              },
            );
          },
        );
      },
    );
  }

  Future<void> _downloadModelFile(String modelId, String fileName) async {
    // NEW: Initialize the cancel token before starting
    _cancelToken = CancelToken();

    setState(() {
      _isDownloading = true;
      _downloadingFileName = fileName;
      _downloadProgress = 0.0;
    });

    final dir = await getApplicationDocumentsDirectory();
    final savePath = '${dir.path}/$fileName';

    try {
      final downloadUrl = 'https://huggingface.co/$modelId/resolve/main/$fileName';
      
      await _dio.download(
        downloadUrl,
        savePath,
        cancelToken: _cancelToken, // NEW: Attach the token to the download
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      final dao = ModelDao();
      await dao.insert({'fileName': savePath});

      setState(() {
        _isDownloading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Model downloaded successfully!')),
      );

    } on DioException catch (e) {
      setState(() {
        _isDownloading = false;
      });
      
      // NEW: Check if the error was caused by the user canceling
      if (CancelToken.isCancel(e)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download canceled by user.')),
        );
        // Clean up the partially downloaded file
        final partialFile = File(savePath);
        if (await partialFile.exists()) {
          await partialFile.delete();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: ${e.message}')),
        );
      }
    }
  }

  // NEW: Method to trigger cancellation
  void _cancelDownload() {
    _cancelToken?.cancel("User triggered cancel");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Hugging Face Hub')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search for GGUF models',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: _searchModels,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () => _searchModels(_searchController.text),
                ),
              ],
            ),
          ),
          
          if (_isDownloading)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text('Downloading: $_downloadingFileName'),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(value: _downloadProgress),
                      ),
                      SizedBox(width: 10),
                      Text('${(_downloadProgress * 100).toStringAsFixed(1)}%'),
                      // NEW: Cancel Button in the UI
                      IconButton(
                        icon: Icon(Icons.cancel, color: Colors.red),
                        onPressed: _cancelDownload,
                        tooltip: 'Cancel Download',
                      ),
                    ],
                  ),
                ],
              ),
            ),

          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _models.length,
                    itemBuilder: (context, index) {
                      final model = _models[index];
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          title: Text(model['id'], style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Downloads: ${model['downloads']}'),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: _isDownloading ? null : () => _showModelFiles(model['id']),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}