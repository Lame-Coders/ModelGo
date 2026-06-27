import 'package:flutter/material.dart';
import 'dart:io';
import 'model_dao.dart';

class ManageModelsScreen extends StatefulWidget {
  @override
  _ManageModelsScreenState createState() => _ManageModelsScreenState();
}

class _ManageModelsScreenState extends State<ManageModelsScreen> {
  final ModelDao _dao = ModelDao();
  List<Map<String, dynamic>> _models = [];

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  Future<void> _loadModels() async {
    final data = await _dao.getAllModels();
    setState(() {
      _models = data;
    });
  }

  Future<void> _deleteModel(int id, String path) async {
    // Delete file from device
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
    // Delete from DB
    await _dao.deleteModel(id);
    _loadModels(); // Refresh list
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Manage Models')),
      body: _models.isEmpty
          ? Center(child: Text('No models found.'))
          : ListView.builder(
              itemCount: _models.length,
              itemBuilder: (context, index) {
                final model = _models[index];
                return ListTile(
                  leading: Icon(Icons.psychology, color: Colors.blue),
                  title: Text(model['fileName'].toString().split('/').last),
                  subtitle: Text(model['fileName']),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteModel(model['id'], model['fileName']),
                  ),
                );
              },
            ),
    );
  }
}