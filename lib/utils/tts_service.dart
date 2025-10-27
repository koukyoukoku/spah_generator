import 'package:flutter_tts/flutter_tts.dart';
import 'package:Eksplorasi/models/languages/index.dart';

class TTSService {
  static final FlutterTts _tts = FlutterTts();
  static bool _isInitialized = false;
  static bool _ttsAvailable = true;

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
        _isInitialized = true;
        print('✅ TTS initialized successfully');
      } catch (e) {
        _ttsAvailable = false;
        print('❌ TTS initialization failed: $e');
      }
    }
  }

  static Future<void> speakSpelling(String text, String language) async {
    if (text.isEmpty || !_ttsAvailable || !_isInitialized) return;

    try {
      await setLanguage(language);
      await speak(text);
    } catch (e) {
      print('❌ Error in speakSpelling: $e');
    }
  }

  static Future<void> setLanguage(String languageCode) async {
    if (!_ttsAvailable || !_isInitialized) return;

    try {
      List<dynamic> languages = await _tts.getLanguages;
      String targetLanguage = languageCode == 'id' ? "id-ID" : "en-US";

      if (languages.contains(targetLanguage)) {
        await _tts.setLanguage(targetLanguage);
        print('✅ TTS language set to: $targetLanguage');
      } else {
        print('⚠️ Language $targetLanguage not available, using default');
        if (languages.isNotEmpty) {
          await _tts.setLanguage(languages.first as String);
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
      print('TTS speaking: $text');
    } catch (e) {
      print('Error speaking text: $e');
      _ttsAvailable = false;
    }
  }

  static Future<void> stop() async {
    if (!_ttsAvailable) return;

    try {
      await _tts.stop();
    } catch (e) {
      print('❌ Error stopping TTS: $e');
    }
  }

  static Future<void> speakObjectName(String objectName) async {
    if (objectName.isEmpty || !_ttsAvailable) return;

    try {
      String currentLanguage =
          AppLocalizations.current?.currentLanguageCode ?? 'id';
      await setLanguage(currentLanguage);
      await speak(objectName);
    } catch (e) {
      print('❌ Error in speakObjectName: $e');
    }
  }

  static bool get isAvailable => _ttsAvailable;
}
