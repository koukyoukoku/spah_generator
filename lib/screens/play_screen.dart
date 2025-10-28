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
import 'package:Eksplorasi/services/firebase.dart';

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
  
  final FirebaseRealtimeDB _firebaseService = FirebaseRealtimeDB();

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
          _displayText = _getUserFriendlyStatus(status);
        });
      }
    });

    _esp32DataSubscription = _esp32Service.deviceDataStream.listen((data) {
      if (data.containsKey('rfid_uid') && _isReading) {
        String uid = data['rfid_uid'].toString();
        if (uid.isNotEmpty && uid.length >= 4) {
          _handleTagRead(uid);
        }
      }
    });

    _esp32Service.startDiscovery();
    _startReading();
  }

  String _getUserFriendlyStatus(String status) {
    if (status.contains('ESP32 Found')) return AppLocalizations.get('play_screen.esp32_found');
    if (status.contains('Connected to ESP32')) return AppLocalizations.get('play_screen.esp32_connected');
    if (status.contains('Handshake Success')) return AppLocalizations.get('play_screen.ready_to_scan');
    if (status.contains('Kartu tidak dikenali') || status.contains('Card not recognized')) {
      return AppLocalizations.get('play_screen.card_not_recognized');
    }
    if (status.contains('RFID Tidak Valid') || status.contains('Invalid card')) {
      return AppLocalizations.get('play_screen.invalid_card');
    }
    if (status.contains('Connection Disconnected')) return AppLocalizations.get('play_screen.connection_lost');
    if (status.contains('Failed to connect')) return AppLocalizations.get('play_screen.connection_failed');
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
      } else {
        setState(() {
          _nfcAvailable = false;
          _status = AppLocalizations.get('play_screen.nfc_disabled');
          _displayText = AppLocalizations.get('play_screen.enable_nfc');
        });
      }
    } catch (e) {
      setState(() {
        _status = AppLocalizations.get('play_screen.nfc_error');
        _displayText = AppLocalizations.get('play_screen.nfc_error');
      });
    }
  }

  void _startReading() {
    setState(() {
      _isReading = true;
      _displayText = _useESP32Mode 
          ? AppLocalizations.get('play_screen.tap_rfid')
          : AppLocalizations.get('play_screen.tap_nfc');
      _showSuccess = false;
    });
    _animationController.repeat();

    if (!_useESP32Mode) {
      _readNfcContinuously();
    }
  }

  void _readNfcContinuously() async {
    while (_isReading && mounted) {
      try {
        final tag = await FlutterNfcKit.poll(
          timeout: Duration(seconds: 60),
          iosMultipleTagMessage: AppLocalizations.get('play_screen.multiple_tags'),
          iosAlertMessage: AppLocalizations.get('play_screen.scan_object'),
        );

        if (tag.id.isNotEmpty) {
          _handleTagRead(tag.id.toUpperCase());
        }
        await Future.delayed(Duration(seconds: 2));
      } catch (e) {
        await Future.delayed(Duration(seconds: 1));
      }
    }
  }

  void _handleTagRead(String uid) async {
    if (uid.length < 4) return;

    print('🟡 DEBUG: Starting _handleTagRead for UID: $uid');

    try {
      final objectData = await _getObjectFromFirebase(uid);
      print('🟡 DEBUG: Object data received: $objectData');

      if (objectData != null && objectData.isNotEmpty) {
        final objectName = _getObjectName(objectData);
        print('🟡 DEBUG: Object name extracted: $objectName');
        setState(() {
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
                  objectData: objectData,
                ),
              ),
            );
          }
        });
      } else {
        print('🔴 DEBUG: Object data is NULL or EMPTY for UID: $uid');
        setState(() {
          _displayText = AppLocalizations.get('play_screen.unknown_object');
          _showSuccess = false;
        });
      }
    } catch (e) {
      print('🔴 DEBUG: Error in _handleTagRead: $e');
      setState(() {
        _displayText = AppLocalizations.get('play_screen.error_try_again');
        _showSuccess = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _getObjectFromFirebase(String uid) async {
    try {
      final normalizedUID = uid.toUpperCase().replaceAll(' ', '');
      print('🟡 DEBUG: Fetching from Firebase for UID: $normalizedUID');
      
      final objectData = await _firebaseService.getData('objects/$normalizedUID');
      print('🟡 DEBUG: Raw data from Firebase: $objectData');
      
      return objectData;
    } catch (e) {
      print('🔴 DEBUG: Firebase error: $e');
      return null;
    }
  }

  String _getObjectName(Map<String, dynamic> objectData) {
    try {
      final currentLanguage = AppLocalizations.current?.currentLanguageCode ?? 'id';
      final languageKey = currentLanguage == 'en' ? 'en' : 'id';
      
      print('🟡 DEBUG: Current language: $currentLanguage, looking for key: $languageKey');
      print('🟡 DEBUG: Available keys in objectData: ${objectData.keys}');
      
      if (objectData.containsKey(languageKey)) {
        final name = objectData[languageKey]?.toString();
        print('🟡 DEBUG: Found object name: $name');
        return name ?? AppLocalizations.get('play_screen.unknown_object');
      } else {
        print('🔴 DEBUG: Language key "$languageKey" not found in object data');
        return AppLocalizations.get('play_screen.unknown_object');
      }
    } catch (e) {
      print('🔴 DEBUG: Error in _getObjectName: $e');
      return AppLocalizations.get('play_screen.unknown_object');
    }
  }

  Future<void> _saveScanResult(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList('scan_history') ?? [];
      
      history.add(json.encode({
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'uid': uid,
        'object_name': _currentObjectName,
        'mode': _useESP32Mode ? 'ESP32' : 'NFC',
      }));

      if (history.length > 100) history.removeAt(0);
      await prefs.setStringList('scan_history', history);
      
      print('✅ Scan result saved: $uid - $_currentObjectName');
    } catch (e) {
      print('🔴 Save error: $e');
    }
  }

  void _stopReadingAndExit() {
    setState(() {
      _isReading = false;
      _displayText = AppLocalizations.get('play_screen.stopping');
    });

    _animationController.stop();
    TTSService.stop();

    if (_useESP32Mode) {
      _esp32Service.sendTCPMessage('STOP_RFID_READING');
    } else {
      FlutterNfcKit.finish();
    }

    if (mounted) Navigator.pop(context);
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