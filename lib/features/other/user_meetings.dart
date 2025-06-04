import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:tikitar_demo/common/webview_common_screen.dart';
import 'package:tikitar_demo/features/webview/meeting_list_screen.dart';

class UserMeetings extends StatefulWidget {
  // these two are the variables that are passed from the dashboard screen
  // it indicates the variables belong to person that report to currently logged user
  final int userId;
  final String userName;

  const UserMeetings({super.key, required this.userId, required this.userName});

  @override
  State<UserMeetings> createState() => _UserMeetingsState();
}

class _UserMeetingsState extends State<UserMeetings> {
  InAppWebViewController? _controller;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(), // navigate back
        ),
        title: Text(widget.userName),
        backgroundColor: const Color(0xFFFECC00),
        foregroundColor: Colors.white, // Optional: sets title and icon color
        elevation: 2,
      ),
      body: WebviewCommonScreen(
        url: "usermeetings.php",
        title: "User Meetings Screen",
        onLoadStop: (controller, url) async {
          _controller = controller;
          await fetchAndInjectMeetings(
            controller: controller,
            pageName: "UserMeetings",
            userId: widget.userId,
          );

          await _injectJS();
        },
        onWebViewCreated: (controller) {
          controller.addJavaScriptHandler(
            handlerName: 'onFilterChange',
            callback: (args) {
              final selectedFilter = args[0]; // e.g., "Last 1 Month"
              final fromDateExtracted = args.length > 2 ? args[1] : null;
              final toDateExtracted = args.length > 2 ? args[2] : null;
              
              fetchAndInjectMeetings(
                controller: controller,
                pageName: "UserMeetings",
                userId: widget.userId,
                filter: selectedFilter.toString(), // passing the filter
                fromDatePassed: fromDateExtracted, // passing the fromDate if choosed "Custom Date"
                toDatePassed: toDateExtracted, // passing the toDate if choosed "Custom Date"
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _injectJS() async {
    String JS = """
      function waitForDropdownAndBind() {
        const spans = document.querySelectorAll('#myDropdown span');
        if (spans.length === 0) {
          setTimeout(waitForDropdownAndBind, 300);
          return;
        }

        spans.forEach(span => {
          span.addEventListener('click', function () {
            const selectedFilter = this.textContent.trim();
            if (selectedFilter !== "Custom Date") {
              window.flutter_inappwebview.callHandler('onFilterChange', selectedFilter);
            } else {

              const waitForApplyBtn = setInterval(() => {
                const applyBtn = document.querySelector(".applyBtn.btn.btn-sm.btn-primary[type='button']");
                if (applyBtn) {
                  clearInterval(waitForApplyBtn);
                  console.log("Apply button found, binding click listener");

                  applyBtn.addEventListener('click', function () {
                    setTimeout(() => {
                      const customInput = document.getElementById('customDate');
                      if (customInput) {
                        const value = customInput.value.trim(); // updated value after Apply
                        const parts = value.split(" - ");
                        if (parts.length === 2) {
                          const from = parts[0];
                          const to = parts[1];
                          console.log("Sending to Flutter:", from, to);
                          window.flutter_inappwebview.callHandler('onFilterChange', "Custom Date", from, to);
                        } else {
                          console.warn("Invalid date format:", value);
                        }
                      }
                    }, 200); // 100ms delay to let the input update
                  });
                }
              }, 300);
            }
          });
        });
      }

      waitForDropdownAndBind();
    """;
    await _controller?.evaluateJavascript(source: JS);
  }
}
