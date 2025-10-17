import 'package:flutter/material.dart';
import 'package:spah_generator/screens/menu_utama.dart';

void main() {
  runApp(ExplorasiApp());
}

class ExplorasiApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eksplorasi',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'ComicNeue',
      ),
      home: MenuUtama(),
      debugShowCheckedModeBanner: false,
    );
  }
}