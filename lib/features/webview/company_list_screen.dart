import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:tikitar_demo/common/webview_common_screen.dart';

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
      },
      onLoadStop: (controller, url) async {
        // You can add any additional logic here if needed
        if (from == 'handler') {
          await controller.evaluateJavascript(
            source: """
            const addCompanyButton = document.querySelector('a.addcomp.popup-link[href="#addcomponydetails"]');
            if (addCompanyButton) {
              addCompanyButton.click();
            }
          """,
          );
        }
        await injectMoreJS();       
      },
    );
  }

Future<void> injectMoreJS() async {
  await _controller?.evaluateJavascript(source: """
    const fieldIds = [
      'company', 'city', 'zip', 'state',
      'fullname', 'mobile', 'whatsappnumber',
      'email', 'jobtitle'
    ];

    function resetForm() {
      fieldIds.forEach(id => {
        const field = document.getElementById(id);
        if (field) {
          field.value = '';
        }
      });
    }

    function setupButtonListener() {
      const saveBtn = document.querySelector('.btn.btn-primary.savecomdetails');
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
          if (!allFilled) {
            alert('Please fill all the fields');
          } else {
            // Proceed with form submission if needed
          }
        };
      }
    }

    // Wait until all form fields are available
    const waitForFields = setInterval(() => {
      const allExist = fieldIds.every(id => document.getElementById(id));
      if (allExist) {
        clearInterval(waitForFields);
        resetForm();
        setupButtonListener();
      }
    }, 300); // check every 300ms
  """);
}
}
