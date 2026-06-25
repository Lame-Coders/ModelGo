import 'package:flutter/material.dart';
import 'home_screen.dart'; // We will create this screen later

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