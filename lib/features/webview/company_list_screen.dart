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
    // Add any additional JavaScript injection here if needed
    // For example, you can inject a script to handle specific events
    // or modify the DOM of the loaded page.
    await _controller?.evaluateJavascript(
      source: """
      // Your JavaScript code here



      // getting the input fields and setting them to empty
      // to reset the form
      const fieldIds = [
        'company', 'city', 'zip', 'state',
        'fullname', 'mobile', 'whatsappnumber',
        'email', 'jobtitle'
      ];
      function resetForm(){
        fieldIds.forEach(id => {
          const field = document.getElementById(id);
          if (field) {
            field.value = '';
          }
        });
      }
      // initializing the form or emptying the fields
      resetForm();


      // getting the add company button and setting the onclick event
      // to prevent the default action and check if all fields are filled
      const addCompanyButton = document.getElementsByClassName('btn btn-primary savecomdetails');
      if(addCompanyButton.length > 0) {
        addCompanyButton[0].onclick = function(event) {
          // Prevents the default action
          event.preventDefault();

          fieldIds.forEach(id => {
            const field = document.getElementById(id);
            if (field && field.value == '') {
              throw new Error('Please fill all the fields');
            }
          });
        };
      }


    """,
    );
  }
}
