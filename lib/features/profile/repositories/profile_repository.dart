import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tikitar_demo/features/profile/models/profile_model.dart';

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileModel?>(
  (ref) => ProfileNotifier(),
);

class ProfileNotifier extends StateNotifier<ProfileModel?> {
  ProfileNotifier() : super(null);

  // Setter
  void setProfile(Map<String, dynamic> map) {
    state = ProfileModel.fromJson(map);
  }

  void clearProfile() {
    state = null;
  }
}
