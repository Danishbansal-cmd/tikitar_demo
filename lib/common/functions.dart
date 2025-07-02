import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:tikitar_demo/features/auth/auth_controller.dart';
import 'dart:developer' as developer;
class Functions {
  /// Escapes strings to safely inject into JavaScript
  static String escapeJS(String value) {
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll(r'"', r'\"')
        .replaceAll("'", r"\'")
        .replaceAll('\n', r'\\n');
  }

  /// Fetches and injects monthly target data into the WebView
  static Future<void> fetchMonthlyData({
    required InAppWebViewController controller,
    required int daysInMonth,
  }) async {
    // show the middle gauges
    controller.evaluateJavascript(
      source: """
        document.getElementById('monthlyDataGauges').style.display = 'flex';  
      """,
    );

    // for current month meetings
    String currentMonthMeetingsJS = '';
    final currentMonthMeetingsData =
        await AuthController.fetchCurrentMonthMeetings();
    if (currentMonthMeetingsData['status'] == true) {
      developer.log(
        "currentMonthMeetingsData: $currentMonthMeetingsData",
        name: "fetchMonthlyData",
      );
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
        currentMonthMeetingsValueDisplay =
            (totalMeetings / (daysInMonth * meetingTarget)).round();
      }
      developer.log(
        "currentMonthMeetingsValueDisplay: $currentMonthMeetingsValueDisplay",
        name: "fetchMonthlyData",
      );
      currentMonthMeetingsJS = """
        var insertCurrentMonthMeetingsValue = document.getElementById('currentMonthMeetingsValue');
        insertCurrentMonthMeetingsValue.textContent = "$currentMonthMeetingsValueDisplay";
        updateCurrentMonthMeetingsValue();
      """;
    } else {
      currentMonthMeetingsJS = """
        updateCurrentMonthMeetingsValue();
      """;
    }
    await controller.evaluateJavascript(source: currentMonthMeetingsJS);


    // for current month Target
    String currentMonthTargetJs = '';
    final currentMonthTargetData =
        await AuthController.fetchCurrentMonthTarget();
    if (currentMonthTargetData['status'] == true) {
      developer.log(
        "currentMonthTargetData: $currentMonthTargetData",
        name: "fetchMonthlyData",
      );
      final int averageMeetings =
          int.tryParse(
            currentMonthTargetData['data']['average_meetings'].toString(),
          ) ??
          0;
      currentMonthTargetJs = """
        var insertCurrentMonthTargetValue = document.getElementById('currentMonthTargetValue');
        insertCurrentMonthTargetValue.textContent = "$averageMeetings";
        updateCurrentMonthTargetValue();
      """;
    } else {
      currentMonthTargetJs = """
        updateCurrentMonthTargetValue();
      """;
    }
    await controller.evaluateJavascript(source: currentMonthTargetJs);
  }

  static Future<void> fetchBonusMetricData({required InAppWebViewController controller}) async{
    // for Bonus Metric Value
    String bonusMetricJS = '';
    final bonusMetricData = await AuthController.fetchBonusMetric();
    if (bonusMetricData['status'] == true) {
      developer.log(
        "bonusMetricData: $bonusMetricData",
        name: "fetchIndividualData",
      );
      final targetCompletion = int.tryParse(
        bonusMetricData['data']['target_completion'].toString(),
        ) ??
        0;
      bonusMetricJS = """
        document.getElementById('bonusMetricGauge').style.display = 'block'; 
        var insertBonusMetricValue = document.getElementById('bonusMetricValue');
        insertBonusMetricValue.textContent = "$targetCompletion";
        updateBonusMetricValue();
      """;
    }
    await controller.evaluateJavascript(source: bonusMetricJS);
  }
}
