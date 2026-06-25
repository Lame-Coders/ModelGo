import 'package:flutter/material.dart';

class UploadModelScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Model'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            // Implement model upload logic here (e.g., pick file, upload to SQLite)
            print('Upload model button pressed');
          },
          child: Text('Select Model File'),
        ),
      ),
    );
  }
}