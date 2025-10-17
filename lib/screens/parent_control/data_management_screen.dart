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
      backgroundColor: Color(0xFFF9F5E8),
      appBar: AppBar(
        backgroundColor: Color(0xFFC8A2C8),
        title: Text(
          'Data Anak',
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
                    color: Color(0xFFC8A2C8),
                    width: 4,
                  ),
                ),
                child: Icon(
                  Icons.people,
                  size: 50,
                  color: Color(0xFFC8A2C8),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Data & Progres Anak',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFC8A2C8),
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Kelola data dan lihat perkembangan belajar anak',
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
                    children: [
                      Text(
                        'Ringkasan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFC8A2C8),
                        ),
                      ),
                      SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('Total Anak', _childrenData.length.toString(), Icons.people),
                          _buildStatItem('Sesi Aktif', '23', Icons.play_arrow),
                          _buildStatItem('Rata-rata Progress', '68%', Icons.trending_up),
                        ],
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
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Data Individual',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFC8A2C8),
                            ),
                          ),
                          SmoothPressButton(
                            onPressed: _addNewChild,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Color(0xFFC8A2C8).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.add, size: 16, color: Color(0xFFC8A2C8)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Tambah',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFC8A2C8),
                                      fontWeight: FontWeight.bold,
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
                        'Kelola Data',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFC8A2C8),
                        ),
                      ),
                      SizedBox(height: 15),
                      _buildDataOption(
                        'Ekspor Data',
                        'Simpan data progres ke file',
                        Icons.download,
                        () {
                          _exportData();
                        },
                      ),
                      SizedBox(height: 12),
                      _buildDataOption(
                        'Backup Otomatis',
                        'Aktifkan backup ke cloud',
                        Icons.cloud_upload,
                        () {
                          _toggleAutoBackup();
                        },
                      ),
                      SizedBox(height: 12),
                      _buildDataOption(
                        'Hapus Data',
                        'Reset semua data progres',
                        Icons.delete,
                        () {
                          _showDeleteConfirmation();
                        },
                        isDanger: true,
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

  Widget _buildStatItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Color(0xFFC8A2C8).withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Color(0xFFC8A2C8),
            size: 24,
          ),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFFC8A2C8),
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildChildCard(ChildData child) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFFC8A2C8).withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Color(0xFFC8A2C8).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(0xFFC8A2C8).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              color: Color(0xFFC8A2C8),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFC8A2C8),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Progress: ${child.progress}% • ${child.lastActivity}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4),
                LinearProgressIndicator(
                  value: child.progress / 100,
                  backgroundColor: Colors.grey[300],
                  color: Color(0xFFC8A2C8),
                ),
              ],
            ),
          ),
          SmoothPressButton(
            onPressed: () {
              _viewChildDetails(child);
            },
            child: Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Color(0xFFC8A2C8).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.visibility,
                size: 16,
                color: Color(0xFFC8A2C8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataOption(String title, String subtitle, IconData icon, VoidCallback onTap, {bool isDanger = false}) {
    Color color = isDanger ? Colors.red : Color(0xFFC8A2C8);
    
    return SmoothPressButton(
      onPressed: onTap,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 18,
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
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
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
        title: Text('Hapus Semua Data?'),
        content: Text('Tindakan ini akan menghapus semua data progres dan tidak dapat dipulihkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('BATAL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              print('Data berhasil dihapus');
            },
            child: Text(
              'HAPUS',
              style: TextStyle(color: Colors.red),
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