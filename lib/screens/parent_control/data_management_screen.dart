import 'package:flutter/material.dart';
import 'package:spah_generator/components/SmoothPress.dart';

class DataManagementScreen extends StatefulWidget {
  @override
  _DataManagementScreenState createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends State<DataManagementScreen> {
  final List<ChildData> _childrenData = [
    ChildData(
      name: 'Anak 1',
      progress: 75,
      lastActivity: 'Hari ini, 10:30',
      totalSessions: 15,
      favoriteActivity: 'Eksplorasi Benda',
    ),
    ChildData(
      name: 'Anak 2', 
      progress: 60,
      lastActivity: 'Kemarin, 14:20',
      totalSessions: 8,
      favoriteActivity: 'Kuis Warna',
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
                  color: Color(0xFFC8A2C8).withOpacity(0.1),
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
                              color: Color(0xFFC8A2C8),
                              width: 4,
                            ),
                          ),
                          child: Icon(
                            Icons.people_rounded,
                            size: 60,
                            color: Color(0xFFC8A2C8),
                          ),
                        ),

                        SizedBox(height: 30),
                        Text(
                          'Data & Progres Anak',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2D5A7E),
                            fontFamily: 'ComicNeue',
                          ),
                        ),

                        SizedBox(height: 8),

                        Text(
                          'Kelola data dan lihat perkembangan belajar anak',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF666666),
                            fontFamily: 'ComicNeue',
                          ),
                          textAlign: TextAlign.center,
                        ),

                        SizedBox(height: 40),
                        _buildDataCard(
                          title: 'Ringkasan',
                          children: [
                            SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatItem('Total Anak', _childrenData.length.toString(), Icons.people_rounded),
                                _buildStatItem('Sesi Aktif', '23', Icons.play_arrow_rounded),
                                _buildStatItem('Rata-rata Progress', '68%', Icons.trending_up_rounded),
                              ],
                            ),
                          ],
                        ),

                        SizedBox(height: 20),
                        _buildDataCard(
                          title: 'Data Individual',
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Daftar Anak',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF666666),
                                    fontFamily: 'ComicNeue',
                                  ),
                                ),
                                SmoothPressButton(
                                  onPressed: _addNewChild,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Color(0xFFC8A2C8),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0xFFC8A2C8).withOpacity(0.3),
                                          blurRadius: 6,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.add, size: 16, color: Colors.white),
                                        SizedBox(width: 6),
                                        Text(
                                          'Tambah',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'ComicNeue',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 15),
                            ..._childrenData.map((child) => _buildChildCard(child)).toList(),
                          ],
                        ),

                        SizedBox(height: 20),
                        _buildDataCard(
                          title: 'Kelola Data',
                          children: [
                            SizedBox(height: 10),
                            _buildDataOption(
                              'Ekspor Data',
                              'Simpan data progres ke file',
                              Icons.download_rounded,
                              () {
                                _exportData();
                              },
                            ),
                            SizedBox(height: 12),
                            _buildDataOption(
                              'Backup Otomatis',
                              'Aktifkan backup ke cloud',
                              Icons.cloud_upload_rounded,
                              () {
                                _toggleAutoBackup();
                              },
                            ),
                            SizedBox(height: 12),
                            _buildDataOption(
                              'Hapus Data',
                              'Reset semua data progres',
                              Icons.delete_rounded,
                              () {
                                _showDeleteConfirmation();
                              },
                              isDanger: true,
                            ),
                          ],
                        ),

                        SizedBox(height: 20),
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

  Widget _buildDataCard({required String title, required List<Widget> children}) {
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
          color: Color(0xFFC8A2C8).withOpacity(0.3),
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
          ...children,
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Color(0xFFC8A2C8).withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: Color(0xFFC8A2C8).withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            color: Color(0xFFC8A2C8),
            size: 28,
          ),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2D5A7E),
            fontFamily: 'ComicNeue',
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF666666),
            fontFamily: 'ComicNeue',
          ),
        ),
      ],
    );
  }

  Widget _buildChildCard(ChildData child) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFC8A2C8).withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Color(0xFFC8A2C8).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Color(0xFFC8A2C8).withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Color(0xFFC8A2C8).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.person_rounded,
              color: Color(0xFFC8A2C8),
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D5A7E),
                    fontFamily: 'ComicNeue',
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Progress: ${child.progress}% • ${child.lastActivity}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                    fontFamily: 'ComicNeue',
                  ),
                ),
                SizedBox(height: 8),
                LinearProgressIndicator(
                  value: child.progress / 100,
                  backgroundColor: Colors.grey[300],
                  color: Color(0xFFC8A2C8),
                  borderRadius: BorderRadius.circular(10),
                  minHeight: 8,
                ),
              ],
            ),
          ),
          SmoothPressButton(
            onPressed: () {
              _viewChildDetails(child);
            },
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Color(0xFFC8A2C8).withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Color(0xFFC8A2C8).withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.visibility_rounded,
                size: 20,
                color: Color(0xFFC8A2C8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataOption(String title, String subtitle, IconData icon, VoidCallback onTap, {bool isDanger = false}) {
    Color color = isDanger ? Color(0xFFFE6D73) : Color(0xFFC8A2C8);
    
    return SmoothPressButton(
      onPressed: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                icon,
                color: color,
                size: 22,
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
                      color: color,
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
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
              color: color,
            ),
          ],
        ),
      ),
    );
  }

  void _addNewChild() {
    print('Tambah anak baru');
  }

  void _viewChildDetails(ChildData child) {
    print('Lihat detail: ${child.name}');
  }

  void _exportData() {
    print('Ekspor data');
  }

  void _toggleAutoBackup() {
    print('Toggle backup otomatis');
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Hapus Semua Data?',
          style: TextStyle(
            fontFamily: 'ComicNeue',
            color: Color(0xFF2D5A7E),
          ),
        ),
        content: Text(
          'Tindakan ini akan menghapus semua data progres dan tidak dapat dipulihkan.',
          style: TextStyle(
            fontFamily: 'ComicNeue',
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'BATAL',
              style: TextStyle(
                fontFamily: 'ComicNeue',
                color: Color(0xFF666666),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Data berhasil dihapus',
                    style: TextStyle(
                      fontFamily: 'ComicNeue',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: Color(0xFFFE6D73),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            child: Text(
              'HAPUS',
              style: TextStyle(
                fontFamily: 'ComicNeue',
                color: Color(0xFFFE6D73),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChildData {
  final String name;
  final int progress;
  final String lastActivity;
  final int totalSessions;
  final String favoriteActivity;

  ChildData({
    required this.name,
    required this.progress,
    required this.lastActivity,
    required this.totalSessions,
    required this.favoriteActivity,
  });
}