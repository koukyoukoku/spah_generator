import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:esp_smartconfig/esp_smartconfig.dart';
import 'package:network_info_plus/network_info_plus.dart';

class ESP32Service {
  static final ESP32Service _instance = ESP32Service._internal();
  factory ESP32Service() => _instance;
  ESP32Service._internal() {
    _initializeService();
  }

  final Provisioner _provisioner = Provisioner.espTouch();
  final NetworkInfo _networkInfo = NetworkInfo();
  
  Socket? _tcpSocket;
  RawDatagramSocket? _udpSocket;
  
  bool _tcpConnected = false;
  bool _isDiscovering = false;
  bool _isConnecting = false;
  bool _shouldAutoConnect = true;
  String _wifiName = '';
  String _deviceIP = '';
  String _lastStatus = 'Menyiapkan...';
  final List<String> _foundDevices = [];
  final Map<String, dynamic> _deviceData = {};
  Timer? _discoveryTimer;
  Timer? _pingTimer;

  final _statusController = StreamController<String>.broadcast();
  final _connectedController = StreamController<bool>.broadcast();
  final _devicesController = StreamController<List<String>>.broadcast();
  final _deviceDataController = StreamController<Map<String, dynamic>>.broadcast();
  final _scanningController = StreamController<bool>.broadcast();
  final _provisioningController = StreamController<bool>.broadcast();

  Stream<String> get statusStream => _statusController.stream;
  Stream<bool> get connectedStream => _connectedController.stream;
  Stream<List<String>> get devicesStream => _devicesController.stream;
  Stream<Map<String, dynamic>> get deviceDataStream => _deviceDataController.stream;
  Stream<bool> get scanningStream => _scanningController.stream;
  Stream<bool> get provisioningStream => _provisioningController.stream;

  // ========== INITIALIZATION ==========
  Future<void> _initializeService() async {
    _updateStatus('Starting ESP32...');
    
    try {
      String? wifiName = await _networkInfo.getWifiName();
      String? wifiIP = await _networkInfo.getWifiIP();
      
      _wifiName = wifiName?.replaceAll('"', '') ?? 'Unknown';
      _deviceIP = wifiIP ?? '';
      
      _updateStatus('WiFi: $_wifiName');
      
      await Future.delayed(Duration(seconds: 2));
      _startAutoDiscovery();
      
    } catch (e) {
      _updateStatus('❌ Error inilization: $e');
    }
  }

  // ========== AUTO DISCOVERY SYSTEM ==========
  void _startAutoDiscovery() {
    _isDiscovering = true;
    _shouldAutoConnect = true;
    _updateStatus('Starting auto-discovery...');
    _startUDPDiscovery();
    
    _discoveryTimer = Timer.periodic(Duration(seconds: 15), (timer) {
      if (!_tcpConnected && _isDiscovering) {
        _updateStatus('Re-scan devices...');
        _startUDPDiscovery();
      }
    });
  }

  void stopDiscovery() {
    _isDiscovering = false;
    _shouldAutoConnect = false;
    _discoveryTimer?.cancel();
    _stopUDPDiscovery();
    _updateStatus('Discovery Stopped');
  }

  void startDiscovery() {
    if (!_isDiscovering) {
      _startAutoDiscovery();
    }
  }

