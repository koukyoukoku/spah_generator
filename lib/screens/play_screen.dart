import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Eksplorasi/components/SmoothPress.dart';
import 'package:Eksplorasi/services/esp32_service.dart';

class PlayScreen extends StatefulWidget {
  @override
  _PlayScreenState createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen>
    with SingleTickerProviderStateMixin {
  String _status = "Menyiapkan...";
  bool _isReading = false;
  bool _nfcAvailable = false;
  bool _showSuccess = false;
  bool _useESP32Mode = false;
  String _displayText = "Menyiapkan...";
  String _lastUID = "";

  late AnimationController _animationController;
  final ESP32Service _esp32Service = ESP32Service();
  StreamSubscription? _esp32DataSubscription;
  StreamSubscription? _esp32StatusSubscription;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );

    _loadESP32Preference();
  }

  Future<void> _loadESP32Preference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _useESP32Mode = prefs.getBool('use_esp32_mode') ?? false;
    });

    if (_useESP32Mode) {
      _initializeESP32Mode();
    } else {
      _checkNfcAvailability();
    }
  }

  void _initializeESP32Mode() async {
    setState(() {
      _status = "Menyiapkan mode ESP32...";
      _displayText = "Menyiapkan mode ESP32...";
    });

    _esp32StatusSubscription = _esp32Service.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          _status = status;
          if (!status.contains('WiFi:') &&
              !status.contains('Starting') &&
              !status.contains('Scanning') &&
              !status.contains('Connecting') &&
              !status.contains('Re-scan') &&
              !status.contains('No devices') &&
              !status.contains('UDP Discovery') &&
              !status.contains('Data:') &&
              !status.contains('Status:') &&
              !status.contains('Ping:')) {
            _displayText = _getUserFriendlyStatus(status);
          }
        });
      }
    });

    _esp32DataSubscription = _esp32Service.deviceDataStream.listen((data) {
      if (data.containsKey('rfid_uid') && _isReading) {
        String uid = data['rfid_uid'].toString();

        if (uid.isNotEmpty && uid.length >= 4) {
          _handleTagRead(uid);
        } else {
          setState(() {
            _status = "UID tidak valid";
            _displayText = "UID tidak valid";
            _showSuccess = false;
          });

          if (_isReading) {
            _animationController.repeat();
          }
        }
      }
    });

    _esp32Service.startDiscovery();
    _startReading();
  }

  String _getUserFriendlyStatus(String status) {
    if (status.contains('ESP32 Found')) {
      return "Perangkat ESP32 ditemukan";
    } else if (status.contains('Connected to ESP32')) {
      return "Terhubung ke ESP32";
    } else if (status.contains('Handshake Success')) {
      return "Siap memindai RFID";
    } else if (status.contains('Kartu tidak dikenali')) {
      return "Kartu tidak dikenali";
    } else if (status.contains('RFID Tidak Valid')) {
      return "Kartu tidak valid";
    } else if (status.contains('Connection Disconnected')) {
      return "Koneksi terputus";
    } else if (status.contains('Failed to connect')) {
      return "Gagal terhubung";
    }
    return status;
  }

  Future<void> _checkNfcAvailability() async {
    try {
      var availability = await FlutterNfcKit.nfcAvailability;
      if (availability == NFCAvailability.available) {
        setState(() {
          _nfcAvailable = true;
          _status = "NFC siap";
          _displayText = "Tempelkan perangkat ke tag NFC";
        });
        _startReading();
      } else if (availability == NFCAvailability.disabled) {
        setState(() {
          _nfcAvailable = false;
          _status = "NFC dimatikan";
          _displayText = "NFC dimatikan\n\nAktifkan NFC di pengaturan";
        });
      } else if (availability == NFCAvailability.not_supported) {
        setState(() {
          _nfcAvailable = false;
          _status = "NFC tidak didukung";
          _displayText = "Perangkat tidak mendukung NFC";
        });
      }
    } catch (e) {
      setState(() {
        _status = "Error cek NFC: $e";
        _displayText = "Error memeriksa NFC";
      });
    }
  }

  void _startReading() {
    setState(() {
      _isReading = true;
      _status = "Memulai pembacaan...";
      _displayText = _useESP32Mode
          ? "Tempelkan kartu RFID ke reader"
          : "Tempelkan perangkat ke tag NFC";
      _showSuccess = false;
      _lastUID = "";
    });

    _animationController.repeat();

    if (_useESP32Mode) {
      _esp32Service.sendTCPMessage('START_RFID_READING');
    } else {
      _readNfcContinuously();
    }
  }

  void _readNfcContinuously() async {
    while (_isReading && mounted) {
      try {
        final tag = await FlutterNfcKit.poll(
          timeout: Duration(seconds: 60),
          iosMultipleTagMessage: "Terdeteksi Tag lebih dari 1!",
          iosAlertMessage: "Scan benda",
        );

        String tagId = '';
        if (tag.id.isNotEmpty) {
          tagId = tag.id.toUpperCase();
        }

        if (tagId.isNotEmpty && tagId.length >= 4) {
          _handleTagRead(tagId);
        } else {
          setState(() {
            _status = "Tag NFC tidak dikenali";
            _displayText = "Tag NFC tidak dikenali";
            _showSuccess = false;
          });
          _animationController.repeat();
        }

        await Future.delayed(Duration(seconds: 2));

        if (mounted && _isReading) {
          setState(() {
            _status = "Menunggu tag berikutnya...";
            _displayText = "Tempelkan ke tag lain...";
            _showSuccess = false;
          });

          _animationController.repeat();
        }
      } catch (e) {
        if (_isReading && mounted) {
          setState(() {
            _status = "Terjadi Kesalahan! Coba lagi.";
            _displayText = "Terjadi kesalahan, coba lagi";
            _showSuccess = false;
          });
          await Future.delayed(Duration(seconds: 1));
        }
      }
    }
  }

  void _handleTagRead(String uid) {
    if (uid.length < 4) {
      setState(() {
        _status = "UID terlalu pendek";
        _displayText = "UID terlalu pendek";
        _showSuccess = false;
      });
      return;
    }

    setState(() {
      _status = "Benda dikenali: $uid";
      _displayText = uid;
      _lastUID = uid;
      _showSuccess = true;
    });

    _animationController.stop();

    _saveScanResult(uid);
  }

  Future<void> _saveScanResult(String uid) async {
    if (uid.length < 4) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final scanResult = {
      'timestamp': now.millisecondsSinceEpoch,
      'uid': uid,
      'mode': _useESP32Mode ? 'ESP32' : 'NFC',
    };

    final history = prefs.getStringList('scan_history') ?? [];
    history.add(json.encode(scanResult));

    if (history.length > 100) {
      history.removeAt(0);
    }

    await prefs.setStringList('scan_history', history);

    print('✅ RFID UID Disimpan: $uid');
  }

  void _stopReadingAndExit() {
    setState(() {
      _isReading = false;
      _status = "Menghentikan...";
      _displayText = "Menghentikan...";
    });

    _animationController.stop();

    if (_useESP32Mode) {
      _esp32Service.sendTCPMessage('STOP_RFID_READING');
    } else {
      FlutterNfcKit.finish();
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _isReading = false;
    _animationController.dispose();

    if (_useESP32Mode) {
      _esp32DataSubscription?.cancel();
      _esp32StatusSubscription?.cancel();
    } else {
      FlutterNfcKit.finish();
    }

    super.dispose();
  }

  Widget _buildModeIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _useESP32Mode
            ? Color(0xFF4ECDC4).withOpacity(0.1)
            : Color(0xFFFE6D73).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _useESP32Mode ? Color(0xFF4ECDC4) : Color(0xFFFE6D73),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _useESP32Mode ? Icons.wifi_rounded : Icons.nfc_rounded,
            color: _useESP32Mode ? Color(0xFF4ECDC4) : Color(0xFFFE6D73),
            size: 16,
          ),
          SizedBox(width: 6),
          Text(
            _useESP32Mode ? "Mode ESP32" : "Mode NFC",
            style: TextStyle(
              fontSize: 12,
              color: _useESP32Mode ? Color(0xFF4ECDC4) : Color(0xFFFE6D73),
              fontWeight: FontWeight.w600,
              fontFamily: 'ComicNeue',
            ),
          ),
        ],
      ),
    );
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
                  onPressed: _stopReadingAndExit,
                ),
              ),
            ),

            Positioned(top: 16, right: 16, child: _buildModeIndicator()),

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
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF4ECDC4),
                                    ),
                                    strokeWidth: 4,
                                    backgroundColor: Colors.transparent,
                                  ),
                                ),

                              Container(
                                width: 180,
                                height: 180,
                                decoration: BoxDecoration(
                                  color: _showSuccess
                                      ? Color(0xFF4ECDC4).withOpacity(0.2)
                                      : Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 15,
                                      offset: Offset(0, 6),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: _showSuccess
                                        ? Color(0xFF4ECDC4)
                                        : Colors.transparent,
                                    width: _showSuccess ? 6 : 0,
                                  ),
                                ),
                                child: Icon(
                                  _showSuccess
                                      ? Icons.check_circle_rounded
                                      : (_useESP32Mode
                                            ? Icons.wifi_rounded
                                            : Icons.nfc_rounded),
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
                              ? (_showSuccess
                                    ? "BERHASIL!"
                                    : "Eksplorasi Benda")
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
                                    : ((_useESP32Mode && _esp32Service.isConnected)
                                          ? Icons.wifi_rounded
                                          : (_nfcAvailable || _useESP32Mode
                                                ? Icons.info_outline_rounded
                                                : Icons.error_outline_rounded)),
                                color: _showSuccess
                                    ? Color(0xFF4ECDC4)
                                    : ((_useESP32Mode && _esp32Service.isConnected)
                                          ? Color(0xFF4ECDC4)
                                          : (_nfcAvailable || _useESP32Mode
                                                ? Color(0xFF4ECDC4)
                                                : Color(0xFFFE6D73))),
                                size: 40,
                              ),
                              SizedBox(height: 15),
                              Text(
                                _displayText,
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
                                  "Benda berhasil dikenali!",
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

                        if (_isReading && !_showSuccess)
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
                                    _useESP32Mode
                                        ? "Tempelkan kartu RFID ke reader ESP32"
                                        : "Tempelkan bagian atas perangkat ke tag NFC",
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
                    onPressed: _stopReadingAndExit,
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
                          Icon(
                            Icons.exit_to_app_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                          SizedBox(width: 12),
                          Text(
                            "KEMBALI",
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