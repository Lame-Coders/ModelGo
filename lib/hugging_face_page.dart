import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'dart:isolate';
import 'dart:ui';
import 'dart:io';
import 'model_dao.dart';

class HuggingFacePage extends StatefulWidget {
  @override
  _HuggingFacePageState createState() => _HuggingFacePageState();
}

class _HuggingFacePageState extends State<HuggingFacePage> {
  final Dio _dio = Dio();
  
  List<dynamic> _models = [];
  bool _isLoading = false;
  
  // Download State
  String? _downloadingFileName;
  double _downloadProgress = 0.0;
  bool _isDownloading = false;
  String? _currentTaskId;

  ReceivePort _port = ReceivePort();

  @override
  void initState() {
    super.initState();
    
    // 1. Clear any old port mappings (Crucial for preventing frozen UI on Hot Restarts)
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    
    // 2. Register the new port
    IsolateNameServer.registerPortWithName(_port.sendPort, 'downloader_send_port');
    
    _port.listen((dynamic data) {
      String id = data[0];
      int statusIndex = data[1] as int;
      int progress = data[2] as int;

      // Extract the enum safely using the index
      DownloadTaskStatus status = DownloadTaskStatus.values[statusIndex]; 

      // Update UI even if the app was minimized and _currentTaskId was lost
      if (_currentTaskId == id || _currentTaskId == null) { 
        if (!_isDownloading && status == DownloadTaskStatus.running) {
             setState(() { _isDownloading = true; _currentTaskId = id; });
        }

        setState(() {
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
            SnackBar(content: Text(status == DownloadTaskStatus.canceled ? 'Download canceled.' : 'Download failed.')),
          );
        }
      }
    });

    FlutterDownloader.registerCallback(downloadCallback);

    _fetchMobileFriendlyModels();
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    super.dispose();
  }

  // Must be static or top-level to run in the background isolate
  @pragma('vm:entry-point')
  static void downloadCallback(String id, int status, int progress) { // CHANGED THIS TO int status
    final SendPort? send = IsolateNameServer.lookupPortByName('downloader_send_port');
    send?.send([id, status, progress]);
  }
  
  Future<void> _fetchMobileFriendlyModels() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _dio.get(
        'https://huggingface.co/api/models',
        queryParameters: {
          'filter': 'gguf',
          'sort': 'downloads',
          'direction': -1,
          'limit': 25,
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

      allGgufFiles.sort((a, b) {
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

  String _formatSize(int bytes) {
    if (bytes == 0) return 'Unknown Size'; 
    final double mb = bytes / (1024 * 1024);
    if (mb > 1024) {
      final double gb = mb / 1024;
      return '${gb.toStringAsFixed(2)} GB';
    }
    return '${mb.toStringAsFixed(0)} MB';
  }

  void _showFileSelectionBottomSheet(String modelId, List<dynamic> files) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Select Quantization',
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
                  final fileSizeStr = _formatSize(fileSize);

                  return ListTile(
                    leading: Icon(Icons.download, color: Colors.blue),
                    title: Text(fileName, style: TextStyle(fontSize: 14)),
                    trailing: Text(fileSizeStr, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
                    onTap: () {
                      Navigator.pop(context);
                      _startBackgroundDownload(modelId, fileName);
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

  Future<void> _startBackgroundDownload(String modelId, String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final downloadUrl = 'https://huggingface.co/$modelId/resolve/main/$fileName';

    setState(() {
      _isDownloading = true;
      _downloadingFileName = fileName;
      _downloadProgress = 0.0;
    });

    try {
      final taskId = await FlutterDownloader.enqueue(
        url: downloadUrl,
        savedDir: dir.path,
        fileName: fileName,
        showNotification: true, // Shows progress in the Android notification tray
        openFileFromNotification: false,
      );

      setState(() {
        _currentTaskId = taskId;
      });
    } catch (e) {
      setState(() {
        _isDownloading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start download: $e')),
      );
    }
  }
  
  Future<void> _handleDownloadComplete() async {
    if (_downloadingFileName == null) return;
    
    final dir = await getApplicationDocumentsDirectory();
    final savePath = '${dir.path}/$_downloadingFileName';
    
    final dao = ModelDao();
    await dao.insert({'fileName': savePath});

    setState(() {
      _isDownloading = false;
      _currentTaskId = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Model downloaded successfully!')),
    );
  }

  void _cancelDownload() {
    if (_currentTaskId != null) {
      FlutterDownloader.cancel(taskId: _currentTaskId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Popular Mobile Models')),
      body: Column(
        children: [
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
                : _models.isEmpty
                    ? Center(child: Text('No models found.'))
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