  // ========== UDP DISCOVERY ==========
  Future<void> _startUDPDiscovery() async {
    if (!_isDiscovering) return;

    _scanningController.add(true);
    _updateStatus('Scanning for ESP32...');

    try {
      await _stopUDPDiscovery();
    
      _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _udpSocket!.broadcastEnabled = true;

      _udpSocket!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          Datagram? datagram = _udpSocket!.receive();
          if (datagram != null) {
            _handleUDPResponse(datagram);
          }
        }
      });
      await _sendUDPBroadcast();

      Timer(Duration(seconds: 10), () {
        if (_foundDevices.isEmpty && _isDiscovering) {
          _scanningController.add(false);
          _updateStatus('No other devices found. Re-scanning...');
        }
      });

    } catch (e) {
      _scanningController.add(false);
      _updateStatus('❌ UDP Discovery error: $e');
    }
  }

  void _handleUDPResponse(Datagram datagram) {
    try {
      String message = String.fromCharCodes(datagram.data).trim();
      String deviceIP = datagram.address.address;

      print('📨 UDP Response from $deviceIP: $message');

      if (_isValidESP32Response(message)) {
        if (!_foundDevices.contains(deviceIP)) {
          _foundDevices.add(deviceIP);
          _devicesController.add(List.from(_foundDevices));
          _updateStatus('ESP32 Found: $deviceIP');

          if (_shouldAutoConnect) {
            Future.delayed(Duration(milliseconds: 500), () {
              _autoConnectToDevice(deviceIP);
            });
          }
        }
      } else {
        print('❌ Invalid ESP32 response: $message');
      }
    } catch (e) {
      print('❌ Error handling UDP response: $e');
    }
  }

  bool _isValidESP32Response(String message) {
    try {
      Map<String, dynamic> jsonResponse = json.decode(message);
      bool isValid = jsonResponse.containsKey('device') && 
                     jsonResponse['device'].toString().toLowerCase().contains('esp32');
      
      print('✅ JSON Valid: $isValid - Device: ${jsonResponse['device']}');
      return isValid;
      
    } catch (e) {
      bool containsESP32 = message.toLowerCase().contains('esp32');
      print('🔄 Fallback validation: $containsESP32');
      return containsESP32;
    }
  }

  Future<void> _sendUDPBroadcast() async {
    if (_udpSocket == null) return;

    String discoveryMessage = 'ESP32_DISCOVERY_REQUEST';
    List<int> data = utf8.encode(discoveryMessage);

    List<String> broadcastIPs = await _getBroadcastAddresses();
    
    for (String broadcastIP in broadcastIPs) {
      try {
        await _udpSocket!.send(
          data, 
          InternetAddress(broadcastIP), 
          8888
        );
        print('📢 Sent broadcast to: $broadcastIP');
      } catch (e) {
        print('❌ Broadcast to $broadcastIP failed: $e');
      }
    }

    _updateStatus('Sending broadcast discovery...');
  }

  Future<List<String>> _getBroadcastAddresses() async {
    List<String> addresses = [];
    
    try {
      if (_deviceIP.isNotEmpty) {
        List<String> parts = _deviceIP.split('.');
        if (parts.length == 4) {
          addresses.add('${parts[0]}.${parts[1]}.${parts[2]}.255');
        }
      }
    } catch (e) {
      print('Error calculating broadcast: $e');
    }

    if (addresses.isEmpty) {
      addresses.addAll([
        '255.255.255.255',
        '192.168.1.255', 
        '192.168.0.255',
        '192.168.4.255',
        '10.0.0.255',
      ]);
    }

    return addresses;
  }

  Future<void> _stopUDPDiscovery() async {
    _udpSocket?.close();
    _udpSocket = null;
    _scanningController.add(false);
  }

  // ========== AUTO TCP CONNECTION ==========
  Future<void> _autoConnectToDevice(String ip) async {
    if (_tcpConnected && _deviceIP == ip) {
      print('Already connected to $ip, skipping...');
      return;
    }

    if (_isConnecting) {
      print('⏳ Already connecting to another device, skipping $ip');
      return;
    }

    _isConnecting = true;
    _updateStatus('Connecting to $ip...');

    try {
      _stopUDPDiscovery();
    
      await _disconnectTCP();
      
      print('🔌 Attempting TCP connection to $ip:1234');
      
      _tcpSocket = await Socket.connect(
        ip, 
        1234, 
        timeout: Duration(seconds: 3)
      ).timeout(Duration(seconds: 5));

      _tcpSocket!.listen(
        _handleTCPData,
        onError: _handleTCPError,
        onDone: _handleTCPDone,
        cancelOnError: true,
      );

      _tcpConnected = true;
      _deviceIP = ip;
      _connectedController.add(true);
      _updateStatus('✅ Connected to ESP32: $ip');

      await _performAutoHandshake();

      _startPingService();

    } catch (e) {
      print('❌ Failed connect to $ip: $e');
      _tcpConnected = false;
      _connectedController.add(false);
      _updateStatus('❌ Failed connect: ${e.toString()}');
      
      if (_isDiscovering) {
        _updateStatus('Attempting to Rescanning...');
        await Future.delayed(Duration(seconds: 2));
        _startUDPDiscovery();
      }
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> _performAutoHandshake() async {
    print('Starting auto-handshake sequence...');
    
    await Future.delayed(Duration(milliseconds: 300));
    _sendTCPMessage('HANDSHAKE');
    
    await Future.delayed(Duration(milliseconds: 500));
    _sendTCPMessage('GET_STATUS');
    
    await Future.delayed(Duration(milliseconds: 500));
    _sendTCPMessage('GET_WIFI_INFO');
    
    print('Auto-handshake sequence completed');
  }

  void _startPingService() {
    _pingTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (_tcpConnected) {
        String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        _sendTCPMessage('PING:$timestamp');
      } else {
        timer.cancel();
      }
    });
  }

  // ========================= TCP MESSAGE HANDLER =========================
  void _handleTCPData(List<int> data) {
    try {
      String message = utf8.decode(data).trim();
      print('📨 Received: $message');
      
      _processTCPMessage(message);
    } catch (e) {
      print('Error decoding TCP data: $e');
    }
  }

  void _processTCPMessage(String message) {
    if (message.startsWith('HELLO:')) {
      _updateStatus('👋 ${message.substring(6)}');
    } 
    else if (message == 'HANDSHAKE_ACK' || message.contains('READY')) {
      _updateStatus('🤝 Handshake Success');
    }
    else if (message.startsWith('STATUS:')) {
      _handleStatusMessage(message.substring(7));
    }
    else if (message.startsWith('PONG:')) {
      _handlePongMessage(message.substring(5));
    }
    else if (message.startsWith('WIFI_INFO:')) {
      _handleWifiInfo(message.substring(10));
    }
    else if (message.startsWith('RFID:')) {
      _handleRFIDMessage(message.substring(5));
    }
    else if (message.startsWith('ERROR:')) {
      _updateStatus('❌ ${message.substring(6)}');
    }
    else {
      _updateStatus('📡 Data: $message');
    }
  }

  void _handleStatusMessage(String jsonStr) {
    try {
      Map<String, dynamic> statusData = json.decode(jsonStr);
      _deviceData.addAll(statusData);
      _deviceDataController.add(Map.from(_deviceData));
      
      String status = statusData['status'] ?? 'Connected';
      int? rssi = statusData['rssi'];
      
      if (rssi != null) {
        _updateStatus('📊 Status: $status | Signal: ${rssi}dBm');
      } else {
        _updateStatus('📊 Status: $status');
      }
    } catch (e) {
      _updateStatus('📊 Status: $jsonStr');
    }
  }

  void _handlePongMessage(String timestamp) {
    try {
      int sentTime = int.parse(timestamp);
      int latency = DateTime.now().millisecondsSinceEpoch - sentTime;
      _updateStatus('🏓 Ping: ${latency}ms');
    } catch (e) {
      _updateStatus('🏓 Pong received');
    }
  }

  void _handleWifiInfo(String jsonStr) {
    try {
      Map<String, dynamic> wifiInfo = json.decode(jsonStr);
      _deviceData.addAll(wifiInfo);
      _deviceDataController.add(Map.from(_deviceData));
    } catch (e) {
      print('Error parsing WiFi info: $e');
    }
  }

  void _handleRFIDMessage(String rfidData) {
    _deviceData['rfid'] = rfidData;
    _deviceDataController.add(Map.from(_deviceData));
    _updateStatus('🎫 RFID: $rfidData');
  }

  void _handleTCPError(error) {
    print('❌ TCP Error: $error');
    _updateStatus('❌ Connection Disconnected: $error');
    _tcpConnected = false;
    _connectedController.add(false);
    _isConnecting = false;
    
    _disconnectTCP();
    
    if (_isDiscovering && _shouldAutoConnect) {
      _updateStatus('🔄 Trying to reconnect in 3 seconds...');
      Timer(Duration(seconds: 3), () {
        if (!_tcpConnected && _isDiscovering) {
          _startUDPDiscovery();
        }
      });
    }
  }

  void _handleTCPDone() {
    print('📴 TCP Connection closed');
    _updateStatus('📴 Connection Disconnected by ESP32');
    _tcpConnected = false;
    _connectedController.add(false);
    _isConnecting = false;
    
    _disconnectTCP();
    
    if (_isDiscovering && _shouldAutoConnect) {
      Timer(Duration(seconds: 2), () {
        if (!_tcpConnected) {
          _startUDPDiscovery();
        }
      });
    }
  }

  // ==========- PUBLIC METHODS -==========
  void sendTCPMessage(String message) {
    if (_tcpSocket != null && _tcpConnected) {
      try {
        _tcpSocket!.write('$message\n');
        print('📤 Sent: $message');
      } catch (e) {
        print('Error sending TCP: $e');
        _handleTCPError(e);
      }
    } else {
      _updateStatus('❌ Not Connected to ESP32');
    }
  }

  void connectToDevice(String ip) {
    _autoConnectToDevice(ip);
  }

  void simulateRFIDScan(String rfidData) {
    if (isConnected) {
      sendTCPMessage('RFID:$rfidData');
    }
  }

  void requestDeviceStatus() {
    sendTCPMessage('GET_STATUS');
  }

  void pingDevice() {
    String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    sendTCPMessage('PING:$timestamp');
  }

  Future<void> startProvisioning(String ssid, String password) async {
    _provisioningController.add(true);
    _updateStatus('📡 Sending WiFi Credentials to ESP32...');

    try {
      String? bssid = await _networkInfo.getWifiBSSID();

      await _provisioner.start(
        ProvisioningRequest.fromStrings(
          ssid: ssid,
          bssid: bssid ?? '',
          password: password,
        ),
      );

      await Future.delayed(Duration(seconds: 8));
      
      _provisioningController.add(false);
      _updateStatus('✅ WiFi credentials was sent! ESP32 Restarting...');

      _provisioner.stop();

      Timer(Duration(seconds: 10), () {
        _startUDPDiscovery();
      });

    } catch (e) {
      _provisioningController.add(false);
      _updateStatus('❌ Provisioning failed: $e');
    }
  }

  // ========== UTILITY METHODS ==========
  void _updateStatus(String status) {
    _lastStatus = status;
    _statusController.add(status);
    print('🔔 Status: $status');
  }

  void _sendTCPMessage(String message) {
    sendTCPMessage(message);
  }

  Future<void> _disconnectTCP() async {
    _pingTimer?.cancel();
    _pingTimer = null;
    
    _tcpSocket?.destroy();
    _tcpSocket = null;
    
    _tcpConnected = false;
    _connectedController.add(false);
  }

  void disconnect() {
    _disconnectTCP();
    stopDiscovery();
  }

  // ========== GETTERS ==========
  String get wifiName => _wifiName;
  String get deviceIP => _deviceIP;
  bool get isConnected => _tcpConnected;
  bool get isDiscovering => _isDiscovering;
  bool get isConnecting => _isConnecting;
  List<String> get foundDevices => List.from(_foundDevices);
  Map<String, dynamic> get deviceData => Map.from(_deviceData);
  String get lastStatus => _lastStatus;

  // ========== CLEANUP ==========
  void dispose() {
    disconnect();
    _provisioner.stop();
    
    _statusController.close();
    _connectedController.close();
    _devicesController.close();
    _deviceDataController.close();
    _scanningController.close();
    _provisioningController.close();
  }
}