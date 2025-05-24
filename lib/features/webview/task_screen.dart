import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tikitar_demo/common/webview_common_screen.dart';
import 'package:tikitar_demo/features/auth/clients_controller.dart';
import 'package:tikitar_demo/features/auth/company_controller.dart';
import 'package:tikitar_demo/features/auth/meetings_controller.dart';
import 'package:tikitar_demo/features/data/local/data_strorage.dart';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:tikitar_demo/common/functions.dart';
import 'dart:io'; // Add import for File handling
import 'dart:developer' as developer;

class TaskScreen extends StatefulWidget {
  @override
  _TaskScreenState createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  InAppWebViewController? _controller;
  List<Map<String, dynamic>> fields = [];
  File? _visitedCardFile; // Variable to hold the selected file
  String categoryOptionsHTML = ''; // store the categoryOptions
  String stateOptionsHTML = ''; // store the stateOptions
  String companyOptionsHTML = ''; // store the companyOptions
  int userId = 0;

  @override
  void initState() {
    super.initState();
    _fetchStoredStaticData(); // fetch all the static data
    _initializeTaskScreen();
    _fetchCompaniesData();
  }

  @override
  Widget build(BuildContext context) {
    return WebviewCommonScreen(
      url: "task.php",
      title: "Task",
      onWebViewCreated: (controller) {
        _controller = controller;

        // Add JavaScript handler for clearing form and visiting card
        controller.addJavaScriptHandler(
          handlerName: 'clearFormAndVisitingCard',
          callback: (args) async {
            setState(() {
              _visitedCardFile = null; // Clear the file reference
            });
          },
        );

        _controller?.addJavaScriptHandler(
          handlerName: 'uploadVisitingCard',
          callback: (args) async {
            await _pickVisitedCardFile();
          },
        );

        _controller?.addJavaScriptHandler(
          handlerName: 'clearVisitedCardFile',
          callback: (args) {
            setState(() {
              _visitedCardFile = null; // Clear the selected file in Flutter
            });
          },
        );

        _controller?.addJavaScriptHandler(
          handlerName: 'saveOnlyCompanyData',
          callback: (args) {
            _saveOnlyCompanyData(
              name: args[0],
              city: args[1],
              zip: args[2],
              state: args[3],
              categoryId: args[4],
            );
          },
        );
      },
      onLoadStop: (controller, url) async {
        // await fetchCurrentUsersClientsAndInjectJS();
      },
      onConsoleMessage: (consoleMessage) {
        if (consoleMessage.messageLevel == ConsoleMessageLevel.LOG) {
          final message = consoleMessage.message;

          if (message.startsWith("SUBMIT_CLIENT_DATA::")) {
            final jsonData = message.replaceFirst("SUBMIT_CLIENT_DATA::", "");
            final data = json.decode(jsonData);
            _handlePopupFormSubmit(data); // Handle popup form submission
          } else if (message.startsWith("MAIN_SUBMIT::")) {
            final jsonData = message.replaceFirst("MAIN_SUBMIT::", "");
            final data = json.decode(jsonData);
            _submitMeetingData(data); // Handle main form submit
          }
        }
      },
    );
  }

