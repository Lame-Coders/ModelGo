import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'model_dao.dart'; // Ensure this path is correct
import 'home_screen.dart'; // Ensure this path is correct
import 'dart:io';

class UploadModelScreen extends StatefulWidget {
  @override
  _UploadModelScreenState createState() => _UploadModelScreenState();
}

class _UploadModelScreenState extends State<UploadModelScreen> {
  File? _file;
  int _progressPercent = 0; // Fix: Initialized to 0 to prevent crash

  final picker = ImagePicker();

  Future<void> _pickFile() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _file = File(pickedFile.path);
        // Call a method to simulate upload progress
        _uploadModel();
      });
    }
  }

  Future<void> _getFromHuggingFace() async {
    print('Redirecting to Hugging Face...');
    ScaffoldMessenger.of(context).showSnackBar( // Fix: Changed SDKMessenger to ScaffoldMessenger
      SnackBar(content: Text('Opening Hugging Face in your browser.')),
    );

    // For demonstration purposes, redirecting to a hardcoded URL
    await Future.delayed(Duration(seconds: 2));
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HuggingFacePage()),
      );
    }
  }

  Future<void> _uploadModel() async {
    // Simulate uploading process every 10%
    for (int i = 0; i <= 100; i += 10) {
      setState(() {
        _progressPercent = i;
      });

      await Future.delayed(Duration(seconds: 2)); // Delay to simulate network delay
    }

    // Store model in SQLite if it was uploaded successfully
    if (_file != null) {
      final dao = ModelDao();
      try {
        // Fix: Delegated database interaction to the DAO instead of using undefined 'db'
        await dao.insert({'fileName': _file!.path});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Model uploaded successfully!')),
        );
      } catch (e) {
        print(e);
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_file != null)
              Image.file(_file!)
            else
              Icon(Icons.cloud_upload, size: 64),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickFile,
              child: Text('Select Model from Gallery'),
            ),
            SizedBox(height: 20),
            LinearProgressIndicator(value: _progressPercent / 100.0, backgroundColor: Colors.grey, color: Colors.blue),
          ],
        ),
      ),
    );
  }
}

class HuggingFacePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Hugging Face Models')),
      body: Center(child: Text("Welcome to Hugging Face models page!")),
    );
  }
}