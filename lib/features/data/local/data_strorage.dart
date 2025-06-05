import 'package:shared_preferences/shared_preferences.dart';

class DataStorage {
  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get _instance async {
    return _prefs ??= await SharedPreferences.getInstance();
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

  static Future<void> saveStateNames(List stateNames) async {
    final prefs = await _instance;
    await prefs.setStringList('state_names', stateNames.cast<String>());
  }

  static Future<List<String>?> getStateNames() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('state_names');
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
}
