import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebviewCommonScreen extends StatefulWidget {
  final String url;
  final String title;

  const WebviewCommonScreen({Key? key, required this.url, required this.title}) : super(key: key);

  @override
  State<WebviewCommonScreen> createState() => _WebviewCommonScreenState();
}

class _WebviewCommonScreenState extends State<WebviewCommonScreen> {
  late final WebViewController _controller;

    @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: WebViewWidget(controller: _controller), // Use WebViewWidget instead of WebView
    );
  }
}