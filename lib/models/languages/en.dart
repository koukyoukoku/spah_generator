import 'package:flutter/material.dart';

class EnglishLanguage {
  static final Map<String, Map<String, String>> en = {
    'navigation': {
      'home': 'Home',
      'settings': 'Settings',
      'exploration': 'Exploration',
      'parent': 'Parent',
      'exit': 'Exit',
    },
    'common': {
      'welcome': 'Welcome',
      'start': 'Start',
      'refresh': 'Refresh',
      'test': 'Test',
    },
    'parent_control': {
      'title': 'Parental Control',
      'subtitle': 'Manage app settings for children',
      'about_app': 'About App',
      'about_description': 'Exploration App is specially designed for children with a simple and friendly interface.',
      'made_with_love': 'Made With Love ❤️',
      'change_pin': 'Change PIN',
      'sync': 'Sync',
      'guide': 'Guide',
      'settings': 'Settings',
      'child_data': 'Child Data',
      'esp32_setup': 'ESP32 Setup',
    },
    'play_screen': {
      'preparing': 'Preparing...',
      'preparing_esp32': 'Preparing ESP32 mode...',
      'esp32_found': 'ESP32 device found',
      'esp32_connected': 'Connected to ESP32',
      'ready_to_scan': 'Ready to scan RFID',
      'card_not_recognized': 'Card not recognized',
      'invalid_card': 'Invalid card',
      'connection_lost': 'Connection lost',
      'connection_failed': 'Connection failed',
      'nfc_ready': 'NFC ready',
      'tap_nfc': 'Tap device to NFC tag',
      'nfc_disabled': 'NFC disabled',
      'enable_nfc': 'Enable NFC in settings',
      'nfc_not_supported': 'Device does not support NFC',
      'nfc_error': 'Error checking NFC',
      'starting_read': 'Starting read...',
      'tap_rfid': 'Tap RFID card to reader',
      'multiple_tags': 'More than 1 tag detected!',
      'scan_object': 'Scan object',
      'tag_not_recognized': 'NFC tag not recognized',
      'waiting_next': 'Waiting for next tag...',
      'tap_another': 'Tap to another tag...',
      'error_try_again': 'Error occurred, please try again',
      'stopping': 'Stopping...',
      'success': 'SUCCESS!',
      'explore_object': 'Explore Object',
      'object_recognized': 'Object recognized successfully!',
      'esp32_mode': 'ESP32 Mode',
      'nfc_mode': 'NFC Mode',
      'tip_esp32': 'Tap RFID card to ESP32 reader',
      'tip_nfc': 'Tap the top of the device to NFC tag',
      'back': 'BACK',
      'invalid_uid': 'Invalid UID',
      'nfc_mode_active': 'NFC Mode Active',
    },
    'menu_utama': {
      'searching_device': 'Searching device...',
      'connected_esp32': 'Connected ESP32',
      'nfc_mode_active': 'NFC Mode Active',
      'subtitle': 'Fun Learning For SCP-173',
      'quiz': 'QUIZ',
    },
  };

  static String get(String key) {
    for (var category in en.values) {
      if (category.containsKey(key)) {
        return category[key]!;
      }
    }
    return key;
  }
}