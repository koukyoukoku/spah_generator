import 'package:flutter/material.dart';
import 'package:Eksplorasi/screens/parent_control/esp32_manager_screen.dart';
import 'package:Eksplorasi/models/parent_menu_item.dart';
import 'package:Eksplorasi/components/SmoothPress.dart';
import 'package:Eksplorasi/services/esp32_service.dart';
import 'parent_control/change_pin_screen.dart';
import 'parent_control/sync_data_screen.dart';
import 'parent_control/usage_guide_screen.dart';
import 'parent_control/app_settings_screen.dart';
import 'parent_control/data_management_screen.dart';
import 'package:Eksplorasi/models/languages/index.dart';

class ParentControlScreen extends StatefulWidget {
  final ESP32Service esp32Service;

  const ParentControlScreen({Key? key, required this.esp32Service})
    : super(key: key);

  @override
  _ParentControlScreenState createState() => _ParentControlScreenState();
}

class _ParentControlScreenState extends State<ParentControlScreen> {
  @override
  void initState() {
    super.initState();
    _initializeLanguage();
  }

  void _initializeLanguage() async {
    await AppLocalizations.init();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _toggleLanguage() async {
    await AppLocalizations.toggleLanguage();
    if (mounted) {
      setState(() {});
    }
  }

  List<ParentMenuItem> get menuItems => [
    ParentMenuItem(
      title: AppLocalizations.get('parent_control.change_pin'),
      icon: Icons.lock,
      color: Color(0xFF4ECDC4),
      screenBuilder: (context) => ChangePinScreen(),
    ),
    ParentMenuItem(
      title: AppLocalizations.get('parent_control.sync'),
      icon: Icons.cloud_sync,
      color: Color(0xFFFE6D73),
      screenBuilder: (context) => SyncDataScreen(),
    ),
    ParentMenuItem(
      title: AppLocalizations.get('parent_control.guide'),
      icon: Icons.menu_book,
      color: Color(0xFFFED766),
      screenBuilder: (context) => UsageGuideScreen(),
    ),
    ParentMenuItem(
      title: AppLocalizations.get('parent_control.esp32_setup'),
      icon: Icons.developer_board,
      color: Color(0xFFFFB347),
      screenBuilder: (context) =>
          ESP32ManagerScreen(esp32Service: widget.esp32Service),
    ),
  ];

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

            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              SmoothPressButton(
                                onPressed: () => _toggleLanguage(),
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 6,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        AppLocalizations.currentLocale == 'id' ? '🇮🇩' : '🇺🇸',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        AppLocalizations.currentLocale == 'id' ? 'ID' : 'EN',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF2D5A7E),
                                          fontFamily: 'ComicNeue',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),

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
                            AppLocalizations.get('parent_control.title'),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2D5A7E),
                              fontFamily: 'ComicNeue',
                            ),
                          ),
                          SizedBox(height: 8),

                          Text(
                            AppLocalizations.get('parent_control.subtitle'),
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF666666),
                              fontFamily: 'ComicNeue',
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 30),
                          Container(
                            constraints: BoxConstraints(maxWidth: 600),
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 1.1,
                                  ),
                              itemCount: menuItems.length,
                              itemBuilder: (context, index) {
                                return _buildMenuCard(
                                  menuItems[index],
                                  context,
                                );
                              },
                            ),
                          ),

                          SizedBox(height: 30),
                          Container(
                            constraints: BoxConstraints(maxWidth: 600),
                            width: double.infinity,
                            padding: EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  AppLocalizations.get('parent_control.about_app'),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2D5A7E),
                                    fontFamily: 'ComicNeue',
                                  ),
                                ),
                                SizedBox(height: 12),

                                Text(
                                  AppLocalizations.get('parent_control.about_description'),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF666666),
                                    fontFamily: 'ComicNeue',
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 12),

                                Text(
                                  AppLocalizations.get('parent_control.made_with_love'),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color.fromARGB(255, 236, 105, 105),
                                    fontFamily: 'ComicNeue',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: SmoothPressButton(
                onPressed: () => Navigator.pop(context),
                child: Container(
                  width: 50,
                  height: 50,
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

  Widget _buildMenuCard(ParentMenuItem item, BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: item.screenBuilder));
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    item.color.withOpacity(0.15),
                    item.color.withOpacity(0.05),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: item.color.withOpacity(0.2),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: item.color.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(item.icon, color: item.color, size: 28),
                  ),

                  SizedBox(height: 12),
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2D5A7E),
                      fontFamily: 'ComicNeue',
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 