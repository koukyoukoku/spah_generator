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
      backgroundColor: Color(0xFFF9F5E8),
      appBar: AppBar(
        backgroundColor: Color(0xFFA5D8FF),
        title: Text(
          'Pengaturan Aplikasi',
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
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Color(0xFFA5D8FF),
                    width: 4,
                  ),
                ),
                child: Icon(
                  Icons.settings,
                  size: 50,
                  color: Color(0xFFA5D8FF),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Pengaturan Aplikasi',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFA5D8FF),
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Sesuaikan pengalaman menggunakan aplikasi',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),

              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pengaturan Suara',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFA5D8FF),
                        ),
                      ),
                      SizedBox(height: 15),
                      _buildSettingSwitch(
                        'Suara',
                        'Aktifkan efek suara',
                        _soundEnabled,
                        (value) {
                          setState(() {
                            _soundEnabled = value;
                          });
                        },
                        Icons.volume_up,
                      ),
                      if (_soundEnabled) ...[
                        SizedBox(height: 15),
                        Padding(
                          padding: EdgeInsets.only(left: 40),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Volume: ${(_volumeLevel * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 8),
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
                ),
              ),
              SizedBox(height: 20),

              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pengaturan Lainnya',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFA5D8FF),
                        ),
                      ),
                      SizedBox(height: 15),
                      _buildSettingSwitch(
                        'Getar',
                        'Aktifkan feedback getar',
                        _vibrationEnabled,
                        (value) {
                          setState(() {
                            _vibrationEnabled = value;
                          });
                        },
                        Icons.vibration,
                      ),
                      SizedBox(height: 15),
                      _buildSettingSwitch(
                        'Animasi',
                        'Aktifkan animasi aplikasi',
                        _animationsEnabled,
                        (value) {
                          setState(() {
                            _animationsEnabled = value;
                          });
                        },
                        Icons.animation,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bahasa',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFA5D8FF),
                        ),
                      ),
                      SizedBox(height: 15),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: DropdownButton<String>(
                            value: _selectedLanguage,
                            isExpanded: true,
                            icon: Icon(Icons.arrow_drop_down, color: Color(0xFFA5D8FF)),
                            underline: SizedBox(),
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
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 30),

              SmoothPressButton(
                onPressed: () {
                  _resetToDefaults();
                },
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      'RESET KE PENGATURAN DEFAULT',
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

  Widget _buildSettingSwitch(String title, String subtitle, bool value, Function(bool) onChanged, IconData icon) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Color(0xFFA5D8FF).withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Color(0xFFA5D8FF),
            size: 20,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Color(0xFFA5D8FF),
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
        content: Text('Pengaturan telah direset ke default'),
        backgroundColor: Colors.green,
      ),
    );
  }
}