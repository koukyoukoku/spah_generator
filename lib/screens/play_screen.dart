import 'dart:async';
import 'dart:convert';
import 'package:Eksplorasi/screens/play_screen/object_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Eksplorasi/components/SmoothPress.dart';
import 'package:Eksplorasi/services/esp32_service.dart';
import 'package:Eksplorasi/models/languages/index.dart';
import 'package:Eksplorasi/utils/tts_service.dart';

class PlayScreen extends StatefulWidget {
  @override
  _PlayScreenState createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen>
    with SingleTickerProviderStateMixin {
  String _status = '';
  bool _isReading = false;
  bool _nfcAvailable = false;
  bool _showSuccess = false;
  bool _useESP32Mode = false;
  String _displayText = '';
  String _lastUID = "";
  String _currentObjectName = "";

  late AnimationController _animationController;
  final ESP32Service _esp32Service = ESP32Service();
  StreamSubscription? _esp32DataSubscription;
  StreamSubscription? _esp32StatusSubscription;

  final Map<String, Map<String, String>> _objectDictionary = {
    'FEA4B889': {'id': 'Apel', 'en': 'Apple'},
    '89AAE568': {'id': 'Pisang', 'en': 'Banana'},
    '041234567890': {'id': 'Mobil', 'en': 'Car'},
    '04ABCDEF1234': {'id': 'Bola', 'en': 'Ball'},
    '04A1B2C3D4E5': {'id': 'Buku', 'en': 'Book'},
    '04FEDCBA9876': {'id': 'Pensil', 'en': 'Pencil'},
    '041A2B3C4D5E': {'id': 'Rumah', 'en': 'House'},
    '045A4B3C2D1E': {'id': 'Pohon', 'en': 'Tree'},
    '049876543210': {'id': 'Kucing', 'en': 'Cat'},
    '041F2E3D4C5B': {'id': 'Anjing', 'en': 'Dog'},
    '04C1D2E3F4A5': {'id': 'Meja', 'en': 'Table'},
    '04B2A3C4D5E6': {'id': 'Kursi', 'en': 'Chair'},
    '04D3E4F5A6B7': {'id': 'Topi', 'en': 'Hat'},
    '04E5F6A7B8C9': {'id': 'Sepatu', 'en': 'Shoe'},
    '04F7A8B9C0D1': {'id': 'Bunga', 'en': 'Flower'},
    '04A5B6C7D8E9': {'id': 'Matahari', 'en': 'Sun'},
    '04B7C8D9E0F1': {'id': 'Bulan', 'en': 'Moon'},
    '04C9D0E1F2A3': {'id': 'Bintang', 'en': 'Star'},
  };

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );

