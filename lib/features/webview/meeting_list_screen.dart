import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:tikitar_demo/common/functions.dart';
import 'package:tikitar_demo/common/webview_common_screen.dart';
import 'package:tikitar_demo/features/auth/meetings_controller.dart';
import 'dart:developer' as developer;

import 'package:tikitar_demo/features/data/local/data_strorage.dart';

class MeetingListScreen extends StatefulWidget {
  const MeetingListScreen({super.key});

  @override
  State<MeetingListScreen> createState() => _MeetingListScreenState();
}

class _MeetingListScreenState extends State<MeetingListScreen> {
  int? userId;

  @override
  void initState() {
    super.initState();
    _initializeMeetingListScreen(); // to initialize the userId variable
  }

  @override
  Widget build(BuildContext context) {
    return WebviewCommonScreen(
      url: "meeting-list.php",
      title: "Meeting List",
      onLoadStop: (controller, url) async {
        await fetchAndInjectMeetings(
          controller: controller,
          pageName: "MeetingListScreen",
          userId: userId
        );
      },
    );
  }

    // Get userData from SharedPreferences, to finally get the userId
  Future<void> _initializeMeetingListScreen() async {
    final userData = await DataStorage.getUserData();
    if (userData != null) {
      final decoded = jsonDecode(userData);
      // converting to int successfully
      userId = int.tryParse(decoded['id'].toString()) ?? 0;
    }
    developer.log("Extracted userId: $userId", name: "TaskScreen");
  }
}

Future<void> showLoadingSpinner(InAppWebViewController controller) async {
  await controller.evaluateJavascript(source: """
    if (!document.getElementById('dataLoader')) {
      const loader = document.createElement('div');
      loader.id = 'dataLoader';
      loader.style.position = 'fixed';
      loader.style.top = '0';
      loader.style.left = '0';
      loader.style.width = '100%';
      loader.style.height = '100%';
      loader.style.display = 'flex';
      loader.style.justifyContent = 'center';
      loader.style.alignItems = 'center';
      loader.style.background = 'rgba(255, 255, 255, 0.7)';
      loader.style.zIndex = '2000';
      loader.innerHTML = '<div style="width: 50px; height: 50px; border: 6px solid #ccc; border-top: 6px solid #fecc00; border-radius: 50%; animation: spin 1s linear infinite;"></div>';

      const style = document.createElement('style');
      style.innerHTML = \`
        @keyframes spin {
          0% { transform: rotate(0deg); }
          100% { transform: rotate(360deg); }
        }
      \`;
      document.head.appendChild(style);

      document.body.appendChild(loader);
    }
  """);
}


Future<void> fetchAndInjectMeetings({
  required InAppWebViewController controller,
  String? pageName,
  int? userId,
}) async {
  String tableRowsJS = '''
    <tr>
      <th>S. No.</th>
      <th>Client Name</th>
      <th>Date</th>
      <th>View</th>
    </tr>
  ''';
  try {
    // ✅ Show loading spinner immediately
    await showLoadingSpinner(controller);

    developer.log("User ID being passed: $userId", name: "DashboardScreen");
    final response = await MeetingsController.userBasedMeetings(userId!);
    final List<dynamic> meetingsList = response['data'] ?? [];

    developer.log("Meeting list response: $meetingsList", name: "DashboardScreen");

    String twoDigits(int n) => n.toString().padLeft(2, '0');

    for (int i = 0; i < meetingsList.length; i++) {
      final meeting = meetingsList[i];
      if (meeting == null) continue; // Skip if null
      final rank = i + 1;
      // for date, escape new lines and quotes
      final rawDate = meeting['meeting_date'] ?? '';
      final contactPersonMobile = meeting['contact_person_mobile'] ?? '';
      final contactPersonEmail = meeting['contact_person_email'] ?? '';
      final clientName = meeting['client'] != null
        ? Functions.escapeJS(meeting['client']['name'] ?? '')
        : 'N/A';
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

      // to insert the link of the file that is being submitted during the meeting
      // it contains the link
      final visitingCardUrl = Functions.escapeJS(meeting['visiting_card'] ?? '');

      tableRowsJS += """
          <tr>
            <td>$rank</td>
            <td>$clientName</td>
            <td>$date</td>
            <td>
              <a href="#" 
              class="chat-icon" 
              data-contact-person-mobile="$contactPersonMobile"
              data-contact-person-email="$contactPersonEmail"
              data-comment="$comments"
              data-pdf="https://app.tikitar.com/storage/app/public/$visitingCardUrl">
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
  // Remove loading spinner
  const loaderToRemove = document.getElementById('dataLoader');
  if (loaderToRemove) loaderToRemove.remove();
  
  const table = document.querySelector('.reporttable');
  const rows = table.querySelectorAll('tr');
  for (let i = rows.length - 1; i > -1; i--) {
    table.deleteRow(i);
  }
  table.insertAdjacentHTML('beforeend', `$tableRowsDataJS`);

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
          position: absolute;
          top: 0px;
          right: 0px;
          cursor: pointer;
          font-size: 32px;
          padding: 8px 20px;
          background-color: #fecc00;
          color: #fff;
          border-radius: 4px;
          font-weight: bold;
          transition: background-color 0.3s ease;
        ">&times;</span>
        <div style="font-weight: bold; font-size: 18px; margin-bottom: 10px;">Meeting Details</div>
        <div id="commentContent" style="white-space: normal; margin-bottom: 20px; line-height: 1.5;"></div>
        <button id="openPdfBtn" style="padding: 10px 15px; background-color: #007BFF; color: white; border: none; border-radius: 5px;">View Attachment</button>
      </div>
    \`;
    document.body.appendChild(modal);
    document.getElementById('closeModal').onclick = () => {
      modal.style.display = 'none';
    }
  }

  document.querySelectorAll('.chat-icon').forEach(el => {
    el.addEventListener('click', function(e) {
      e.preventDefault();
      const clientName = this.closest('tr').children[1].innerText;
      const date = this.closest('tr').children[2].innerText;
      const contactEmail = this.getAttribute('data-contact-person-email');
      const contactMobile = this.getAttribute('data-contact-person-mobile');
      const comment = this.getAttribute('data-comment');
      const pdfUrl = this.getAttribute('data-pdf');

      const contentHtml = \`
        <div><b>Client Name:</b> \${clientName}</div>
        <div><b>Meeting Date:</b> \${date}</div>
        <div><b>Contact Person Email:</b> \${contactEmail}</div>
        <div><b>Contact Person Mobile:</b> \${contactMobile}</div>
        <div><b>Comments:</b> \${comment}</div>
      \`;

      document.getElementById('commentContent').innerHTML = contentHtml;
      document.getElementById('commentModal').style.display = 'flex';

      document.getElementById('openPdfBtn').onclick = () => {
        window.flutter_inappwebview.callHandler('openPdfExternally', pdfUrl);
      };
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