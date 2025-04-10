import 'package:flutter/material.dart';
import 'package:tikitar_demo/common/webview_common_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return const WebviewCommonScreen(
      url: "https://tikidemo.com/tikitar-app/dev/dashboard.php",
      title: "Dashboard",
    );
  }
}