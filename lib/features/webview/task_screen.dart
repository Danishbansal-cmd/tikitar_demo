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
  int? userId;

  @override
  void initState() {
    super.initState();
    _fetchStoredStaticData(); // fetch all the static data
    _initializeTaskScreen(); // to initialize the userId variable
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
              address: args[5],
              branch: args[6],
            );
          },
        );

        // it is called when the specific company is selected
        _controller?.addJavaScriptHandler(
          handlerName: 'companySelected',
          callback: (args) {
            _companySelected(selectedCompanyOptionValue: int.tryParse(args[0]));
          },
        );

        // called on click of the "save" button of (Add Contact Person Dialog or Form)
        _controller?.addJavaScriptHandler(
          handlerName: 'addContactPersonDetails',
          callback: (args) {
            _addContactPersonDetails(contactPersonData: args[0]);
          },
        );
      },
      onLoadStop: (controller, url) async {
        await _fetchCompaniesData();
        await injectWebJS();
      },
      onConsoleMessage: (consoleMessage) {
        if (consoleMessage.messageLevel == ConsoleMessageLevel.LOG) {
          final message = consoleMessage.message;

          if (message.startsWith("MAIN_SUBMIT::")) {
            final jsonData = message.replaceFirst("MAIN_SUBMIT::", "");
            final data = json.decode(jsonData);
            _submitMeetingData(data); // Handle main form submit
          }
        }
      },
    );
  }

  // JavaScript code to inject into the web view
  String baseJS() {
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

    // ✅Company Select Field 
    // get all the selects that match this querySelector
    const selects = document.querySelectorAll('select.form-select[placeholder="Company Name"]');
    let selectedCompanyValue = null;
    // Company select field data injection
    selects.forEach(select => {
      select.innerHTML = `$companyOptionsHTML`;

      select.addEventListener('change', function (){
        const selectedOption = this.options[this.selectedIndex];
        selectedCompanyValue = selectedOption.value;

        console.log(this.selectedIndex);
        console.log(selectedCompanyValue);
        window.flutter_inappwebview.callHandler('companySelected', selectedCompanyValue);
      });
    });

    // ✅ Contact Person Select Field
    // Contact Person select field injection
    function updatesContactPersonOptions(htmlString) {
      const optionsHTML = htmlString;

      const contactPersonSelects = document.querySelectorAll('select.form-select[placeholder="Contact Person"]');
      contactPersonSelects.forEach(select => {
        select.innerHTML = optionsHTML;

        select.addEventListener('change', function () {
          const selectedOption = this.options[this.selectedIndex];
          if (!selectedOption) return;

          const contactEmailAttr = selectedOption.getAttribute('data-contact_email') || '';
          const contactMobileAttr = selectedOption.getAttribute('data-contact_mobile') || '';

          contactMobile && (contactMobile.value = contactEmailAttr || '');
          contactEmail && (contactEmail.value = contactMobileAttr || '');
        });
      });

      // update these ♿two disabled fields to empty or default values as the Contact Person Data updates
      // means if the data of the contact person select is updated, then it means at such time no contact person
      // is selected, so make those values to default or back to normal
      contactMobile && (contactMobile.value = '');
      contactEmail && (contactEmail.value = '');
    }
    updatesContactPersonOptions('<option selected>No Contact Person</option>');

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
        <input type="text" placeholder="Address Line 1" class="form-control mb-1 address-line-1"/>
        <input type="text" placeholder="Branch Name" class="form-control mb-1 branch-name"/>
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
        const address = document.querySelector(".address-line-1").value;
        const branch = document.querySelector(".branch-name").value;

        window.flutter_inappwebview.callHandler('saveOnlyCompanyData', name, city, zip, selectedStateText, category, address, branch);
      });
    });

    // ✅ New Person Form Full Popup Button
    const addContactPersonFieldsClasses = ['contact_person', 'contact_email', 'contact_phone', 'job_title', 'whatsapp'];
    document.querySelectorAll('.addmore')[1]?.addEventListener('click', function(e) {
      e.preventDefault();
      const html = \`
        <h5>Add New Client</h5>
        <input type="text" placeholder="Contact Person" class="form-control mb-1 contact_person"/>
        <input type="text" placeholder="Contact Email" class="form-control mb-1 contact_email"/>
        <input type="text" placeholder="Contact Phone" class="form-control mb-1 contact_phone"/>
        <input type="text" placeholder="Job Title" class="form-control mb-1 job_title"/>
        <input type="text" placeholder="Whatsapp" class="form-control mb-1 whatsapp"/>
        
        <button id="popup-close" class="btn btn-danger me-2">Close</button>
        <button id="submit-client" class="btn btn-primary">Save</button>
      \`;
      createPopup(html);

      // close button logic
      document.getElementById('popup-close')?.addEventListener('click', () => {
        document.getElementById('flutter-popup')?.remove();
      });

      // phone input validation
      const observePhoneInputs = () => {
        document.querySelectorAll('.contact_phone').forEach(input => {
          input.removeEventListener('input', phoneInputHandler);
          input.addEventListener('input', phoneInputHandler);
        });
      };
      const phoneInputHandler = function () {
        this.value = this.value.replace(/[^0-9]/g, '').substring(0, 10);
      };
      observePhoneInputs();

      document.getElementById('submit-client')?.addEventListener('click', () => {
        let isAllFilled = true;
        const formData = {};

        addContactPersonFieldsClasses.forEach(function(className) {
          const input = document.querySelector('.' + className);
            if (!input || input.value.trim() === '') {
              isAllFilled = false;
            } else {
              formData[className] = input.value.trim();
            }
        });

        if (!isAllFilled) {
          console.log('Please fill all fields.');
        }

        const companySelect = document.querySelector('select.form-select[placeholder="Company Name"]');
        let client_id_data = companySelect?.value || null;

        // if no company is selected then, it shows this option "Select Company"
        // then send the null
        if (client_id_data === "Select Company") {
          client_id_data = null;
        }

        // Example payload - adapt as needed
        const finalPayload = {
          client_id: client_id_data,
          name: formData['contact_person'],
          contact_email: formData['contact_email'],
          contact_phone: formData['contact_phone'],
          job_title: formData['job_title'],
          whatsapp: formData['whatsapp'],
        };

        // call the method to handle the adding of Contact Person
        window.flutter_inappwebview.callHandler('addContactPersonDetails', finalPayload);
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

        // ❌❌❌ fix once apis are corrected
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

  // Inject JavaScript into the web view
  Future<void> injectWebJS() async {
    developer.log("injectwebjs");
    final jsCode = baseJS();
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
      developer.log(
        "categoryOptionsHTML $categoryOptionsHTML",
        name: "TaskScreen",
      );

      // Fetch states from sharedPreferences
      final statesData = await DataStorage.getStateNames() as List<dynamic>;
      if (statesData.isEmpty) return;

      stateOptionsHTML = '<option selected>Select State</option>';
      for (int i = 0; i < statesData.length; i++) {
        final name = Functions.escapeJS(statesData[i].toString());
        stateOptionsHTML +=
            '<option value="${(i + 1).toString()}">$name</option>';
      }
      developer.log("stateOptionsHTML $stateOptionsHTML", name: "TaskScreen");
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
    String? address,
    String? branch,
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
      address: address!,
      branch: branch!,
    );

    // makes sure the widget is mounted or in the context
    if (!mounted) return;
    if (response['status'] == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Company saved successfully.")));
      await _controller?.evaluateJavascript(
        source: """
          // remove the popup or (Company Add) Dialog
          document.getElementById('flutter-popup')?.remove();
        """,
      );
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

  Future<void> _fetchCompaniesData() async {
    developer.log(
      "_fetchCompaniesData send data ${userId}",
      name: "TaskScreen",
    );
    final response = await CompanyController.getOnlyCompanies(userId!);

    if (response['status'] == true) {
      developer.log(
        "_fetchCompaniesData successfully ${response['data']}",
        name: "TaskScreen",
      );
      final companiesData = response['data'];
      companyOptionsHTML = '<option selected>Select Company</option>';
      for (int i = 0; i < companiesData.length; i++) {
        final name = Functions.escapeJS(companiesData[i]['name'].toString());
        final id = companiesData[i]['id'];
        companyOptionsHTML += '<option value="$id">$name</option>';
      }
      developer.log(
        "companyOptionsHTML $companyOptionsHTML",
        name: "TaskScreen",
      );
    } else {
      developer.log(
        "_fetchCompaniesData un-successfully ${response['data']}",
        name: "TaskScreen",
      );
    }
  }

  // Get userData from SharedPreferences, to finally get the userId
  Future<void> _initializeTaskScreen() async {
    final userData = await DataStorage.getUserData();
    if (userData != null) {
      final decoded = jsonDecode(userData);
      // converting to int successfully
      userId = int.tryParse(decoded['id'].toString()) ?? 0;
    }
    developer.log("Extracted userId: $userId", name: "TaskScreen");
  }

  Future<void> _fetchCurrentUsersContactPerson(int companyId) async {
    // In actuall companyId is the clientId, we are sending the companyId
    // but in api it is considered as clientId
    final response = await ClientsController.getUserContactPersonsData(
      companyId,
      userId!,
    );
    developer.log(
      "_fetchCurrentUsersContactPerson response ${response['data']}",
      name: "TaskScreen",
    );

    final bool status = response['status'] == true;
    final message = response['message'] ?? 'Unknown error';

    String contactPersonOptionsHTML =
        '<option selected>No Contact Person</option>';

    // makes sure the widget is mounted or in the context
    if (!mounted) return;

    if (status) {
      final usersContactPersonsData = response['data'] as List;

      if (usersContactPersonsData.isNotEmpty) {
        contactPersonOptionsHTML =
            '<option selected>Select Contact Person</option>';

        developer.log(
          "in true but list not empty _fetchCurrentUsersContactPerson",
          name: "TaskScreen",
        );

        for (int i = 0; i < usersContactPersonsData.length; i++) {
          final person = usersContactPersonsData[i];
          final id = person['id'];
          final name = Functions.escapeJS(person['contact_person'].toString());
          final contactEmail = Functions.escapeJS(
            person['contact_email'].toString(),
          );
          final contactMobile = Functions.escapeJS(
            person['contact_phone'].toString(),
          );

          contactPersonOptionsHTML +=
              '<option value="$id" data-contact_email="$contactEmail" data-contact_mobile="$contactMobile">$name</option>';
        }

        await _controller?.evaluateJavascript(
          source: """
            // updates the contact person options
            updatesContactPersonOptions(`${Functions.escapeJS(contactPersonOptionsHTML)}`);
          """,
        );
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } else {
      developer.log("in false _fetchCurrentUsersContactPerson");
      await _controller?.evaluateJavascript(
        source: """
          // updates the contact person options
          updatesContactPersonOptions(`${Functions.escapeJS(contactPersonOptionsHTML)}`);
        """,
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  // run this function on selecting the company
  Future<void> _companySelected({int? selectedCompanyOptionValue}) async {
    developer.log(
      "selected Company Value $selectedCompanyOptionValue",
      name: "TaskScreen",
    );

    if (selectedCompanyOptionValue != null) {
      await _fetchCurrentUsersContactPerson(selectedCompanyOptionValue);
    }
  }

  Future<void> _addContactPersonDetails({
    required Map<String, dynamic> contactPersonData,
  }) async {
    // Ensure the client ID is available (you can pass it or store it somewhere)
    final clientId = contactPersonData['client_id'] ?? 0; // Replace with your actual logic to fetch client_id

    if (clientId == 0) {
      developer.log("Client ID is not set", name: "TaskScreen");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please Select the Company from Above.")),
      );
      return;
    }

    // Construct the API payload
    final payload = {
      "client_id": clientId.toString(), // API expects string
      "contact_person": contactPersonData['name'] ?? '',
      "contact_email": contactPersonData['contact_email'] ?? '',
      "contact_phone": contactPersonData['contact_phone'] ?? '',
      "job_title": contactPersonData['job_title'] ?? '',
      "whatsapp": contactPersonData['whatsapp'] ?? '',
    };

    developer.log("Sending contact person data: $payload", name: "TaskScreen");

    final response = await ClientsController.addContactPerson(payload);
    developer.log("Add Contact Person Response: $response", name: "TaskScreen");

    final bool status = response['status'] == true;
    final message = response['message'] ?? 'Unknown error';

    // makes sure the widget is mounted or in the context
    if (!mounted) return;

    if (status) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Contact person added successfully.")),
      );
      // Optionally refresh the contact person list
      await _fetchCurrentUsersContactPerson(int.tryParse(clientId) ?? 0);
      await _controller?.evaluateJavascript(
        source: """
          // close the popup after successfully adding the contact person
          document.getElementById('flutter-popup')?.remove();
        """
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}
