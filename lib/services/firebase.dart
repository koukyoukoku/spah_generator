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

  Future<void> saveData(String path, Map<String, dynamic> data) async {
    try {
      await _database.child(path).set(data);
      print('Data saved successfully at path: $path');
    } catch (e) {
      print('Error saving data: $e');
      throw Exception('Failed to save data: $e');
    }
  }

  Future<Map<String, dynamic>?> getData(String path) async {
    try {
      final snapshot = await _database.child(path).get();
      if (snapshot.exists) {
        print('Data retrieved successfully from path: $path');
        return Map<String, dynamic>.from(
            snapshot.value as Map<dynamic, dynamic>);
      }
      print('No data found at path: $path');
      return null;
    } catch (e) {
      print('Error getting data: $e');
      throw Exception('Failed to get data: $e');
    }
  }

  Stream<DatabaseEvent> streamData(String path) {
    return _database.child(path).onValue;
  }

  Future<void> updateData(String path, Map<String, dynamic> data) async {
    try {
      await _database.child(path).update(data);
      print('Data updated successfully at path: $path');
    } catch (e) {
      print('Error updating data: $e');
      throw Exception('Failed to update data: $e');
    }
  }

  Future<void> deleteData(String path) async {
    try {
      await _database.child(path).remove();
      print('Data deleted successfully at path: $path');
    } catch (e) {
      print('Error deleting data: $e');
      throw Exception('Failed to delete data: $e');
    }
  }
}