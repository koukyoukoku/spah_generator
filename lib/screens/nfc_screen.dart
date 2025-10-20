import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:ndef/ndef.dart' as ndef;
import 'package:spah_generator/components/SmoothPress.dart';

class NfcScreen extends StatefulWidget {
  @override
  _NfcScreenState createState() => _NfcScreenState();
}

class _NfcScreenState extends State<NfcScreen> with SingleTickerProviderStateMixin {
  String _status = "Menyiapkan NFC...";
  bool _isReading = false;
  String _nfcData = "";
  bool _nfcAvailable = false;
  bool _showSuccess = false;
  
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );
    
    _checkNfcAvailability();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _stopNfcReading();
    super.dispose();
  }

  Future<void> _checkNfcAvailability() async {
    try {
      var availability = await FlutterNfcKit.nfcAvailability;
      if (availability == NFCAvailability.available) {
        setState(() {
          _nfcAvailable = true;
          _status = "Tempelkan perangkat ke benda yang memiliki tag NFC";
        });
        _startNfcReading();
      } else if (availability == NFCAvailability.disabled) {
        setState(() {
          _nfcAvailable = false;
          _status = "NFC dimatikan\n\nAktifkan NFC di pengaturan untuk menggunakan fitur ini";
        });
      } else if (availability == NFCAvailability.not_supported) {
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
      _status = "Tempelkan perangkat ke benda yang memiliki tag NFC";
      _showSuccess = false;
    });
    
    _animationController.repeat();

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
          _status = "Benda dikenali!";
          _showSuccess = true;
        });
        
        _animationController.stop();

        await Future.delayed(Duration(seconds: 2));

        if (mounted && _isReading) {
          setState(() {
            _status = "Tempelkan ke benda lain...";
            _showSuccess = false;
          });
          
          _animationController.repeat();
        }
      } catch (e) {
        if (_isReading && mounted) {
          setState(() {
            _status = "Terjadi Kesalahan! Coba lagi.";
            _showSuccess = false;
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
      _showSuccess = false;
    });
    
    _animationController.stop();
    FlutterNfcKit.finish();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE8F4F8),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -50,
              right: -30,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Color(0xFF4ECDC4).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Positioned(
              bottom: -80,
              left: -40,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: Color(0xFFFE6D73).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: Color(0xFF2D5A7E),
                    size: 24,
                  ),
                  onPressed: () {
                    _stopNfcReading();
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
            
            Column(
              children: [
                SizedBox(height: 40),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 200,
                          height: 200,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (_isReading && !_showSuccess)
                                Container(
                                  width: 200,
                                  height: 200,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
                                    strokeWidth: 4,
                                    backgroundColor: Colors.transparent,
                                  ),
                                ),
                              
                              Container(
                                width: 180,
                                height: 180,
                                decoration: BoxDecoration(
                                  color: _showSuccess ? Color(0xFF4ECDC4).withOpacity(0.2) : Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 15,
                                      offset: Offset(0, 6),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: _showSuccess ? Color(0xFF4ECDC4) : Colors.transparent,
                                    width: _showSuccess ? 6 : 0,
                                  ),
                                ),
                                child: Icon(
                                  _showSuccess 
                                    ? Icons.check_circle_rounded
                                    : Icons.nfc_rounded,
                                  size: 80,
                                  color: Color(0xFF4ECDC4),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 40),
                        
                        Text(
                          _isReading 
                            ? (_showSuccess ? "BERHASIL!" : "Eksplorasi Benda")
                            : "Eksplorasi Benda",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2D5A7E),
                            fontFamily: 'ComicNeue',
                          ),
                          textAlign: TextAlign.center,
                        ),

                        SizedBox(height: 15),
                        
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _showSuccess 
                              ? Color(0xFF4ECDC4).withOpacity(0.1)
                              : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _showSuccess 
                                ? Color(0xFF4ECDC4).withOpacity(0.3)
                                : Color(0xFF4ECDC4).withOpacity(0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Icon(
                                _showSuccess 
                                  ? Icons.check_circle_rounded
                                  : (_nfcAvailable 
                                      ? Icons.info_outline_rounded 
                                      : Icons.error_outline_rounded),
                                color: _showSuccess 
                                  ? Color(0xFF4ECDC4)
                                  : (_nfcAvailable 
                                      ? Color(0xFF4ECDC4) 
                                      : Color(0xFFFE6D73)),
                                size: 40,
                              ),
                              SizedBox(height: 15),
                              Text(
                                _status,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF2D5A7E),
                                  fontFamily: 'ComicNeue',
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (_showSuccess) ...[
                                SizedBox(height: 10),
                                Text(
                                  "Benda berhasil dikenali! SCP dapat belajar tentang benda ini",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF666666),
                                    fontFamily: 'ComicNeue',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        ),

                        SizedBox(height: 30),
                        
                        if (_nfcAvailable && _isReading && !_showSuccess)
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Color(0xFFFED766).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Color(0xFFFED766).withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.lightbulb_rounded,
                                  color: Color(0xFFFED766),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    "Tempelkan bagian atas perangkat ke benda yang memiliki tag NFC",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF2D5A7E),
                                      fontFamily: 'ComicNeue',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                
                Padding(
                  padding: EdgeInsets.all(25),
                  child: SmoothPressButton(
                    onPressed: () {
                      _stopNfcReading();
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: Color(0xFFFE6D73),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFFE6D73).withOpacity(0.3),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.stop_rounded, color: Colors.white, size: 28),
                          SizedBox(width: 12),
                          Text(
                            "BERHENTI EKSPLORASI",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'ComicNeue',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}