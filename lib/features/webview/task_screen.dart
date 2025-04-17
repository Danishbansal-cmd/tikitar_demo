import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:tikitar_demo/common/webview_common_screen.dart';
import 'package:tikitar_demo/features/auth/meetings_controller.dart';
import 'package:tikitar_demo/features/data/local/data_strorage.dart';
import 'dart:convert';
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
        // Helper to create popup
        function createPopup(content) {
          const existingPopup = document.getElementById('flutter-popup');
          if (existingPopup) existingPopup.remove();

          const popup = document.createElement('div');
          popup.id = 'flutter-popup';
          popup.style.position = 'fixed';
          popup.style.top = '0';
          popup.style.left = '0';
          popup.style.width = '100vw';
          popup.style.height = '100vh';
          popup.style.background = 'rgba(0,0,0,0.5)';
          popup.style.zIndex = '9999';
          popup.style.display = 'flex';
          popup.style.alignItems = 'center';
          popup.style.justifyContent = 'center';

          const inner = document.createElement('div');
          inner.style.background = '#fff';
          inner.style.padding = '20px';
          inner.style.borderRadius = '10px';
          inner.innerHTML = content;

          popup.appendChild(inner);
          document.body.appendChild(popup);
        }

        // First Add More (Index 0) - Just close
        document.querySelectorAll('.addmore')[0]?.addEventListener('click', function(e) {
          e.preventDefault();
          const html = \`
            <h5>Simple Popup</h5>
            <button id="popup-close">Close</button>
          \`;
          createPopup(html);
          document.getElementById('popup-close')?.addEventListener('click', () => {
            document.getElementById('flutter-popup')?.remove();
          });
        });

        // Second Add More (Index 1) - Form popup
        document.querySelectorAll('.addmore')[1]?.addEventListener('click', function(e) {
          e.preventDefault();
          const html = \`
            <h5>Add New Contact</h5>
            <input type="text" placeholder="Name" id="popup-name" class="form-control mb-2"/><br/>
            <input type="text" placeholder="Contact Person" id="popup-contact-person" class="form-control mb-2"/><br/>
            <input type="email" placeholder="Contact Email" id="popup-contact-email" class="form-control mb-2"/><br/>
            <input type="text" placeholder="Contact Phone (10 digits)" id="popup-contact-phone" class="form-control mb-2"/><br/>
            <select id="popup-category" class="form-select mb-2">
              <option selected disabled>Select Category</option>
              <option value="1">General</option>
              <option value="2">Premium</option>
            </select><br/>
            <div id="location-list">
              <h6>Locations</h6>
              <div class="location-item mb-2">
                <input type="text" placeholder="Location Name" class="form-control mb-1 loc-name"/>
                <input type="text" placeholder="Address" class="form-control mb-1 loc-address"/>
              </div>
            </div>
            <button id="add-location" class="btn btn-secondary btn-sm mb-2">Add Location</button><br/>
            <button id="popup-close">Close</button>
          \`;
          createPopup(html);

          document.getElementById('popup-close')?.addEventListener('click', () => {
            document.getElementById('flutter-popup')?.remove();
          });

          document.getElementById('add-location')?.addEventListener('click', () => {
            const locDiv = document.createElement('div');
            locDiv.className = "location-item mb-2";
            locDiv.innerHTML = \`
              <input type="text" placeholder="Location Name" class="form-control mb-1 loc-name"/>
              <input type="text" placeholder="Address" class="form-control mb-1 loc-address"/>
            \`;
            document.getElementById('location-list')?.appendChild(locDiv);
          });

          // Phone input validation
          const phoneInput = document.getElementById('popup-contact-phone');
          phoneInput?.addEventListener('input', function () {
            this.value = this.value.replace(/[^0-9]/g, '').substring(0, 10);
          });
        });
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
      latitude: enrichedFormData["latitude"].toString(),
      longitude: enrichedFormData["longitude"].toString(),
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
