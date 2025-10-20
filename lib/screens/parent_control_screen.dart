import 'package:flutter/material.dart';
import 'package:spah_generator/screens/parent_control/esp32_manager_screen.dart';
import 'package:spah_generator/models/parent_menu_item.dart';
import 'package:spah_generator/components/SmoothPress.dart';
import 'package:spah_generator/services/esp32_service.dart';
import 'parent_control/change_pin_screen.dart';
import 'parent_control/sync_data_screen.dart';
import 'parent_control/usage_guide_screen.dart';
import 'parent_control/app_settings_screen.dart';
import 'parent_control/data_management_screen.dart';

class ParentControlScreen extends StatelessWidget {
  final ESP32Service esp32Service;

  const ParentControlScreen({Key? key, required this.esp32Service}) : super(key: key);

  List<ParentMenuItem> get menuItems => [
    ParentMenuItem(
      title: 'Ubah PIN',
      description: 'Ganti PIN akses orang tua',
      icon: Icons.lock,
      color: Color(0xFF4ECDC4),
      screenBuilder: (context) => ChangePinScreen(),
    ),
    ParentMenuItem(
      title: 'Sinkronisasi',
      description: 'Sync data dengan cloud',
      icon: Icons.cloud_sync,
      color: Color(0xFFFE6D73),
      screenBuilder: (context) => SyncDataScreen(),
    ),
    ParentMenuItem(
      title: 'Panduan',
      description: 'Cara menggunakan aplikasi',
      icon: Icons.menu_book,
      color: Color(0xFFFED766),
      screenBuilder: (context) => UsageGuideScreen(),
    ),
    ParentMenuItem(
      title: 'Pengaturan',
      description: 'Pengaturan aplikasi',
      icon: Icons.settings,
      color: Color(0xFFA5D8FF),
      screenBuilder: (context) => AppSettingsScreen(),
    ),
    ParentMenuItem(
      title: 'Data Anak',
      description: 'Kelola data progres anak',
      icon: Icons.people,
      color: Color(0xFFC8A2C8),
      screenBuilder: (context) => DataManagementScreen(),
    ),
    ParentMenuItem(
      title: 'Setup ESP32',
      description: 'Setup koneksi ESP32',
      icon: Icons.developer_board,
      color: Color(0xFFFFB347),
      screenBuilder: (context) => ESP32ManagerScreen(esp32Service: esp32Service),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF9F5E8),
      appBar: AppBar(
        backgroundColor: Color(0xFF4ECDC4),
        title: Text(
          'Kontrol Orang Tua',
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
                    color: Color(0xFF4ECDC4),
                    width: 4,
                  ),
                ),
                child: Icon(
                  Icons.family_restroom,
                  size: 50,
                  color: Color(0xFF4ECDC4),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Pengaturan Orang Tua',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4ECDC4),
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Kelola pengaturan aplikasi untuk anak',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),

              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 1.0,
                ),
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  return _buildMenuCard(menuItems[index], context);
                },
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
                    children: [
                      Text(
                        'Tentang Aplikasi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4ECDC4),
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Aplikasi Eksplorasi dirancang khusus untuk Anomali SCP-173 khusus dengan antarmuka yang sederhana dan ramah.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Versi 1.0.0',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(ParentMenuItem item, BuildContext context) {
    return SmoothPressButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: item.screenBuilder),
        );
      },
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                item.color.withOpacity(0.1),
                item.color.withOpacity(0.05),
              ],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item.icon,
                    color: item.color,
                    size: 24,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: item.color,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4),
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}