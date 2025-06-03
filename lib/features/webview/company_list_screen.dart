import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:tikitar_demo/common/functions.dart';
import 'package:tikitar_demo/common/webview_common_screen.dart';
import 'dart:developer' as developer;

import 'package:tikitar_demo/core/network/api_base.dart';
import 'package:tikitar_demo/features/auth/clients_controller.dart';
import 'package:tikitar_demo/features/auth/company_controller.dart';
import 'package:tikitar_demo/features/data/local/data_strorage.dart';
import 'package:tikitar_demo/features/webview/meeting_list_screen.dart';

class CompanyListScreen extends StatefulWidget {
  const CompanyListScreen({super.key});

  @override
  State<CompanyListScreen> createState() => _CompanyListScreenState();
}

class _CompanyListScreenState extends State<CompanyListScreen> {
  InAppWebViewController? _controller;
  int? userId;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _initializeCompanyListScreen();
  }

  @override
  Widget build(BuildContext context) {
    return WebviewCommonScreen(
      url: "company-list.php",
      title: "Company List",
      onWebViewCreated: (controller) {
        _controller = controller;

        controller.addJavaScriptHandler(
          handlerName: "HANDLE_ADD_COMPANY_DATA",
          callback: (args) {
            // args[0] is finalPayload from JavaScript
            developer.log(
              "Received payload from WebView: ${args[0]}",
              name: 'CompanyListScreen',
            );
            final decodedData = jsonDecode(args[0]);
            _handleAddCompany(companyData: decodedData);
          },
        );

        controller.addJavaScriptHandler(
          handlerName: "fetchCompanyContacts",
          callback: (args) {
            // args[0] is finalPayload from JavaScript
            _fetchCompanyContacts(companyId: int.tryParse(args[0]) ?? 0);
          },
        );
      },
      onLoadStop: (controller, url) async {
        // ✅ Show loading spinner immediately
        await showLoadingSpinner(controller);

        // You can add any additional logic here if needed
        await injectMoreJS();

        // fetch the companies data and inject in this view
        await fetchCompanies();
      },
    );
  }

  Future<void> _initializeCompanyListScreen() async {
    // Get userData from SharedPreferences, to finally get the userId
    final userData = await DataStorage.getUserData();
    if (userData != null) {
      final decoded = jsonDecode(userData);
      userId = int.tryParse(decoded['id'].toString()) ?? 0;
    }
    developer.log("Extracted userId: $userId", name: "CompanyListScreen");
  }

  Future<void> fetchCompanies() async {
    String companyRowJS = '''
      <tr>
        <th>Rank</th>
        <th>Company Name</th>
        <th>View</th>
      </tr>
    ''';
    developer.log(
      "fetchCompaniesAndInject send data ${userId}",
      name: "CompanyListScreen",
    );
    final response = await CompanyController.getOnlyCompanies(userId!);

    if (response['status'] == true) {
      developer.log(
        "fetchCompaniesAndInject successfully ${response['data']}",
        name: "CompanyListScreen",
      );
      final companiesData = response['data'];

      for (int i = 0; i < companiesData.length; i++) {
        final company = companiesData[i];
        if (company == null) continue; // Skip if null

        final rank = i + 1;
        final companyName = Functions.escapeJS(company['name'].toString());
        final id = company['id'];

        companyRowJS += """
          <tr>
            <td>$rank</td>
            <td>$companyName</td>
            <td>
              <a class="popup-link" 
              href="#viewcompanydetails"
              data-id="$id" data-companyName="$companyName">
                <span class="material-symbols-outlined">
                  visibility
                </span>
              </a>
            </td>
          </tr>
        """;
      }
      // developer.log("companyRowJS $companyRowJS", name: "CompanyListScreen");
    } else {
      if (!mounted) return;

      // Handle the error here, e.g., show a message to the user
      // Show a snackbar or dialog with the error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response['message'] ?? 'Try Again Later, No Company Found!',
          ),
        ),
      );
      return;
    }

    _injectCompanies(companyRowJS: companyRowJS);
  }

  Future<void> _injectCompanies({required String companyRowJS}) async {
    try {
      final fullJs = """
        var table = document.querySelector(".reporttable.companies");
        var rows = table.querySelectorAll('tr');
        for (let i = rows.length - 1; i > -1; i--) {
          table.deleteRow(i);
        }

        var html = `$companyRowJS`;
        table.insertAdjacentHTML('beforeend', html);

        // Reinitialize Magnific Popup on new elements
        if (window.jQuery) {
          window.jQuery('.popup-link').magnificPopup({
            type: 'inline',
            midClick: true
          });
        }

        // Attach click handler for company details
        document.querySelectorAll(".popup-link").forEach(function(link) {
          link.addEventListener("click", function(e) {
            var companyId = this.getAttribute("data-id");
            var companyName = this.getAttribute("data-companyName");

            // Update popup content
            var popupTitle = document.querySelector("#viewcompanydetails h5");
            if (popupTitle) popupTitle.textContent = companyName;

            // Call Flutter to fetch contact data
            if (window.flutter_inappwebview) {
              window.flutter_inappwebview.callHandler('fetchCompanyContacts', companyId);
            }
          });
        });
      """;

      await _controller?.evaluateJavascript(source: fullJs);
    } catch (e) {
      developer.log(
        "Error fetching or injecting Companies data: $e",
        name: "CompanyListScreen",
      );
    }
  }

  Future<void> _fetchCompanyContacts({required int companyId}) async {
    await _controller?.evaluateJavascript(
      source: """
        // adding the spinner icon to show the loading
        var companyContactPersonTable = document.querySelector('.componytable');
        if (companyContactPersonTable) {
          companyContactPersonTable.innerHTML = '<span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>';
        }
      """,
    );
    final response = await ClientsController.getUserContactPersonsData(
      companyId,
      userId!,
    );
    developer.log(
      "_fetchCompanyContacts response ${response}",
      name: "CompanyListScreen",
    );

    final bool status = response['status'] == true;
    final message = response['message'] ?? 'Unknown error';

    developer.log("status: $status", name: "CompanyListScreen");
    developer.log("message: $message", name: "CompanyListScreen");

    String tableRowJS = '''
      <tr>
        <td>Name</td>
        <td>Phone</td>
        <td>Email</td>
        <td>Job title</td>
      </tr>
    ''';

    // makes sure the widget is mounted or in the context
    if (!mounted) return;

    if (status) {
      final companyContactPersonsData = response['data'] as List;

      if (companyContactPersonsData.isNotEmpty) {
        developer.log("i m here");
        for (int i = 0; i < companyContactPersonsData.length; i++) {
          final company = companyContactPersonsData[i];
          if (company == null) continue; // skip if null

          final contactPersonName = Functions.escapeJS(
            company['contact_person'] ?? '',
          );
          final contactPersonEmail = Functions.escapeJS(
            company['contact_email'],
          );
          final contactPersonPhone = Functions.escapeJS(
            company['contact_phone'],
          );
          final jobTitle = Functions.escapeJS(company['job_title']);

          tableRowJS += """
            <tr>
              <td>$contactPersonName</td>
              <td>$contactPersonPhone</td>
              <td>$contactPersonEmail</td>
              <td>$jobTitle</td>
            </tr>
          """;
        }
        developer.log("tableRowJS: $tableRowJS", name: "CompanyListScreen");
        await _controller?.evaluateJavascript(
          source: """
            var companyContactPersonTable = document.querySelector('.componytable');
            if (companyContactPersonTable) {
              companyContactPersonTable.innerHTML = ''; // cleanly clear all rows
              companyContactPersonTable.insertAdjacentHTML('beforeend', `$tableRowJS`);
            }
          """,
        );
      }
    } else {
      await _controller?.evaluateJavascript(
        source: """
          var companyContactPersonTable = document.querySelector('.componytable');
          if (companyContactPersonTable) {
            const html = `<tr><td colspan="5" style="text-align:left;">No contact person found</td></tr>`;
            companyContactPersonTable.innerHTML = html;
          }
        """,
      );
    }
  }

  Future<void> injectMoreJS() async {
    await _controller?.evaluateJavascript(
      source: """
        // Remove loading spinner
        const loaderToRemove = document.getElementById('dataLoader');
        if (loaderToRemove) loaderToRemove.remove();        
        
        const fieldIds = [
          'company', 'city', 'zip', 'state',
          'fullname', 'mobile', 'whatsappnumber',
          'email', 'jobtitle'
        ];

        function resetCompanyForm() {
          fieldIds.forEach(id => {
            const field = document.getElementById(id);
            if (field) {
              field.value = '';
            }
          });
        }

        // accessing the save button and storing it
        const saveBtn = document.querySelector('.btn.btn-primary.savecomdetails');
        
        function setupButtonListener() {
          if (saveBtn) {
            saveBtn.onclick = function(event) {
              event.preventDefault();
              let allFilled = true;
              fieldIds.forEach(id => {
                const field = document.getElementById(id);
                if (field && field.value.trim() === '') {
                  allFilled = false;
                }
              });
              if (allFilled) {
                alert('Please fill all the fields');
              } else {
                // Proceed with form submission if needed
                // Replace the save button content with a spinner indicator and disable it
                saveBtn.disabled = true;
                saveBtn.innerHTML = '<span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span> Saving...';

                const finalPayload = fieldIds.reduce((acc, id) => {
                  acc[id] = document.getElementById(id)?.value || '';
                  return acc;
                }, {});

                // Send the data to the Flutter side
                window.flutter_inappwebview.callHandler("HANDLE_ADD_COMPANY_DATA", JSON.stringify(finalPayload));
              }
            };
          }
        }

        // Wait until all form fields are available
        const waitForFields = setInterval(() => {
          const allExist = fieldIds.every(id => document.getElementById(id));
          if (allExist) {
            clearInterval(waitForFields);
            resetCompanyForm();
            setupButtonListener();
          }
        }, 300); // check every 300ms
      """,
    );
  }

  Future<void> _handleAddCompany({Map<String, dynamic>? companyData}) async {
    try {
      // get all the fields and send to the api to create or add the company
      final companyName = companyData?["company"];

      if (companyName != null) {
        // Call the API to change the password
        final response = await ApiBase.post('/companies', {
          'name': "$companyName",
          'description': "hahead",
        });
        //   'city': "",
        //   'zip': "",
        //   'state': "",

        //   // fields for clients data
        //   'fullname': "",
        //   'mobile': "",
        //   'whatsupnumber': "",
        //   'email': "",
        //   'jobtitle': "",
        // });

        developer.log("response: $response", name: 'CompanyListScreen');

        // if everything goes well it follows from here, shows snackbar and all

        // makes sure the widget is mounted or in the context
        if (!mounted) return;
        // Handle the error here, e.g., show a message to the user
        // Show a snackbar or dialog with the error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ?? 'Company Details Saved Successfully.',
            ),
          ),
        );

        // clear the company and clients fields, after successfull saving details and remove the spinner
        await _controller?.evaluateJavascript(
          source: '''
          resetCompanyForm();
          // Remove the spinner and enable the save button again
          saveBtn.disabled = false;
          saveBtn.innerHTML = 'Save';
          const addCompanyFormCloseButton = document.querySelector('button[type="button"].mfp-close');
          if(addCompanyFormCloseButton){
            addCompanyFormCloseButton.click();
          }
        ''',
        );
      }
    } catch (e) {
      developer.log(
        "Error handling Adding Company data: $e",
        name: 'CompanyListScreen',
        error: e,
      );

      // makes sure the widget is mounted or in the context
      if (!mounted) return;
      // Handle the error here, e.g., show a message to the user
      // Show a snackbar or dialog with the error message
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));

      await _controller?.evaluateJavascript(
        source: '''
          // Remove the spinner and enable the save button again
          saveBtn.disabled = false;
          saveBtn.innerHTML = 'Save';
        ''',
      );
    }
  }
}
