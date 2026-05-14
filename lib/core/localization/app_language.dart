import 'dart:ui';

class AppLanguage {
  const AppLanguage({
    required this.code,
    required this.flag,
    required this.name,
    required this.nativeName,
  });

  final String code;
  final String flag;
  final String name;
  final String nativeName;
}

class AppLanguages {
  AppLanguages._();

  static const String fallbackCode = 'en';

  static const List<AppLanguage> supported = [
    AppLanguage(
      code: 'en',
      flag: '\u{1F1FA}\u{1F1F8}',
      name: 'English',
      nativeName: 'English',
    ),
    AppLanguage(
      code: 'es',
      flag: '\u{1F1EA}\u{1F1F8}',
      name: 'Spanish',
      nativeName: 'Espa\u00f1ol',
    ),
    AppLanguage(
      code: 'fr',
      flag: '\u{1F1EB}\u{1F1F7}',
      name: 'French',
      nativeName: 'Fran\u00e7ais',
    ),
    AppLanguage(
      code: 'pt',
      flag: '\u{1F1E7}\u{1F1F7}',
      name: 'Portuguese',
      nativeName: 'Portugu\u00eas',
    ),
    AppLanguage(
      code: 'de',
      flag: '\u{1F1E9}\u{1F1EA}',
      name: 'German',
      nativeName: 'Deutsch',
    ),
    AppLanguage(
      code: 'it',
      flag: '\u{1F1EE}\u{1F1F9}',
      name: 'Italian',
      nativeName: 'Italiano',
    ),
    AppLanguage(
      code: 'ja',
      flag: '\u{1F1EF}\u{1F1F5}',
      name: 'Japanese',
      nativeName: '\u65e5\u672c\u8a9e',
    ),
    AppLanguage(
      code: 'ko',
      flag: '\u{1F1F0}\u{1F1F7}',
      name: 'Korean',
      nativeName: '\ud55c\uad6d\uc5b4',
    ),
    AppLanguage(
      code: 'zh',
      flag: '\u{1F1E8}\u{1F1F3}',
      name: 'Chinese',
      nativeName: '\u4e2d\u6587',
    ),
    AppLanguage(
      code: 'ar',
      flag: '\u{1F1F8}\u{1F1E6}',
      name: 'Arabic',
      nativeName: '\u0627\u0644\u0639\u0631\u0628\u064a\u0629',
    ),
    AppLanguage(
      code: 'hi',
      flag: '\u{1F1EE}\u{1F1F3}',
      name: 'Hindi',
      nativeName: '\u0939\u093f\u0928\u094d\u0926\u0940',
    ),
    AppLanguage(
      code: 'fil',
      flag: '\u{1F1F5}\u{1F1ED}',
      name: 'Filipino',
      nativeName: 'Filipino',
    ),
    AppLanguage(
      code: 'vi',
      flag: '\u{1F1FB}\u{1F1F3}',
      name: 'Vietnamese',
      nativeName: 'Ti\u1ebfng Vi\u1ec7t',
    ),
    AppLanguage(
      code: 'th',
      flag: '\u{1F1F9}\u{1F1ED}',
      name: 'Thai',
      nativeName: '\u0e44\u0e17\u0e22',
    ),
    AppLanguage(
      code: 'id',
      flag: '\u{1F1EE}\u{1F1E9}',
      name: 'Indonesian',
      nativeName: 'Bahasa Indonesia',
    ),
    AppLanguage(
      code: 'ms',
      flag: '\u{1F1F2}\u{1F1FE}',
      name: 'Malay',
      nativeName: 'Bahasa Melayu',
    ),
    AppLanguage(
      code: 'ru',
      flag: '\u{1F1F7}\u{1F1FA}',
      name: 'Russian',
      nativeName: '\u0420\u0443\u0441\u0441\u043a\u0438\u0439',
    ),
    AppLanguage(
      code: 'tr',
      flag: '\u{1F1F9}\u{1F1F7}',
      name: 'Turkish',
      nativeName: 'T\u00fcrk\u00e7e',
    ),
    AppLanguage(
      code: 'pl',
      flag: '\u{1F1F5}\u{1F1F1}',
      name: 'Polish',
      nativeName: 'Polski',
    ),
    AppLanguage(
      code: 'nl',
      flag: '\u{1F1F3}\u{1F1F1}',
      name: 'Dutch',
      nativeName: 'Nederlands',
    ),
    AppLanguage(
      code: 'sw',
      flag: '\u{1F1F0}\u{1F1EA}',
      name: 'Swahili',
      nativeName: 'Kiswahili',
    ),
  ];

  static const List<String> supportedLocaleCodes = [
    'en',
    'es',
    'fr',
    'pt',
    'de',
    'it',
    'ja',
    'ko',
    'zh',
    'ar',
    'hi',
    'fil',
    'vi',
    'th',
    'id',
    'ms',
    'ru',
    'tr',
    'pl',
    'nl',
    'sw',
  ];

  static const List<String> fullySupportedLocaleCodes = ['en', 'es', 'ms'];

  static final List<AppLanguage> fullySupported = supported
      .where((language) => fullySupportedLocaleCodes.contains(language.code))
      .toList(growable: false);

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('pt'),
    Locale('de'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
    Locale('ar'),
    Locale('hi'),
    Locale('fil'),
    Locale('vi'),
    Locale('th'),
    Locale('id'),
    Locale('ms'),
    Locale('ru'),
    Locale('tr'),
    Locale('pl'),
    Locale('nl'),
    Locale('sw'),
  ];

  static const List<Locale> fullySupportedLocales = [
    Locale('en'),
    Locale('es'),
    Locale('ms'),
  ];

  static const Map<String, String> _aliases = {'tl': 'fil'};

  static String normalizeCode(String code) {
    final normalized = code.trim().toLowerCase();
    final aliased = _aliases[normalized] ?? normalized;
    return supportedLocaleCodes.contains(aliased) ? aliased : fallbackCode;
  }

  static String normalizeFullySupportedCode(String code) {
    final normalized = normalizeCode(code);
    return fullySupportedLocaleCodes.contains(normalized)
        ? normalized
        : fallbackCode;
  }
}
