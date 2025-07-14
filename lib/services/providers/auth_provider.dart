import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:tikitar_demo/core/local/data_strorage.dart';
import 'package:tikitar_demo/core/network/api_base.dart';
import 'package:tikitar_demo/services/providers/profile_provider.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Map<String, dynamic>? _data;

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required ProfileProvider profileProvider,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final body = {"email": email, "password": password};
      final response = await ApiBase.post('/login', body);
      print("[AuthProvider response]: $response");

      if ((response['status'] == true || response['status'] == "true") &&
          response['data']?['token'] != null) {
        _data = response['data'];

        ApiBase.setToken(_data!['token']);
        await DataStorage.saveToken(_data!['token']);
        await DataStorage.saveUserData(jsonEncode(_data!['user']));

        /// Set user profile
        profileProvider.setProfile(_data!['user']);

        notifyListeners(); // Notify UI
      }
      return {
        'status': true,
        'message': 'Successfully logged in.',
        'data' : _data!
      };
    } catch (e) {
      print("[AuthProvider error]: $e");
      return {
        'status': false,
        'message': 'Invalid Details! Please Try Again.',
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
