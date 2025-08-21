

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tikitar_demo/controllers/auth_controller.dart';

class PersonalDataState {
  final int personalTargetValueDisplay;
  final int bonusMetricTargetCompletion;

  PersonalDataState({this.personalTargetValueDisplay = 0 ,this.bonusMetricTargetCompletion = 0});

  PersonalDataState copyWith({
    int? personalTargetValueDisplay,
    int? bonusMetricTargetCompletion,
  }){
    return PersonalDataState(
      personalTargetValueDisplay: personalTargetValueDisplay ?? this.personalTargetValueDisplay,
      bonusMetricTargetCompletion: bonusMetricTargetCompletion ?? this.bonusMetricTargetCompletion
    );
  }
}


/// --- NOTIFIER ---
class PersonalDataNotifier extends StateNotifier<PersonalDataState>{
  PersonalDataNotifier() : super(PersonalDataState());

  //// fetches the bonus metric data
  Future<void> fetchBonusMetricData() async{
    //// for Bonus Metric Value
    final bonusMetricData = await AuthController.fetchBonusMetric();
    if (bonusMetricData['status'] == true) {
      final targetCompletion = int.tryParse(
        bonusMetricData['data']['target_completion'].toString(),
        ) ??
        0;
        // update the state
      state = state.copyWith(
        bonusMetricTargetCompletion: targetCompletion,
      );
    }
  }

  //// fetches the bonus metric data
  Future<void> fetchPersonalTargetData() async{
    // for Personal Target Value
    final personalTargetData = await AuthController.fetchPersonalTarget();
    if (personalTargetData['status'] == true) {
      final int totalMeetings =
          int.tryParse(
            personalTargetData['data']['total_meetings'].toString(),
          ) ??
          0;
      final int meetingTarget =
          int.tryParse(
            personalTargetData['data']['meeting_target'].toString(),
          ) ??
          0;
      // Guard against division by zero
      int personalTargetValueDisplay = 0;
      if (meetingTarget > 0) {
        double result = (totalMeetings / meetingTarget) * 100;
        personalTargetValueDisplay = result.round();
      }
      // update the state
      state = state.copyWith(
        personalTargetValueDisplay: personalTargetValueDisplay
      );
    } 
  }
}

/// --- PROVIDER ---
final personalDataProvider = StateNotifierProvider<PersonalDataNotifier, PersonalDataState>((ref){
  return PersonalDataNotifier();
});


// defaults to true to show the value of bonus metric
final showBonusMetricBooleanProvider = StateProvider<bool>((ref) => true);
