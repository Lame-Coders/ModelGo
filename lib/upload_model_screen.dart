import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'model_dao.dart';
import 'model_model.dart';

class UploadModelScreen extends StatefulWidget {
  @override
  _UploadModelScreenState createState() => _UploadModelScreenState();
}

class _UploadModelScreenState extends State<UploadModelScreen> {
  File? _file;
  late int _progressPercent;

  final picker = ImagePicker();

  Future<void> _pickFileFromGallery() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _file = File(pickedFile.path);
        // Call a method to simulate upload progress
        _uploadModel();
      });
    }
  }

  Future<void> _pickFileFromLocalStorage() async {
    // Implement local storage picker logic here
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
    // Replace this with actual logic to direct the user to Hugging Face model page or list of models.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening Hugging Face in your browser.'),
      ),
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
      final db = await dao.database;

      try {
        await db!.transaction((txn) async {
          txn.insert(ModelDao.TableInfo, ModelModel(fileName: _file!.path).toMap());
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Model uploaded successfully!'),
          ),
        );
      } catch (e) {
        print(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to store model.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Model'),
      ),
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
              onPressed: () => _pickFileFromGallery(),
              child: Text('Select Model from Gallery'),
            ),
            SizedBox(height: 20),
            LinearProgressIndicator(
              value: _progressPercent / 100.0,
              backgroundColor: Colors.grey,
              color: Colors.blue,
            ),
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
      appBar: AppBar(
        title: Text('Hugging Face Models'),
      ),
      body: Center(
        child: Text("Welcome to Hugging Face models page!"),
      ),
    );
  }
}