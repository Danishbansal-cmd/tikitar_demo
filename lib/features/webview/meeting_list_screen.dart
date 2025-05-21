import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:tikitar_demo/common/functions.dart';
import 'package:tikitar_demo/common/webview_common_screen.dart';
import 'package:tikitar_demo/core/network/api_base.dart';
import 'dart:developer' as developer;

import 'package:tikitar_demo/features/data/local/data_strorage.dart';

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
    developer.log("User ID being passed: $userId", name: "$pageName");
    final response = await ApiBase.get('/meetings/user/$userId');
    developer.log("Meeting list response: $response", name: "$pageName");
    final meetings = response['data'] ?? [];

    String tableRowsJS = '';
    String twoDigits(int n) => n.toString().padLeft(2, '0');

    for (int i = 0; i < meetings.length; i++) {
      final meeting = meetings[i];
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
            <td>${meeting['user_id']}</td>
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

Future<void> fetchAndInjectUsers({
  required InAppWebViewController controller,
  String? pageName,
}) async {
  try {
    // Get userData from SharedPreferences
    final userData = await DataStorage.getUserData();
    int userId = 0;

    if (userData != null) {
      final decoded = jsonDecode(userData);
      userId = int.tryParse(decoded['id'].toString()) ?? 0;
    }

    developer.log("Extracted userId: $userId", name: "$pageName");

    final response = await ApiBase.get('/specific-employees/$userId');
    developer.log("User list response: $response", name: "$pageName");

    if (response['data'] == null) {
      developer.log("response['data'] was null so here", name: "$pageName");
      fetchAndInjectMeetings(
        controller: controller,
        pageName: pageName,
        userId: userId,
      );
      return;
    }

    final users = response['data']?['employees'] ?? [];

    String tableRowsJS = '';
    for (int i = 0; i < users.length; i++) {
      final user = users[i];
      final rank = i + 1;
      final name = Functions.escapeJS(user['name'] ?? '');
      final role = Functions.escapeJS(user['role'] ?? '');

      tableRowsJS += """
          <tr>
            <td>$rank</td>
            <td>$name</td>
            <td>$role</td>
            <td>
              <a class="popup-link" href="#viewcompanydetails">
                <span class="material-symbols-outlined">
                  visibility
                </span>
              </a>
            </td>
          </tr>
        """;
    }

    // to insert the data with comments into the table
    // here needs to change for the view, to let them view all the meetings of the user
    // that works under them
    injectTableDataWithComments(
      controller: controller,
      tableRowsDataJS: tableRowsJS,
      pageName: pageName,
    );
  } catch (e) {
    developer.log(
      "Error fetching or injecting User Report data: $e",
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
        for (let i = rows.length - 1; i > 0; i--) {
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
