import 'package:flutter/material.dart';
import 'package:spah_generator/screens/menu_utama.dart';
import 'package:spah_generator/services/esp32_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ExplorasiApp());
}

class ExplorasiApp extends StatelessWidget {
  final ESP32Service esp32Service = ESP32Service();

  ExplorasiApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eksplorasi',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'ComicNeue',
      ),
      home: MenuUtama(esp32Service: esp32Service),
      debugShowCheckedModeBanner: false,
    );
  }
}