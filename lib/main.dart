import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart'; // Added import
import 'upload_model_screen.dart';
import 'package:modelgo/home_screen.dart';

void main() async {
  // Required because we are executing asynchronous code before runApp()
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the native downloader component
  await FlutterDownloader.initialize(
    debug: true, // Set to false when you build the final release APK to hide logs
    ignoreSsl: true, // Useful to prevent SSL errors on certain file hosts
  );

  runApp(ModelGo());
}

class ModelGo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ModelGo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(),
    );
  }
}