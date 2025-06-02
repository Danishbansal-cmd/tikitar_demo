import 'package:flutter/material.dart';
import 'package:tikitar_demo/common/webview_common_screen.dart';
import 'package:tikitar_demo/features/webview/meeting_list_screen.dart';

class UserMeetings extends StatefulWidget {
  // these two are the variables that are passed from the dashboard screen
  // it indicates the variables belong to person that report to currently logged user
  final int userId;
  final String userName;

  const UserMeetings({super.key, required this.userId, required this.userName});

  @override
  State<UserMeetings> createState() => _UserMeetingsState();
}

class _UserMeetingsState extends State<UserMeetings> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(), // navigate back
        ),
        title: Text(widget.userName),
        backgroundColor: const Color(0xFFFECC00), 
        foregroundColor: Colors.white, // Optional: sets title and icon color
        elevation: 2,
      ),
      body: WebviewCommonScreen(
        url: "usermeetings.php",
        title: "User Meetings Screen",
        onLoadStop: (controller, url) async {
          await fetchAndInjectMeetings(
            controller: controller,
            pageName: "UserMeetings",
            userId: widget.userId,
          );
        },
      ),
    );
  }
}