  // JavaScript code to inject into the web view
  String baseJS(String contactPersonOptions, String categoryOptions) {
    return """
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
      inner.style.maxHeight = '90vh';
      inner.style.overflowY = 'auto';
      inner.style.maxWidth = '80%';
      inner.style.boxSizing = 'border-box';

      inner.innerHTML = content;

      popup.appendChild(inner);
      document.body.appendChild(popup);
    }

    
    // ♿to disable the Contact Mobile & Contact Email
    const contactMobile = document.querySelector('input.form-control[placeholder="Contact Person Mobile"]');
    const contactEmail = document.querySelector('input.form-control[placeholder="Contact Person Email"]');
    if(contactMobile){
      contactMobile.disabled = true;
    }
    if(contactEmail){
      contactEmail.disabled = true;
    }

    // Contact Person select field injection
    const selects = document.querySelectorAll('select.form-select[placeholder="Company Name"]');
    selects.forEach(select => {
      select.innerHTML = `$companyOptionsHTML`;

      select.addEventListener('change', function (){
        const selectedOption = this.options[this.selectedIndex];
      });
    });

    // Contact Person select field injection
    const selects = document.querySelectorAll('select.form-select[placeholder="Contact Person"]');
    selects.forEach(select => {
      select.innerHTML = `$contactPersonOptions`;

      select.addEventListener('change', function (){
        const selectedOption = this.options[this.selectedIndex];

        contactMobile &&  (contactMobile.value = selectedOption.getAttribute('data-contact_mobile') || '');
        contactEmail && (contactEmail.value = selectedOption.getAttribute('data-contact_email') || '');
      });
    });

    // ✅ Add Company button
    document.querySelectorAll('.addmore')[0]?.addEventListener('click', function(e) {
      e.preventDefault();
      const companyDialogHTML = \`
        <h5>Add New Company</h5>
        <input type="text" placeholder="Company Name" id="popup-name" class="form-control mb-1"/>
        <input type="text" placeholder="City" class="form-control mb-1 loc-city"/>
        <input type="text" placeholder="Zip" class="form-control mb-1 loc-zip"/>
        <select id="popup-states" class="form-select">
          $stateOptionsHTML
        </select><br/>
        <select id="popup-category" class="form-select mb-1">
          $categoryOptionsHTML
        </select><br/>
        <button id="popup-close" class="btn btn-danger me-2">Close</button>
        <button id="submit-company" class="btn btn-primary">Save</button>
      \`;
      createPopup(companyDialogHTML);

      document.getElementById('popup-close')?.addEventListener('click', () => {
        document.getElementById('flutter-popup')?.remove();
      });

      document.getElementById('submit-company')?.addEventListener('click', function(e){
        e.preventDefault();

        const name = document.getElementById("popup-name").value;
        const city = document.querySelector(".loc-city").value;
        const zip = document.querySelector(".loc-zip").value;
        const statesDropdown = document.getElementById("popup-states");
        const statesDropdownValue = statesDropdown.value;
        const selectedStateText = statesDropdown.options[statesDropdownValue].text;
        const category = parseInt(document.querySelector("#popup-category").value || "0");

        console.log("name: ", name, city, zip, category);
        console.log("selectedStateText: ", selectedStateText, statesDropdownValue);

        window.flutter_inappwebview.callHandler('saveOnlyCompanyData', name, city, zip, selectedStateText, category);
      });
    });

    // ✅ New Person Form Full Popup Button
    document.querySelectorAll('.addmore')[1]?.addEventListener('click', function(e) {
      e.preventDefault();
      const html = \`
        <h5>Add New Client</h5>
        <input type="text" placeholder="Name" id="popup-name" class="form-control mb-1"/>
        <select id="popup-category" class="form-select">
          $categoryOptions
        </select><br/>
        <div id="location-list">
          <h6>Locations</h6>
          <div class="location-item mb-3">
            <input type="text" placeholder="Branch Name" class="form-control mb-1 loc-branch-name"/>
            <input type="text" placeholder="Address Line 1" class="form-control mb-1 loc-address1"/>
            <input type="text" placeholder="Address Line 2" class="form-control mb-1 loc-address2"/>
            <input type="text" placeholder="City" class="form-control mb-1 loc-city"/>
            <input type="text" placeholder="State" class="form-control mb-1 loc-state"/>
            <input type="text" placeholder="Country" class="form-control mb-1 loc-country"/>
            <input type="text" placeholder="Contact Person" class="form-control mb-1 loc-contact-person"/>
            <input type="email" placeholder="Contact Email" class="form-control mb-1 loc-contact-email"/>
            <input type="text" placeholder="Contact Phone (10 digits)" class="form-control mb-1 loc-contact-phone"/>
          </div>
        </div>
        <button id="add-location" class="btn btn-secondary btn-sm mb-3">Add Another Location</button><br/>
        <button id="popup-close" class="btn btn-danger me-2">Close</button>
        <button id="submit-client" class="btn btn-primary">Save</button>
      \`;
      createPopup(html);

      document.getElementById('popup-close')?.addEventListener('click', () => {
        document.getElementById('flutter-popup')?.remove();
      });

      document.getElementById('add-location')?.addEventListener('click', () => {
        const locDiv = document.createElement('div');
        locDiv.className = "location-item mb-3";
        locDiv.innerHTML = \`
          <hr/>
          <input type="text" placeholder="Branch Name" class="form-control mb-1 loc-branch-name"/>
          <input type="text" placeholder="Address Line 1" class="form-control mb-1 loc-address1"/>
          <input type="text" placeholder="Address Line 2" class="form-control mb-1 loc-address2"/>
          <input type="text" placeholder="City" class="form-control mb-1 loc-city"/>
          <input type="text" placeholder="State" class="form-control mb-1 loc-state"/>
          <input type="text" placeholder="Country" class="form-control mb-1 loc-country"/>
          <input type="text" placeholder="Contact Person" class="form-control mb-1 loc-contact-person"/>
          <input type="email" placeholder="Contact Email" class="form-control mb-1 loc-contact-email"/>
          <input type="text" placeholder="Contact Phone (10 digits)" class="form-control mb-1 loc-contact-phone"/>
        \`;
        document.getElementById('location-list')?.appendChild(locDiv);
      });

      const observePhoneInputs = () => {
        document.querySelectorAll('.loc-contact-phone').forEach(input => {
          input.removeEventListener('input', phoneInputHandler);
          input.addEventListener('input', phoneInputHandler);
        });
      };

      const phoneInputHandler = function () {
        this.value = this.value.replace(/[^0-9]/g, '').substring(0, 10);
      };

      observePhoneInputs();
      const observer = new MutationObserver(observePhoneInputs);
      observer.observe(document.getElementById('location-list'), { childList: true, subtree: true });

      document.getElementById('submit-client')?.addEventListener('click', () => {
        const name = document.getElementById('popup-name')?.value || "";
        const category = parseInt(document.getElementById('popup-category')?.value || "0");

        const locationNodes = document.querySelectorAll('.location-item');
        const locations = [];

        locationNodes.forEach((loc) => {
          const getVal = (selector) => loc.querySelector(selector)?.value || "";
          const locationData = {
            branch_name: getVal('.loc-branch-name'),
            address_line1: getVal('.loc-address1'),
            address_line2: getVal('.loc-address2'),
            city: getVal('.loc-city'),
            state: getVal('.loc-state'),
            country: getVal('.loc-country'),
            contact_person: getVal('.loc-contact-person'),
            contact_email: getVal('.loc-contact-email'),
            contact_phone: getVal('.loc-contact-phone'),
          };

          if (locationData.contact_person && locationData.contact_email && locationData.contact_phone) {
            locations.push(locationData);
          }
        });

        const finalPayload = {
          name: name,
          category_id: category,
          locations: locations
        };

        console.log("SUBMIT_CLIENT_DATA::" + JSON.stringify(finalPayload));
        document.getElementById('flutter-popup')?.remove();
      });
    });

    // ✅ Main form submit logic
    const submitBtn = document.querySelector('button.btn.btn-primary[type="submit"]');
    if (submitBtn) {
      submitBtn.addEventListener('click', function(event) {
        event.preventDefault();

        // Replace the button content with a spinner indicator and disable it
        submitBtn.disabled = true;
        submitBtn.innerHTML = '<span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span> Submitting...';

        const contactPerson = document.querySelector('select.form-select[placeholder="Contact Person"]')?.value || '';
        const comments = document.querySelector('textarea.form-control[placeholder="Comments"]')?.value || '';

        const data = {
          client_id: contactPerson,
          contact_person_mobile: contactMobile,
          contact_person_email: contactEmail,
          comments: comments
        };

        console.log("MAIN_SUBMIT::" + JSON.stringify(data));

        // After submission, notify Flutter to clear the form and visiting card
        if (window.flutter_inappwebview) {
          window.flutter_inappwebview.callHandler('clearFormAndVisitingCard');
        } else if (window.ReactNativeWebView) {
          window.ReactNativeWebView.postMessage(JSON.stringify({ type: 'clearFormAndVisitingCard' }));
        } else if (window.Flutter) {
          window.Flutter.postMessage(JSON.stringify({ type: 'clearFormAndVisitingCard' }));
        }
      });
    }

    // Add input validation for mobile number field
    const contactMobileInput = document.querySelector('input.form-control[placeholder="Contact Person Mobile"]');
    if (contactMobileInput) {
      // Set input type to 'tel' for better mobile keyboard support
      contactMobileInput.type = 'tel';
      
      // Add input event handler
      contactMobileInput.addEventListener('input', function() {
        // Remove any non-digit characters and limit to 10 digits
        this.value = this.value.replace(/[^0-9]/g, '').substring(0, 10);
      });
      
      // Add paste event handler to handle pasted content
      contactMobileInput.addEventListener('paste', function(e) {
        e.preventDefault();
        const pastedText = (e.clipboardData || window.clipboardData).getData('text');
        this.value = pastedText.replace(/[^0-9]/g, '').substring(0, 10);
      });
    }

    // 👇 This function can be called from Flutter to reset the button
    function resetSubmitButton() {
      const btn = document.querySelector('button.btn.btn-primary[type="submit"]');
      if (btn) {
        btn.disabled = false;
        btn.innerHTML = 'Submit';
      }
    }

    // 📎 Visiting Card Upload Click Handler
    function attachUploadClickHandler() {
      const uploadWrapperLink = document.querySelector('.uploadfilewrapper a');
      if (uploadWrapperLink) {
        uploadWrapperLink.addEventListener('click', function (e) {
          e.preventDefault();
          if (window.flutter_inappwebview) {
            window.flutter_inappwebview.callHandler('uploadVisitingCard');
          } else if (window.ReactNativeWebView) {
            window.ReactNativeWebView.postMessage(JSON.stringify({ type: 'uploadVisitingCard' }));
          } else if (window.Flutter) {
            window.Flutter.postMessage(JSON.stringify({ type: 'uploadVisitingCard' }));
          }
        });
      }
    }

    // Initial attach
    attachUploadClickHandler();
  """;
  }

