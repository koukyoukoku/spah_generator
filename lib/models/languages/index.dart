import 'id.dart';
import 'en.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocalizations {
  static const String _languageKey = 'selected_language';
  static String _currentLocale = 'id';

  static final Map<String, Map<String, Map<String, String>>> _localizedValues = {
    'id': IndonesianLanguage.id,
    'en': EnglishLanguage.en,
  };

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLocale = prefs.getString(_languageKey) ?? 'id';
  }

  static String get currentLocale => _currentLocale;

  static Future<void> setLocale(String locale) async {
    _currentLocale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, locale);
  }

  static Future<void> toggleLanguage() async {
    _currentLocale = _currentLocale == 'id' ? 'en' : 'id';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, _currentLocale);
  }

  static String get(String key) {
    if (key.contains('.')) {
      List<String> parts = key.split('.');
      if (parts.length == 2) {
        String category = parts[0];
        String actualKey = parts[1];
        
        final categoryMap = _localizedValues[_currentLocale]?[category];
        if (categoryMap != null && categoryMap.containsKey(actualKey)) {
          return categoryMap[actualKey]!;
        }
      }
    } else {
      final localeData = _localizedValues[_currentLocale];
      if (localeData != null) {
        for (var category in localeData.values) {
          if (category.containsKey(key)) {
            return category[key]!;
          }
        }
      }
    }

    print('⚠️ Key not found: $key for locale: $_currentLocale');
    return key;
  }

  static String getWithLocale(String key, String locale) {
    if (key.contains('.')) {
      List<String> parts = key.split('.');
      if (parts.length == 2) {
        String category = parts[0];
        String actualKey = parts[1];
        
        final categoryMap = _localizedValues[locale]?[category];
        if (categoryMap != null && categoryMap.containsKey(actualKey)) {
          return categoryMap[actualKey]!;
        }
      }
    }
    
    return key;
  }

  static void debugKeys() {
    print('=== DEBUG LOCALIZATION KEYS ===');
    print('Current locale: $_currentLocale');
    
    final localeData = _localizedValues[_currentLocale];
    if (localeData != null) {
      localeData.forEach((category, keys) {
        print('Category: $category');
        keys.forEach((key, value) {
          print('  $key: $value');
        });
      });
    }
    print('=== END DEBUG ===');
  }
}