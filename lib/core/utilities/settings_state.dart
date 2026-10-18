import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState extends ChangeNotifier {
  static const String _darkModeKey = 'darkMode';
  static const String _languageKey = 'language';
  static const String _fontFamilyKey = 'fontFamily';
  static const String _fontSizeKey = 'fontSize';
  static const String _onboardingCompleteKey = 'onboardingComplete';
  static const String _appLockEnabledKey = 'appLockEnabled';
  static const String _appLockPinHashKey = 'appLockPinHash';
  static const String _appLockUseBiometricKey = 'appLockUseBiometric';
  static const String _notificationsEnabledKey = 'notificationsEnabled';
  static const String _notificationSoundKey = 'notificationSound';
  static const String _vibrationEnabledKey = 'vibrationEnabled';
  static const String _encryptBackupsKey = 'encryptBackups';
  static const String _encryptBackupsKeyHashPref = 'encryptBackupsKeyHash';
  static const String _calendarTypeKey = 'calendarType';

  bool _darkMode = false;
  String _languageCode = 'en';
  String _fontFamily = 'Roboto';
  double _fontSize = 14.0;
  bool _onboardingComplete = false;
  bool _appLockEnabled = false;
  String _appLockPinHash = '';
  bool _appLockUseBiometric = false;
  bool _notificationsEnabled = true;
  String _notificationSound = 'default';
  bool _vibrationEnabled = true;
  bool _encryptBackups = false;
  String _encryptBackupsKeyHash = '';
  String _calendarType = 'gregorian';

  bool get darkMode => _darkMode;
  Locale get locale => Locale(_languageCode);
  String get fontFamily => _fontFamily;
  double get fontSize => _fontSize;
  bool get isOnboardingComplete => _onboardingComplete;
  bool get isAppLockEnabled => _appLockEnabled;
  String get appLockPinHash => _appLockPinHash;
  bool get appLockUseBiometric => _appLockUseBiometric;
  bool get notificationsEnabled => _notificationsEnabled;
  String get notificationSound => _notificationSound;
  bool get vibrationEnabled => _vibrationEnabled;
  bool get encryptBackups => _encryptBackups;
  String get encryptBackupsKeyHash => _encryptBackupsKeyHash;
  String get calendarType => _calendarType;

  // Available font families
  static const List<Map<String, String>> availableFonts = [
    {'name': 'Roboto', 'displayName': 'Roboto'},
    {'name': 'NotoSansArabic', 'displayName': 'Noto Sans Arabic'},
    {'name': 'NotoSans', 'displayName': 'Noto Sans'},
    {'name': 'OpenSans', 'displayName': 'Open Sans'},
    {'name': 'Lato', 'displayName': 'Lato'},
    {'name': 'Poppins', 'displayName': 'Poppins'},
    {'name': 'Montserrat', 'displayName': 'Montserrat'},
    {'name': 'Raleway', 'displayName': 'Raleway'},
    {'name': 'Ubuntu', 'displayName': 'Ubuntu'},
    {'name': 'Cairo', 'displayName': 'Cairo (Arabic Friendly)'},
    {'name': 'Amiri', 'displayName': 'Amiri (Persian/Arabic)'},
    {'name': 'Scheherazade', 'displayName': 'Scheherazade (Dari/Pashto)'},
    {'name': 'NotoNaskhArabic', 'displayName': 'Noto Naskh Arabic'},
    {'name': 'IBMPlexSans', 'displayName': 'IBM Plex Sans'},
    {'name': 'FiraCode', 'displayName': 'Fira Code (Monospace)'},
  ];

  // Available font sizes
  static const Map<String, double> fontSizes = {
    'Small': 12.0,
    'Medium': 14.0,
    'Large': 16.0,
    'Extra Large': 18.0,
  };

  // Available languages
  static const List<Map<String, String>> availableLanguages = [
    {'code': 'en', 'name': 'English', 'nativeName': 'English'},
    {'code': 'fa', 'name': 'Dari', 'nativeName': 'دری'},
    {'code': 'ps', 'name': 'Pashto', 'nativeName': 'پښتو'},
  ];

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _darkMode = prefs.getBool(_darkModeKey) ?? false;
    _languageCode = prefs.getString(_languageKey) ?? 'en';
    _fontFamily = prefs.getString(_fontFamilyKey) ?? 'Roboto';
    _fontSize = prefs.getDouble(_fontSizeKey) ?? 14.0;
    _onboardingComplete = prefs.getBool(_onboardingCompleteKey) ?? false;
    _appLockEnabled = prefs.getBool(_appLockEnabledKey) ?? false;
    _appLockPinHash = prefs.getString(_appLockPinHashKey) ?? '';
    _appLockUseBiometric = prefs.getBool(_appLockUseBiometricKey) ?? false;
    _notificationsEnabled = prefs.getBool(_notificationsEnabledKey) ?? true;
    _notificationSound = prefs.getString(_notificationSoundKey) ?? 'default';
    _vibrationEnabled = prefs.getBool(_vibrationEnabledKey) ?? true;
    _encryptBackups = prefs.getBool(_encryptBackupsKey) ?? false;
    _encryptBackupsKeyHash = prefs.getString(_encryptBackupsKeyHashPref) ?? '';
    _calendarType = prefs.getString(_calendarTypeKey) ?? 'gregorian';
    notifyListeners();
  }

  Future<void> setOnboardingComplete(bool value) async {
    _onboardingComplete = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompleteKey, value);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _darkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    _languageCode = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, code);
    notifyListeners();
  }

  Future<void> setFontFamily(String family) async {
    _fontFamily = family;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fontFamilyKey, family);
    notifyListeners();
  }

  Future<void> setFontSize(double size) async {
    _fontSize = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, size);
    notifyListeners();
  }

  Future<void> setAppLock({required bool enabled, required String pinHash, required bool useBiometric}) async {
    _appLockEnabled = enabled;
    _appLockPinHash = pinHash;
    _appLockUseBiometric = useBiometric;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_appLockEnabledKey, enabled);
    await prefs.setString(_appLockPinHashKey, pinHash);
    await prefs.setBool(_appLockUseBiometricKey, useBiometric);
    notifyListeners();
  }

  String getFontSizeName() {
    return fontSizes.entries.firstWhere(
      (entry) => entry.value == _fontSize,
      orElse: () => const MapEntry('Medium', 14.0),
    ).key;
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, value);
    notifyListeners();
  }

  Future<void> setNotificationSound(String value) async {
    _notificationSound = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_notificationSoundKey, value);
    notifyListeners();
  }

  Future<void> setVibrationEnabled(bool value) async {
    _vibrationEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vibrationEnabledKey, value);
    notifyListeners();
  }

  Future<void> setEncryptBackups({required bool enabled, required String keyHash}) async {
    _encryptBackups = enabled;
    _encryptBackupsKeyHash = keyHash;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_encryptBackupsKey, enabled);
    await prefs.setString(_encryptBackupsKeyHashPref, keyHash);
    notifyListeners();
  }

  Future<void> setCalendarType(String type) async {
    _calendarType = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_calendarTypeKey, type);
    notifyListeners();
  }
}
