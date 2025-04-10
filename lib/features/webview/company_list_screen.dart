import 'package:flutter/material.dart';
import 'package:tikitar_demo/common/webview_common_screen.dart';

class CompanyListScreen extends StatefulWidget {
  const CompanyListScreen({super.key});

  @override
  State<CompanyListScreen> createState() => _CompanyListScreenState();
}

class _CompanyListScreenState extends State<CompanyListScreen> {
  @override
  Widget build(BuildContext context) {
    return const WebviewCommonScreen(
      url: "https://tikidemo.com/tikitar-app/dev/company-list.php",
      title: "Company List",
    );
  }
}