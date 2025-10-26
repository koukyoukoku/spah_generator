import 'package:flutter/material.dart';

class IndonesianLanguage {
  static final Map<String, Map<String, String>> id = {
    'navigation': {
      'home': 'Beranda',
      'settings': 'Pengaturan',
      'exploration': 'Eksplorasi',
      'parent': 'Orang Tua',
      'exit': 'Keluar',
    },
    'common': {
      'welcome': 'Selamat Datang',
      'start': 'Mulai',
      'refresh': 'Muat Ulang',
      'test': 'Tes',
    },
    'parent_control': {
      'title': 'Kontrol Orang Tua',
      'subtitle': 'Kelola pengaturan aplikasi untuk anak',
      'about_app': 'Tentang Aplikasi',
      'about_description': 'Aplikasi Eksplorasi dirancang khusus untuk anak-anak dengan antarmuka yang sederhana dan ramah.',
      'made_with_love': 'Made With Love ❤️',
      'change_pin': 'Ubah PIN',
      'sync': 'Sinkronisasi',
      'guide': 'Panduan',
      'settings': 'Pengaturan',
      'child_data': 'Data Anak',
      'esp32_setup': 'Setup ESP32',
    },
    'play_screen': {
      'preparing': 'Menyiapkan...',
      'preparing_esp32': 'Menyiapkan mode ESP32...',
      'esp32_found': 'Perangkat ESP32 ditemukan',
      'esp32_connected': 'Terhubung ke ESP32',
      'ready_to_scan': 'Siap memindai RFID',
      'card_not_recognized': 'Kartu tidak dikenali',
      'invalid_card': 'Kartu tidak valid',
      'connection_lost': 'Koneksi terputus',
      'connection_failed': 'Gagal terhubung',
      'nfc_ready': 'NFC siap',
      'tap_nfc': 'Tempelkan perangkat ke tag NFC',
      'nfc_disabled': 'NFC dimatikan',
      'enable_nfc': 'Aktifkan NFC di pengaturan',
      'nfc_not_supported': 'Perangkat tidak mendukung NFC',
      'nfc_error': 'Error memeriksa NFC',
      'starting_read': 'Memulai pembacaan...',
      'tap_rfid': 'Tempelkan kartu RFID ke reader',
      'multiple_tags': 'Terdeteksi Tag lebih dari 1!',
      'scan_object': 'Scan benda',
      'tag_not_recognized': 'Tag NFC tidak dikenali',
      'waiting_next': 'Menunggu tag berikutnya...',
      'tap_another': 'Tempelkan ke tag lain...',
      'error_try_again': 'Terjadi kesalahan, coba lagi',
      'stopping': 'Menghentikan...',
      'success': 'BERHASIL!',
      'explore_object': 'Eksplorasi Benda',
      'object_recognized': 'Benda berhasil dikenali!',
      'esp32_mode': 'Mode ESP32',
      'nfc_mode': 'Mode NFC',
      'tip_esp32': 'Tempelkan kartu RFID ke reader ESP32',
      'tip_nfc': 'Tempelkan bagian atas perangkat ke tag NFC',
      'back': 'KEMBALI',
      'invalid_uid': 'UID tidak valid',
      'nfc_mode_active': 'Mode NFC Aktif',
    },
    'menu_utama': { 
      'searching_device': 'Mencari perangkat...',
      'connected_esp32': 'Terhubung ESP32',
      'nfc_mode_active': 'Mode NFC Aktif',
      'subtitle': 'Belajar Seru Untuk SCP-173',
      'quiz': 'KUIS',
    },
  };

  static String get(String key) {
    for (var category in id.values) {
      if (category.containsKey(key)) {
        return category[key]!;
      }
    }
    return key;
  }
}