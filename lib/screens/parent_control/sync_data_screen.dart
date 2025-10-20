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
                  color: Color(0xFFFE6D73).withOpacity(0.1),
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
                              color: Color(0xFFFE6D73),
                              width: 4,
                            ),
                          ),
                          child: Icon(
                            Icons.cloud_sync_rounded,
                            size: 60,
                            color: Color(0xFFFE6D73),
                          ),
                        ),

                        SizedBox(height: 30),
                        Text(
                          'Sinkronisasi Data',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2D5A7E),
                            fontFamily: 'ComicNeue',
                          ),
                        ),

                        SizedBox(height: 8),

                        Text(
                          'Sync data progres anak ke cloud',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF666666),
                            fontFamily: 'ComicNeue',
                          ),
                          textAlign: TextAlign.center,
                        ),

                        SizedBox(height: 40),
                        Container(
                          padding: EdgeInsets.all(25),
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
                              color: Color(0xFFFE6D73).withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              if (_isSyncing) ...[
                                SizedBox(height: 10),
                                CircularProgressIndicator(
                                  color: Color(0xFFFE6D73),
                                  strokeWidth: 6,
                                ),
                                SizedBox(height: 25),
                                Text(
                                  'Menyinkronisasi data...',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Color(0xFF2D5A7E),
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'ComicNeue',
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'Mohon tunggu sebentar',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF666666),
                                    fontFamily: 'ComicNeue',
                                  ),
                                ),
                              ] else if (_isSynced) ...[
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFF4ECDC4),
                                  size: 70,
                                ),
                                SizedBox(height: 20),
                                Text(
                                  'Data berhasil disinkronisasi!',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Color(0xFF2D5A7E),
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'ComicNeue',
                                  ),
                                ),
                                SizedBox(height: 15),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF4ECDC4).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'Terakhir sync: ${DateTime.now().toString().substring(0, 16)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF2D5A7E),
                                      fontFamily: 'ComicNeue',
                                    ),
                                  ),
                                ),
                              ] else ...[
                                Icon(
                                  Icons.cloud_off_rounded,
                                  color: Color(0xFF666666),
                                  size: 70,
                                ),
                                SizedBox(height: 20),
                                Text(
                                  'Data belum disinkronisasi',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Color(0xFF2D5A7E),
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'ComicNeue',
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'Klik tombol di bawah untuk memulai sinkronisasi',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF666666),
                                    fontFamily: 'ComicNeue',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        ),

                        SizedBox(height: 40),

                        if (!_isSyncing && !_isSynced)
                          SmoothPressButton(
                            onPressed: _startSync,
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: Color(0xFFFE6D73),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFFFE6D73).withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  'SINKRONISASI SEKARANG',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'ComicNeue',
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
                              padding: EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: Color(0xFFFE6D73),
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'RESET',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Color(0xFFFE6D73),
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'ComicNeue',
                                  ),
                                ),
                              ),
                            ),
                          ),
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
}