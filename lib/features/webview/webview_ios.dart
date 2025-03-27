import 'package:flutter/cupertino.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewIOS extends StatefulWidget {
  final String url;
  WebViewIOS({required this.url});

  @override
  State<WebViewIOS> createState() => _WebViewIOSState();
}

class _WebViewIOSState extends State<WebViewIOS> {
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
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text("WebView (iOS)")),
      child: WebViewWidget(controller: _controller),
    );
  }
}