import 'package:flutter/material.dart';

void main() {
  runApp(ExplorasiApp());
}

class ExplorasiApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eksplorasi',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'ComicNeue',
      ),
      home: MenuUtama(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MenuUtama extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF9F5E8),
      body: SafeArea(
        child: Column(
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
                          Icons.eco,
                          size: 70,
                          color: Color(0xFF4ECDC4),
                        ),
                        Positioned(
                          bottom: 25,
                          right: 25,
                          child: Text(
                            '🐰',
                            style: TextStyle(fontSize: 30),
                          ),
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
                    'Belajar Seru untuk Anak Hebat',
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
                    _TombolBesar(
                      warna: Color(0xFF4ECDC4),
                      ikon: Icons.play_arrow_rounded,
                      teks: 'MULAI',
                      emoji: '🎮',
                      onTap: () {
                        print('Tombol MULAI ditekan');
                      },
                    ),
                    
                    SizedBox(height: 30),
                    
                    _TombolBesar(
                      warna: Color(0xFFFE6D73),
                      ikon: Icons.quiz_rounded,
                      teks: 'KUIZ',
                      emoji: '❓',
                      onTap: () {
                        print('Tombol KUIZ ditekan');
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            Padding(
              padding: EdgeInsets.all(25.0),
              child: Container(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Color(0xFF4ECDC4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: BorderSide(
                        color: Color(0xFF4ECDC4),
                        width: 3,
                      ),
                    ),
                    elevation: 5,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.family_restroom,
                        color: Color(0xFF4ECDC4),
                        size: 28,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Bantuan Orang Tua',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF4ECDC4),
                          fontWeight: FontWeight.bold,
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
}

class _TombolBesar extends StatelessWidget {
  final Color warna;
  final IconData ikon;
  final String teks;
  final String emoji;
  final VoidCallback onTap;

  const _TombolBesar({
    required this.warna,
    required this.ikon,
    required this.teks,
    required this.emoji,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            color: warna,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: Colors.white,
              width: 4,
            ),
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
              Positioned(
                top: 10,
                right: 10,
                child: Text(
                  '🌿',
                  style: TextStyle(fontSize: 40),
                ),
              ),
              
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
                      child: Text(
                        emoji,
                        style: TextStyle(fontSize: 35),
                      ),
                    ),
                  ),
                  
                  SizedBox(width: 20),
                  
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        ikon,
                        size: 50,
                        color: Colors.white,
                      ),
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
        ),
      ),
    );
  }
}