  // Fetch categories and current user's clients, then inject JS into the web view
  // Future<void> fetchCurrentUsersClientsAndInjectJS() async {
  //   try {
  //     // Fetch current user's clients
  //     // final storedData = await DataStorage.getUserClientsData();
  //     if (storedData == null) return;

  //     final clients = jsonDecode(storedData) as List<dynamic>;

  //     String contactPersonOptionsHTML =
  //         '<option selected>Contact Person</option>';
  //     for (var client in clients) {
  //       final id = Functions.escapeJS(client['id'].toString());
  //       final name = Functions.escapeJS(client['name'].toString());
  //       final contact_email = Functions.escapeJS(
  //         client['contact_email'].toString(),
  //       );
  //       final contact_mobile = Functions.escapeJS(
  //         client['contact_phone'].toString(),
  //       );
  //       contactPersonOptionsHTML +=
  //           '<option value="$id" data-contact_email="$contact_email" data-contact_mobile="$contact_mobile">$name</option>';
  //     }

  //     // Now inject both category and contact person options into the web view
  //     print("Categories HTML: $categoryOptionsHTML");
  //     print("Contact Person Options HTML: $contactPersonOptionsHTML");

  //     await injectWebJS(
  //       categoryOptions: categoryOptionsHTML,
  //       contactPersonOptions: contactPersonOptionsHTML,
  //     );
  //   } catch (e) {
  //     developer.log(
  //       "Error fetchCurrentUsersClientsAndInjectJS(): $e",
  //       name: "TaskScreen",
  //     );
  //   }
  // }

