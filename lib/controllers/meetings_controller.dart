import 'dart:io';
import 'dart:developer' as developer;
import 'package:tikitar_demo/core/network/api_base.dart';

class MeetingsController {
  /// Submits a meeting to the API, including optional file for `visited_card`
  static Future<Map<String, dynamic>> submitMeeting({
    required String clientId,
    required String userId,
    required String email,
    required String mobile,
    required String comments,
    required String latitude,
    required String longitude,
    required String meeting_date,
    required String visitedData,
    required File visitedCardFile,
  }) async {
    final payload = {
      "client_id": clientId,
      "user_id": userId,
      "contact_person_email": email,
      "contact_person_mobile": mobile,
      "comments": comments,
      "latitude": latitude,
      "longitude": longitude,
      "meeting_date": meeting_date,
      "visited": visitedData,
    };

    try {
      final responseBody = await ApiBase.multipartPost(
        '/meetings',
        payload,
        "visiting_card",
        visitedCardFile,
      );

      return {
        'status': true,
        'message': 'Meeting submitted successfully.',
        'data': responseBody,
      };

    } catch (e) {
      return {
        'status': false,
        'message': 'Meeting does not submitted: $e',
        'data': null,
      };
    }
  }

  static Future<List<Map<String, dynamic>>> userBasedMeetings(int userId) async {
    try {
      final response = await ApiBase.get('/meetings/user/$userId');
      final data = response['data'];

      developer.log(
        "Meeting list response: $data",
        name: "MeetingsController.userBasedMeetings",
      );

      if (data != null && data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('No meetings found or wrong data type');
      }
    } catch (e) {
      throw Exception('Failed to load the meetings of this user: $e');
    }
  }
}
