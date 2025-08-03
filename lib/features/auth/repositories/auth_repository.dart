import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tikitar_demo/core/local/data_strorage.dart';
import 'package:tikitar_demo/core/network/api_base.dart';
import 'package:tikitar_demo/features/profile/repositories/profile_repository.dart';

final authProvider = AsyncNotifierProvider<AuthNotifier, void>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // no initial logic needed here
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();

    try {
      final body = {"email": email, "password": password};
      final response = await ApiBase.post('/login', body);
      print("[AuthProvider response]: $response");

      if ((response['status'] == true || response['status'] == "true") &&
          response['data']?['token'] != null) {
        final data = response['data'];

        ApiBase.setToken(data['token']);
        await DataStorage.saveToken(data['token']);
        await DataStorage.saveUserData(jsonEncode(data['user']));

        // Set user profile in profileProvider
        ref.read(profileProvider.notifier).setProfile(data['user']);

        return {
          'status': true,
          'message': 'Successfully logged in.',
          'data': data,
        };
      }
      return {
        'status': false,
        'message': 'Invalid response from server.',
      };
    } catch (e) {
      print("[AuthProvider error]: $e");
      return {
        'status': false,
        'message': 'Invalid Details! Please Try Again.',
      };
    } finally {
      state = const AsyncData(null); // Reset loading
    }
  }
}
