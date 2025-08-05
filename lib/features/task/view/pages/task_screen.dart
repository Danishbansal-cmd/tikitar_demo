import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tikitar_demo/features/common/constants.dart';
import 'package:tikitar_demo/features/common/view/pages/webview_common_screen.dart';
import 'package:tikitar_demo/controllers/clients_controller.dart';
import 'package:tikitar_demo/controllers/company_controller.dart';
import 'package:tikitar_demo/controllers/meetings_controller.dart';
import 'package:tikitar_demo/core/local/data_strorage.dart';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:tikitar_demo/features/common/functions.dart';
import 'package:tikitar_demo/features/companies/repositories/company_repository.dart';
import 'dart:io'; // Add import for File handling
import 'dart:developer' as developer;

import 'package:tikitar_demo/features/profile/repositories/profile_repository.dart';

class TaskScreen extends ConsumerStatefulWidget {
  const TaskScreen({super.key});

  @override
  ConsumerState<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends ConsumerState<TaskScreen> {
  InAppWebViewController? _controller;
  File? _visitedCardFile; // Variable to hold the selected file
  String categoryOptionsHTML = ''; // store the categoryOptions
  String stateOptionsHTML = ''; // store the stateOptions
  String companyOptionsHTML = '<option value="0">No Company Found</option>'; // store the companyOptions

  @override
  void initState() {
    super.initState();
    _fetchStoredStaticData(); // fetch all the static data
  }

  @override
  Widget build(BuildContext context) {
    return WebviewCommonScreen(
      url: "task.php",
      title: "Task",
      onWebViewCreated: (controller) {
        _controller = controller;

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

        // to handle the main Form Submitted data
        _controller?.addJavaScriptHandler(
          handlerName: 'mainFormSubmit',
          callback: (args) {
            // used to handle the main Form data, which is the
            // submit meeting data
            _submitMeetingData(args[0]);
          },
        );
      },
      onLoadStop: (controller, url) async {
        await _fetchCompaniesData();
        await injectWebJS();
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
      popup.style.padding = '10px'; // to prevent edge overflow on small screens

      const inner = document.createElement('div');
      inner.style.background = '#fff';
      inner.style.padding = '20px';
      inner.style.borderRadius = '10px';
      inner.style.maxHeight = '90vh';
      inner.style.overflowY = 'auto';
      inner.style.maxWidth = '80%';
      inner.style.boxSizing = 'border-box';

      // Add inline style overrides to content inputs
      const styledContent = `
        <style>
          #flutter-popup .form-control,
          #flutter-popup .form-select {
            width: 100% !important;
            min-width: unset !important;
            box-sizing: border-box;
          }
        </style>
        \${content}
      `;

      inner.innerHTML = styledContent;

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

    // globally storing the comments in the variable to make it accessible from most places
    const commentboxField = document.querySelector('textarea.form-control[placeholder="Comments"]');

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

    // globally storing the companySelect
    const companySelect = document.querySelector('select.form-select[placeholder="Company Name"]');

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

          contactMobile && (contactMobile.value = contactMobileAttr || '');
          contactEmail && (contactEmail.value = contactEmailAttr || '');
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
        <select id="popup-states" class="form-select mb-1">
          $stateOptionsHTML
        </select>
        <select id="popup-category" class="form-select mb-1">
          $categoryOptionsHTML
        </select>
        <input type="text" placeholder="Address Line 1" class="form-control mb-1 address-line-1"/>
        <input type="text" placeholder="Branch Name" class="form-control mb-1 branch-name"/>
        <br />
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
        const selectedStateText = statesDropdown.options[statesDropdown.selectedIndex].text;
        const category = parseInt(document.querySelector("#popup-category").value || "0");
        const address = document.querySelector(".address-line-1").value;
        const branch = document.querySelector(".branch-name").value;

        window.flutter_inappwebview.callHandler('saveOnlyCompanyData', name, city, zip, selectedStateText, category, address, branch);
      });
    });

