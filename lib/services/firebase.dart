import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseRealtimeDB {
  late DatabaseReference _database;

  FirebaseRealtimeDB() {
    _database = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://spah-e2a0b-default-rtdb.asia-southeast1.firebasedatabase.app',
    ).ref();
  }

  Future<Map<String, dynamic>?> getData(String path) async {
    try {
      final snapshot = await _database.child(path).get();
      if (snapshot.exists) {
        print('✅ Data retrieved from path: $path');
        
        final Map<String, dynamic> result = {};
        final data = snapshot.value;
        
        if (data is Map) {
          data.forEach((key, value) {
            result[key.toString()] = value;
          });
          return result;
        }
      }
      print('ℹ️ No data found at path: $path');
      return null;
    } catch (e) {
      print('❌ Error getting data: $e');
      return null;
    }
  }

  Future<void> saveData(String path, Map<String, dynamic> data) async {
    try {
      await _database.child(path).set(data);
      print('✅ Data saved at path: $path');
    } catch (e) {
      print('❌ Error saving data: $e');
    }
  }

  Stream<DatabaseEvent> streamData(String path) {
    return _database.child(path).onValue;
  }

  Future<void> updateData(String path, Map<String, dynamic> data) async {
    try {
      await _database.child(path).update(data);
      print('✅ Data updated at path: $path');
    } catch (e) {
      print('❌ Error updating data: $e');
    }
  }

  Future<void> deleteData(String path) async {
    try {
      await _database.child(path).remove();
      print('✅ Data deleted at path: $path');
    } catch (e) {
      print('❌ Error deleting data: $e');
    }
  }
}