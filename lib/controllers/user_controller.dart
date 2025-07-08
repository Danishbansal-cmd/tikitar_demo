

import 'package:tikitar_demo/core/network/api_base.dart';
import 'dart:developer' as developer;

class UserController {

  static Future<Map<String, dynamic>> specificEmployeesReporting(int userId) async {
    try {
      final response = await ApiBase.get('/specific-employees/$userId');
      final data = response['data'];
      developer.log("User list response: $data", name: "UserController.specificEmployeesReporting");

      if (data != null && data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(data);
      } else {
        throw Exception('No reporting employees found');
      }
    } catch (e) {
      throw Exception('Failed to load specific employees: $e');
    }
  }
}