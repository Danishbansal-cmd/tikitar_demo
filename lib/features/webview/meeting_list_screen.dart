import 'package:flutter/material.dart';
import 'package:tikitar_demo/common/webview_common_screen.dart';

class MeetingListScreen extends StatefulWidget {
  const MeetingListScreen({super.key});

  @override
  State<MeetingListScreen> createState() => _MeetingListScreenState();
}

class _MeetingListScreenState extends State<MeetingListScreen> {
  @override
  Widget build(BuildContext context) {
    return const WebviewCommonScreen(
      url: "https://tikidemo.com/tikitar-app/dev/meeting-list.php",
      title: "Meeting List",
    );
  }
}