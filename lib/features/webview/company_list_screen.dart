import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:tikitar_demo/common/webview_common_screen.dart';
import 'dart:developer' as developer;

import 'package:tikitar_demo/core/network/api_base.dart';

class CompanyListScreen extends StatefulWidget {
  const CompanyListScreen({super.key});

  @override
  State<CompanyListScreen> createState() => _CompanyListScreenState();
}

class _CompanyListScreenState extends State<CompanyListScreen> {
  InAppWebViewController? _controller;
  Map? args;
  dynamic from;
  bool _initialized = false;

  // This method is called when the widget is first created
  // to safely access and store the route arguments passed
  //to the CompanyListScreen
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      args = ModalRoute.of(context)?.settings.arguments as Map?;
      from = args?['from'];
      _initialized = true;
    }
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
      },
      onLoadStop: (controller, url) async {
        // You can add any additional logic here if needed
        await injectMoreJS();
      },
    );
  }

  Future<void> injectMoreJS() async {
    await _controller?.evaluateJavascript(
      source: """
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
