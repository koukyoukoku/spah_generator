import 'package:flutter/material.dart';
import 'package:spah_generator/components/SmoothPress.dart';

class UsageGuideScreen extends StatefulWidget {
  @override
  _UsageGuideScreenState createState() => _UsageGuideScreenState();
}

class _UsageGuideScreenState extends State<UsageGuideScreen> {
  final List<GuideItem> _guideItems = [
    GuideItem(
      title: 'Cara Menggunakan NFC',
      description: 'Tutorial penggunaan fitur NFC untuk eksplorasi benda',
      icon: Icons.nfc_rounded,
      color: Color(0xFF4ECDC4),
    ),
    GuideItem(
      title: 'Fitur Kuiz',
      description: 'Cara anak berinteraksi dengan kuis edukasi',
      icon: Icons.quiz_rounded,
      color: Color(0xFFFE6D73),
    ),
    GuideItem(
      title: 'Pengaturan Orang Tua',
      description: 'Cara mengakses dan menggunakan kontrol orang tua',
      icon: Icons.family_restroom_rounded,
      color: Color(0xFFFED766),
    ),
    GuideItem(
      title: 'Tips Belajar',
      description: 'Tips untuk mendampingi SPAH selama belajar',
      icon: Icons.lightbulb_rounded,
      color: Color(0xFFA5D8FF),
    ),
  ];

  int _expandedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE8F4F8),
      body: SafeArea(
        child: Stack(
          children: [
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
                              color: Color(0xFFFED766),
                              width: 4,
                            ),
                          ),
                          child: Icon(
                            Icons.menu_book_rounded,
                            size: 60,
                            color: Color(0xFFFED766),
                          ),
                        ),

                        SizedBox(height: 30),
                        Text(
                          'Panduan Penggunaan',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2D5A7E),
                            fontFamily: 'ComicNeue',
                          ),
                        ),

                        SizedBox(height: 8),

                        Text(
                          'Pelajari cara menggunakan aplikasi dengan optimal',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF666666),
                            fontFamily: 'ComicNeue',
                          ),
                          textAlign: TextAlign.center,
                        ),

                        SizedBox(height: 40),
                        ..._guideItems.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          return _buildGuideItem(item, index);
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: -50,
              right: -30,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Color(0xFFFED766).withOpacity(0.1),
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
          ],
        ),
      ),
    );
  }

  Widget _buildGuideItem(GuideItem item, int index) {
    bool isExpanded = _expandedIndex == index;

    return Container(
      margin: EdgeInsets.only(bottom: 20),
      child: SmoothPressButton(
        onPressed: () {
          setState(() {
            _expandedIndex = isExpanded ? -1 : index;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
            border: Border.all(color: item.color.withOpacity(0.3), width: 2),
          ),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: item.color.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item.icon, color: item.color, size: 24),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2D5A7E),
                              fontFamily: 'ComicNeue',
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            item.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF666666),
                              fontFamily: 'ComicNeue',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isExpanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: item.color,
                      size: 28,
                    ),
                  ],
                ),
                if (isExpanded) ...[
                  SizedBox(height: 16),
                  Divider(color: item.color.withOpacity(0.3), height: 1),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: item.color.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getGuideContent(item.title),
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2D5A7E),
                        height: 1.6,
                        fontFamily: 'ComicNeue',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getGuideContent(String title) {
    switch (title) {
      case 'Cara Menggunakan NFC':
        return '1. Tekan tombol "MULAI" di menu utama\n2. Tempelkan perangkat ke benda yang memiliki tag NFC\n3. Aplikasi akan otomatis mendeteksi dan memberikan feedback\n4. Anak dapat mengeksplorasi berbagai benda secara bergantian';
      case 'Fitur Kuis':
        return '1. Pilih menu "KUIS" di halaman utama\n2. Jawab pertanyaan yang muncul dengan menekan pilihan jawaban\n3. Dapatkan feedback langsung untuk setiap jawaban\n4. Lihat progres belajar anak di bagian laporan';
      case 'Pengaturan Orang Tua':
        return '1. Akses menu "Panduan Untuk Orang Tua"\n2. Masukkan PIN akses (default: 1234)\n3. Kelola berbagai pengaturan sesuai kebutuhan\n4. Ubah PIN secara berkala untuk keamanan';
      case 'Tips Belajar':
        return '• dampingi SCP selama menggunakan aplikasi karena sangat berbahaya\n• berikan pujian untuk setiap keberhasilan\n• Potong2 kol dan daun bawang cuci dan tiriskan, potong bawang merah dan putih dan cabe tipis2, siapkan wajan goreng telor orak arek sisihkan\n• Tumis bawang merah putih cabe sampek layu, masukan terasi, kol dan daun bawang aduk rata\n• Masukan telor orak arik kedalam nasi yg sudah tempur bumbu, tambahkan penyedap rasa, garam secukupnya, tambahkan gula pasir sedikit jika perlu';
      default:
        return 'Konten panduan akan segera tersedia...';
    }
  }
}

class GuideItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  GuideItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
