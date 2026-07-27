import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported locale codes for the app
class AppLocale {
  final String code;
  final String name;
  final String nativeName;
  final String flag;

  const AppLocale({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
  });

  static const List<AppLocale> supportedLocales = [
    AppLocale(code: 'en', name: 'English', nativeName: 'English', flag: '🇺🇸'),
    AppLocale(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी', flag: '🇮🇳'),
    AppLocale(code: 'bn', name: 'Bengali', nativeName: 'বাংলা', flag: '🇮🇳'),
    AppLocale(code: 'te', name: 'Telugu', nativeName: 'తెలుగు', flag: '🇮🇳'),
    AppLocale(code: 'ta', name: 'Tamil', nativeName: 'தமிழ்', flag: '🇮🇳'),
    AppLocale(code: 'mr', name: 'Marathi', nativeName: 'मराठी', flag: '🇮🇳'),
    AppLocale(code: 'gu', name: 'Gujarati', nativeName: 'ગુજરાતી', flag: '🇮🇳'),
    AppLocale(code: 'kn', name: 'Kannada', nativeName: 'ಕನ್ನಡ', flag: '🇮🇳'),
    AppLocale(code: 'ml', name: 'Malayalam', nativeName: 'മലയാളം', flag: '🇮🇳'),
  ];

  static AppLocale get defaultLocale => supportedLocales.first;

  static AppLocale fromCode(String code) {
    return supportedLocales.firstWhere(
      (l) => l.code == code,
      orElse: () => defaultLocale,
    );
  }
}

class LanguageProvider extends ChangeNotifier {
  AppLocale _currentLocale = AppLocale.defaultLocale;

  AppLocale get currentLocale => _currentLocale;
  String get currentCode => _currentLocale.code;

  Future<void> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString('app_language');
    if (savedCode != null) {
      _currentLocale = AppLocale.fromCode(savedCode);
      notifyListeners();
    }
  }

  Future<void> setLanguage(AppLocale locale) async {
    _currentLocale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', locale.code);
  }

  /// Show a language selection bottom sheet (called from UI)
  static Future<void> showLanguageSheet(
    BuildContext context,
    LanguageProvider provider,
  ) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Select Language',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Choose your preferred app language',
                style: TextStyle(fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.black45)),
            const SizedBox(height: 16),
            ...AppLocale.supportedLocales.map((locale) {
              final selected = provider.currentCode == locale.code;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: ListTile(
                  leading: Text(locale.flag, style: const TextStyle(fontSize: 24)),
                  title: Text(locale.nativeName,
                      style: TextStyle(fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF0F172A))),
                  subtitle: Text(locale.name,
                      style: TextStyle(fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black45)),
                  trailing: selected
                      ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                      : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: selected
                      ? theme.colorScheme.primary.withValues(alpha: 0.08)
                      : null,
                  onTap: () {
                    provider.setLanguage(locale);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Language set to ${locale.nativeName}'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
