import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:tikitar_demo/common/functions.dart';
import 'package:tikitar_demo/common/webview_common_screen.dart';
import 'package:tikitar_demo/features/auth/meetings_controller.dart';
import 'dart:developer' as developer;

class MeetingListScreen extends StatefulWidget {
  const MeetingListScreen({super.key});

  @override
  State<MeetingListScreen> createState() => _MeetingListScreenState();
}

class _MeetingListScreenState extends State<MeetingListScreen> {
  @override
  Widget build(BuildContext context) {
    return WebviewCommonScreen(
      url: "meeting-list.php",
      title: "Meeting List",
      onLoadStop: (controller, url) async {
        await fetchAndInjectMeetings(
          controller: controller,
          pageName: "MeetingListScreen",
        );
      },
    );
  }
}

Future<void> fetchAndInjectMeetings({
  required InAppWebViewController controller,
  String? pageName,
  int? userId,
}) async {
  try {
    developer.log("User ID being passed: $userId", name: "DashboardScreen");
    final meetingsList = await MeetingsController.userBasedMeetings(userId!);
    developer.log("Meeting list response: $meetingsList", name: "DashboardScreen");

    String tableRowsJS = '''
      <tr>
        <th>S. No.</th>
        <th>Client Name</th>
        <th>Date</th>
        <th>View</th>
      </tr>
    ''';
    String twoDigits(int n) => n.toString().padLeft(2, '0');

    for (int i = 0; i < meetingsList.length; i++) {
      final meeting = meetingsList[i];
      final rank = i + 1;
      // for date, escape new lines and quotes
      final rawDate = meeting['meeting_date'] ?? '';
      String formattedDate = '';
      try {
        final parsedDate = DateTime.parse(rawDate);
        formattedDate =
            "${parsedDate.year}-${twoDigits(parsedDate.month)}-${twoDigits(parsedDate.day)}";
      } catch (e) {
        formattedDate = Functions.escapeJS(rawDate);
      }
      final date = Functions.escapeJS(formattedDate);
      // for comments, escape new lines and quotes
      final comments = Functions.escapeJS(meeting['comments'] ?? '');

      tableRowsJS += """
          <tr>
            <td>$rank</td>
            <td>${meeting['client']['name']}</td>
            <td>$date</td>
            <td>
              <a href="#" class="chat-icon" data-comment="$comments">
                <span class="material-symbols-outlined">chat</span>
              </a>
            </td>
          </tr>
        """;
    }

    developer.log("tableRowJs Data: $tableRowsJS", name: "$pageName");

    // to inject the meetings data with the comments
    injectTableDataWithComments(
      controller: controller,
      tableRowsDataJS: tableRowsJS,
      pageName: pageName,
    );
  } catch (e) {
    developer.log(
      "Error fetching or injecting meeting data: $e",
      name: "$pageName",
    );
  }
}

Future<void> injectTableDataWithComments({
  required controller,
  required String tableRowsDataJS,
  String? pageName,
}) async {
  try {
    final fullJS = """
        const table = document.querySelector('.reporttable');
        const rows = table.querySelectorAll('tr');
        for (let i = rows.length - 1; i > -1; i--) {
          table.deleteRow(i);
        }
        table.insertAdjacentHTML('beforeend', `$tableRowsDataJS`);

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
    developer.log(
      "Error fetching or injecting meeting data: $e",
      name: "$pageName",
    );
  }
}