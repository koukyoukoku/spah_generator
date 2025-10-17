import 'package:flutter/material.dart';
import 'package:spah_generator/components/SmoothPress.dart';

class ESP32ManagerScreen extends StatefulWidget {
  @override
  _ESP32ManagerScreenState createState() => _ESP32ManagerScreenState();
}

class _ESP32ManagerScreenState extends State<ESP32ManagerScreen> {
  bool _isConnecting = false;
  bool _isConnected = false;
  bool _isScanning = false;
  bool _isProvisioning = false;

  void _startConnection() async {
    setState(() {
      _isConnecting = true;
    });
    await Future.delayed(Duration(seconds: 2));

    setState(() {
      _isConnecting = false;
      _isConnected = true;
    });
  }

  void _startScanning() async {
    setState(() {
      _isScanning = true;
    });
    await Future.delayed(Duration(seconds: 3));

    setState(() {
      _isScanning = false;
    });
  }

  void _startProvisioning() async {
    setState(() {
      _isProvisioning = true;
    });
    await Future.delayed(Duration(seconds: 2));

    setState(() {
      _isProvisioning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF9F5E8),
      appBar: AppBar(
        backgroundColor: Color(0xFFFFB347),
        title: Text(
          'Scanner',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(25),
          child: Column(
            children: [
              // Header Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Color(0xFFFFB347),
                    width: 4,
                  ),
                ),
                child: Icon(
                  Icons.developer_board,
                  size: 60,
                  color: Color(0xFFFFB347),
                ),
              ),
              SizedBox(height: 30),
              
              // Title
              Text(
                'Scanner Setup',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFB347),
                ),
              ),
              SizedBox(height: 40),

              // Connection Status Card
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: EdgeInsets.all(25),
                  child: Column(
                    children: [
                      if (_isConnecting) ...[
                        CircularProgressIndicator(
                          color: Color(0xFFFFB347),
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Connecting to ESP32...',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ] else if (_isConnected) ...[
                        Icon(
                          Icons.bluetooth_connected,
                          color: Colors.green,
                          size: 60,
                        ),
                        SizedBox(height: 20),
                        Text(
                          'ESP32 Connected!',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Device ready for configuration',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ] else ...[
                        Icon(
                          Icons.bluetooth_disabled,
                          color: Colors.grey[400],
                          size: 60,
                        ),
                        SizedBox(height: 20),
                        Text(
                          'ESP32 Not Connected',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),

              // WiFi Networks Card
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: EdgeInsets.all(25),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Available Networks',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFFB347),
                            ),
                          ),
                          if (_isScanning)
                            CircularProgressIndicator(
                              color: Color(0xFFFFB347),
                              strokeWidth: 2,
                            )
                          else
                            IconButton(
                              onPressed: _startScanning,
                              icon: Icon(Icons.refresh),
                              color: Color(0xFFFFB347),
                            ),
                        ],
                      ),
                      SizedBox(height: 15),
                      
                      // Network List (Placeholder)
                      Container(
                        height: 150,
                        child: _isScanning
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      color: Color(0xFFFFB347),
                                    ),
                                    SizedBox(height: 10),
                                    Text('Scanning for networks...'),
                                  ],
                                ),
                              )
                            : ListView(
                                children: [
                                  _buildNetworkItem('Home WiFi', -45, true),
                                  _buildNetworkItem('Office Network', -55, false),
                                  _buildNetworkItem('Guest WiFi', -65, false),
                                  _buildNetworkItem('TP-Link_2G', -70, false),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 30),

              // Action Buttons
              if (!_isConnected && !_isConnecting)
                SmoothPressButton(
                  onPressed: _startConnection,
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Color(0xFFFFB347),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Text(
                        'Connect to Scanner!',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

              if (_isConnected && !_isProvisioning)
                SmoothPressButton(
                  onPressed: _startProvisioning,
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Text(
                        'PROVISION WIFI',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

              if (_isProvisioning)
                SmoothPressButton(
                  onPressed: () {},
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                          SizedBox(width: 15),
                          Text(
                            'PROVISIONING...',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Reset Button
              if (_isConnected)
                SmoothPressButton(
                  onPressed: () {
                    setState(() {
                      _isConnected = false;
                      _isProvisioning = false;
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Text(
                        'DISCONNECT',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkItem(String ssid, int rssi, bool isConnected) {
    return ListTile(
      leading: Icon(
        _getWifiIcon(rssi),
        color: isConnected ? Colors.green : Color(0xFFFE6D73),
      ),
      title: Text(
        ssid,
        style: TextStyle(
          fontWeight: isConnected ? FontWeight.bold : FontWeight.normal,
          color: isConnected ? Colors.green : Colors.black87,
        ),
      ),
      subtitle: Text('Signal: ${rssi.abs()} dBm'),
      trailing: isConnected
          ? Icon(Icons.check_circle, color: Colors.green)
          : Icon(Icons.radio_button_unchecked, color: Colors.grey),
      onTap: () {
        // Handle network selection
        print('Selected network: $ssid');
      },
    );
  }

  IconData _getWifiIcon(int rssi) {
    if (rssi > -50) return Icons.wifi;
    if (rssi > -60) return Icons.wifi;
    if (rssi > -70) return Icons.wifi;
    return Icons.wifi;
  }
}