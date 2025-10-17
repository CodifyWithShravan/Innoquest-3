import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocalizations with ChangeNotifier {
  Locale _locale = const Locale('en'); // Default to English
  Locale get locale => _locale;

  // --- START OF TRANSLATION STRINGS ---
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'dashboard': 'Krishi Sakhi Dashboard',
      'welcome': 'Welcome,',
      'current_weather': 'Current Weather (Kochi)',
      'latest_news': 'Latest News',
      'prompt': 'Press the microphone to ask a question or log an activity',
      'profile': 'Profile',
      'activity_log': 'Activity Log',
      'market_prices': 'Market Prices',
      'crop_calendar': 'Crop Calendar',
      'news_schemes': 'News & Schemes',
      'pest_id': 'Pest & Disease ID',
      'sustainability': 'Sustainability',
      'ai_advisor': 'AI Advisor',
      'farm_management': 'Farm Management',
      'sign_out': 'Sign Out',
    },
    'ml': {
      'dashboard': 'കൃഷി സഖി ഡാഷ്‌ബോർഡ്',
      'welcome': 'സ്വാഗതം,',
      'current_weather': 'ഇപ്പോഴത്തെ കാലാവസ്ഥ (കൊച്ചി)',
      'latest_news': 'പുതിയ വാർത്തകൾ',
      'prompt':
          'ഒരു ചോദ്യം ചോദിക്കാനോ പ്രവർത്തനം രേഖപ്പെടുത്താനോ മൈക്രോഫോൺ അമർത്തുക',
      'profile': 'പ്രൊഫൈൽ',
      'activity_log': 'പ്രവർത്തന ലോഗ്',
      'market_prices': 'വിപണി വില',
      'crop_calendar': 'വിള കലണ്ടർ',
      'news_schemes': 'വാർത്തകളും പദ്ധതികളും',
      'pest_id': 'കീടങ്ങളെ തിരിച്ചറിയൽ',
      'sustainability': 'സുസ്ഥിരത',
      'ai_advisor': 'AI ഉപദേശകൻ',
      'farm_management': 'ഫാം മാനേജ്മെന്റ്',
      'sign_out': 'സൈൻ ഔട്ട്',
    }
  };
  // --- END OF TRANSLATION STRINGS ---

  String translate(String key) {
    return _localizedValues[_locale.languageCode]?[key] ?? key;
  }

  Future<void> switchLanguage() async {
    _locale =
        _locale.languageCode == 'en' ? const Locale('ml') : const Locale('en');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', _locale.languageCode);
    notifyListeners();
  }

  Future<void> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('languageCode') ?? 'en';
    _locale = Locale(languageCode);
    notifyListeners();
  }
}
