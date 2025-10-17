import 'package:flutter/material.dart';
import 'package:spah_generator/components/SmoothPress.dart';

class SyncDataScreen extends StatefulWidget {
  @override
  _SyncDataScreenState createState() => _SyncDataScreenState();
}

class _SyncDataScreenState extends State<SyncDataScreen> {
  bool _isSyncing = false;
  bool _isSynced = false;

  void _startSync() async {
    setState(() {
      _isSyncing = true;
    });
    await Future.delayed(Duration(seconds: 2));

    setState(() {
      _isSyncing = false;
      _isSynced = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF9F5E8),
      appBar: AppBar(
        backgroundColor: Color(0xFFFE6D73),
        title: Text(
          'Sinkronisasi Data',
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
        child: Padding(
          padding: EdgeInsets.all(25),
          child: Column(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Color(0xFFFE6D73),
                    width: 4,
                  ),
                ),
                child: Icon(
                  Icons.cloud_sync,
                  size: 60,
                  color: Color(0xFFFE6D73),
                ),
              ),
              SizedBox(height: 30),
              Text(
                'Sinkronisasi Data',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFE6D73),
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Sync data progres anak ke cloud',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),
              
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: EdgeInsets.all(25),
                  child: Column(
                    children: [
                      if (_isSyncing) ...[
                        CircularProgressIndicator(
                          color: Color(0xFFFE6D73),
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Menyinkronisasi data...',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ] else if (_isSynced) ...[
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 60,
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Data berhasil disinkronisasi!',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Terakhir sync: ${DateTime.now().toString()}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ] else ...[
                        Icon(
                          Icons.cloud_off,
                          color: Colors.grey[400],
                          size: 60,
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Data belum disinkronisasi',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: 30),
              
              if (!_isSyncing && !_isSynced)
                SmoothPressButton(
                  onPressed: _startSync,
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Color(0xFFFE6D73),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Text(
                        'SINKRONISASI SEKARANG',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              
              if (_isSynced)
                SmoothPressButton(
                  onPressed: () {
                    setState(() {
                      _isSynced = false;
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Text(
                        'RESET',
                        style: TextStyle(
                          fontSize: 18,
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
}