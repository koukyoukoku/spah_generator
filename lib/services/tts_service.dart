import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  static final FlutterTts _tts = FlutterTts();
  static bool _isInitialized = false;
  static bool _ttsAvailable = true;
  static String _currentLanguage = 'id-ID';

  static Future<void> init() async {
    if (!_isInitialized) {
      try {
        var languages = await _tts.getLanguages;
        if (languages.isEmpty) {
          _ttsAvailable = false;
          print('⚠️ TTS not available on this device');
          return;
        }

        await _tts.setPitch(1.0);
        await _tts.setSpeechRate(0.5);
        await _tts.setVolume(1.0);
        await _tts.setLanguage("id-ID");
        
        _isInitialized = true;
        print('✅ TTS initialized successfully');
      } catch (e) {
        _ttsAvailable = false;
        print('❌ TTS initialization failed: $e');
      }
    }
  }

  static Future<void> setLanguage(String languageCode) async {
    if (!_ttsAvailable || !_isInitialized) return;

    try {
      List<dynamic> languages = await _tts.getLanguages;
      
      String targetLanguage;
      switch (languageCode.toLowerCase()) {
        case 'id':
          targetLanguage = "id-ID";
          break;
        case 'en':
          targetLanguage = "en-US";
          break;
        default:
          targetLanguage = "id-ID";
      }

      if (languages.contains(targetLanguage)) {
        await _tts.setLanguage(targetLanguage);
        _currentLanguage = targetLanguage;
        print('✅ TTS language set to: $targetLanguage');
      } else {
        print('⚠️ Language $targetLanguage not available, using default');
        if (languageCode == 'id' && languages.contains("id-ID")) {
          await _tts.setLanguage("id-ID");
          _currentLanguage = "id-ID";
        } else if (languages.contains("en-US")) {
          await _tts.setLanguage("en-US");
          _currentLanguage = "en-US";
        } else if (languages.isNotEmpty) {
          await _tts.setLanguage(languages.first as String);
          _currentLanguage = languages.first as String;
        }
      }
    } catch (e) {
      print('❌ Error setting TTS language: $e');
      _ttsAvailable = false;
    }
  }

  static Future<void> speak(String text) async {
    if (text.isEmpty || !_ttsAvailable || !_isInitialized) return;

    try {
      await _tts.stop();
      await _tts.speak(text);
      print('🔊 TTS speaking: $text in $_currentLanguage');
    } catch (e) {
      print('❌ Error speaking text: $e');
      _ttsAvailable = false;
    }
  }

  static Future<void> stop() async {
    if (!_ttsAvailable) return;

    try {
      await _tts.stop();
      print('🔇 TTS stopped');
    } catch (e) {
      print('❌ Error stopping TTS: $e');
    }
  }

  static bool get isAvailable => _ttsAvailable;
  static String get currentLanguage => _currentLanguage;
}