    // ✅ New Contact Person Form Full Popup Button
    const addContactPersonFieldsClasses = ['contact_person', 'contact_email', 'contact_phone', 'job_title', 'whatsapp'];
    document.querySelectorAll('.addmore')[1]?.addEventListener('click', function(e) {
      e.preventDefault();
      const html = \`
        <h5>Add New Contact Person</h5>
        <input type="text" placeholder="Contact Person" class="form-control mb-1 contact_person"/>
        <input type="text" placeholder="Contact Email" class="form-control mb-1 contact_email"/>
        <input type="text" placeholder="Contact Phone" class="form-control mb-1 contact_phone"/>
        <input type="text" placeholder="Job Title" class="form-control mb-1 job_title"/>
        <input type="text" placeholder="Whatsapp" class="form-control mb-1 whatsapp"/>
        <br />
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

      // whatsapp input validation
      const whatsappHandler = e => {
        e.target.value = e.target.value.replace(/[^0-9]/g, '').substring(0, 10);
      };
      document.querySelectorAll('.whatsapp').forEach(input => {
        if (!input.dataset.bound) {
          input.addEventListener('input', whatsappHandler);
          input.dataset.bound = 'true';
        }
      });

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

        let client_id_data = companySelect?.value || null;
        // if no company is selected then, it shows this option "Select Company"
        // then send the null
        if (client_id_data === "Select Company") {
          client_id_data = null;
        }

        // 🔘Get selected visited option (site or office)
        const visitedValue = document.querySelector('input[name="inlineRadioOptions"]:checked')?.value || '';

        // making the visited field value to capitalize, as it is necessary for api
        // this is how the api demands it
        const data = {
          client_id: client_id_data,
          contact_person_mobile: contactMobile.value || '',
          contact_person_email: contactEmail.value || '',
          comments: commentboxField?.value || '',
          visited: visitedValue.charAt(0).toUpperCase() + visitedValue.slice(1).toLowerCase()
        };

        // will call this handler or function that will handle the 
        // submit meeting data
        window.flutter_inappwebview.callHandler('mainFormSubmit', data);
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

    // 👇 This function can be called from Flutter to reset the Meeting Form
    function clearMeetingForm() {
      // Clear the selected file in Flutter
      window.flutter_inappwebview.callHandler('clearVisitedCardFile');

      // first selecting the fields then resetting to default
      let companySelects = document.querySelectorAll('select.form-select[placeholder="Company Name"]');
      let contactPersonSelects = document.querySelectorAll('select.form-select[placeholder="Contact Person"]');

      companySelects.forEach(select => {
        select.selectedIndex = 0; // Set to first option (default)
      });
      contactPersonSelects.forEach(select => {
        select.selectedIndex = 0; // Set to first option (default)
      });

      if (typeof contactMobile !== 'undefined') contactMobile.value = '';
      if (typeof contactEmail !== 'undefined') contactEmail.value = '';
      if (typeof commentboxField !== 'undefined') commentboxField.value = '';
      
      // Reset visiting card UI
      let wrapper = document.querySelector('.uploadfilewrapper a');
      if (wrapper) {
        wrapper.innerHTML = `
          <div class="uploadfilewrapper a" style="cursor:pointer;">
            <img src="assets/img/upload.svg" alt="">
            <span class="scanfile">Scan/Upload Visiting Card</span>
          </div>
        `;
        if (typeof attachUploadClickHandler === 'function') {
          attachUploadClickHandler(); // Re-bind the click handler
        }
      }
    }

    let uploadClickHandler; // Global variable to store the handler reference
    // 📎 Visiting Card Upload Click Handler for Flutter-only environment
    function attachUploadClickHandler() {
      // Select the anchor tag inside the .uploadfilewrapper container
      const uploadWrapperLink = document.querySelector('.uploadfilewrapper a');

      // Proceed only if the link is found
      if (uploadWrapperLink) {
        // Remove any previously attached listener
        if (uploadWrapperLink.uploadClickHandler) {
          uploadWrapperLink.removeEventListener('click', uploadWrapperLink.uploadClickHandler);
        }

        // Define and assign a new named handler
        const handler = function (e) {
          e.preventDefault(); // Prevent default anchor behavior (e.g., navigation)

          // Check if the flutter_inappwebview bridge is available
          if (window.flutter_inappwebview) {
            // Call the Flutter handler named 'uploadVisitingCard'
            window.flutter_inappwebview.callHandler('uploadVisitingCard');
          } else {
            // Optional: Warn if the Flutter WebView bridge is not available
            console.warn('flutter_inappwebview is not available.');
          }
        };

        // Save reference and attach
        uploadWrapperLink.uploadClickHandler = handler;
        uploadWrapperLink.addEventListener('click', handler);
      }
    }

    // Initial attach
    // 🔄Run the click handler attachment on page load or whenever needed
    attachUploadClickHandler();


    //❌ Remove loading spinner
    var loaderToRemove = document.getElementById('dataLoader');
    if (loaderToRemove) loaderToRemove.remove();
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
              onPressed: () => Get.back(result: 1), // Camera
              child: const Text('Take Photo'),
            ),
            TextButton(
              onPressed: () => Get.back(result: 2), // Gallery
              child: const Text('Choose from Gallery'),
            ),
            TextButton(
              onPressed: () => Get.back(result: 3), // File picker
              child: const Text('Choose File'),
            ),
            TextButton(
              onPressed: () => Get.back(result: 0), // Cancel
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    // Allow only the following file formats to be uploaded:
    final allowedFormats = ['jpg', 'jpeg', 'png', 'heic'];

    if (option == null || option == 0) return; // User canceled

    try {
      XFile? pickedFile;
      File? selectedFile;
      String? fileName;

      if (option == 1 || option == 2) {
        // Camera or gallery
        pickedFile = await ImagePicker().pickImage(
          source: option == 1 ? ImageSource.camera : ImageSource.gallery,
          imageQuality: 80,
          maxWidth: 1200,
        );

        if (pickedFile == null) return; // User canceled the image picker
        developer.log(
          "pickedFile.path: ${pickedFile.path}",
          name: "TaskScreen",
        );
        developer.log(
          "pickedFile.name: ${pickedFile.name}",
          name: "TaskScreen",
        );

        selectedFile = File(pickedFile.path);
        fileName = pickedFile.name;
      } else if (option == 3) {
        // File picker
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: allowedFormats,
        );

        if (result == null || result.files.isEmpty) return; // User canceled

        final file = result.files.first;

        if (!allowedFormats.contains(file.extension?.toLowerCase())) {
          throw PlatformException(
            code: 'INVALID_FORMAT',
            message: 'Unsupported file format.',
          );
        }

        selectedFile = File(file.path!);
        fileName = file.name;
      }

      // Ensure a file is actually selected
      if (selectedFile != null && fileName != null) {
        // For image_picker results
        setState(() {
          _visitedCardFile = selectedFile!;
        });
        final safeFileName = fileName
            .replaceAll("'", "\\'")
            .replaceAll('"', '\\"');

        // Inject JavaScript code to update the UI and handle the remove functionality
        _controller?.evaluateJavascript(
          source: """
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
                  <div class="uploadfilewrapper a" style="cursor:pointer;">
                    <img src="assets/img/upload.svg" alt="">
                    <span class="scanfile">Scan/Upload Visiting Card</span>
                  </div>
                \`;

                // Notify Flutter to clear the variable _visitedCardFile
                if (window.flutter_inappwebview) {
                  window.flutter_inappwebview.callHandler('clearVisitedCardFile');
                } else {
                  // Optional: Warn if the Flutter WebView bridge is not available
                  console.warn('flutter_inappwebview is not available.');
                }
              });
            }
          }

          // Update the UI with the selected file
          updateSelectedFileUI("${safeFileName}");
        """,
        );
      }
    } on PlatformException catch (e) {
      developer.log("Failed to pick file: $e", name: "TaskScreen");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick file: ${e.message}')),
      );
    } catch (e) {
      developer.log("Error picking file: $e", name: "TaskScreen");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
    }
  }

  Future<void> _submitMeetingData(Map<String, dynamic> formData) async {
    // Validate required fields
    final requiredFields = {
      "client_id": "Company is required",
      "contact_person_email": "Contact Person Email is required",
      "contact_person_mobile": "Contact Person Mobile is required",
      "comments": "Comments are required",
    };

    for (var entry in requiredFields.entries) {
      final value = formData[entry.key];
      if (value == null || value.toString().trim().isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(entry.value)));
        await _controller?.evaluateJavascript(
          source: '''
            // reset the form submitting button
            resetSubmitButton();
          ''',
        );
        return;
      }
    }

    // Pause the background service tracking to avoid conflict
    FlutterBackgroundService().invoke('pauseTracking');
    await Future.delayed(
      const Duration(milliseconds: 2000),
    ); // give isolate time to react

    // Check and request location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // makes sure the widget is mounted or in the context
    if (!mounted) return;
    developer.log("formData $formData", name: "TaskScreen");

    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      developer.log("permission denied");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Location permission denied")));
      await _controller?.evaluateJavascript(
        source: '''
          // reset the form submitting button
          resetSubmitButton();
        ''',
      );
      // Ensure background tracking resumes
      FlutterBackgroundService().invoke('resumeTracking');
      return;
    }

    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      );
    } catch (e) {
      print("Live GPS location failed, trying fallback...");
      position = await Geolocator.getLastKnownPosition();
    }

    if (position == null) {
      // gracefully exit
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unable to get location. Please try again.")),
      );
      await _controller?.evaluateJavascript(source: 'resetSubmitButton();');
      FlutterBackgroundService().invoke('resumeTracking');
      return;
    }

    final enrichedFormData = {
      ...formData,
      "latitude": position.latitude,
      "longitude": position.longitude,
    };

    developer.log("enrichedFormData $enrichedFormData", name: "TaskScreen");

    // makes sure the widget is mounted or in the context
    if (!mounted) return;

    if (_visitedCardFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please upload a visiting card before submitting."),
        ),
      );
      await _controller?.evaluateJavascript(source: 'resetSubmitButton();');
      // Ensure background tracking resumes
      FlutterBackgroundService().invoke('resumeTracking');
      return;
    }

    // read data from the riverpod_provider
    final profile = ref.read(profileProvider);
    final userId = profile?.id ?? 0;

    final now = DateTime.now();
    final formattedDate =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    // Submit meeting with visited card file (if selected)
    final response = await MeetingsController.submitMeeting(
      clientId: enrichedFormData["client_id"],
      userId: userId.toString(),
      email: enrichedFormData["contact_person_email"],
      mobile: enrichedFormData["contact_person_mobile"],
      comments: enrichedFormData["comments"],
      latitude: enrichedFormData["latitude"].toString(),
      longitude: enrichedFormData["longitude"].toString(),
      meeting_date: formattedDate,
      visitedData: enrichedFormData['visited'],
      visitedCardFile: _visitedCardFile!, // Include the visited card file here
    );

    // makes sure the widget is mounted or in the context
    if (!mounted) return;
    if (response['status'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Meeting submitted successfully!")),
      );

      // Clear form fields
      final clearFormJS = """
        // reset the form submitting button
        resetSubmitButton();

        // Clear the Meeting Form using the defined Function
        clearMeetingForm();
      """;

      await _controller?.evaluateJavascript(
        source: '''
          $clearFormJS
        ''',
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to submit meeting, Try Again!")),
      );
      await _controller?.evaluateJavascript(
        source: '''
          // reset the form submitting button
          resetSubmitButton();
        ''',
      );
    }

    // Resume background tracking
    FlutterBackgroundService().invoke('resumeTracking');
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
    final companyList = await ref.read(companyProvider.future);

    if (companyList.isNotEmpty) {
      companyOptionsHTML = '<option selected>Select Company</option>';
      for (int i = 0; i < companyList.length; i++) {
        final company = companyList[i];
        final name = Functions.escapeJS(company.name.toString());
        final id = company.id;
        companyOptionsHTML += '<option value="$id">$name</option>';
      }
    }
  }

  Future<void> _fetchCurrentUsersContactPerson(int companyId) async {
    // read data from the riverpod_provider
    final profile = ref.read(profileProvider);
    final userId = profile?.id ?? 0;

    // In actuall companyId is the clientId, we are sending the companyId
    // but in api it is considered as clientId
    final response = await ClientsController.getUserContactPersonsData(
      companyId,
      userId,
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
          // fetching the "whatsapp" feild from the "person" object
          // and attaching it to the "data-contact_mobile" property, used in sending the "meetings" api
          final contactMobile = Functions.escapeJS(
            person['whatsapp'].toString(),
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
    final clientId =
        contactPersonData['client_id'] ??
        0; // Replace with your actual logic to fetch client_id

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
        """,
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
