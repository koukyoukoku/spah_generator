import 'package:flutter/material.dart';
import 'package:spah_generator/components/SmoothPress.dart';

class AppSettingsScreen extends StatefulWidget {
  @override
  _AppSettingsScreenState createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _animationsEnabled = true;
  double _volumeLevel = 0.8;
  String _selectedLanguage = 'Indonesia';

  final List<String> _languages = ['Indonesia', 'English', '日本語'];

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
                  color: Color(0xFFA5D8FF).withOpacity(0.1),
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
                  color: Color(0xFF4ECDC4).withOpacity(0.1),
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
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
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
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: Color(0xFFA5D8FF),
                              width: 4,
                            ),
                          ),
                          child: Icon(
                            Icons.settings_rounded,
                            size: 60,
                            color: Color(0xFFA5D8FF),
                          ),
                        ),

                        SizedBox(height: 30),
                        Text(
                          'Pengaturan Aplikasi',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2D5A7E),
                            fontFamily: 'ComicNeue',
                          ),
                        ),

                        SizedBox(height: 8),

                        Text(
                          'Sesuaikan pengalaman menggunakan aplikasi',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF666666),
                            fontFamily: 'ComicNeue',
                          ),
                          textAlign: TextAlign.center,
                        ),

                        SizedBox(height: 40),
                        _buildSettingsCard(
                          title: 'Pengaturan Suara',
                          children: [
                            _buildSettingSwitch(
                              'Suara',
                              'Aktifkan efek suara',
                              _soundEnabled,
                              (value) {
                                setState(() {
                                  _soundEnabled = value;
                                });
                              },
                              Icons.volume_up_rounded,
                            ),
                            if (_soundEnabled) ...[
                              SizedBox(height: 20),
                              Padding(
                                padding: EdgeInsets.only(left: 40),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Volume: ${(_volumeLevel * 100).toInt()}%',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF2D5A7E),
                                        fontFamily: 'ComicNeue',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    Slider(
                                      value: _volumeLevel,
                                      onChanged: (value) {
                                        setState(() {
                                          _volumeLevel = value;
                                        });
                                      },
                                      activeColor: Color(0xFFA5D8FF),
                                      inactiveColor: Colors.grey[300],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),

                        SizedBox(height: 20),
                        _buildSettingsCard(
                          title: 'Pengaturan Lainnya',
                          children: [
                            _buildSettingSwitch(
                              'Getar',
                              'Aktifkan feedback getar',
                              _vibrationEnabled,
                              (value) {
                                setState(() {
                                  _vibrationEnabled = value;
                                });
                              },
                              Icons.vibration_rounded,
                            ),
                            SizedBox(height: 20),
                            _buildSettingSwitch(
                              'Animasi',
                              'Aktifkan animasi aplikasi',
                              _animationsEnabled,
                              (value) {
                                setState(() {
                                  _animationsEnabled = value;
                                });
                              },
                              Icons.animation_rounded,
                            ),
                          ],
                        ),

                        SizedBox(height: 20),
                        _buildSettingsCard(
                          title: 'Bahasa',
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Color(0xFFA5D8FF).withOpacity(0.5),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: DropdownButton<String>(
                                value: _selectedLanguage,
                                isExpanded: true,
                                icon: Icon(Icons.arrow_drop_down_rounded, color: Color(0xFFA5D8FF)),
                                underline: SizedBox(),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF2D5A7E),
                                  fontFamily: 'ComicNeue',
                                ),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedLanguage = newValue!;
                                  });
                                },
                                items: _languages.map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 30),
                        SmoothPressButton(
                          onPressed: () {
                            _resetToDefaults();
                          },
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Color(0xFFA5D8FF),
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
                            child: Center(
                              child: Text(
                                'RESET KE PENGATURAN DEFAULT',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF2D5A7E),
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'ComicNeue',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildSettingsCard({required String title, required List<Widget> children}) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: Color(0xFFA5D8FF).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D5A7E),
              fontFamily: 'ComicNeue',
            ),
          ),
          SizedBox(height: 15),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingSwitch(String title, String subtitle, bool value, Function(bool) onChanged, IconData icon) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Color(0xFFA5D8FF).withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Color(0xFFA5D8FF),
            size: 24,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D5A7E),
                  fontFamily: 'ComicNeue',
                ),
              ),
              SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF666666),
                  fontFamily: 'ComicNeue',
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Color(0xFFA5D8FF),
          activeTrackColor: Color(0xFFA5D8FF).withOpacity(0.5),
        ),
      ],
    );
  }

  void _resetToDefaults() {
    setState(() {
      _soundEnabled = true;
      _vibrationEnabled = true;
      _animationsEnabled = true;
      _volumeLevel = 0.8;
      _selectedLanguage = 'Indonesia';
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Pengaturan telah direset ke default',
          style: TextStyle(
            fontFamily: 'ComicNeue',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Color(0xFF4ECDC4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}