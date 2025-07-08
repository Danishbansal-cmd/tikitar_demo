import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tikitar_demo/common/constants.dart';
import 'package:tikitar_demo/features/data/local/data_strorage.dart';
import 'package:tikitar_demo/features/other/user_meetings.dart';
import 'package:tikitar_demo/features/webview/meeting_list_screen.dart';
import 'dart:developer' as developer;
import 'package:url_launcher/url_launcher.dart';

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

bool _hasError = false;
bool _isLoading = true;

class _WebviewCommonScreenState extends State<WebviewCommonScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (_isLoading)
            Container(
              color: Colors.white,
              child: const Center(child: CircularProgressIndicator()),
            ),

          _hasError
              ? _buildErrorView()
              : InAppWebView(
                // this settings help to remove the black screen that appears
                //when the webview is loading and when moving between screens
                initialSettings: InAppWebViewSettings(
                  transparentBackground: true,
                ),
                initialUrlRequest: URLRequest(
                  url: WebUri("$baseUrl${widget.url}"),
                ),
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
                  widget.onWebViewCreated?.call(controller);

                  controller.addJavaScriptHandler(
                    handlerName: "HANDLE_NAVIGATION",
                    callback: (args) async {
                      // args[0] is finalPayload from JavaScript
                      developer.log(
                        "Received payload from webview_common_screen: ${args[0]}",
                        name: 'WebviewCommonScreen',
                      );

                      // handling the navigation based on what icon they have clicked
                      final message = args[0];
                      switch (message) {
                        case "flutter_navigate_to_profile":
                          Get.offNamed('/profile');
                          return;
                        case "flutter_navigate_to_companyList":
                          Get.offNamed('/companyList');
                          return;
                        case "flutter_navigate_to_meetingList":
                          Get.offNamed('/meetingList');
                          return;
                        case "flutter_navigate_to_addTask":
                          Get.offNamed('/addTask');
                          return;
                        case "flutter_navigate_to_dashboard":
                          Get.offNamed('/dashboard');
                          return;
                        case "flutter_navigate_to_logout":
                          bool? confirmed = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text("Logout"),
                                content: Text(
                                  "Are you sure you want to logout?",
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Get.back(result: false),
                                    child: Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () => Get.back(result: true),
                                    child: Text("Sure"),
                                  ),
                                ],
                              );
                            },
                          );

                          if (confirmed == true) {
                            await DataStorage.clearToken();
                            await DataStorage.clearUserData();
                            await DataStorage.clearShowGaugesBoolean();
                            await DataStorage.clearShowBonusMetricBoolean();
                            Get.offAllNamed('/login');
                          }
                          await controller.evaluateJavascript(
                            source: """
                              // resetting the color of the icon to default color
                              var moveItemElement = Array.from(document.querySelectorAll(".material-symbols-outlined")).find(el => el.textContent.trim() === "move_item");
                              moveItemElement.style.color = "#838383";
                            """,
                          );
                          return;
                        default:
                          developer.log(
                            "It should not come here never:",
                            name: "WebviewCommonScreen",
                          );
                      }
                    },
                  );

                  controller.addJavaScriptHandler(
                    // it is the handler to view the user's meeting, when the user
                    // click on the visibility button in the dashboard page
                    handlerName: 'onUserViewClick',
                    callback: (args) async {
                      final userId = int.tryParse(args[0].toString()) ?? 0;
                      final userName = args[1]?.toString() ?? '';
                      developer.log(
                        "Navigating to meetings of user $userName ($userId)",
                      );
                      developer.log("I came here");
                      developer.log("Clicked userId: $userId");

                      Get.to(
                        () => UserMeetings(userId: userId, userName: userName),
                      );
                    },
                  );

                  controller.addJavaScriptHandler(
                    handlerName: 'openPdfExternally',
                    callback: (args) async {
                      if (args.isNotEmpty) {
                        final url = args[0];
                        final Uri uri = Uri.parse(url);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        } else {
                          developer.log("Could not launch PDF URL: \$url");
                        }
                      }
                    },
                  );
                },
                onLoadStart: (controller, url) {
                  showLoadingSpinner(controller); // ✅ Show loader when navigation starts
                },
                onLoadStop: (controller, url) async {
                  // it disables the user select
                  await controller.evaluateJavascript(
                    source: """
                    const style = document.createElement('style');
                    style.innerHTML = `
                      * {
                        -webkit-user-select: none !important;
                        -moz-user-select: none !important;
                        -ms-user-select: none !important;
                        user-select: none !important;
                      }
                    `;
                    document.head.appendChild(style);
                  """,
                  );

                  // Check if the widget is still mounted before proceeding
                  // A State object is considered "mounted" when it is associated
                  //with a BuildContext and is part of the widget tree.
                  if (!mounted || _hasError) return;

                  // Set loading state to true
                  if (mounted && !_hasError) {
                    setState(() {
                      _isLoading = false;
                    });
                  }

                  try {
                    final status = await Permission.location.status;
                    final hasPermission = status.isGranted;

                    // widget.url provides the actual url of the webpage that we are
                    // rendering in the current context or in app
                    final sendUrl = _getActiveIconLabel(widget.url);
                    developer.log(
                      "widget.url ${widget.url}",
                      name: "WebviewCommonScreen",
                    );
                    developer.log(
                      "sendUrl $sendUrl",
                      name: "WebviewCommonScreen",
                    );

                    // Inject JavaScript with or without 'add' action
                    await controller.evaluateJavascript(
                      source: _footerNavigationJS(
                        allowAddTask: hasPermission,
                        // added this field to send the label's text, based on which the
                        // specific icon is colored
                        activeIconLabel: sendUrl,
                        currentRoute: widget.url,
                      ),
                    );

                    // Get user name from SharedPreferences
                    final userData = await DataStorage.getUserData();
                    String userName = 'User';

                    if (userData != null) {
                      final decoded = jsonDecode(userData);
                      userName = decoded['first_name'] ?? userName;
                    }

                    // Change the logo of the User
                    controller.evaluateJavascript(
                      source: _changeUserLogo(
                        firstLetter: userName.trim()[0].toUpperCase(),
                      ),
                    );

                    // Get current date formatted
                    final now = DateTime.now();
                    final formattedDate =
                        "it’s ${_getWeekday(now.weekday)}, ${_getMonth(now.month)} ${now.day}, ${now.year}";
                    final formattedName =
                        "${_getGreetings(now.hour)}, <span>$userName</span>";

                    // Inject JS to update name and date in the profile header
                    await controller.evaluateJavascript(
                      source: _updateProfileHeaderJS(
                        userName: formattedName,
                        formattedDate: formattedDate,
                      ),
                    );

                    // ✅ Call the external callback if provided
                    widget.onLoadStop?.call(controller, url);
                  } catch (e) {
                    developer.log(
                      "Error in onLoadStop: $e",
                      name: "WebviewCommonScreen",
                      error: e,
                    );
                  }
                },
                // This callback is triggered when the webview
                //encounters an error while loading a URL.
                onLoadError: (controller, url, code, message) {
                  setState(() {
                    _hasError = true;
                    _isLoading = false;
                  });
                },
                // This callback is triggered when the webview
                //encounters an HTTP error (e.g., 404 or 500)
                //while loading a URL.
                onLoadHttpError: (controller, url, statusCode, description) {
                  setState(() {
                    _hasError = true;
                  });
                },
              ),
        ],
      ),
    );
  }

  String _footerNavigationJS({
    required bool allowAddTask,
    String? activeIconLabel,
    required String currentRoute,
  }) {
    return """
      var currentRoute = "$currentRoute";

      // selecting the tag with class ".profile-img" and storing it
      var profileImageSelector = document.querySelector(".profile-img");
      
      // Adding the Listener for the "profileImageSelector"
      profileImageSelector?.addEventListener("click", function() {
        if(currentRoute !== "myprofile.php"){
          window.flutter_inappwebview.callHandler("HANDLE_NAVIGATION", "flutter_navigate_to_profile");
        }
      });

      document.querySelector(".menu")?.addEventListener("click", function(e) {
        e.preventDefault();
        if(currentRoute !== "dashboard.php"){
          window.flutter_inappwebview.callHandler("HANDLE_NAVIGATION", "flutter_navigate_to_dashboard");
        }
      });

      const footerIcons = document.querySelectorAll(".material-symbols-outlined");
      footerIcons.forEach((icon, index) => {
        const label = icon.innerText.trim();

        if (label === "account_circle") {
          icon.addEventListener("click", function() {
            if(currentRoute !== "myprofile.php"){
              window.flutter_inappwebview.callHandler("HANDLE_NAVIGATION", "flutter_navigate_to_profile");
            }
          });
        }

        if (label === "format_list_numbered") {
          icon.addEventListener("click", function() {
            if(currentRoute !== "meeting-list.php"){
              window.flutter_inappwebview.callHandler("HANDLE_NAVIGATION", "flutter_navigate_to_meetingList");
            }
          });
        }

        if (label === "factory") {
          icon.addEventListener("click", function() {
            if(currentRoute !== "company-list.php"){
              window.flutter_inappwebview.callHandler("HANDLE_NAVIGATION", "flutter_navigate_to_companyList");
            }
          });
        }

        if (label === "add") {
          ${allowAddTask ? """
          icon.removeAttribute("data-bs-toggle");
          icon.removeAttribute("data-bs-target");
          icon.addEventListener("click", function() {
            if(currentRoute !== "task.php"){
              window.flutter_inappwebview.callHandler("HANDLE_NAVIGATION", "flutter_navigate_to_addTask");
            }
          });
          """ : ""}
        }

        if (label === "move_item") {
          icon.addEventListener("click", function() {
            window.flutter_inappwebview.callHandler("HANDLE_NAVIGATION", "flutter_navigate_to_logout");
            icon.style.color = "#fecc00";
          });
        }

        // style the color to the selected page's icon or label
        if(label == "$activeIconLabel"){
          icon.style.color = "#fecc00";
        }
      });
    """;
  }

  // get the activeIconLabel based on the widget.url that we would pass it
  String? _getActiveIconLabel(String path) {
    // for three pages only
    if (path.contains("myprofile")) return "account_circle";
    if (path.contains("meeting-list")) return "format_list_numbered";
    if (path.contains("company-list")) return "factory";
    return "";
  }

  String _getWeekday(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[weekday - 1];
  }

  String _getGreetings(int hour) {
    developer.log("Current hour: $hour", name: "WebviewCommonScreen");
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
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  String _updateProfileHeaderJS({
    required String userName,
    required String formattedDate,
  }) {
    return """
      var interval = setInterval(function() {
        const nameSpan = document.querySelector(".profile-name");
        const dateDiv = document.querySelector(".profile-date");

        if (nameSpan && dateDiv) {
          nameSpan.innerHTML = "$userName";
          dateDiv.innerText = "$formattedDate";
          clearInterval(interval);
        }
      }, 300); // check every 300ms
    """;
  }

  // This method builds the error view when
  //an error occurs.
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/svg/warning.svg', // Replace with your image or GIF
            height: 200,
          ),
          const SizedBox(height: 20),
          const Text(
            'Oops! Something went wrong.',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Please check your internet connection or try again later.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _hasError = false;
              });
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // this is function to change the Logo on the top right corner
  // to the first Letter of the userName
  String _changeUserLogo({String? firstLetter}) {
    return """
    if(profileImageSelector){
      profileImageSelector.innerHTML = `
        <span style="
          display: inline-block;
          width: 40px;
          height: 40px;
          background-color: #fecc00;
          color: white;
          font-weight: bold;
          font-size: 32px;
          border-radius: 50%;
          text-align: center;
          line-height: 40px;
        ">
          $firstLetter
        </span>
      `;
    }
  """;
  }
}
