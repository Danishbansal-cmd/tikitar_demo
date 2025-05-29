import 'package:tikitar_demo/core/network/api_base.dart';

class ClientsController {
  /// Adds a new Contact Person for the specific user and specific company
  static Future<Map<String, dynamic>> addContactPerson(Map<String, dynamic> contactPersonData) async {
    try {
      final response = await ApiBase.post('/clients/contactpersonsave', contactPersonData);

      return {"status": response['status'] || true, "message": response['message']};
    } catch (e) {
      return {"status": false, "message": "$e"};
    }
  }

  static Future<Map<String, dynamic>> getUserContactPersonsData(
    int clientId,
    int userId,
  ) async {
    try {
      final response = await ApiBase.get(
        '/clients/getcontactperson/$clientId/$userId',
      );

      if (response != null &&
          response['status'] == true &&
          response['data'] != null) {
        return {
          "status": true,
          "message":
              response['message'] ??
              "User's Specific Companies' Clients fetched successfully",
          "data": response['data'], // could be a List or Map depending on API
        };
      } else {
        return {
          "status": false,
          "message": response['message'] ?? "Invalid response",
          "data": null,
        };
      }
    } catch (e) {
      return {
        "status": false,
        "message": "Error occured in getUserClientsData(): $e",
        "data": null,
      };
    }
  }
}
