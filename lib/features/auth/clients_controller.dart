import 'dart:convert';
import 'package:tikitar_demo/features/data/local/data_strorage.dart';
import 'package:tikitar_demo/core/network/api_base.dart';

class ClientsController {
  /// Fetches client data and stores the entire list in local storage.
  static Future<void> fetchAndStoreClientsData() async {
    void printLongString(String text, {int chunkSize = 800}) {
      final pattern = RegExp('.{1,$chunkSize}', dotAll: true);
      pattern.allMatches(text).forEach((match) => print(match.group(0)));
    }

    try {
      final response = await ApiBase.get('/user/clients');
      final data = response['data'];
      print("Client from controller: $data");

      if (data != null && data is List && data.isNotEmpty) {
        final jsonToStore = jsonEncode(data);
        await DataStorage.saveUserClientsData(jsonToStore);
        printLongString("All client data stored: $jsonToStore");
      }
    } catch (e) {
      print("Error fetching/storing client data: $e");
    }
  }

  /// Adds a new client by sending the data to the /clients endpoint
  static Future<void> addClient(Map<String, dynamic> clientData) async {
    try {
      final response = await ApiBase.post(
        '/clients',
        clientData,
      );
      final data = response['data'];

      if (data != null && data is Map && data.isNotEmpty) {
        print("Client added successfully.");
        // Optionally refresh local cache
        await fetchAndStoreClientsData();
      } else {
        print("Failed to submit client: ${response['message']}");
      }

    } catch (e) {
      print("Error adding client: $e");
    }
  }
}
