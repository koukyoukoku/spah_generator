import 'dart:async';

import 'package:flutter/material.dart';
import 'package:spah_generator/services/esp32_service.dart';
import 'package:spah_generator/components/SmoothPress.dart';

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
  List<String> _foundDevices = [];
  Map<String, dynamic> _deviceData = {};

  late StreamSubscription<String> _statusSubscription;
  late StreamSubscription<bool> _scanningSubscription;
  late StreamSubscription<bool> _connectedSubscription;
  late StreamSubscription<List<String>> _devicesSubscription;
  late StreamSubscription<Map<String, dynamic>> _deviceDataSubscription;
  late StreamSubscription<bool> _provisioningSubscription;

  @override
  void initState() {
    super.initState();
    
    _wifiName = widget.esp32Service.wifiName;
    _isConnected = widget.esp32Service.isConnected;
    _status = widget.esp32Service.lastStatus;
    _ssidController.text = _wifiName;
    
    _setupStreamListeners();
  }

  void _setupStreamListeners() {
    _statusSubscription = widget.esp32Service.statusStream.listen((status) {
      print('📱 Manager - Status: $status');
      if (mounted) {
        setState(() {
          _status = status;
        });
      }
    });

    _scanningSubscription = widget.esp32Service.scanningStream.listen((scanning) {
      print('📱 Manager - Scanning: $scanning');
      if (mounted) {
        setState(() {
          _isScanning = scanning;
        });
      }
    });

    _connectedSubscription = widget.esp32Service.connectedStream.listen((connected) {
      print('📱 Manager - Connected: $connected');
      if (mounted) {
        setState(() {
          _isConnected = connected;
        });
      }
    });

    _devicesSubscription = widget.esp32Service.devicesStream.listen((devices) {
      print('📱 Manager - Devices: $devices');
      if (mounted) {
        setState(() {
          _foundDevices = devices;
        });
      }
    });

    _deviceDataSubscription = widget.esp32Service.deviceDataStream.listen((data) {
      print('📱 Manager - Device Data: $data');
      if (mounted) {
        setState(() {
          _deviceData = data;
        });
      }
    });

    _provisioningSubscription = widget.esp32Service.provisioningStream.listen((provisioning) {
      print('📱 Manager - Provisioning: $provisioning');
      if (mounted) {
        setState(() {
          _isProvisioning = provisioning;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF9F5E8),
      appBar: AppBar(
        backgroundColor: Color(0xFFFE6D73),
        title: Text('Pengaturan ESP32'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              _buildStatusCard(),
              SizedBox(height: 16),
              if (_deviceData.isNotEmpty) _buildDeviceInfoCard(),
              _buildDiscoveryCard(),
              SizedBox(height: 16),
              _buildWiFiConfigCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    bool isActuallyConnected = widget.esp32Service.isConnected;
    String deviceIP = widget.esp32Service.deviceIP;
    
    print('🎯 Manager Screen - Connection Status:');
    print('   - _isConnected (UI): $_isConnected');
    print('   - isActuallyConnected (Service): $isActuallyConnected');
    print('   - deviceIP: $deviceIP');

    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isActuallyConnected ? Colors.green : Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isActuallyConnected ? Icons.check : Icons.warning,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isActuallyConnected ? '✅ TERHUBUNG' : '🔄 MENCOBA HUBUNG',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isActuallyConnected ? Colors.green : Colors.orange,
                        ),
                      ),
                      Text(
                        _status,
                        style: TextStyle(fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isActuallyConnected && deviceIP.isNotEmpty) ...[
              SizedBox(height: 8),
              Divider(),
              Row(
                children: [
                  Icon(Icons.computer, size: 16, color: Colors.green),
                  SizedBox(width: 8),
                  Text('IP: $deviceIP'),
                  Spacer(),
                  Icon(Icons.wifi, size: 16, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('${widget.esp32Service.wifiName}'),
                ],
              ),
              if (_deviceData['rssi'] != null) ...[
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.signal_cellular_alt, size: 14, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      'Sinyal: ${_deviceData['rssi']} dBm',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Spacer(),
                    Icon(Icons.timer, size: 14, color: Colors.grey),
                    SizedBox(width: 4),
                    if (_deviceData['uptime'] != null)
                      Text(
                        'Uptime: ${_formatUptime(_deviceData['uptime'])}',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                  ],
                ),
              ],
            ] else if (!isActuallyConnected && _foundDevices.isNotEmpty) ...[
              SizedBox(height: 8),
              Divider(),
              Text(
                '📱 ${_foundDevices.length} perangkat ditemukan',
                style: TextStyle(fontSize: 12, color: Colors.orange),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceInfoCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '📊 Info ESP32',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                if (widget.esp32Service.isConnected)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'ONLINE',
                      style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  )
                else
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'OFFLINE',
                      style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 8),
            if (_deviceData['status'] != null)
              _buildInfoRow('Status', _deviceData['status']),
            if (_deviceData['rssi'] != null)
              _buildInfoRow('Sinyal WiFi', '${_deviceData['rssi']} dBm'),
            if (_deviceData['ssid'] != null)
              _buildInfoRow('WiFi Terhubung', _deviceData['ssid']),
            if (_deviceData['uptime'] != null)
              _buildInfoRow('Uptime', '${_formatUptime(_deviceData['uptime'])}'),
            if (_deviceData['free_heap'] != null)
              _buildInfoRow('Memory', '${_formatBytes(_deviceData['free_heap'])}'),
          ],
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
        return '${hours}j ${minutes}m ${secs}d';
      } else if (minutes > 0) {
        return '${minutes}m ${secs}d';
      } else {
        return '${secs}d';
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildDiscoveryCard() {
    bool isActuallyConnected = widget.esp32Service.isConnected;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🔍 Kontrol Pencarian',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isScanning
                        ? widget.esp32Service.stopDiscovery
                        : widget.esp32Service.startDiscovery,
                    icon: Icon(_isScanning ? Icons.stop : Icons.search),
                    label: Text(
                      _isScanning ? 'BERHENTI MENCARI' : 'MULAI MENCARI',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isScanning
                          ? Colors.orange
                          : Color(0xFF4ECDC4),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            if (_foundDevices.isNotEmpty) ...[
              SizedBox(height: 12),
              Row(
                children: [
                  Text('Perangkat Ditemukan:'),
                  Spacer(),
                  Text(
                    '${_foundDevices.length} device(s)',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _foundDevices.map((ip) {
                  bool isCurrent = widget.esp32Service.deviceIP == ip;
                  return Chip(
                    label: Text(
                      ip,
                      style: TextStyle(
                        color: isCurrent ? Colors.white : Colors.black,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    backgroundColor: isCurrent ? Colors.green : Colors.grey[300],
                    deleteIcon: Icon(
                      isCurrent ? Icons.check : Icons.link,
                      color: isCurrent ? Colors.white : Colors.grey[600],
                      size: 18,
                    ),
                    onDeleted: () {
                      if (!isCurrent) {
                        widget.esp32Service.connectToDevice(ip);
                      }
                    },
                  );
                }).toList(),
              ),
            ],
            if (isActuallyConnected) ...[
              SizedBox(height: 12),
              Divider(),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        widget.esp32Service.requestDeviceStatus();
                      },
                      icon: Icon(Icons.refresh, size: 18),
                      label: Text('REFRESH STATUS'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        widget.esp32Service.pingDevice();
                      },
                      icon: Icon(Icons.network_check, size: 18),
                      label: Text('TEST PING'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWiFiConfigCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📡 Konfigurasi WiFi ESP32',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              'Kirim kredensial WiFi ke ESP32 untuk koneksi pertama',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _ssidController,
              decoration: InputDecoration(
                labelText: 'Nama WiFi (SSID)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.wifi),
                hintText: 'Masukkan nama WiFi',
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password WiFi',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
                hintText: 'Masukkan password WiFi',
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isProvisioning ? null : _provisionESP32,
              icon: _isProvisioning 
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(Icons.send),
              label: Text(_isProvisioning ? 'MENGIRIM...' : 'KIRIM KE ESP32'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFE6D73),
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
              ),
            ),
            if (_isProvisioning) ...[
              SizedBox(height: 12),
              LinearProgressIndicator(),
              SizedBox(height: 8),
              Text(
                'Mengirim kredensial WiFi ke ESP32...\nTunggu hingga proses selesai.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
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
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Perhatian'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('OK'),
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
    
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}