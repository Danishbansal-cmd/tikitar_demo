import 'package:flutter_inappwebview/flutter_inappwebview.dart';


class Functions {
  /// Escapes strings to safely inject into JavaScript
  static String escapeJS(String value) {
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll(r'"', r'\"')
        .replaceAll("'", r"\'")
        .replaceAll('\n', r'\\n');
  }
}


class MonthlyDataWebViewHelper {
  final InAppWebViewController controller;

  MonthlyDataWebViewHelper(this.controller);

  Future<void> showGauges() async {
    await controller.evaluateJavascript(
      source: """
        document.getElementById('monthlyDataGauges').style.display = 'flex';  
      """,
    );
  }

  Future<void> insertCurrentMonthMeetingsValue(int value) async {
    await controller.evaluateJavascript(
      source: """
        var insertCurrentMonthMeetingsValue = document.getElementById('currentMonthMeetingsValue');
        insertCurrentMonthMeetingsValue.textContent = "$value";
        updateCurrentMonthMeetingsValue();
      """,
    );
  }

  Future<void> insertCurrentMonthTargetValue(int value) async {
    await controller.evaluateJavascript(
      source: """
        var insertCurrentMonthTargetValue = document.getElementById('currentMonthTargetValue');
        insertCurrentMonthTargetValue.textContent = "$value";
        updateCurrentMonthTargetValue();
      """,
    );
  }

  Future<void> refreshCurrentMonthMeetings() async {
    await controller.evaluateJavascript(
      source: "updateCurrentMonthMeetingsValue();",
    );
  }

  Future<void> refreshCurrentMonthTarget() async {
    await controller.evaluateJavascript(
      source: "updateCurrentMonthTargetValue();",
    );
  }
}

class PersonalDataWebViewHelper {
  final InAppWebViewController controller;

  PersonalDataWebViewHelper(this.controller);

  Future<void> insertPersonalTargetValue(int value) async {
    await controller.evaluateJavascript(
      source: """
        var insertPersonalTargetValue = document.getElementById('personalTargetValue');
        insertPersonalTargetValue.textContent = "$value";
        updatePersonalTargetValue();
      """,
    );
  }

  Future<void> insertBonusMetricValue(int value) async {
    await controller.evaluateJavascript(
      source: """
        document.getElementById('bonusMetricGauge').style.display = 'block'; 
        var insertBonusMetricValue = document.getElementById('bonusMetricValue');
        insertBonusMetricValue.textContent = "$value";
        updateBonusMetricValue();
      """,
    );
  }

  Future<void> refreshPersonalTargetValue() async {
    await controller.evaluateJavascript(
      source: "updatePersonalTargetValue();",
    );
  }

  Future<void> refreshBonusMetricValue() async {
    await controller.evaluateJavascript(
      source: "updateBonusMetricValue();",
    );
  }
}