    _initializeTTS();
    _loadESP32Preference();
    _initializeLanguage();
  }

  void _initializeTTS() async {
    await TTSService.init();
  }

  void _initializeLanguage() async {
    await AppLocalizations.init();
    if (mounted) {
      setState(() {
        _status = AppLocalizations.get('play_screen.preparing');
        _displayText = AppLocalizations.get('play_screen.preparing');
      });
    }
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
      _status = AppLocalizations.get('play_screen.preparing_esp32');
      _displayText = AppLocalizations.get('play_screen.preparing_esp32');
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
            _status = AppLocalizations.get('play_screen.invalid_card');
            _displayText = AppLocalizations.get('play_screen.invalid_card');
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
      return AppLocalizations.get('play_screen.esp32_found');
    } else if (status.contains('Connected to ESP32')) {
      return AppLocalizations.get('play_screen.esp32_connected');
    } else if (status.contains('Handshake Success')) {
      return AppLocalizations.get('play_screen.ready_to_scan');
    } else if (status.contains('Kartu tidak dikenali') ||
        status.contains('Card not recognized')) {
      return AppLocalizations.get('play_screen.card_not_recognized');
    } else if (status.contains('RFID Tidak Valid') ||
        status.contains('Invalid card')) {
      return AppLocalizations.get('play_screen.invalid_card');
    } else if (status.contains('Connection Disconnected')) {
      return AppLocalizations.get('play_screen.connection_lost');
    } else if (status.contains('Failed to connect')) {
      return AppLocalizations.get('play_screen.connection_failed');
    }
    return status;
  }

  Future<void> _checkNfcAvailability() async {
    try {
      var availability = await FlutterNfcKit.nfcAvailability;
      if (availability == NFCAvailability.available) {
        setState(() {
          _nfcAvailable = true;
          _status = AppLocalizations.get('play_screen.nfc_ready');
          _displayText = AppLocalizations.get('play_screen.tap_nfc');
        });
        _startReading();
      } else if (availability == NFCAvailability.disabled) {
        setState(() {
          _nfcAvailable = false;
          _status = AppLocalizations.get('play_screen.nfc_disabled');
          _displayText = AppLocalizations.get('play_screen.enable_nfc');
        });
      } else if (availability == NFCAvailability.not_supported) {
        setState(() {
          _nfcAvailable = false;
          _status = AppLocalizations.get('play_screen.nfc_not_supported');
          _displayText = AppLocalizations.get('play_screen.nfc_not_supported');
        });
      }
    } catch (e) {
      setState(() {
        _status = "${AppLocalizations.get('play_screen.nfc_error')}: $e";
        _displayText = AppLocalizations.get('play_screen.nfc_error');
      });
    }
  }

  void _startReading() {
    setState(() {
      _isReading = true;
      _status = AppLocalizations.get('play_screen.starting_read');
      _displayText = _useESP32Mode
          ? AppLocalizations.get('play_screen.tap_rfid')
          : AppLocalizations.get('play_screen.tap_nfc');
      _showSuccess = false;
      _lastUID = "";
      _currentObjectName = "";
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
          iosMultipleTagMessage: AppLocalizations.get(
            'play_screen.multiple_tags',
          ),
          iosAlertMessage: AppLocalizations.get('play_screen.scan_object'),
        );

        String tagId = '';
        if (tag.id.isNotEmpty) {
          tagId = tag.id.toUpperCase();
        }

        if (tagId.isNotEmpty && tagId.length >= 4) {
          _handleTagRead(tagId);
        } else {
          setState(() {
            _status = AppLocalizations.get('play_screen.tag_not_recognized');
            _displayText = AppLocalizations.get(
              'play_screen.tag_not_recognized',
            );
            _showSuccess = false;
          });
          _animationController.repeat();
        }

        await Future.delayed(Duration(seconds: 2));

        if (mounted && _isReading) {
          setState(() {
            _status = AppLocalizations.get('play_screen.waiting_next');
            _displayText = AppLocalizations.get('play_screen.tap_another');
            _showSuccess = false;
          });

          _animationController.repeat();
        }
      } catch (e) {
        if (_isReading && mounted) {
          setState(() {
            _status = AppLocalizations.get('play_screen.error_try_again');
            _displayText = AppLocalizations.get('play_screen.error_try_again');
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
        _status = AppLocalizations.get('play_screen.invalid_card');
        _displayText = AppLocalizations.get('play_screen.invalid_card');
        _showSuccess = false;
      });
      return;
    }

    String objectName = _getObjectName(uid);

    setState(() {
      _status =
          "${AppLocalizations.get('play_screen.object_recognized')}: $objectName";
      _displayText = objectName;
      _lastUID = uid;
      _currentObjectName = objectName;
      _showSuccess = true;
    });

    _animationController.stop();

    _saveScanResult(uid);

    Future.delayed(Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ObjectDetailScreen(
              objectName: objectName,
              objectId: uid,
              isEnglish: AppLocalizations.current?.currentLanguageCode == 'en',
            ),
          ),
        );
      }
    });
  }

  String _getObjectName(String uid) {
    String normalizedUID = uid.toUpperCase().replaceAll(' ', '');

    if (_objectDictionary.containsKey(normalizedUID)) {
      String currentLanguage =
          AppLocalizations.current?.currentLanguageCode ?? 'id';
      return _objectDictionary[normalizedUID]![currentLanguage] ??
          AppLocalizations.get('play_screen.unknown_object');
    }

    return AppLocalizations.get('play_screen.unknown_object');
  }

  void _speakObjectName() async {
    if (_currentObjectName.isNotEmpty) {
      String currentLanguage =
          AppLocalizations.current?.currentLanguageCode ?? 'id';
      await TTSService.setLanguage(currentLanguage);
      await TTSService.speak(_currentObjectName);
    }
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
      'object_name': _currentObjectName,
      'mode': _useESP32Mode ? 'ESP32' : 'NFC',
    };

    final history = prefs.getStringList('scan_history') ?? [];
    history.add(json.encode(scanResult));

    if (history.length > 100) {
      history.removeAt(0);
    }

    await prefs.setStringList('scan_history', history);

    print('✅ RFID UID Disimpan: $uid - $_currentObjectName');
  }

  void _stopReadingAndExit() {
    setState(() {
      _isReading = false;
      _status = AppLocalizations.get('play_screen.stopping');
      _displayText = AppLocalizations.get('play_screen.stopping');
    });

    _animationController.stop();

    TTSService.stop();

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

    TTSService.stop();

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
            _useESP32Mode
                ? AppLocalizations.get('play_screen.esp32_mode')
                : AppLocalizations.get('play_screen.nfc_mode'),
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
                                    ? AppLocalizations.get(
                                        'play_screen.success',
                                      )
                                    : AppLocalizations.get(
                                        'play_screen.explore_object',
                                      ))
                              : AppLocalizations.get(
                                  'play_screen.explore_object',
                                ),
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
                                    : ((_useESP32Mode &&
                                              _esp32Service.isConnected)
                                          ? Icons.wifi_rounded
                                          : (_nfcAvailable || _useESP32Mode
                                                ? Icons.info_outline_rounded
                                                : Icons.error_outline_rounded)),
                                color: _showSuccess
                                    ? Color(0xFF4ECDC4)
                                    : ((_useESP32Mode &&
                                              _esp32Service.isConnected)
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
                                  AppLocalizations.get(
                                    'play_screen.object_recognized',
                                  ),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF666666),
                                    fontFamily: 'ComicNeue',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 5),
                                Text(
                                  "UID: $_lastUID",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF888888),
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
                                        ? AppLocalizations.get(
                                            'play_screen.tip_esp32',
                                          )
                                        : AppLocalizations.get(
                                            'play_screen.tip_nfc',
                                          ),
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
                            AppLocalizations.get('play_screen.back'),
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
