import 'package:shared_preferences/shared_preferences.dart';

class DataStorage {
  static Future<void> saveUserData(String data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', data);
  }

  static Future<String?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_data');
  }

  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
  }

  // save user clients data
  static Future<void> saveUserClientsData(String data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_clients_data', data);
  }

  static Future<String?> getUserClientsData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_clients_data');
  }

  static Future<void> clearUserClientsData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_clients_data');
  }
}
