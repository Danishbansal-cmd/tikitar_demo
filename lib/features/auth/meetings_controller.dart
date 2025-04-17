import 'package:tikitar_demo/core/network/api_base.dart';
import 'package:tikitar_demo/features/data/local/token_storage.dart';

class MeetingsController {
  /// Submits a meeting to the API
  static Future<void> submitMeeting({
    required String clientId,
    required String email,
    required String mobile,
    required String comments,
    required String latitude,
    required String longitude,
  }) async {
    final token = await TokenStorage.getToken();
    if (token == null) {
      print("Token not found.");
      throw Exception("Authentication token not found.");
    }else {
      print("meeting submitted token: $token");
    }

    final payload = {
      "client_id": clientId,
      "contact_person_email": email,
      "contact_person_mobile": mobile,
      "comments": comments,
      "latitude": latitude,
      "longitude": longitude
    };

    try {
      final response = await ApiBase.post('/meetings', payload, token: token);
      print("Meeting submitted successfully: $response");
    } catch (e) {
      print("Error submitting meeting: $e");
      rethrow;
    }
  }
}
