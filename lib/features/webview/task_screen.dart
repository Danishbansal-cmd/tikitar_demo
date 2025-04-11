import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:tikitar_demo/common/webview_common_screen.dart';
import 'package:tikitar_demo/core/network/api_base.dart';
import 'package:tikitar_demo/features/auth/meetings_controller.dart';
import 'package:tikitar_demo/features/data/local/data_strorage.dart';
import 'package:tikitar_demo/features/data/local/token_storage.dart';
import 'dart:convert';
  import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

class TaskScreen extends StatefulWidget {
  @override
  _TaskScreenState createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  InAppWebViewController? _controller;
  List<Map<String, dynamic>> fields = [];

  @override
  Widget build(BuildContext context) {
    return WebviewCommonScreen(
      url: "https://tikidemo.com/tikitar-app/dev/task.php",
      title: "Task",
      onWebViewCreated: (controller) {
        _controller = controller;
      },
      onLoadStop: (controller, url) async {
        await fetchCurrentUsersClients();
      },
      onConsoleMessage: (consoleMessage) {
        if (consoleMessage.messageLevel == ConsoleMessageLevel.LOG &&
            consoleMessage.message.startsWith("SUBMIT_DATA::")) {
          final jsonData = consoleMessage.message.replaceFirst("SUBMIT_DATA::", "");
          final data = json.decode(jsonData);
          _submitMeetingData(data);
        }
      },
    );
  }

  Future<void> fetchCurrentUsersClients() async {
    try {
      final storedData = await DataStorage.getUserClientsData();
      if (storedData == null) {
        print("No stored client data found.");
        return;
      }

      final clients = jsonDecode(storedData) as List<dynamic>;

      fields = clients.map<Map<String, dynamic>>((client) {
        return {
          'id': client['id'],
          'name': client['name'],
        };
      }).toList();

      // Build option list
      String optionsHTML = '<option selected>Contact Person</option>';
      for (var client in fields) {
        final id = _escapeJS(client['id'].toString());
        final name = _escapeJS(client['name'].toString());
        optionsHTML += '<option value="$id">$name</option>';
      }

      // Inject JS
      final jsToInject = """
        const selects = document.querySelectorAll('select.form-select[placeholder="Contact Person"]');
        selects.forEach(select => {
          select.innerHTML = `$optionsHTML`;
        });

        const submitBtn = document.querySelector('button.btn.btn-primary[type="submit"]');
        if (submitBtn) {
          submitBtn.addEventListener('click', function(event) {
            event.preventDefault();

            const contactPerson = document.querySelector('select.form-select[placeholder="Contact Person"]')?.value || '';
            const contactMobile = document.querySelector('input.form-control[placeholder="Contact Person Mobile"]')?.value || '';
            const contactEmail = document.querySelector('input.form-control[placeholder="Contact Person Email"]')?.value || '';
            const comments = document.querySelector('textarea.form-control[placeholder="Comments"]')?.value || '';

            const data = {
              client_id: contactPerson,
              contact_person_mobile: contactMobile,
              contact_person_email: contactEmail,
              comments: comments
            };

            console.log("SUBMIT_DATA::" + JSON.stringify(data));
          });
        }
      """;

      await _controller?.evaluateJavascript(source: jsToInject);
    } catch (e) {
      print("Error reading/injecting stored client data: $e");
    }
  }


Future<void> _submitMeetingData(Map<String, dynamic> formData) async {
  try {
    // Check and request location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Location permission denied")),
      );
      return;
    }

    // Get current location
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    print("Latitude: ${position.latitude}, Longitude: ${position.longitude}");

    final enrichedFormData = {
      ...formData,
      "latitude": position.latitude,
      "longitude": position.longitude,
    };

    await MeetingsController.submitMeeting(
      clientId: enrichedFormData["client_id"],
      email: enrichedFormData["contact_person_email"],
      mobile: enrichedFormData["contact_person_mobile"],
      comments: enrichedFormData["comments"],
      latitude: enrichedFormData["latitude"],
      longitude: enrichedFormData["longitude"],
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Meeting submitted successfully!")),
    );

    // Clear form fields
    final clearFormJS = """
      document.querySelector('select.form-select[placeholder="Contact Person"]').selectedIndex = 0;
      document.querySelector('input.form-control[placeholder="Contact Person Mobile"]').value = '';
      document.querySelector('input.form-control[placeholder="Contact Person Email"]').value = '';
      document.querySelector('textarea.form-control[placeholder="Comments"]').value = '';
    """;

    await _controller?.evaluateJavascript(source: clearFormJS);
  } catch (e) {
    print("Error fetching location or submitting meeting: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to submit meeting")),
    );
  }
}


  String _escapeJS(String value) {
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll(r'"', r'\"')
        .replaceAll("'", r"\'")
        .replaceAll('\n', r'\\n');
  }
}
