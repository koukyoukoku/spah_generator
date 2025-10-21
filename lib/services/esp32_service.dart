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
  final _deviceDataController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _scanningController = StreamController<bool>.broadcast();
  final _provisioningController = StreamController<bool>.broadcast();

  Stream<String> get statusStream => _statusController.stream;
  Stream<bool> get connectedStream => _connectedController.stream;
  Stream<List<String>> get devicesStream => _devicesController.stream;
  Stream<Map<String, dynamic>> get deviceDataStream =>
      _deviceDataController.stream;
  Stream<bool> get scanningStream => _scanningController.stream;
  Stream<bool> get provisioningStream => _provisioningController.stream;

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
      _updateStatus('Error inilization: $e');
    }
  }

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

      await _scanAllNetworks();

      Timer(Duration(seconds: 5), () {
        if (_foundDevices.isEmpty && _isDiscovering) {
          _scanningController.add(false);
          _updateStatus('No devices found. Re-scanning...');
        }
      });
    } catch (e) {
      _scanningController.add(false);
      _updateStatus('UDP Discovery error: $e');
    }
  }

  Future<void> _scanAllNetworks() async {
    try {
      List<NetworkInterface> interfaces = await NetworkInterface.list();

      for (NetworkInterface interface in interfaces) {
        for (InternetAddress address in interface.addresses) {
          if (address.type == InternetAddressType.IPv4) {
            String subnet = _getSubnet(address.address);
            String broadcast = '$subnet.255';

            _sendDiscoveryPacket(broadcast);
          }
        }
      }

      _scanCommonSubnets();
    } catch (e) {
      _scanCommonSubnets();
    }
  }

  String _getSubnet(String ip) {
    List<String> parts = ip.split('.');
    if (parts.length == 4) {
      return '${parts[0]}.${parts[1]}.${parts[2]}';
    }
    return '192.168.1';
  }

  void _scanCommonSubnets() {
    List<String> commonSubnets = [
      '192.168.1.255',
      '192.168.0.255',
      '192.168.4.255',
      '10.0.0.255',
      '10.65.176.255',
      '172.16.0.255',
      '172.17.0.255',
      '172.18.0.255',
      '172.19.0.255',
      '172.20.0.255',
      '255.255.255.255',
    ];

    for (String subnet in commonSubnets) {
      _sendDiscoveryPacket(subnet);
    }
  }

  void _sendDiscoveryPacket(String broadcastIP) {
    if (_udpSocket == null) return;

    try {
      String discoveryMessage = 'ESP32_DISCOVERY_REQUEST';
      List<int> data = utf8.encode(discoveryMessage);

      _udpSocket!.send(data, InternetAddress(broadcastIP), 8888);
      print('📢 Sent broadcast to: $broadcastIP');
    } catch (e) {
      print('❌ Broadcast to $broadcastIP failed: $e');
    }
  }

  void _handleUDPResponse(Datagram datagram) {
    try {
      String message = String.fromCharCodes(datagram.data).trim();
      String deviceIP = datagram.address.address;

      print('📨 UDP Response from $deviceIP: $message');

      if (_isValidESP32Response(message)) {
        print('✅ Valid ESP32 response, proceeding with connection...');
        if (!_foundDevices.contains(deviceIP)) {
          _foundDevices.add(deviceIP);
          _devicesController.add(List.from(_foundDevices));
          _updateStatus('ESP32 Found: $deviceIP');

          if (_shouldAutoConnect && !_tcpConnected && !_isConnecting) {
            print('🚀 Auto-connect triggered for $deviceIP');
            Future.delayed(Duration(milliseconds: 300), () {
              _autoConnectToDevice(deviceIP);
            });
          }
        } else {
          print('🔄 Device $deviceIP already in list');
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
      bool isValid =
          jsonResponse.containsKey('device') &&
          jsonResponse['device'].toString().toLowerCase().contains('esp32');

      print('✅ JSON Valid: $isValid - Device: ${jsonResponse['device']}');
      return isValid;
    } catch (e) {
      bool containsESP32 = message.toLowerCase().contains('esp32');
      print('🔄 Fallback validation: $containsESP32');
      return containsESP32;
    }
  }

  Future<void> _stopUDPDiscovery() async {
    _udpSocket?.close();
    _udpSocket = null;
    _scanningController.add(false);
  }

  Future<void> _autoConnectToDevice(String ip) async {
    if (_tcpConnected && _deviceIP == ip) {
      print('✅ Already connected to $ip, skipping...');
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
        timeout: Duration(seconds: 5),
      );

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
      print('❌ Failed to connect to $ip: $e');
      _tcpConnected = false;
      _connectedController.add(false);
      _updateStatus('❌ Failed to connect: ${e.toString()}');

      if (_isDiscovering) {
        _updateStatus('🔄 Attempting to rescan...');
        await Future.delayed(Duration(seconds: 2));
        _startUDPDiscovery();
      }
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> _performAutoHandshake() async {
    print('🔄 Starting auto-handshake sequence...');

    await Future.delayed(Duration(milliseconds: 500));
    _sendTCPMessage('HANDSHAKE');

    await Future.delayed(Duration(milliseconds: 500));
    _sendTCPMessage('GET_STATUS');

    await Future.delayed(Duration(milliseconds: 500));
    _sendTCPMessage('GET_WIFI_INFO');

    print('✅ Auto-handshake sequence completed');
  }

  void _startPingService() {
    _pingTimer = Timer.periodic(Duration(seconds: 25), (timer) {
      if (_tcpConnected) {
        String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        _sendTCPMessage('PING:$timestamp');
      } else {
        timer.cancel();
      }
    });
  }

  void _handleTCPData(List<int> data) {
    try {
      String message = utf8.decode(data).trim();
      print('📨 Received: $message');

      _processTCPMessage(message);
    } catch (e) {
      print('❌ Error decoding TCP data: $e');
    }
  }

  void _processTCPMessage(String message) {
    // Coba parse sebagai JSON terlebih dahulu
    try {
      Map<String, dynamic> jsonData = json.decode(message);
      String messageType = jsonData['type'] ?? '';

      if (messageType == 'wifi_info') {
        _handleWifiInfo(jsonData); // Kirim Map yang sudah di-parse
        return;
      } else if (messageType == 'status') {
        _handleStatusMessage(
          json.encode(jsonData),
        ); // Tetap kirim string untuk konsistensi
        return;
      } else if (messageType == 'pong') {
        String timestamp = jsonData['original_timestamp']?.toString() ?? '';
        _handlePongMessage(timestamp);
        return;
      }
    } catch (e) {}

    if (message.startsWith('HELLO:')) {
      _updateStatus('👋 ${message.substring(6)}');
    } else if (message == 'HANDSHAKE_ACK' || message.contains('READY')) {
      _updateStatus('🤝 Handshake Success');
    } else if (message.startsWith('STATUS:')) {
      _handleStatusMessage(message.substring(7));
    } else if (message.startsWith('PONG:')) {
      _handlePongMessage(message.substring(5));
    } else if (message.startsWith('WIFI_INFO:')) {
      try {
        Map<String, dynamic> wifiInfo = json.decode(message.substring(10));
        _handleWifiInfo(wifiInfo);
      } catch (e) {
        print('❌ Error parsing legacy WiFi info: $e');
      }
    } else if (message.startsWith('RFID:')) {
      _handleRFIDMessage(message.substring(5));
    } else if (message.startsWith('ERROR:')) {
      _updateStatus('❌ ${message.substring(6)}');
    } else {
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

  void _handleWifiInfo(Map<String, dynamic> wifiInfo) {
    try {
      print("📡 WiFi Info: ${wifiInfo}");
      _deviceData.addAll(wifiInfo);
      _wifiName = wifiInfo['ssid'] ?? _wifiName;
      _deviceDataController.add(Map.from(_deviceData));
      print('asas ${_wifiName}');
    } catch (e) {
      print('❌ Error handling WiFi info: $e');
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

  void sendTCPMessage(String message) {
    if (_tcpSocket != null && _tcpConnected) {
      try {
        _tcpSocket!.write('$message\n');
        print('📤 Sent: $message');
      } catch (e) {
        print('❌ Error sending TCP: $e');
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

  void startDiscovery() {
    if (!_isDiscovering) {
      _startAutoDiscovery();
    }
  }

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

  String get wifiName => _wifiName;
  String get deviceIP => _deviceIP;
  bool get isConnected => _tcpConnected;
  bool get isDiscovering => _isDiscovering;
  bool get isConnecting => _isConnecting;
  List<String> get foundDevices => List.from(_foundDevices);
  Map<String, dynamic> get deviceData => Map.from(_deviceData);
  String get lastStatus => _lastStatus;

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