  // Inject JavaScript into the web view
  Future<void> injectWebJS({
    String contactPersonOptions = '',
    String categoryOptions = '',
  }) async {
    final jsCode = baseJS(contactPersonOptions, categoryOptions);
    await _controller?.evaluateJavascript(source: jsCode);
  }

  // Add method to pick an image file (for visiting card) with multiple options
  Future<void> _pickVisitedCardFile() async {
    // Show a dialog to let the user choose between camera, gallery, or file picker
    final option = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Upload Visiting Card'),
          content: const Text('Choose an option to upload your visiting card'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, 1), // Camera
              child: const Text('Take Photo'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 2), // Gallery
              child: const Text('Choose from Gallery'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 3), // File picker
              child: const Text('Choose File'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 0), // Cancel
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (option == null || option == 0) return; // User canceled

    try {
      XFile? pickedFile;
      String? fileName;

      if (option == 1) {
        // Camera
        pickedFile = await ImagePicker().pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
          maxWidth: 1200,
        );
        fileName = pickedFile?.name ?? 'camera_image.jpg';
      } else if (option == 2) {
        // Gallery
        pickedFile = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          imageQuality: 80,
          maxWidth: 1200,
        );
        fileName = pickedFile?.name ?? 'gallery_image.jpg';
      } else if (option == 3) {
        // File picker
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
        );

