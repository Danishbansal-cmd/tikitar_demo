import 'package:flutter/material.dart';
import 'package:tikitar_demo/services/models/profile_model.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileModel? _profile;

  // Getter
  ProfileModel? get profile {
    return _profile;
  }

  // Setter
  void setProfile(Map<String, dynamic> map) {
    _profile = ProfileModel.fromJson(map);
    notifyListeners();
  }
}
