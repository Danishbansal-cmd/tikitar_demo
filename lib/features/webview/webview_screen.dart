import 'package:flutter/material.dart';
import 'dart:io' show Platform;

// Ensure correct imports
import 'webview_android.dart';
import 'webview_ios.dart';

class WebviewScreen extends StatelessWidget {
  final String url;
  WebviewScreen({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      return WebViewAndroid(url: url);
    } else if (Platform.isIOS) {
      return WebViewIOS(url: url);
    } else {
      return Scaffold(
        appBar: AppBar(title: Text("Unsupported Platform")),
        body: Center(child: Text("WebView is not supported on this platform.")),
      );
    }
  }
}
