import 'package:flutter/material.dart';
import 'nfc_screen.dart';
import 'password_screen.dart';
import 'parent_control_screen.dart';
import 'package:spah_generator/components/SmoothPress.dart';

class MenuUtama extends StatelessWidget {
  void _openParentControl(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PasswordScreen(
          onSuccess: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ParentControlScreen()),
            );
          },
        ),
      ),
    );
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
                  padding: EdgeInsets.all(30.0),
                  child: Column(
                    children: [
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: Color(0xFFFED766),
                          shape: BoxShape.circle,
                          border: Border.all(color: Color(0xFF4ECDC4), width: 5),
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
                            Icon(Icons.warning, size: 70, color: Color.fromARGB(255, 240, 16, 16)),
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
                        style: TextStyle(fontSize: 18, color: Color(0xFFFE6D73)),
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
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => NfcScreen()),
                            );
                          },
                          child: TombolBesar(
                            warna: Color(0xFF4ECDC4),
                            ikon: Icons.play_arrow_rounded,
                            teks: 'MULAI',
                            emoji: '🎮',
                            onTap: () {},
                          ),
                        ),

                        SizedBox(height: 30),
                        SmoothPressButton(
                          onPressed: () {
                            print('Tombol KUIZ ditekan');
                          },
                          child: TombolBesar(
                            warna: Color(0xFFFE6D73),
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
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: Icon(
                    Icons.family_restroom,
                    color: Color(0xFF4ECDC4),
                    size: 32,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
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