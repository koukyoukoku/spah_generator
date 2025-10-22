import 'dart:async';
import 'package:flutter/material.dart';
import 'package:spah_generator/services/esp32_service.dart';
import 'package:spah_generator/components/SmoothPress.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ESP32ManagerScreen extends StatefulWidget {
  final ESP32Service esp32Service;

  const ESP32ManagerScreen({Key? key, required this.esp32Service}) : super(key: key);

  @override
  _ESP32ManagerScreenState createState() => _ESP32ManagerScreenState();
}

class _ESP32ManagerScreenState extends State<ESP32ManagerScreen> {
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _status = 'Menyiapkan...';
  String _wifiName = '';
  bool _isProvisioning = false;
  bool _isScanning = false;
  bool _isConnected = false;
  bool _useESP32Mode = false;
  List<String> _foundDevices = [];
  Map<String, dynamic> _deviceData = {};

  late StreamSubscription<String> _statusSubscription;
  late StreamSubscription<bool> _scanningSubscription;
  late StreamSubscription<bool> _connectedSubscription;
  late StreamSubscription<List<String>> _devicesSubscription;
  late StreamSubscription<Map<String, dynamic>> _deviceDataSubscription;
  late StreamSubscription<bool> _provisioningSubscription;

  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();

    _wifiName = widget.esp32Service.wifiName;
    _isConnected = widget.esp32Service.isConnected;
    _status = widget.esp32Service.lastStatus;
    _ssidController.text = _wifiName;

