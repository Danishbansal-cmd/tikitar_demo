

import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tikitar_demo/controllers/meetings_controller.dart';
import 'package:tikitar_demo/features/common/models/meeting_model.dart';
import 'package:tikitar_demo/features/profile/repositories/profile_repository.dart';

// creating provider
final meetingProvider = AsyncNotifierProvider<MeetingRepository, List<MeetingModel>>(MeetingRepository.new,);

class MeetingRepository extends AsyncNotifier<List<MeetingModel>>{
  int? _userId;
  void setUserId(int userId) {
    _userId = userId;
  }

  @override
  Future<List<MeetingModel>> build() async {
    // read data from the riverpod_provider
    final profile = ref.read(profileProvider);

    final userId = _userId ?? profile?.id;
    if (userId == null) {
      developer.log("No userId found in MeetingRepository", name: "MeetingRepo");
      return [];
    }

    developer.log("Fetching meetings for userId: $userId");
    return await fetchAllMeetings(userId: userId);
  }

  Future<List<MeetingModel>> fetchAllMeetings({required int userId}) async {
    try {
      final responseList = await MeetingsController.userBasedMeetings(userId);
      developer.log("responseList fetchAllMeetings: ${responseList}");

      return responseList
          .map((meetingData) => MeetingModel.fromJson(meetingData))
          .toList();
    } catch (e) {
      developer.log("fetchAllMeetings: $e", name: "fetchAllMeetings");
      debugPrint("fetchAllMeetings: $e");
      return [];
    }
  }
}