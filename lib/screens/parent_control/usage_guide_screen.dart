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
      icon: Icons.nfc,
      color: Color(0xFF4ECDC4),
    ),
    GuideItem(
      title: 'Fitur Kuiz',
      description: 'Cara anak berinteraksi dengan kuis edukasi',
      icon: Icons.quiz,
      color: Color(0xFFFE6D73),
    ),
    GuideItem(
      title: 'Pengaturan Orang Tua',
      description: 'Cara mengakses dan menggunakan kontrol orang tua',
      icon: Icons.family_restroom,
      color: Color(0xFFFED766),
    ),
    GuideItem(
      title: 'Tips Belajar',
      description: 'Tips untuk mendampingi SCP selama belajar',
      icon: Icons.lightbulb,
      color: Color(0xFFA5D8FF),
    ),
  ];

  int _expandedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF9F5E8),
      appBar: AppBar(
        backgroundColor: Color(0xFFFED766),
        title: Text(
          'Panduan Penggunaan',
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
                    color: Color(0xFFFED766),
                    width: 4,
                  ),
                ),
                child: Icon(
                  Icons.menu_book,
                  size: 50,
                  color: Color(0xFFFED766),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Panduan Lengkap',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFED766),
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Pelajari cara menggunakan aplikasi dengan optimal',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _guideItems.length,
                itemBuilder: (context, index) {
                  return _buildGuideItem(_guideItems[index], index);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuideItem(GuideItem item, int index) {
    bool isExpanded = _expandedIndex == index;
    
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      child: SmoothPressButton(
        onPressed: () {
          setState(() {
            _expandedIndex = isExpanded ? -1 : index;
          });
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
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: item.color.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item.icon,
                          color: item.color,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: item.color,
                              ),
                            ),
                            Text(
                              item.description,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: item.color,
                      ),
                    ],
                  ),
                  if (isExpanded) ...[
                    SizedBox(height: 16),
                    Divider(color: item.color.withOpacity(0.3)),
                    SizedBox(height: 12),
                    Text(
                      _getGuideContent(item.title),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
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
      case 'Fitur Kuiz':
        return '1. Pilih menu "KUIZ" di halaman utama\n2. Jawab pertanyaan yang muncul dengan menekan pilihan jawaban\n3. Dapatkan feedback langsung untuk setiap jawaban\n4. Lihat progres belajar anak di bagian laporan';
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