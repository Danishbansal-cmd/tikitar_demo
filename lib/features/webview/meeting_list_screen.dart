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

  Future<void> _fetchAndInjectMeetings(
    InAppWebViewController controller,
  ) async {
    final token = await TokenStorage.getToken();
    if (token == null) return;

    try {
      final response = await ApiBase.get('/meetings/user', token: token);
      print("Meeting list response: $response");
      final meetings = response['data']?['meetings'] ?? [];

      String tableRowsJS = '';
      String twoDigits(int n) => n.toString().padLeft(2, '0');

      for (int i = 0; i < meetings.length; i++) {
        final meeting = meetings[i];
        final rank = i + 1;
        final name = _escapeJS(meeting['client']?['name'] ?? '');
        // for date, escape new lines and quotes
        final rawDate = meeting['meeting_date'] ?? '';
        String formattedDate = '';
        try {
          final parsedDate = DateTime.parse(rawDate);
          formattedDate =
              "${parsedDate.year}-${twoDigits(parsedDate.month)}-${twoDigits(parsedDate.day)}";
        } catch (e) {
          formattedDate = _escapeJS(rawDate);
        }
        final date = _escapeJS(formattedDate);
        // for comments, escape new lines and quotes
        final comments = _escapeJS(meeting['comments'] ?? '');

        tableRowsJS += """
          <tr>
            <td>$rank</td>
            <td>$name</td>
            <td>$date</td>
            <td>
              <a href="#" class="chat-icon" data-comment="$comments">
                <span class="material-symbols-outlined">chat</span>
              </a>
            </td>
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

        // Create popup modal if not exists
        if (!document.getElementById('commentModal')) {
          const modal = document.createElement('div');
          modal.id = 'commentModal';
          modal.style.position = 'fixed';
          modal.style.top = '0';
          modal.style.left = '0';
          modal.style.width = '100%';
          modal.style.height = '100%';
          modal.style.backgroundColor = 'rgba(0,0,0,0.5)';
          modal.style.display = 'none';
          modal.style.justifyContent = 'center';
          modal.style.alignItems = 'center';
          modal.style.zIndex = '1000';
          modal.innerHTML = \`
            <div style="background:#fff; padding:25px 15px; border-radius:8px; max-width:90%; max-height:80%; overflow:auto; position:relative;">
              <span id="closeModal" style="
                position:absolute;
                top:0px;
                right:0px;
                cursor:pointer;
                font-size:20px;
                padding:0px 10px;
                background-color:#f0f0f0;
                border-radius:8px;
                transition:background-color 0.2s ease;
              ">&times;</span>
              <div id="commentContent" style="white-space:pre-wrap;"></div>
            </div>
          \`;
          document.body.appendChild(modal);

          document.getElementById('closeModal').onclick = () => {
            modal.style.display = 'none';
          }
        }

        // Attach click events
        document.querySelectorAll('.chat-icon').forEach(el => {
          el.addEventListener('click', function(e) {
            e.preventDefault();
            const comment = this.getAttribute('data-comment');
            document.getElementById('commentContent').innerText = comment;
            document.getElementById('commentModal').style.display = 'flex';
          });
        });
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
