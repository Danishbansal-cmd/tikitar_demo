import 'package:tikitar_demo/core/network/api_base.dart';

class CompanyController {
  static Future<Map<String, dynamic>> saveOnlyCompany({
    required String name,
    required String city,
    required String zip,
    required String state,
    required int categoryId,
  }) async {
    try {
      final response = await ApiBase.post("/clients/storeclients", {
        "name": name,
        "category_id": categoryId,
        "city": city,
        "state": state,
        "zip": zip,
      });
      return {"status": response['status'] || true, "message": response['message']};
    } catch (e) {
      return {"status": false, "message": "Error: $e"};
    }
  }

  static Future<Map<String, dynamic>> getOnlyCompanies(int userId) async {
    try {
      final response = await ApiBase.get("/clients/getcompanies/$userId");

      // Check if response and expected fields exist
      if (response != null &&
          response['status'] == true &&
          response['data'] != null) {
        return {
          "status": true,
          "message": response['message'] ?? "Companies fetched successfully",
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
      return {"status": false, "message": "Error: $e", "data": []};
    }
  }
}
