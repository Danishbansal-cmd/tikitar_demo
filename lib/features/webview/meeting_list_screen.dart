import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:tikitar_demo/common/webview_common_screen.dart';
import 'package:tikitar_demo/core/network/api_base.dart';
import 'package:tikitar_demo/features/data/local/token_storage.dart';

class MeetingListScreen extends StatefulWidget {
  const MeetingListScreen({super.key});

  @override
  State<MeetingListScreen> createState() => _MeetingListScreenState();
}

class _MeetingListScreenState extends State<MeetingListScreen> {
  InAppWebViewController? _controller;

  @override
  Widget build(BuildContext context) {
    return WebviewCommonScreen(
      url: "https://tikidemo.com/tikitar-app/dev/meeting-list.php",
      title: "Meeting List",
      onWebViewCreated: (controller) {
        _controller = controller;
      },
      onLoadStop: (controller, url) async {
        await _fetchAndInjectMeetings(controller);
      },
    );
  }

  Future<void> _fetchAndInjectMeetings(InAppWebViewController controller) async {
    final token = await TokenStorage.getToken();
    if (token == null) return;

    try {
      final response = await ApiBase.get('/meetings/user', token: token);
      final meetings = response['data']?['meetings'] ?? [];

      String tableRowsJS = '';
      for (int i = 0; i < meetings.length; i++) {
        final meeting = meetings[i];
        final rank = i + 1;
        final name = _escapeJS(meeting['client']?['name'] ?? '');
        final date = _escapeJS(meeting['created_at'] ?? '');
        final comments = _escapeJS(meeting['comments'] ?? '');

        tableRowsJS += """
          <tr>
            <td>$rank</td>
            <td>$name</td>
            <td>$date</td>
            <td><a href="#"><span class="material-symbols-outlined">chat</span></a></td>
          </tr>
        """;
      }

      final fullJS = """
        const table = document.querySelector('.reporttable');
        const rows = table.querySelectorAll('tr');
        for (let i = rows.length - 1; i > 0; i--) {
          table.deleteRow(i);
        }
        table.insertAdjacentHTML('beforeend', `$tableRowsJS`);
      """;

      await controller.evaluateJavascript(source: fullJS);
    } catch (e) {
      print("Error fetching or injecting meeting data: $e");
    }
  }

  /// Escapes strings to safely inject into JavaScript
  String _escapeJS(String? value) {
    if (value == null) return '';
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll(r'"', r'\"')
        .replaceAll(r'\n', r'\\n')
        .replaceAll("'", r"\'");
  }
}
