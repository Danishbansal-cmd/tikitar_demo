import 'package:flutter/material.dart';
import 'package:tikitar_demo/common/webview_common_screen.dart';
import 'package:tikitar_demo/core/network/api_base.dart';
import 'package:tikitar_demo/features/data/local/token_storage.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  InAppWebViewController? _controller;

  @override
  Widget build(BuildContext context) {
    return WebviewCommonScreen(
      url: "https://tikidemo.com/tikitar-app/dev/myprofile.php",
      title: "My Profile",
      onWebViewCreated: (controller) {
        _controller = controller;
      },
      onLoadStop: (controller, url) async {
        await _fetchAndInjectUserProfile(controller);
      },
    );
  }

  Future<void> _fetchAndInjectUserProfile(InAppWebViewController controller) async {
    final token = await TokenStorage.getToken();
    if (token == null) return;

    try {
      final response = await ApiBase.get('/user', token: token);
      print("User profile: $response");
      final data = response['data']?['user'];
      print("User data address: ${data['address']['line1']}");
      print("User data city: ${data['address']['city']}");
      print("User data zip: ${data['address']['zip']}");
      print("User data state: ${data['address']['state']}");

      if (data != null) {
        final address = data['address'] ?? {};

        final js = """
          document.getElementById("firstName").value = "${_escapeJS(data['first_name'])}";
          document.getElementById("lastName").value = "${_escapeJS(data['last_name'])}";
          document.getElementById("mobile").value = "${_escapeJS(data['mobile'])}";
          document.getElementById("whatsappnumber").value = "${_escapeJS(data['mobile'])}";
          document.getElementById("email").value = "${_escapeJS(data['email'])}";
          document.getElementById("jobtitle").value = "${_escapeJS(data['designation'])}";
          document.getElementById("address").value = `${_escapeJS(address['line1'])}`;
          document.getElementById("city").value = "${_escapeJS(address['city'])}";
          document.getElementById("zip").value = "${_escapeJS(address['zip'])}";
          document.getElementById("state").value = "${_escapeJS(address['state'])}";
        """;

        await controller.evaluateJavascript(source: js);
      }
    } catch (e) {
      print("Error injecting user data: $e");
    }
  }

  /// Escapes strings to safely inject into JavaScript
  String _escapeJS(String? value) {
    if (value == null) return '';
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll(r'"', r'\"')
        .replaceAll(r'\n', r'\\n')
        .replaceAll("'", r"\'");
  }
}
