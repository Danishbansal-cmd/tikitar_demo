import 'package:flutter/material.dart';
import 'features/webview/webview_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WebviewScreen(url: "https://tikidemo.com/tikitar-app/dev/company-list.php#"),
    );
  }
}
