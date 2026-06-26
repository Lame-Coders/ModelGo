import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; // Fixed import
import 'model_dao.dart'; 
import 'dart:io';
import 'hugging_face_page.dart';

class UploadModelScreen extends StatefulWidget {
  @override
  _UploadModelScreenState createState() => _UploadModelScreenState();
}

class _UploadModelScreenState extends State<UploadModelScreen> {
  File? _file;
  int _progressPercent = 0; 
  bool _isUploading = false; // Added to handle upload state

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);

    if (result != null) {
      setState(() {
        _file = File(result.files.first.path ?? '');
      });
      // Call a method to simulate upload progress
      _uploadModel();
    }
  }

  Future<void> _getFromHuggingFace() async {
    print('Redirecting to Hugging Face...');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening Hugging Face in your browser.')),
    );

    await Future.delayed(Duration(seconds: 2));
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HuggingFacePage()),
      );
    }
  }

  Future<void> _uploadModel() async {
    setState(() {
      _isUploading = true;
      _progressPercent = 0;
    });

    // Simulate uploading process every 10%
    for (int i = 0; i <= 100; i += 10) {
      await Future.delayed(Duration(seconds: 1)); // Network delay simulation
      if (mounted) { // Prevent setState errors if user leaves screen
        setState(() {
          _progressPercent = i;
        });
      }
    }

    // Store model in SQLite if it was uploaded successfully
    if (_file != null && mounted) {
      final dao = ModelDao();
      try {
        await dao.insert({'fileName': _file!.path});
        
        setState(() {
          _isUploading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Model uploaded successfully!')),
        );
      } catch (e) {
        print(e);
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to store model.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upload Model')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (_file != null) ...[
                Icon(Icons.insert_drive_file, size: 64, color: Colors.blue),
                SizedBox(height: 10),
                Text(
                  _file!.path.split('/').last, // Display just the filename
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ] else
                Icon(Icons.cloud_upload, size: 64, color: Colors.grey),
              
              SizedBox(height: 30),
              
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _pickFile,
                icon: Icon(Icons.folder),
                label: Text('Select Model from Device'),
              ),
              
              SizedBox(height: 10),
              
              // Added missing button for Hugging Face integration
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _getFromHuggingFace,
                icon: Icon(Icons.download),
                label: Text('Download from Hugging Face'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                ),
              ),
              
              SizedBox(height: 30),
              
              if (_isUploading) ...[
                Text('Processing: $_progressPercent%'),
                SizedBox(height: 10),
                LinearProgressIndicator(
                  value: _progressPercent / 100.0, 
                  backgroundColor: Colors.grey[300], 
                  color: Colors.blue,
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}