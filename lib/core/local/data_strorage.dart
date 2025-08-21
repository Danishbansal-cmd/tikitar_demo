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

  static Future<String> getUserData() async {
    final prefs = await _instance;
    return prefs.getString('user_data')!;
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

  static Future<SharedPreferences> getInstace() async{
    return await _instance;
  }
}
