// lib/model_model.dart
class ModelModel {
  String fileName;

  ModelModel({required this.fileName});

  Map<String, dynamic> toMap() => {'fileName': fileName};
}