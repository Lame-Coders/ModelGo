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

    final allGgufFiles = siblings.where((s) {
      final name = s['rfilename'] as String;
      return name.endsWith('.gguf');
    }).toList();

    if (allGgufFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No GGUF files found.')),
      );
      return;
    }

    // Sort with safe null-checking for 'size'
    allGgufFiles.sort((a, b) {
      // Use '?? 0' to treat null sizes as 0 bytes, preventing the crash
      final sizeA = (a['size'] ?? 0) as int;
      final sizeB = (b['size'] ?? 0) as int;
      return sizeA.compareTo(sizeB);
    });

    _showFileSelectionBottomSheet(modelId, allGgufFiles);
  } catch (e) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error loading files: ${e.toString()}')),
    );
  }
}

// Scoring helper: Higher = better for mobile inference
int _calculateMobileScore(String name) {
  int score = 0;
  if (name.contains('Q4_K_M')) score += 100; // The industry standard
  if (name.contains('K_M')) score += 50;     // General K-quants are good
  if (name.contains('Q5_K_M')) score += 80;  // High quality
  if (name.contains('Q4_0')) score += 20;    // Basic but runnable
  return score;
}

  // Helper method to format bytes into readable MB or GB
  String _formatSize(int bytes) {
    final double mb = bytes / (1024 * 1024);
    if (mb > 1024) {
      final double gb = mb / 1024;
      return '${gb.toStringAsFixed(2)} GB';
    }
    return '${mb.toStringAsFixed(0)} MB';
  }

  // Updated to accept the full file object (so we can read the size)
  void _showFileSelectionBottomSheet(String modelId, List<dynamic> files) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Select Quantization (<4GB)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: files.length,
                itemBuilder: (context, index) {
                  final fileData = files[index];
                  final fileName = fileData['rfilename'] as String;
                  final fileSize = (fileData['size'] ?? 0) as int;
                  final fileSizeStr = _formatSize(fileData['size'] as int);

                  return ListTile(
                    leading: Icon(Icons.download, color: Colors.blue),
                    title: Text(fileName, style: TextStyle(fontSize: 14)),
                    trailing: Text(fileSizeStr, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
                    onTap: () {
                      Navigator.pop(context);
                      _downloadModelFile(modelId, fileName);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _downloadModelFile(String modelId, String fileName) async {
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
        cancelToken: _cancelToken, 
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
      
      if (CancelToken.isCancel(e)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download canceled by user.')),
        );
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