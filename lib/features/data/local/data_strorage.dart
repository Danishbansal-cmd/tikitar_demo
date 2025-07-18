import 'package:shared_preferences/shared_preferences.dart';

class DataStorage {
  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get _instance async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<void> saveToken(String token) async {
    final prefs = await _instance;
    await prefs.setString('auth_token', token);
  }

  static Future<String?> getToken() async {
    final prefs = await _instance;
    return prefs.getString('auth_token');
  }

  static Future<void> clearToken() async {
    final prefs = await _instance;
    await prefs.remove('auth_token');
  }

  static Future<void> saveUserData(String data) async {
    final prefs = await _instance;
    await prefs.setString('user_data', data);
  }

  static Future<String?> getUserData() async {
    final prefs = await _instance;
    return prefs.getString('user_data');
  }

  static Future<void> clearUserData() async {
    final prefs = await _instance;
    await prefs.remove('user_data');
  }

  static Future<void> saveCategoryOptionsData(String data) async {
    final prefs = await _instance;
    await prefs.setString('category_options', data);
  }

  static Future<String?> getCategoryOptionsData() async {
    final prefs = await _instance;
    return prefs.getString('category_options');
  }

  static Future<bool?> getShowGaugesBoolean() async {
    final prefs = await _instance;
    return prefs.getBool('show_gauges');
  }

  static Future<void> saveShowGaugesBoolean(bool showGaugesStatus) async {
    final prefs = await _instance;
    await prefs.setBool('show_gauges', showGaugesStatus);
  }

  static Future<void> clearShowGaugesBoolean() async {
    final prefs = await _instance;
    await prefs.remove('show_gauges');
  }

  static Future<bool?> getShowBonusMetricBoolean() async {
    final prefs = await _instance;
    return prefs.getBool('bonus_gauge');
  }

  static Future<void> saveShowBonusMetricBoolean(bool showGaugesStatus) async {
    final prefs = await _instance;
    await prefs.setBool('bonus_gauge', showGaugesStatus);
  }

  static Future<void> clearShowBonusMetricBoolean() async {
    final prefs = await _instance;
    await prefs.remove('bonus_gauge');
  }

  static Future<SharedPreferences> getInstace() async{
    return await _instance;
  }
}
