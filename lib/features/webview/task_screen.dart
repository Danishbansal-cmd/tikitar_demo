import 'package:flutter/material.dart';
import 'package:tikitar_demo/common/webview_common_screen.dart';

class TaskScreen extends StatefulWidget {
  @override
  _TaskScreenState createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  @override
  Widget build(BuildContext context) {
    return const WebviewCommonScreen(
      url: "https://tikidemo.com/tikitar-app/dev/task.php",
      title: "Task",
    );
  }
}