    _loadESP32Preference();
    _setupStreamListeners();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isConnected) {
        widget.esp32Service.requestDeviceStatus();
        _startPollingDeviceStatus();
      } else if (!_isConnected && _useESP32Mode) {
        widget.esp32Service.startDiscovery();
      }
    });
  }

  Future<void> _loadESP32Preference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _useESP32Mode = prefs.getBool('use_esp32_mode') ?? false;
    });
  }

  Future<void> _saveESP32Preference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_esp32_mode', value);
    setState(() {
      _useESP32Mode = value;
    });
    
    if (value) {
      widget.esp32Service.startDiscovery();
    } else {
      widget.esp32Service.stopDiscovery();
    }
  }

  void _setupStreamListeners() {
    _statusSubscription = widget.esp32Service.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          _status = status;
        });
      }
    });

    _scanningSubscription = widget.esp32Service.scanningStream.listen((
      scanning,
    ) {
      if (mounted) {
        setState(() {
          _isScanning = scanning;
        });
      }
    });

    _connectedSubscription = widget.esp32Service.connectedStream.listen((
      connected,
    ) {
      if (mounted) {
        setState(() {
          _isConnected = connected;
        });
        if (connected) {
          widget.esp32Service.requestDeviceStatus();
          _startPollingDeviceStatus();
        } else {
          _stopPollingDeviceStatus();
        }
      }
    });

    _devicesSubscription = widget.esp32Service.devicesStream.listen((devices) {
      if (mounted) {
        setState(() {
          _foundDevices = devices;
        });
      }
    });

    _deviceDataSubscription = widget.esp32Service.deviceDataStream.listen((
      data,
    ) {
      if (mounted) {
        setState(() {
          _deviceData = data;
        });
      }
    });

    _provisioningSubscription = widget.esp32Service.provisioningStream.listen((
      provisioning,
    ) {
      if (mounted) {
        setState(() {
          _isProvisioning = provisioning;
        });
      }
    });
  }

  void _startPollingDeviceStatus() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(Duration(seconds: 5), (_) {
      widget.esp32Service.requestDeviceStatus();
    });
  }
  
  void _stopPollingDeviceStatus() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE8F4F8),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Color(0xFF4ECDC4).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            
            Positioned(
              bottom: -50,
              left: -30,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: Color(0xFFFE6D73).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  SizedBox(height: 70),
                  _buildModeToggleCard(),
                  SizedBox(height: 20),
                  _buildConnectionCard(),
                  SizedBox(height: 20),
                  if (_useESP32Mode) _buildDiscoveryCard(),
                  SizedBox(height: 20),
                  if (_isConnected && _deviceData.isNotEmpty) 
                    _buildDeviceInfoCard(),
                  SizedBox(height: 20),
                  if (_useESP32Mode) _buildWiFiConfigCard(),
                  SizedBox(height: 20),
                ],
              ),
            ),
            Positioned(
              top: 16,
              left: 21,
              child: SmoothPressButton(
                onPressed: () => Navigator.pop(context, true),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: Color(0xFF2D5A7E),
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeToggleCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Color(0xFFFED766).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.settings_input_antenna,
              color: Color(0xFFFED766),
              size: 28,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mode Eksplorasi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D5A7E),
                    fontFamily: 'ComicNeue',
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _useESP32Mode ? 'Menggunakan ESP32' : 'Menggunakan NFC',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                    fontFamily: 'ComicNeue',
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _useESP32Mode,
            onChanged: _saveESP32Preference,
            activeColor: Color(0xFF4ECDC4),
            activeTrackColor: Color(0xFF4ECDC4).withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionCard() {
    bool isActuallyConnected = widget.esp32Service.isConnected;
    String deviceIP = widget.esp32Service.deviceIP;

    if (!_useESP32Mode) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4ECDC4), Color(0xFF2AA8A0)],
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.nfc,
                color: Colors.white,
                size: 40,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'MODE NFC AKTIF',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontFamily: 'ComicNeue',
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Gunakan NFC perangkat untuk eksplorasi benda',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
                fontFamily: 'ComicNeue',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isActuallyConnected
              ? [Color(0xFF4ECDC4), Color(0xFF2AA8A0)]
              : [Color(0xFFFE6D73), Color(0xFFE55A60)],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isActuallyConnected ? Icons.check_circle : Icons.sync,
              color: Colors.white,
              size: 40,
            ),
          ),
          SizedBox(height: 16),
          Text(
            isActuallyConnected ? 'TERHUBUNG' : 'MENGHUBUNGKAN...',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontFamily: 'ComicNeue',
            ),
          ),
          SizedBox(height: 8),
          Text(
            _isConnected ? "Perangkat terhubung ke ESP32" : _status,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
              fontFamily: 'ComicNeue',
            ),
            textAlign: TextAlign.center,
          ),
          if (isActuallyConnected && deviceIP.isNotEmpty) ...[
            SizedBox(height: 16),
            Divider(color: Colors.white.withOpacity(0.3)),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem(Icons.developer_board, 'IP Device', deviceIP),
                _buildInfoItem(
                  Icons.wifi,
                  'WiFi',
                  widget.esp32Service.wifiName,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
            fontFamily: 'ComicNeue',
          ),
        ),
        SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontFamily: 'ComicNeue',
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceInfoCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.memory, color: Color(0xFF4ECDC4), size: 24),
              SizedBox(width: 8),
              Text(
                'Info Perangkat',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D5A7E),
                  fontFamily: 'ComicNeue',
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (_deviceData['rssi'] != null)
            _buildDeviceInfoRow('📶 Sinyal WiFi', '${_deviceData['rssi']} dBm'),
          if (_deviceData['ssid'] != null)
            _buildDeviceInfoRow('🌐 WiFi Terhubung', _deviceData['ssid']),
          if (_deviceData['uptime'] != null)
            _buildDeviceInfoRow(
              '⏱️ Waktu Aktif',
              _formatUptime(_deviceData['uptime']),
            ),
          if (_deviceData['free_heap'] != null)
            _buildDeviceInfoRow(
              '💾 Memory',
              _formatBytes(_deviceData['free_heap']),
            ),
        ],
      ),
    );
  }

  Widget _buildDeviceInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
                fontFamily: 'ComicNeue',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF333333),
                fontFamily: 'ComicNeue',
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoveryCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.search, color: Color(0xFFFE6D73), size: 24),
              SizedBox(width: 8),
              Text(
                'Pencarian Perangkat',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D5A7E),
                  fontFamily: 'ComicNeue',
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          SmoothPressButton(
            onPressed: _isScanning
                ? widget.esp32Service.stopDiscovery
                : widget.esp32Service.startDiscovery,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _isScanning ? Color(0xFFFFA726) : Color(0xFF4ECDC4),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isScanning)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else
                    Icon(Icons.search, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    _isScanning ? 'SEDANG MENCARI...' : 'MULAI PENCARIAN',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: 'ComicNeue',
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_foundDevices.isNotEmpty) ...[
            SizedBox(height: 16),
            Text(
              'Perangkat Ditemukan (${_foundDevices.length})',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D5A7E),
                fontFamily: 'ComicNeue',
              ),
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _foundDevices.map((ip) {
                bool isCurrent = widget.esp32Service.deviceIP == ip;
                return SmoothPressButton(
                  onPressed: () {
                    if (!isCurrent) {
                      widget.esp32Service.connectToDevice(ip);
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isCurrent ? Color(0xFF4ECDC4) : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCurrent
                            ? Color(0xFF2AA8A0)
                            : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isCurrent
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: isCurrent ? Colors.white : Colors.grey[600],
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          ip,
                          style: TextStyle(
                            color: isCurrent ? Colors.white : Colors.grey[800],
                            fontWeight: FontWeight.w600,
                            fontFamily: 'ComicNeue',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          if (_isConnected) ...[
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SmoothPressButton(
                    onPressed: () {
                      widget.esp32Service.requestDeviceStatus();
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.refresh, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'REFRESH',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'ComicNeue',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: SmoothPressButton(
                    onPressed: () {
                      widget.esp32Service.pingDevice();
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.purple,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.network_check,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'TEST',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
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
        ],
      ),
    );
  }

  Widget _buildWiFiConfigCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.wifi, color: Color(0xFF4ECDC4), size: 24),
              SizedBox(width: 8),
              Text(
                'Setup WiFi Baru',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D5A7E),
                  fontFamily: 'ComicNeue',
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Untuk perangkat baru, masukkan kredensial WiFi:',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
              fontFamily: 'ComicNeue',
            ),
          ),
          SizedBox(height: 16),
          _buildInputField(
            controller: _ssidController,
            label: 'Nama WiFi (SSID)',
            icon: Icons.wifi,
            hint: 'Masukkan nama WiFi',
          ),
          SizedBox(height: 12),
          _buildInputField(
            controller: _passwordController,
            label: 'Password WiFi',
            icon: Icons.lock,
            hint: 'Masukkan password',
            obscureText: true,
          ),
          SizedBox(height: 20),
          SmoothPressButton(
            onPressed: _isProvisioning ? () {} : _provisionESP32,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _isProvisioning ? Colors.grey : Color(0xFFFE6D73),
                borderRadius: BorderRadius.circular(15),
                boxShadow: _isProvisioning
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isProvisioning)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else
                    Icon(Icons.send, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    _isProvisioning ? 'MENGIRIM...' : 'KIRIM KE PERANGKAT',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: 'ComicNeue',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    bool obscureText = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: TextStyle(fontFamily: 'ComicNeue', fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: Color(0xFF4ECDC4)),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  String _formatUptime(dynamic uptime) {
    if (uptime is int) {
      int seconds = uptime ~/ 1000;
      int hours = seconds ~/ 3600;
      int minutes = (seconds % 3600) ~/ 60;
      int secs = seconds % 60;
      if (hours > 0) {
        return "${hours}:${minutes.toString().padLeft(2, "0")}:${secs.toString().padLeft(2, "0")}";
      } else if (minutes > 0) {
        return "${minutes}:${secs.toString().padLeft(2, "0")}";
      } else {
        return '${secs.toString().padLeft(2, "0")}';
      }
    }
    return uptime.toString();
  }

  String _formatBytes(dynamic bytes) {
    if (bytes is int) {
      if (bytes > 1024) {
        double kb = bytes / 1024;
        return '${kb.toStringAsFixed(1)} KB';
      }
      return '$bytes bytes';
    }
    return bytes.toString();
  }

  void _provisionESP32() {
    if (_ssidController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorDialog('Harap isi nama dan password WiFi');
      return;
    }

    widget.esp32Service.startProvisioning(
      _ssidController.text,
      _passwordController.text,
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text(
              'Perhatian',
              style: TextStyle(
                fontFamily: 'ComicNeue',
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(
            fontFamily: 'ComicNeue',
            fontSize: 16,
            color: Color(0xFF666666),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'MENGERTI',
              style: TextStyle(
                fontFamily: 'ComicNeue',
                fontWeight: FontWeight.w600,
                color: Color(0xFF4ECDC4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _statusSubscription.cancel();
    _scanningSubscription.cancel();
    _connectedSubscription.cancel();
    _devicesSubscription.cancel();
    _deviceDataSubscription.cancel();
    _provisioningSubscription.cancel();

    _stopPollingDeviceStatus();
    
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}