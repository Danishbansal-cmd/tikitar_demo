import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:tikitar_demo/core/network/api_base.dart';
import 'package:tikitar_demo/features/data/local/token_storage.dart';

class MeetingsController {
  /// Submits a meeting to the API, including optional file for `visited_card`
  static Future<void> submitMeeting({
    required String clientId,
    required String email,
    required String mobile,
    required String comments,
    required String latitude,
    required String longitude,
    required String meeting_date,
    File? visitedCardFile,
  }) async {
    final token = await TokenStorage.getToken();
    if (token == null) {
      print("❌ Token not found.");
      throw Exception("Authentication token not found.");
    } else {
      print("✅ Meeting submitted with token: $token");
    }

    final payload = {
      "client_id": clientId,
      "contact_person_email": email,
      "contact_person_mobile": mobile,
      "comments": comments,
      "latitude": latitude,
      "longitude": longitude,
      "meeting_date": meeting_date,
      "visited": "Site", // Always "site"
    };

    try {
      final uri = Uri.parse('${ApiBase.baseUrl}/meetings');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..fields.addAll(payload);

      if (visitedCardFile != null) {
        final file = await http.MultipartFile.fromPath('visited_card', visitedCardFile.path);
        request.files.add(file);
      }

      // Log full request details
      print("📡 URI: ${request.url}");
      print("📄 Headers: ${request.headers}");
      print("📝 Fields: $payload");
      request.fields.forEach((key, value) => print("   • $key: $value"));
      if (request.files.isNotEmpty) {
        print("📎 Attached Files:");
        for (var file in request.files) {
          print("   • Field: ${file.field}, Filename: ${file.filename}, Length: ${file.length}");
        }
      }

      final response = await request.send();

      final responseBody = await response.stream.bytesToString();
      print("📬 Response Status: ${response.statusCode}");
      print("📬 Response Body: $responseBody");

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ Meeting submitted successfully.");
      } else {
        throw Exception("❌ Failed to submit meeting: ${response.statusCode} - $responseBody");
      }
    } catch (e) {
      print("🔥 Error submitting meeting: $e");
      rethrow;
    }
  }
}
