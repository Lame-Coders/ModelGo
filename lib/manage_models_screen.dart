import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_downloader/flutter_downloader.dart'; // Added downloader import
import 'chat_screen.dart';

class ManageModelsScreen extends StatefulWidget {
  @override
  _ManageModelsScreenState createState() => _ManageModelsScreenState();
}

class _ManageModelsScreenState extends State<ManageModelsScreen> {
  List<DownloadTask> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  // Query flutter_downloader's native database for a perfect history
  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final tasks = await FlutterDownloader.loadTasks();
      
      setState(() {
        // Filter for completed GGUF downloads
        _tasks = (tasks ?? []).where((t) => 
            t.status == DownloadTaskStatus.complete && 
            t.filename != null && 
            t.filename!.endsWith('.gguf')
        ).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading tasks: $e')),
      );
    }
  }

  Future<void> _deleteModel(String taskId, String fullPath) async {
    // 1. Remove it from the downloader's database AND delete the physical file
    await FlutterDownloader.remove(taskId: taskId, shouldDeleteContent: true);
    
    // 2. Failsafe physical deletion just in case
    final file = File(fullPath);
    if (await file.exists()) {
      await file.delete();
    }
    
    _loadTasks(); // Refresh list
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Manage Models')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
              ? Center(child: Text('No models found on device.'))
              : ListView.builder(
                  itemCount: _tasks.length,
                  itemBuilder: (context, index) {
                    final task = _tasks[index];
                    // Construct the absolute path based on the downloader's exact records
                    final fullPath = '${task.savedDir}/${task.filename}';
                    final displayName = task.filename ?? 'Unknown Model';
                    
                    String fileSizeStr = "Unknown Size";
                    final file = File(fullPath);
                    if (file.existsSync()) {
                       fileSizeStr = _formatSize(file.lengthSync());
                    }

                    return ListTile(
                      leading: Icon(Icons.psychology, color: Colors.blue),
                      title: Text(displayName),
                      subtitle: Text(fileSizeStr), 
                      onTap: () {
                        if (!file.existsSync()) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('File missing from disk!')),
                            );
                            return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              modelName: displayName,
                              modelPath: fullPath,
                            ),
                          ),
                        );
                      },
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteModel(task.taskId, fullPath),
                      ),
                    );
                  },
                ),
    );
  }
}