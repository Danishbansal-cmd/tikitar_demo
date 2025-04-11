import 'dart:convert';
import 'package:tikitar_demo/features/data/local/data_strorage.dart';
import 'package:tikitar_demo/features/data/local/token_storage.dart';
import 'package:tikitar_demo/core/network/api_base.dart';

class ClientsController {
  /// Fetches client data and stores the entire list in local storage.
  static Future<void> fetchAndStoreClientsData() async {
    final token = await TokenStorage.getToken();
    if (token == null) {
      print("Token not found.");
      return;
    }

    try {
      final response = await ApiBase.get('/user/clients', token: token);
      final data = response['data'];
      print("Client from controller: $data");

      if (data != null && data is List && data.isNotEmpty) {
        final jsonToStore = jsonEncode(data);
        await DataStorage.saveUserClientsData(jsonToStore);
        print("All client data stored: $jsonToStore");
      }
    } catch (e) {
      print("Error fetching/storing client data: $e");
    }
  }
}
