import 'package:flutter/material.dart';
import 'nfc_screen.dart';
import 'password_screen.dart';
import 'parent_control_screen.dart';
import 'parent_control/esp32_manager_screen.dart';
import 'package:spah_generator/services/esp32_service.dart';
import 'package:spah_generator/components/SmoothPress.dart';

class MenuUtama extends StatefulWidget {
  final ESP32Service esp32Service;

  const MenuUtama({Key? key, required this.esp32Service}) : super(key: key);

  @override
  _MenuUtamaState createState() => _MenuUtamaState();
}

class _MenuUtamaState extends State<MenuUtama> {
  bool _isConnectedToESP32 = false;
  String _connectionStatus = 'Mencari perangkat...';
  Map<String, dynamic> _deviceData = {};

  @override
  void initState() {
    super.initState();
    _setupConnectionListener();
  }

  void _setupConnectionListener() {
    widget.esp32Service.connectedStream.listen((connected) {
      print('🔌 Connection state changed: $connected');
      if (mounted) {
        setState(() {
          _isConnectedToESP32 =
              connected;
        });
      }
    });

    widget.esp32Service.statusStream.listen((status) {
      print('🔔 Status update: $status');
      if (mounted) {
        setState(() {
          _connectionStatus = status;
        });
      }
    });

    widget.esp32Service.devicesStream.listen((devices) {
      print('📱 Devices found: $devices');
    });

    widget.esp32Service.deviceDataStream.listen((data) {
      if (mounted) {
        setState(() {
          _deviceData = data;
        });
      }
    });
  }

  void _openParentControl(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PasswordScreen(
          onSuccess: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ParentControlScreen(esp32Service: widget.esp32Service),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openESP32Manager(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ESP32ManagerScreen(esp32Service: widget.esp32Service),
      ),
    );
  }

  void _startGame(BuildContext context) {
    if (_isConnectedToESP32) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => NfcScreen()),
      );
    } else {
      _showConnectionError(context);
    }
  }

  void _startQuiz(BuildContext context) {
    if (_isConnectedToESP32) {
      print('Tombol KUIZ ditekan');
    } else {
      _showConnectionError(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF9F5E8),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(15.0),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _isConnectedToESP32
                              ? Colors.green[50]
                              : Colors.orange[50],
                          borderRadius: BorderRadius.circular(
                            15,
                          ), 
                          border: Border.all(
                            color: _isConnectedToESP32
                                ? Colors.green
                                : Colors.orange,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize
                              .min,
                          children: [
                            Icon(
                              _isConnectedToESP32 ? Icons.wifi : Icons.wifi_off,
                              color: _isConnectedToESP32
                                  ? Colors.green
                                  : Colors.orange,
                              size: 20,
                            ),
                            SizedBox(width: 4),
                            Text(
                              _isConnectedToESP32
                                  ? "Connected"
                                  : "Searching", 
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _isConnectedToESP32
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: Color(0xFFFED766),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Color(0xFF4ECDC4),
                            width: 5,
                          ),
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
                            Icon(
                              _isConnectedToESP32
                                  ? Icons.check_circle
                                  : Icons.warning,
                              size: 70,
                              color: _isConnectedToESP32
                                  ? Colors.green
                                  : Color.fromARGB(255, 240, 16, 16),
                            ),
                            if (!_isConnectedToESP32)
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.orange,
                                ),
                                strokeWidth: 3,
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Eksplorasi',
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4ECDC4),
                          shadows: [
                            Shadow(
                              blurRadius: 2,
                              color: Colors.black12,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Belajar Seru untuk SCP-173',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFFFE6D73),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SmoothPressButton(
                          onPressed: () => _startGame(context),
                          child: TombolBesar(
                            warna: _isConnectedToESP32
                                ? Color(0xFF4ECDC4)
                                : Colors.grey,
                            ikon: Icons.play_arrow_rounded,
                            teks: 'MULAI',
                            emoji: '🎮',
                            onTap: () {},
                          ),
                        ),
                        SizedBox(height: 30),
                        SmoothPressButton(
                          onPressed: () => _startQuiz(context),
                          child: TombolBesar(
                            warna: _isConnectedToESP32
                                ? Color(0xFFFE6D73)
                                : Colors.grey,
                            ikon: Icons.quiz_rounded,
                            teks: 'KUIZ',
                            emoji: '❓',
                            onTap: () {},
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 60),
              ],
            ),

            Positioned(
              top: 10,
              left: 10,
              child: SmoothPressButton(
                onPressed: () => _openParentControl(context),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(color: Colors.transparent),
                  child: Icon(
                    Icons.family_restroom,
                    color: Color(0xFF4ECDC4),
                    size: 32,
                  ),
                ),
              ),
            ),

            Positioned(
              top: 18,
              right: 10,
              child: SmoothPressButton(
                onPressed: () => _openESP32Manager(context),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(color: Colors.transparent),
                  child: Stack(
                    children: [
                      Icon(Icons.settings, color: Color(0xFFFE6D73), size: 32),
                      if (!_isConnectedToESP32)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
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

  void _showConnectionError(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.orange),
            SizedBox(width: 8),
            Text('Perangkat Tidak Terhubung'),
          ],
        ),
        content: Text(
          'Harap hubungkan ke perangkat ESP32 terlebih dahulu melalui menu Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('TUTUP'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _openESP32Manager(context);
            },
            child: Text('SETTINGS'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class TombolBesar extends StatelessWidget {
  final Color warna;
  final IconData ikon;
  final String teks;
  final String emoji;
  final VoidCallback onTap;

  const TombolBesar({
    required this.warna,
    required this.ikon,
    required this.teks,
    required this.emoji,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: warna,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(emoji, style: TextStyle(fontSize: 35)),
                ),
              ),
              SizedBox(width: 20),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(ikon, size: 50, color: Colors.white),
                  SizedBox(height: 5),
                  Text(
                    teks,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 3,
                          color: Colors.black26,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
