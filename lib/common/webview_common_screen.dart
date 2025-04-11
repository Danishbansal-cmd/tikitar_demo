import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:tikitar_demo/features/data/local/data_strorage.dart';
import 'package:tikitar_demo/features/data/local/token_storage.dart';

class WebviewCommonScreen extends StatefulWidget {
  final String url;
  final String title;

  final void Function(InAppWebViewController)? onWebViewCreated;
  final void Function(ConsoleMessage)? onConsoleMessage;
  final void Function(InAppWebViewController, Uri?)? onLoadStop;

  const WebviewCommonScreen({
    Key? key,
    required this.url,
    required this.title,
    this.onWebViewCreated,
    this.onConsoleMessage,
    this.onLoadStop,
  }) : super(key: key);

  @override
  State<WebviewCommonScreen> createState() => _WebviewCommonScreenState();
}

class _WebviewCommonScreenState extends State<WebviewCommonScreen> {
  InAppWebViewController? _webViewController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(widget.url)),
        initialOptions: InAppWebViewGroupOptions(
          crossPlatform: InAppWebViewOptions(
            javaScriptEnabled: true,
            useOnDownloadStart: true,
            useShouldOverrideUrlLoading: true,
            mediaPlaybackRequiresUserGesture: false,
          ),
          android: AndroidInAppWebViewOptions(
            useHybridComposition: true,
          ),
        ),
        onWebViewCreated: (controller) {
          _webViewController = controller;
          widget.onWebViewCreated?.call(controller);
        },
        onLoadStop: (controller, url) async {
          // Inject shared footer event listeners
          await controller.evaluateJavascript(source: _footerNavigationJS());
          widget.onLoadStop?.call(controller, url);
        },
        onConsoleMessage: (controller, consoleMessage) async {
          final message = consoleMessage.message;
          switch (message) {
            case "flutter_navigate_to_profile":
              Navigator.pushReplacementNamed(context, '/profile');
              return;
            case "flutter_navigate_to_companyList":
              Navigator.pushReplacementNamed(context, '/companyList');
              return;
            case "flutter_navigate_to_meetingList":
              Navigator.pushReplacementNamed(context, '/meetingList');
              return;
            case "flutter_navigate_to_addTask":
              Navigator.pushReplacementNamed(context, '/addTask');
              return;
            case "flutter_navigate_to_dashboard":
              Navigator.pushReplacementNamed(context, '/dashboard');
              return;
            case "flutter_navigate_to_logout":
              await TokenStorage.clearToken();
              await DataStorage.clearUserClientsData();
              Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
              return;
            default:
              widget.onConsoleMessage?.call(consoleMessage);
          }
        },
      ),
    );
  }

  String _footerNavigationJS() {
    return """
      // Listener for .profile-img
      document.querySelector(".profile-img")?.addEventListener("click", function() {
        console.log("flutter_navigate_to_profile");
      });

      document.querySelector(".menu")?.addEventListener("click", function(e) {
        e.preventDefault(); // Prevent default anchor behavior
        console.log("flutter_navigate_to_dashboard");
      });

      // Handle footer icons
      const footerIcons = document.querySelectorAll(".material-symbols-outlined");
      footerIcons.forEach((icon) => {
        const label = icon.innerText.trim();

        if (label === "account_circle") {
          icon.addEventListener("click", function() {
            console.log("flutter_navigate_to_profile");
          });
        }

        if (label === "format_list_numbered") {
          icon.addEventListener("click", function() {
            console.log("flutter_navigate_to_companyList");
          });
        }

        if (label === "factory") {
          icon.addEventListener("click", function() {
            console.log("flutter_navigate_to_meetingList");
          });
        }

        if (label === "add") {
          icon.removeAttribute("data-bs-toggle");
          icon.removeAttribute("data-bs-target");
          icon.addEventListener("click", function() {
            console.log("flutter_navigate_to_addTask");
          });
        }

        if (label === "move_item") {
          icon.addEventListener("click", function() {
            console.log("flutter_navigate_to_logout");
          });
        }
      });
    """;
  }
}
