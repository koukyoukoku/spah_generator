import 'package:flutter/material.dart';
import 'package:Eksplorasi/screens/menu_utama.dart';
import 'package:Eksplorasi/services/esp32_service.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
    print('Firebase initialized successfully');
  } catch (e) {
    print('Failed to initialize Firebase: $e');
  }
  
  runApp(ExplorasiApp());
}

class ExplorasiApp extends StatelessWidget {
  final ESP32Service esp32Service = ESP32Service();

  ExplorasiApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eksplorasi',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'ComicNeue'),
      home: MenuUtama(esp32Service: esp32Service),
      debugShowCheckedModeBanner: false,
    );
  }
}