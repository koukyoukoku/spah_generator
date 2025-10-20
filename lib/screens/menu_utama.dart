import 'package:flutter/material.dart';
import 'package:spah_generator/screens/quiz/quiz_main_screen.dart';
import 'nfc_screen.dart';
import 'password_screen.dart';
import 'parent_control_screen.dart';
import 'parent_control/esp32_manager_screen.dart';
import 'package:spah_generator/services/esp32_service.dart';
import 'package:spah_generator/components/SmoothPress.dart';
import 'package:audioplayers/audioplayers.dart';

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

  final AudioPlayer _audioPlayer =
      AudioPlayer();

  @override
  void initState() {
    super.initState();
    _setupConnectionListener();
  }

  void _setupConnectionListener() {
    widget.esp32Service.connectedStream.listen((connected) {
      if (mounted) {
        setState(() {
          _isConnectedToESP32 = connected;
        });
      }
    });

    widget.esp32Service.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          _connectionStatus = status;
        });
      }
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

  Future<void> _startGame(BuildContext context) async {
    try {
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play(AssetSource('audio/BubbleClick.mp3'));
    } catch (e, st) {
      debugPrint('Gagal mainkan audio: $e\n$st');
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NfcScreen()),
    );
  }

  Future<void> _startQuiz(BuildContext context) async {
    try {
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play(AssetSource('audio/BubbleClick.mp3'));
    } catch (e, st) {
      debugPrint('Gagal mainkan audio: $e\n$st');
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QuizMainScreen()),
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

            Column(
              children: [
                Container(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _isConnectedToESP32
                                    ? Colors.green
                                    : Colors.orange,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              _isConnectedToESP32 ? "Terhubung" : "Mencari...",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF333333),
                                fontFamily: 'ComicNeue',
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 30),

                      Text(
                        'Eksplorasi',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2D5A7E),
                          fontFamily: 'ComicNeue',
                          shadows: [
                            Shadow(
                              blurRadius: 4,
                              color: Colors.black12,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 8),

                      Text(
                        'Belajar Seru Untuk SCP-173',
                        style: TextStyle(
                          fontSize: 20,
                          color: Color(0xFF666666),
                          fontFamily: 'ComicNeue',
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SmoothPressButton(
                          onPressed: () => _startGame(context),
                          child: _MainActionButton(
                            color: Color(0xFF4ECDC4),
                            icon: Icons.play_arrow_rounded,
                            text: 'MULAI',
                            emoji: '🚀',
                            isEnabled: true,
                          ),
                        ),

                        SizedBox(height: 25),

                        SmoothPressButton(
                          onPressed: () => _startQuiz(context),
                          child: _MainActionButton(
                            color: Color(0xFFFE6D73),
                            icon: Icons.quiz_rounded,
                            text: 'KUIS',
                            emoji: '🎯',
                            isEnabled: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Container(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SmoothPressButton(
                        onPressed: () async {
                          try {
                            await _audioPlayer.setVolume(1.0);
                            await _audioPlayer.play(
                              AssetSource('audio/PopClick.mp3'),
                            );
                            _openParentControl(context);
                          } catch (e, st) {
                            _openParentControl(context);
                            debugPrint('Gagal mainkan audio: $e\n$st');
                          }
                        },
                        child: _BottomActionButton(
                          icon: Icons.family_restroom,
                          text: 'Orang Tua',
                          color: Color(0xFF4ECDC4),
                        ),
                      ),

                      SmoothPressButton(
                        onPressed: () async {
                          try {
                            await _audioPlayer.setVolume(1.0);
                            await _audioPlayer.play(
                              AssetSource('audio/PopClick.mp3'),
                            );
                          } catch (e, st) {
                            _openParentControl(context);
                            debugPrint('Gagal mainkan audio: $e\n$st');
                          }
                          _openESP32Manager(context);
                        },
                        child: Stack(
                          children: [
                            _BottomActionButton(
                              icon: Icons.settings,
                              text: 'Pengaturan',
                              color: Color(0xFFFE6D73),
                            ),
                            if (!_isConnectedToESP32)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text(
              'Perangkat Tidak Terhubung',
              style: TextStyle(
                fontFamily: 'ComicNeue',
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
        content: Text(
          'Harap hubungkan ke perangkat ESP32 terlebih dahulu melalui menu Pengaturan.',
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
              'TUTUP',
              style: TextStyle(
                fontFamily: 'ComicNeue',
                fontWeight: FontWeight.w600,
                color: Color(0xFF666666),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _openESP32Manager(context);
            },
            child: Text(
              'PENGATURAN',
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
    _audioPlayer.dispose();
    super.dispose();
  }
}

class _MainActionButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;
  final String emoji;
  final bool isEnabled;

  const _MainActionButton({
    required this.color,
    required this.icon,
    required this.text,
    required this.emoji,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 130,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
        gradient: isEnabled
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, Color.lerp(color, Colors.black, 0.1)!],
              )
            : null,
      ),
      child: Stack(
        children: [
          Positioned(
            top: 10,
            right: 20,
            child: Opacity(
              opacity: 0.2,
              child: Text(emoji, style: TextStyle(fontSize: 60)),
            ),
          ),

          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                margin: EdgeInsets.only(left: 20),
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
                child: Center(
                  child: Text(emoji, style: TextStyle(fontSize: 35)),
                ),
              ),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 50, color: Colors.white),
                    SizedBox(height: 8),
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: 'ComicNeue',
                        shadows: [
                          Shadow(
                            blurRadius: 4,
                            color: Colors.black26,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BottomActionButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _BottomActionButton({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
              fontFamily: 'ComicNeue',
            ),
          ),
        ],
      ),
    );
  }
}
