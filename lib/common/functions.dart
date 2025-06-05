
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:tikitar_demo/features/auth/auth_controller.dart';

class Functions{
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
  }) async {
    String currentMonthMeetingsJS = '';
    final currentMonthMeetingsData =
        await AuthController.fetchCurrentMonthMeetings();
    if (currentMonthMeetingsData['status'] == true) {
      currentMonthMeetingsJS = "";
    } else {
      currentMonthMeetingsJS = "";
    }
    await controller.evaluateJavascript(source: currentMonthMeetingsJS);
    
    String currentMonthTargetJs = '';
    final currentMonthTargetData =
        await AuthController.fetchCurrentMonthTarget();
    if (currentMonthTargetData['status'] == true) {
      currentMonthTargetJs = "";
    } else {
      currentMonthTargetJs = "";
    }
    await controller.evaluateJavascript(source: currentMonthTargetJs);
  }
}
