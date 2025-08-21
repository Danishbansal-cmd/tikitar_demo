import 'package:tikitar_demo/core/network/api_base.dart';

class CompanyController {
  static Future<Map<String, dynamic>> saveOnlyCompany({
    required String name,
    required String city,
    required String zip,
    required String state,
    required int categoryId,
    required String address,
    required String branch,
  }) async {
    try {
      final response = await ApiBase.post("/clients/saveCompany", {
        "name": name,
        "category_id": categoryId,
        "city": city,
        "state": state,
        "zip": zip,
        "address_line1": address,
        "branch_name": branch,
      });
      return {"status": response['status'] || true, "message": response['message']};
    } catch (e) {
      return {"status": false, "message": "Error: $e"};
    }
  }

  static Future<Map<String, dynamic>> saveCompanyAlongContactPerson(Map<String, dynamic> companyAlongContactPerson) async {
    try {
      final response = await ApiBase.post('/clients/savethecompany', companyAlongContactPerson);

      return {"status": response['status'] || true, "message": response['message']};
    } catch (e) {
      return {"status": false, "message": "$e"};
    }
  }

  static Future<List<Map<String, dynamic>>> getOnlyCompanies(int userId) async {
    try {
      final response = await ApiBase.get("/clients/getcompanies/$userId");

      // Check if response and expected fields exist
      if (response != null &&
          response['status'] == true &&
          response['data'] != null) {
        return List<Map<String, dynamic>>.from(response['data']);
      } else {
        throw Exception('Invalid response');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
