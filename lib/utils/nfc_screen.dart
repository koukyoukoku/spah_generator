import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:ndef/ndef.dart' as ndef;

class NfcScreen extends StatefulWidget {
  @override
  _NfcScreenState createState() => _NfcScreenState();
}

class _NfcScreenState extends State<NfcScreen> {
  String _status = "Menyiapkan NFC...";
  bool _isReading = false;
  String _nfcData = "";
  bool _nfcAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkNfcAvailability();
  }

  Future<void> _checkNfcAvailability() async {
    try {
      var availability = await FlutterNfcKit.nfcAvailability;
      if (availability == NFCAvailability.available) {
        setState(() {
          _nfcAvailable = true;
          _status = "Tempelkan ke benda...";
        });
        _startNfcReading();
      } 
      else if (availability == NFCAvailability.disabled) {
        setState(() {
          _nfcAvailable = false;
          _status = "NFC dimatikan\n\nAktifkan NFC di pengaturan untuk menggunakan fitur ini";
        });
      } 
      else if (availability == NFCAvailability.not_supported) {
        setState(() {
          _nfcAvailable = false;
          _status = "Perangkat tidak mendukung NFC\n\nFitur ini hanya tersedia di perangkat dengan NFC";
        });
      }
    } catch (e) {
      setState(() {
        _status = "Error cek NFC: $e";
      });
    }
  }

  void _startNfcReading() async {
    setState(() {
      _isReading = true;
      _status = "Tempelkan ke benda...";
    });

    _readNfcContinuously();
  }

  void _readNfcContinuously() async {
    while (_isReading && mounted) {
      try {
        final tag = await FlutterNfcKit.poll(
          timeout: Duration(seconds: 60),
          iosMultipleTagMessage: "Terdeteksi Tag lebih dari 1!",
          iosAlertMessage: "Scan benda",
        );

        setState(() {
          _status = "Benda dikenali! ID: ${tag.id}";
        });

        await Future.delayed(Duration(seconds: 2));
        
        if (mounted && _isReading) {
          setState(() {
            _status = "Tempelkan ke benda lain...";
          });
        }
      } catch (e) {
        if (_isReading && mounted) {
          setState(() {
            _status = "Terjadi Kesalahan!";
          });
          await Future.delayed(Duration(seconds: 1));
        }
      }
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
                          Icon(Icons.nfc, size: 80, color: Color(0xFF4ECDC4))
                        ],
                      ),
                    ),
                    SizedBox(height: 30),
                    Text(
                      _isReading ? "TEMPELKAN KE BENDA" : "MENYIAPKAN NFC...",
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
                  onPressed: () {
                    _stopNfcReading();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFE6D73),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.stop,
                        color: Colors.white,
                        size: 35,
                      ),
                      SizedBox(width: 15),
                      Text(
                        "BERHENTI",
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