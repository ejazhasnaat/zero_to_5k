import 'package:flutter/material.dart';
import 'app.dart';
import 'services/local_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorageService.init();
  runApp(const ZeroTo5KApp());
}
