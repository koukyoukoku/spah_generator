import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Eksplorasi/components/SmoothPress.dart';
import 'package:Eksplorasi/models/languages/index.dart'; 

class AppSettingsScreen extends StatefulWidget {
  @override
  _AppSettingsScreenState createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _animationsEnabled = true;
  double _volumeLevel = 0.8;
  String _selectedLanguage = 'id';

  final Map<String, String> _languages = {
    'id': 'Indonesia',
    'en': 'English'
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initializeLanguage();
  }

  void _initializeLanguage() async {
    await AppLocalizations.init();
    if (mounted) {
      setState(() {
        _selectedLanguage = AppLocalizations.currentLocale;
      });
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      _animationsEnabled = prefs.getBool('animations_enabled') ?? true;
      _volumeLevel = prefs.getDouble('volume_level') ?? 0.8;
    });
  }

  Future<void> _saveSoundEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', value);
  }

  Future<void> _saveVibrationEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibration_enabled', value);
  }

  Future<void> _saveAnimationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('animations_enabled', value);
  }

  Future<void> _saveVolumeLevel(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('volume_level', value);
  }

  Future<void> _saveLanguage(String value) async {
    await AppLocalizations.setLocale(value);
    if (mounted) {
      setState(() {
        _selectedLanguage = value;
      });
    }
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
                          AppLocalizations.get('parent_control.settings'),
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
                                _saveSoundEnabled(value);
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
                                        _saveVolumeLevel(value);
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
                                _saveVibrationEnabled(value);
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
                                _saveAnimationsEnabled(value);
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
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
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
                                icon: Icon(
                                  Icons.arrow_drop_down_rounded,
                                  color: Color(0xFFA5D8FF),
                                ),
                                underline: SizedBox(),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF2D5A7E),
                                  fontFamily: 'ComicNeue',
                                ),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    _saveLanguage(newValue);
                                  }
                                },
                                items: _languages.entries.map<DropdownMenuItem<String>>(
                                  (MapEntry<String, String> entry) {
                                    return DropdownMenuItem<String>(
                                      value: entry.key,
                                      child: Row(
                                        children: [
                                          Text(
                                            entry.key == 'id' ? '🇮🇩' : '🇺🇸',
                                            style: TextStyle(fontSize: 16),
                                          ),
                                          SizedBox(width: 8),
                                          Text(entry.value),
                                        ],
                                      ),
                                    );
                                  },
                                ).toList(),
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

  Widget _buildSettingsCard({
    required String title,
    required List<Widget> children,
  }) {
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
        border: Border.all(color: Color(0xFFA5D8FF).withOpacity(0.3), width: 2),
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

  Widget _buildSettingSwitch(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Color(0xFFA5D8FF).withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Color(0xFFA5D8FF), size: 24),
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

  void _resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      _soundEnabled = true;
      _vibrationEnabled = true;
      _animationsEnabled = true;
      _volumeLevel = 0.8;
      _selectedLanguage = 'id';
    });

    await prefs.setBool('sound_enabled', true);
    await prefs.setBool('vibration_enabled', true);
    await prefs.setBool('animations_enabled', true);
    await prefs.setDouble('volume_level', 0.8);
    await AppLocalizations.setLocale('id');

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}