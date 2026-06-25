import 'package:flutter/material.dart';
import 'upload_model_screen.dart';
import 'package:modelgo/home_screen.dart';

void main() {
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