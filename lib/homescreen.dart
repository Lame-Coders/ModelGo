import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome to ModelGo'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Navigate to another screen or perform an action when pressed
          },
          child: Text('Upload Model'),
        ),
      ),
    );
  }
}