        if (result != null && result.files.isNotEmpty) {
          final file = result.files.first;
          setState(() {
            _visitedCardFile = File(file.path!);
          });
          fileName = file.name;
        }
      }

      if (pickedFile != null && option != 3) {
        // For image_picker results
        setState(() {
          _visitedCardFile = File(pickedFile!.path);
        });
        fileName = pickedFile.name;
      }

      if (fileName != null) {
        // Update the DOM content in WebView
        final safeFileName = fileName
            .replaceAll("'", "\\'")
            .replaceAll('"', '\\"');

        // Inject JavaScript code to update the UI and handle the remove functionality
        _controller?.evaluateJavascript(
          source: """
          function attachUploadClickHandler() {
            const uploadWrapperLink = document.querySelector('.uploadfilewrapper a');
            if (uploadWrapperLink) {
              uploadWrapperLink.addEventListener('click', function (e) {
                e.preventDefault();
                if (window.flutter_inappwebview) {
                  window.flutter_inappwebview.callHandler('uploadVisitingCard');
                } else if (window.ReactNativeWebView) {
                  window.ReactNativeWebView.postMessage(JSON.stringify({ type: 'uploadVisitingCard' }));
                } else if (window.Flutter) {
                  window.Flutter.postMessage(JSON.stringify({ type: 'uploadVisitingCard' }));
                }
              });
            }
          }

          // Function to update the UI based on the selected file
          function updateSelectedFileUI(fileName) {
            const wrapper = document.querySelector('.uploadfilewrapper a');
            if (wrapper) {
              wrapper.innerHTML = \`
                <div style="display: flex; align-items: center; gap: 8px;">
                  <span style="white-space: nowrap; overflow: hidden; text-overflow: ellipsis; max-width: 200px;">📎 Selected: ${safeFileName}</span>
                  <button id="remove-upload-file" style="border: none; background: transparent; font-size: 18px; cursor: pointer;">❌</button>
                </div>
              \`;

              document.getElementById('remove-upload-file')?.addEventListener('click', function() {
                wrapper.innerHTML = \`
                  <a href="#" class="d-flex gap-2 align-items-center justify-content-center">
                    <img src="assets/img/upload.svg" alt=""><span class="scanfile">Scan/Upload Visiting Card</span>
                  </a>
                \`;

                // Notify Flutter to clear the variable _visitedCardFile
                if (window.flutter_inappwebview) {
                  window.flutter_inappwebview.callHandler('clearVisitedCardFile');
                } else if (window.ReactNativeWebView) {
                  window.ReactNativeWebView.postMessage(JSON.stringify({ type: 'clearVisitedCardFile' }));
                } else if (window.Flutter) {
                  window.Flutter.postMessage(JSON.stringify({ type: 'clearVisitedCardFile' }));
                }

                attachUploadClickHandler(); // Re-bind after re-inserting HTML
              });
            }
          }

          // Update the UI with the selected file
          updateSelectedFileUI("${safeFileName}");

          // Initial setup for the upload click handler
          attachUploadClickHandler();
        """,
        );
      }
    } on PlatformException catch (e) {
      print("Failed to pick file: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick file: ${e.message}')),
      );
    } catch (e) {
      print("Error picking file: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
    }
  }

  Future<void> _submitMeetingData(Map<String, dynamic> formData) async {
    try {
      // Check and request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Location permission denied")));
        return;
      }

      // Get current location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final enrichedFormData = {
        ...formData,
        "latitude": position.latitude,
        "longitude": position.longitude,
      };

      print("visitedCardFile: $_visitedCardFile");

      final now = DateTime.now();
      final formattedDate =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      // Submit meeting with visited card file (if selected)
      await MeetingsController.submitMeeting(
        clientId: enrichedFormData["client_id"],
        email: enrichedFormData["contact_person_email"],
        mobile: enrichedFormData["contact_person_mobile"],
        comments: enrichedFormData["comments"],
        latitude: enrichedFormData["latitude"].toString(),
        longitude: enrichedFormData["longitude"].toString(),
        meeting_date: formattedDate,
        visitedCardFile: _visitedCardFile, // Include the visited card file here
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
        
        // Reset visiting card UI
        const wrapper = document.querySelector('.uploadfilewrapper a');
        if (wrapper) {
          wrapper.innerHTML = \`
            <a href="#" class="d-flex gap-2 align-items-center justify-content-center">
              <img src="assets/img/upload.svg" alt=""><span class="scanfile">Scan/Upload Visiting Card</span>
            </a>
          \`;
          attachUploadClickHandler(); // Re-bind the click handler
        }
        
        resetSubmitButton();
      """;

      await _controller?.evaluateJavascript(
        source: '''
          $clearFormJS
          resetSubmitButton();
        ''',
      );
    } catch (e) {
      print("Error fetching location or submitting meeting: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to submit meeting")));
      await _controller?.evaluateJavascript(
        source: '''
          resetSubmitButton();
        ''',
      );
    }
  }

  void _handlePopupFormSubmit(Map<String, dynamic> data) async {
    try {
      print("Received client data from popup:");
      print(data);

      // Basic validation (optional)
      if (data['name'] == null ||
          data['category_id'] == null ||
          !(data['locations'] is List)) {
        print("Invalid data format.");
        return;
      }

      // Call controller to add client
      await ClientsController.addClient(data);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Client added successfully!")));
    } catch (e) {
      print("Error handling popup form submission: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to submit client")));
    }
  }

  Future<void> _fetchStoredStaticData() async {
    try {
      // Fetch categories first from sharedPreferences
      final categories = await DataStorage.getCategoryOptionsData();
      if (categories == null) return;

      final categoriesData = jsonDecode(categories) as List<dynamic>;

      categoryOptionsHTML = '<option selected>Select Category</option>';
      for (var cat in categoriesData) {
        final id = Functions.escapeJS(cat['id'].toString());
        final name = Functions.escapeJS(cat['name'].toString());
        categoryOptionsHTML += '<option value="$id">$name</option>';
      }

      // Fetch states from sharedPreferences
      final statesData = await DataStorage.getStateNames() as List<dynamic>;
      if (statesData.isEmpty) return;

      stateOptionsHTML = '<option selected>Select Select</option>';
      for (int i = 0; i < statesData.length; i++) {
        final name = Functions.escapeJS(statesData[i].toString());
        stateOptionsHTML +=
            '<option value="${(i + 1).toString()}">$name</option>';
      }
    } catch (e) {
      developer.log("Error _fetchStoredStaticData(): $e", name: "TaskScreen");
    }
  }

  Future<void> _saveOnlyCompanyData({
    String? name,
    String? city,
    String? zip,
    String? state,
    int? categoryId,
  }) async {
    if ([
      name,
      city,
      zip,
      state,
      categoryId,
    ].any((e) => e == null || (e is String && e.trim().isEmpty))) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Please fill in all fields")));
      return;
    }

    final response = await CompanyController.saveOnlyCompany(
      name: name!,
      city: city!,
      zip: zip!,
      state: state!,
      categoryId: categoryId!,
    );

    if (response['status'] == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Company saved successfully.")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to save company: ${response['message'] ?? 'Unknown error'}",
          ),
        ),
      );
    }
  }

  void _fetchCompaniesData() async {
    final response = await CompanyController.getOnlyCompanies(userId);

    if (response['status'] == true) {
      
      developer.log("_fetchCompaniesData successfully ${response['data']}", name: "TaskScreen");
    } 
  }

  Future<void> _initializeTaskScreen() async {
    // Get userData from SharedPreferences, to finally get the userId
    final userData = await DataStorage.getUserData();
    if (userData != null) {
      final decoded = jsonDecode(userData);
      userId = int.tryParse(decoded['id'].toString()) ?? 0;
    }
    developer.log("Extracted userId: $userId", name: "DashboardScreen");
  }
}
