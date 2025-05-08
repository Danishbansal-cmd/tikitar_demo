import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
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
  // Removed unused _webViewController field

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
          android: AndroidInAppWebViewOptions(useHybridComposition: true),
        ),
        onWebViewCreated: (controller) {
          // Removed assignment to _webViewController as it is unused
          widget.onWebViewCreated?.call(controller);
        },
        onLoadStop: (controller, url) async {
          final status = await Permission.location.status;
          final hasPermission = status.isGranted;

          // Inject JavaScript with or without 'add' action
          await controller.evaluateJavascript(
            source: _footerNavigationJS(allowAddTask: hasPermission),
          );

          // Get user name from SharedPreferences
          final userData = await DataStorage.getUserData();
          String userName = 'User';

          if (userData != null) {
            try {
              final decoded = jsonDecode(userData);
              userName = decoded['first_name'] ?? userName;
            } catch (e) {
              print("Error decoding user data: $e");
            }
          }

          // Get current date formatted
          final now = DateTime.now();
          final formattedDate = "it’s ${_getWeekday(now.weekday)}, ${_getMonth(now.month)} ${now.day}, ${now.year}";
          final formattedName = "${_getGreetings(now.hour)}, <span>$userName</span>";

          // Inject JS to update name and date in the profile header
          await controller.evaluateJavascript(
            source: _updateProfileHeaderJS(userName: formattedName, formattedDate: formattedDate),
          );

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
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (_) => false,
              );
              return;
            default:
              widget.onConsoleMessage?.call(consoleMessage);
          }
        },
      ),
    );
  }

  String _footerNavigationJS({required bool allowAddTask}) {
    return """
      // Listener for .profile-img
      document.querySelector(".profile-img")?.addEventListener("click", function() {
        console.log("flutter_navigate_to_profile");
      });

      document.querySelector(".menu")?.addEventListener("click", function(e) {
        e.preventDefault();
        console.log("flutter_navigate_to_dashboard");
      });

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
          ${allowAddTask ? """
          icon.removeAttribute("data-bs-toggle");
          icon.removeAttribute("data-bs-target");
          icon.addEventListener("click", function() {
            console.log("flutter_navigate_to_addTask");
          });
          """ : ""}
        }

        if (label === "move_item") {
          icon.addEventListener("click", function() {
            console.log("flutter_navigate_to_logout");
          });
        }
      });
    """;
  }

  String _getWeekday(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }

  String _getGreetings(int hour) {
    print("Current hour: $hour");
    switch (hour) {
      case 0:
      case 1:
      case 2:
      case 3:
      case 4:
      case 5:
        return 'Good Night';
      case 6:
      case 7:
      case 8:
      case 9:
      case 10:
      case 11:
        return 'Good Morning';
      case 12:
      case 13:
      case 14:
      case 15:
      case 16:
        return 'Good Afternoon';
      default:
        return 'Good Evening';
    }
  }

  String _getMonth(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  String _updateProfileHeaderJS({required String userName, required String formattedDate}) {
    return """
      const interval = setInterval(function() {
        const nameSpan = document.querySelector(".profile-name");
        const dateDiv = document.querySelector(".profile-date");

        if (nameSpan && dateDiv) {
          nameSpan.innerHTML = "$userName";
          dateDiv.innerText = "$formattedDate";
          clearInterval(interval);
          console.log("Profile name and date updated by Flutter.");
        }
      }, 300); // check every 300ms
    """;
  }
}
