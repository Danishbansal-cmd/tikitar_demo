


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tikitar_demo/controllers/auth_controller.dart';

class MonthlyDataState {
  final int currentMonthMeetingsValueDisplay;
  final int averageMeetings;
  final int bonusMetricTargetCompletion;

  MonthlyDataState({this.currentMonthMeetingsValueDisplay = 0, this.averageMeetings = 0, this.bonusMetricTargetCompletion = 0});

  MonthlyDataState copyWith({
    int? currentMonthMeetingsValueDisplay,
    int? averageMeetings,
    int? bonusMetricTargetCompletion,
  }){
    return MonthlyDataState(
      currentMonthMeetingsValueDisplay: currentMonthMeetingsValueDisplay ?? this.currentMonthMeetingsValueDisplay,
      averageMeetings: averageMeetings ?? this.averageMeetings,
      bonusMetricTargetCompletion: bonusMetricTargetCompletion ?? this.bonusMetricTargetCompletion
    );
  }
}

/// --- NOTIFIER ---
class MonthlyDataNotifier extends StateNotifier<MonthlyDataState>{
  MonthlyDataNotifier() : super(MonthlyDataState());
  //// Fetches monthly target data
  Future<void> fetchMonthlyData({
    required int daysInMonth,
  }) async {
    //// for current month meetings
    final currentMonthMeetingsData =
        await AuthController.fetchCurrentMonthMeetings();
    if (currentMonthMeetingsData['status'] == true) {
      final int totalMeetings =
          int.tryParse(
            currentMonthMeetingsData['data']['total_meetings'].toString(),
          ) ??
          0;
      final int meetingTarget =
          int.tryParse(
            currentMonthMeetingsData['data']['meeting_target'].toString(),
          ) ??
          0;
      // Guard against division by zero
      int currentMonthMeetingsValueDisplay = 0;
      if (daysInMonth > 0 && meetingTarget > 0) {
        double result = (totalMeetings /  meetingTarget) * 100;
        currentMonthMeetingsValueDisplay = result.round();
      }
      
      state = state.copyWith(
        currentMonthMeetingsValueDisplay: currentMonthMeetingsValueDisplay
      );
    }

    //// for current month Target
    final currentMonthTargetData =
        await AuthController.fetchCurrentMonthTarget();
    if (currentMonthTargetData['status'] == true) {
      final int averageMeetings =
          int.tryParse(
            currentMonthTargetData['data']['average_meetings'].toString(),
          ) ??
          0;
      state = state.copyWith(
        averageMeetings: averageMeetings
      );
    }
  }
}

/// --- PROVIDER ---
final monthlyDataProvider = StateNotifierProvider<MonthlyDataNotifier, MonthlyDataState>((ref){
  return MonthlyDataNotifier();
});

// default to false, means not to show the middle or montly gauges
final showGaugesBooleanProvider = StateProvider<bool>((ref) => false);
