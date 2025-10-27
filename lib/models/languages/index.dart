import 'id.dart';
import 'en.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocalizations {
  static const String _languageKey = 'selected_language';
  static String _currentLocale = 'id';
  static AppLocalizations? _current;

  static final Map<String, Map<String, Map<String, String>>> _localizedValues = {
    'id': IndonesianLanguage.id,
    'en': EnglishLanguage.en,
  };

  AppLocalizations._internal();

  static AppLocalizations get current {
    _current ??= AppLocalizations._internal();
    return _current!;
  }

  String get currentLanguageCode => _currentLocale;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLocale = prefs.getString(_languageKey) ?? 'id';
    _current ??= AppLocalizations._internal();
    _debugPrintAvailableKeys(); 
  }

  static String get currentLocale => _currentLocale;

  static Future<void> setLocale(String locale) async {
    if (_localizedValues.containsKey(locale)) {
      _currentLocale = locale;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, locale);
      _debugPrintAvailableKeys(); 
    } else {
      print('❌ Locale not supported: $locale');
    }
  }

  static Future<void> toggleLanguage() async {
    _currentLocale = _currentLocale == 'id' ? 'en' : 'id';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, _currentLocale);
    _debugPrintAvailableKeys(); 
  }

  static String get(String key) {
    try {
      if (key.contains('.')) {
        List<String> parts = key.split('.');
        if (parts.length == 2) {
          String category = parts[0];
          String subKey = parts[1];
          
          var currentLocaleData = _localizedValues[_currentLocale];
          if (currentLocaleData != null && 
              currentLocaleData.containsKey(category) && 
              currentLocaleData[category]!.containsKey(subKey)) {
            return currentLocaleData[category]![subKey]!;
          }
          
          var enLocaleData = _localizedValues['en'];
          if (enLocaleData != null && 
              enLocaleData.containsKey(category) && 
              enLocaleData[category]!.containsKey(subKey)) {
            print('⚠️ Using English fallback for: "$key"');
            return enLocaleData[category]![subKey]!;
          }
          
          var idLocaleData = _localizedValues['id'];
          if (idLocaleData != null && 
              idLocaleData.containsKey(category) && 
              idLocaleData[category]!.containsKey(subKey)) {
            print('⚠️ Using Indonesian fallback for: "$key"');
            return idLocaleData[category]![subKey]!;
          }
        }
      }
      
      final currentLocaleData = _localizedValues[_currentLocale];
      if (currentLocaleData != null) {
        for (var category in currentLocaleData.values) {
          if (category.containsKey(key)) {
            return category[key]!;
          }
        }
      }
      
      final enLocaleData = _localizedValues['en'];
      if (enLocaleData != null) {
        for (var category in enLocaleData.values) {
          if (category.containsKey(key)) {
            print('⚠️ Using English fallback for: "$key"');
            return category[key]!;
          }
        }
      }
      
      final idLocaleData = _localizedValues['id'];
      if (idLocaleData != null) {
        for (var category in idLocaleData.values) {
          if (category.containsKey(key)) {
            print('⚠️ Using Indonesian fallback for: "$key"');
            return category[key]!;
          }
        }
      }
      
      print('❌ Key not found in any locale: "$key"');
      return _formatKeyToReadable(key);
    } catch (e) {
      print('❌ Error getting key "$key": $e');
      return _formatKeyToReadable(key);
    }
  }

  static String _formatKeyToReadable(String key) {
    String formatted = key.replaceAll('.', ' ');
    formatted = formatted.replaceAllMapped(
      RegExp(r'(^| )[a-z]'),
      (Match m) => m.group(0)!.toUpperCase(),
    );
    return formatted;
  }

  static bool hasKey(String key) {
    if (key.contains('.')) {
      List<String> parts = key.split('.');
      if (parts.length == 2) {
        String category = parts[0];
        String subKey = parts[1];
        
        for (var locale in _localizedValues.values) {
          if (locale.containsKey(category) && locale[category]!.containsKey(subKey)) {
            return true;
          }
        }
      }
    }
    
    for (var locale in _localizedValues.values) {
      for (var category in locale.values) {
        if (category.containsKey(key)) {
          return true;
        }
      }
    }
    
    return false;
  }

  static List<String> get availableLocales {
    return _localizedValues.keys.toList();
  }

  static Map<String, String>? getCategory(String category) {
    return _localizedValues[_currentLocale]?[category];
  }

  static List<String> get categories {
    return _localizedValues[_currentLocale]?.keys.toList() ?? [];
  }

  static void _debugPrintAvailableKeys() {
    print('\n=== AVAILABLE KEYS for $_currentLocale ===');
    final localeData = _localizedValues[_currentLocale];
    if (localeData != null) {
      int totalKeys = 0;
      localeData.forEach((category, keys) {
        print('📁 $category: (${keys.length} keys)');
        keys.forEach((key, value) {
          print('   🔑 $key: "$value"');
        });
        totalKeys += keys.length;
      });
      print('📊 Total categories: ${localeData.length}');
      print('📊 Total keys: $totalKeys');
    } else {
      print('❌ No data found for locale: $_currentLocale');
    }
    print('=== END AVAILABLE KEYS ===\n');
  }

  static void debugKey(String key) {
    print('\n🔍 Debugging key: "$key"');
    print('📍 Current locale: $_currentLocale');
    
    if (key.contains('.')) {
      List<String> parts = key.split('.');
      if (parts.length == 2) {
        String category = parts[0];
        String subKey = parts[1];
        
        print('📂 Category: $category');
        print('🔑 Sub-key: $subKey');
        
        var currentData = _localizedValues[_currentLocale];
        if (currentData != null && currentData.containsKey(category)) {
          if (currentData[category]!.containsKey(subKey)) {
            print('✅ Found in current locale: ${currentData[category]![subKey]}');
          } else {
            print('❌ Sub-key not found in current locale');
          }
        } else {
          print('❌ Category not found in current locale');
        }
        
        _localizedValues.forEach((locale, data) {
          if (locale != _currentLocale && data.containsKey(category) && data[category]!.containsKey(subKey)) {
            print('🌍 Found in $locale: ${data[category]![subKey]}');
          }
        });
      }
    }
    
    print('🎯 Final result: "${get(key)}"');
    print('---\n');
  }

  static void compareWithLocale(String otherLocale) {
    if (!_localizedValues.containsKey(otherLocale)) {
      print('❌ Locale not found: $otherLocale');
      return;
    }
    
    print('\n🔄 COMPARING $_currentLocale with $otherLocale');
    
    final currentData = _localizedValues[_currentLocale];
    final otherData = _localizedValues[otherLocale];
    
    if (currentData == null || otherData == null) return;
    
    otherData.keys.forEach((category) {
      if (!currentData.containsKey(category)) {
        print('❌ Missing category: $category');
      } else {
        otherData[category]!.keys.forEach((key) {
          if (!currentData[category]!.containsKey(key)) {
            print('❌ Missing key: $category.$key');
          }
        });
      }
    });
    
    print('✅ Comparison completed\n');
  }
}