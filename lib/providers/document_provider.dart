import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/document_model.dart';

class DocumentProvider extends ChangeNotifier {
  final String _boxName = 'documents_box';
  List<VehicleDocument> _documents = [];

  List<VehicleDocument> getVehicleDocuments(String vehicleKey) {
    return _documents.where((d) => d.vehicleKey == vehicleKey).toList();
  }

  Future<void> loadDocuments() async {
    var box = Hive.box<VehicleDocument>(_boxName);
    _documents = box.values.toList();
    notifyListeners();
  }

  Future<void> addDocument(VehicleDocument doc) async {
    var box = Hive.box<VehicleDocument>(_boxName);
    await box.add(doc);
    await loadDocuments();
  }

  Future<void> deleteDocument(int index) async {
    var box = Hive.box<VehicleDocument>(_boxName);
    await box.deleteAt(index);
    await loadDocuments();
  }
}