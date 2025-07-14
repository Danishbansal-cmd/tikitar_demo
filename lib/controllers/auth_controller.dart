import 'dart:convert';

import 'package:tikitar_demo/core/network/api_base.dart';
import 'package:tikitar_demo/core/local/data_strorage.dart';

class AuthController {
  
  

      
  Future<Map<String, dynamic>> fetchUserData() async {
    try {
      // Pass token explicitly to the static GET method
      final response = await ApiBase.get('/user');
      print("User Data: $response");
      return response;
    } catch (e) {
      print("User Data Error: $e");
      return {
        'status': false,
        'message': 'Failed to fetch user data',
      };
    }
  }

  static Future<Map<String, dynamic>> fetchPersonalTarget() async {
    try {
      // Pass token explicitly to the static GET method
      final response = await ApiBase.get('/meetings/mypersonaltarget');
      return {
        'status': true,
        'message': response['message'],
        'data': response['data'],
      };
    } catch (e) {
      return {
        'status': false,
        'message': 'Failed to fetchPersonalTarget()',
      };
    }
  }

  static Future<Map<String, dynamic>> fetchBonusMetric() async {
    try {
      // Pass token explicitly to the static GET method
      final response = await ApiBase.get('/meetings/bonusmetric');
      return {
        'status': true,
        'message': response['message'],
        'data': response['data'],
      };
    } catch (e) {
      return {
        'status': false,
        'message': 'Failed to fetchBonusMetric()',
      };
    }
  }

  static Future<Map<String, dynamic>> fetchCurrentMonthMeetings() async {
    try {
      // Pass token explicitly to the static GET method
      final response = await ApiBase.get('/meetings/currentmonthmeetings');
      return {
        'status': true,
        'message': response['message'],
        'data': response['data'],
      };
    } catch (e) {
      return {
        'status': false,
        'message': 'Failed to fetchCurrentMonthMeetings()',
      };
    }
  }

  static Future<Map<String, dynamic>> fetchCurrentMonthTarget() async {
    try {
      // Pass token explicitly to the static GET method
      final response = await ApiBase.get('/meetings/currentmonthtarget');
      return {
        'status': true,
        'message': response['message'],
        'data': response['data'],
      };
    } catch (e) {
      return {
        'status': false,
        'message': 'Failed to fetchCurrentMonthTarget()',
      };
    }
  }
}
