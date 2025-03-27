import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewAndroid extends StatefulWidget {
  final String url;
  WebViewAndroid({required this.url});

  @override
  State<WebViewAndroid> createState() => _WebViewAndroidState();
}

class _WebViewAndroidState extends State<WebViewAndroid> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted) // Enable JavaScript
      ..loadRequest(Uri.parse(widget.url)); // Load URL
  }

  Future<bool> _onWillPop() async {
    if (await _controller.canGoBack()) {
      _controller.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(title: Text("WebView (Android)")),
        body: WebViewWidget(controller: _controller),
      ),
    );
  }
}