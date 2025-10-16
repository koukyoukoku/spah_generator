import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:ndef/ndef.dart' as ndef;

class NfcScreen extends StatefulWidget {
  @override
  _NfcScreenState createState() => _NfcScreenState();
}

class _NfcScreenState extends State<NfcScreen> {
  String _status = "Siap membaca...";
  bool _isReading = false;
  String _nfcData = "";

  @override
  void initState() {
    super.initState();
    _checkNfcAvailability();
  }

  Future<void> _checkNfcAvailability() async {
    try {
      var availability = await FlutterNfcKit.nfcAvailability;
      if (availability != NFCAvailability.available) {
        setState(() {
          _status = "NFC tidak tersedia di perangkat ini";
        });
      }
    } catch (e) {
      setState(() {
        _status = "Error mengecek NFC: $e";
      });
    }
  }

  void _startNfcReading() async {
    setState(() {
      _isReading = true;
      _status = "Tempelkan ke benda...";
    });

    try {
      final tag = await FlutterNfcKit.poll(
        timeout: Duration(seconds: 60),
        iosMultipleTagMessage: "Terdeteksi Tag lebih dari 1!",
        iosAlertMessage: "Scan benda",
      );

      setState(() {
        _status = "Benda dikenali! ID: ${tag.id}";
      });

      await Future.delayed(Duration(seconds: 3));

      if (mounted && _isReading) {
        setState(() {
          _status = "Tempelkan ke benda lain...";
        });
      }
    } catch (e) {
      setState(() {
        _status = "Gagal membaca: $e";
        _isReading = false;
      });
    }
  }

  void _stopNfcReading() {
    setState(() {
      _isReading = false;
      _status = "Membaca dihentikan";
    });
    FlutterNfcKit.finish();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF9F5E8),
      appBar: AppBar(
        backgroundColor: Color(0xFF4ECDC4),
        title: Text(
          'Eksplorasi Benda',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            _stopNfcReading();
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Color(0xFF4ECDC4), width: 6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.nfc, size: 80, color: Color(0xFF4ECDC4)),
                          if (_isReading)
                            Positioned(
                              bottom: 20,
                              child: Text('📱', style: TextStyle(fontSize: 40)),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 30),
                    Text(
                      _isReading ? "TEMPELKAN KE BENDA" : "TEKAN TOMBOL MULAI",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFE6D73),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 15),
                    Text(
                      _status,
                      style: TextStyle(fontSize: 20, color: Color(0xFF4ECDC4)),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.all(25),
              child: Container(
                width: double.infinity,
                height: 80,
                child: ElevatedButton(
                  onPressed: _isReading ? _stopNfcReading : _startNfcReading,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isReading
                        ? Color(0xFFFE6D73)
                        : Color(0xFF4ECDC4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isReading ? Icons.stop : Icons.play_arrow,
                        color: Colors.white,
                        size: 35,
                      ),
                      SizedBox(width: 15),
                      Text(
                        _isReading ? "BERHENTI" : "MULAI BACA",
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text('🐶', style: TextStyle(fontSize: 30)),
                  Text('🐱', style: TextStyle(fontSize: 30)),
                  Text('🐰', style: TextStyle(fontSize: 30)),
                  Text('🐻', style: TextStyle(fontSize: 30)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _stopNfcReading();
    super.dispose();
  }
}
