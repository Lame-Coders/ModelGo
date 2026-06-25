import 'package:flutter/material.dart';
import 'upload_model_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome to ModelGo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UploadModelScreen()),
                );
              },
              child: Text('Upload Model'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to the model management screen or perform another action
              },
              child: Text('Manage Models'),
            ),
          ],
        ),
      ),
    );
  }
}