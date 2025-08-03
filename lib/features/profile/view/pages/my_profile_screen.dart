import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tikitar_demo/features/common/functions.dart';
import 'package:tikitar_demo/features/common/view/pages/webview_common_screen.dart';
import 'package:tikitar_demo/core/network/api_base.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:developer' as developer;

import 'package:tikitar_demo/features/profile/repositories/profile_repository.dart';

class MyProfileScreen extends ConsumerStatefulWidget {
  const MyProfileScreen({super.key});

  @override
  ConsumerState<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends ConsumerState<MyProfileScreen> {
  String base64String = '';
  InAppWebViewController? _controller;

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    return WebviewCommonScreen(
      url: "myprofile.php",
      title: "My Profile",
      onLoadStop: (controller, url) async {
        if (profileState == null) return;
        // // get the response from the API
        // late final Map<String, dynamic>? response;
        // try {
        //   response = await ApiBase.get('/user');
        // } catch (e) {
        //   developer.log(
        //     "Error fetching user data: $e",
        //     name: 'UserProfileWebView',
        //     error: e,
        //   );
        //   return;
        // }
        // if (response == null) return;
        // developer.log("response: $response", name: 'UserProfileWebView');

        // for the extraction of the data and the address
        // final data = response['data']?['user'];
        // final address = data['address'] ?? {};

        final dataVirtualContactFile = '''
BEGIN:VCARD
VERSION:3.0
N:${profileState.lastName};${profileState.firstName};;;
FN:${profileState.firstName} ${profileState.lastName}
TEL;TYPE=WORK,VOICE:${profileState.mobile}
TEL;TYPE=cell,waid=${profileState.mobile}:${profileState.mobile}
EMAIL:${profileState.email}
ADR;TYPE=home:;;${profileState.address};${profileState.city};${profileState.state};;${profileState.zip}
URL:https://tikitar.com
END:VCARD
''';
        base64String = await generateQrCode(dataVirtualContactFile);

        // Inject the user profile data into the webview
        await _injectJSandUserProfile(controller, profileState.toJson());
      },
      onWebViewCreated: (controller) {
        // Set the controller to the state variable
        _controller = controller;

        // Set up the JavaScript handler for password change
        controller.addJavaScriptHandler(
          handlerName: "SUBMIT_PASSWORD_CHANGE_DATA",
          callback: (args) {
            // args[0] is finalPayload from JavaScript
            developer.log(
              "Received payload from WebView: ${args[0]}",
              name: 'UserProfileWebView',
            );

            // You can now parse and use it
            final Map<String, dynamic> data = jsonDecode(args[0]);
            _handlePasswordChangeData(data);
          },
        );
      },
    );
  }

  Future<String> generateQrCode(String data) async {
    final qrValidationResult = QrValidator.validate(
      data: data,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.L,
    );

    if (qrValidationResult.status != QrValidationStatus.valid) {
      throw Exception("QR Code generation failed");
    }

    final qrCode = qrValidationResult.qrCode!;
    final painter = QrPainter.withQr(
      qr: qrCode,
      gapless: true,
      // for the side main dots of the QR code
      eyeStyle: QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: const ui.Color(0xFF000000),
      ),
      // for the data module or the dots of the QR code
      dataModuleStyle: QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: const ui.Color(0xFF000000),
      ),
      embeddedImage: null,
      embeddedImageStyle: QrEmbeddedImageStyle(size: const Size(40, 40)),
    );

    final ui.Image picData = await painter.toImage(300); // 330px
    final ByteData? byteData = await picData.toByteData(
      format: ui.ImageByteFormat.png,
    );
    if (byteData == null) {
      throw Exception('Failed to generate image data');
    }

    final Uint8List pngBytes = byteData.buffer.asUint8List();
    return base64Encode(pngBytes);
  }

  Future<void> _injectJSandUserProfile(
    InAppWebViewController controller,
    Map<String, dynamic> profileData,
  ) async {
    try {
      developer.log("data: $profileData", name: 'UserProfileWebView');

        String escape(dynamic val) =>
            Functions.escapeJS(val?.toString() ?? 'empty');

        final js = """
          document.getElementById("firstName").value = "${escape(profileData['first_name'])}";
          document.getElementById("lastName").value = "${escape(profileData['last_name'])}";
          document.getElementById("mobile").value = "${escape(profileData['mobile'])}";
          document.getElementById("whatsappnumber").value = "${escape(profileData['mobile'])}";
          document.getElementById("email").value = "${escape(profileData['email'])}";
          document.getElementById("jobtitle").value = "${escape(profileData['jobtitle'])}";
          document.getElementById("address").value = `${escape(profileData['address'])}`;
          document.getElementById("city").value = "${escape(profileData['city'])}";
          document.getElementById("zip").value = "${escape(profileData['zip'])}";
          document.getElementById("state").value = "${escape(profileData['state'])}";


          // getting the password fields & clearing their existing values
          const currentPassword = document.getElementById("currentpassword");
          const newPassword = document.getElementById("newpassword");
          const retypePassword = document.getElementById("retypepassword");
          function clearPasswordFields() {
            if(currentPassword){
              currentPassword.value = "";
            }
            if(newPassword){
              newPassword.value = "";
            }
            if(retypePassword){
              retypePassword.value = "";
            }
          }

          // action to clear the password fields
          clearPasswordFields();

          // getting the submit button
          const submitButton = document.querySelector('button[type="submit"].btn.btn-primary.text-uppercase');

          // "for default" removing the "password not match" alert
          const passwordDoesNotMatch = document.getElementsByClassName("passwordnotmatch");
          if (passwordDoesNotMatch.length > 0) {
            passwordDoesNotMatch[0].style.display = "none";
          }

          
          // action on the "confirm" button for change password field
          const confirmButton = document.getElementsByClassName("btn btn-primary text-uppercase");
          if(confirmButton.length > 0) {
            confirmButton[0].onclick = function(event) {
              // Prevents the default action
              event.preventDefault();

              // Check if the new password and retype password fields does not match and are empty
              if (newPassword.value != retypePassword.value || (retypePassword.value == "" && newPassword.value == "")) {
                passwordDoesNotMatch[0].style.display = "block";
              }else {
                passwordDoesNotMatch[0].style.display = "none";

                // Replace the confirm button content with a spinner indicator and disable it
                submitButton.disabled = true;
                submitButton.innerHTML = '<span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span> confirming...';

                const finalPayload = {
                  "currentpassword": currentPassword.value,
                  "newpassword": newPassword.value,
                  "retypepassword": retypePassword.value
                };

                // Send the data to the Flutter side
                window.flutter_inappwebview.callHandler("SUBMIT_PASSWORD_CHANGE_DATA", JSON.stringify(finalPayload));
              }
            };
          }


          // Inject the QR code image into the webview in the safe manner, even if the
          // element is not yet available or takes time to load
          let attempts = 0; // Limit the number of attempts to avoid infinite loops
          const maxAttempts = 50; // Maximum number of attempts (e.g., 50 * 100ms = 5 seconds)
          const qrinterval = setInterval(() => {
            const el = document.getElementById("viewqrcode");
            if (el) {
              el.innerHTML = '<img style="width:100%" src="data:image/png;base64,$base64String" />';
              clearInterval(qrinterval); // Stop the interval once the element is found
            } else if (++attempts >= maxAttempts) {
              clearInterval(qrinterval); // Stop the interval after max attempts
              console.warn("Element with id 'viewqrcode' not found within the time limit.");
            }
          }, 100);

          //❌ Remove loading spinner
          var loaderToRemove = document.getElementById('dataLoader');
          if (loaderToRemove) loaderToRemove.remove();
        """;

        await controller.evaluateJavascript(source: js);

    } catch (e) {
      developer.log(
        "Error injecting user data: $e",
        name: 'UserProfileWebView',
        error: e,
      );
    }
  }

  Future<void> _handlePasswordChangeData(Map<String, dynamic> data) async {
    // Handle the password change data here
    try {
      final currentPassword = data['currentpassword'];
      final newPassword = data['newpassword'];
      final retypePassword = data['retypepassword'];

      if (currentPassword != null &&
          newPassword != null &&
          retypePassword != null) {
        // Call the API to change the password
        final response = await ApiBase.post('/change-password', {
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': retypePassword,
        });

        developer.log("response: $response", name: 'UserProfileWebView');
        // response:   {status: true, message: Password changed successfully.}

        // if everything goes well it follows from here, shows snackbar and all

        // makes sure the widget is mounted or in the context
        if (!mounted) return;
        // to show the message using the snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ?? 'Password changed successfully.',
            ),
          ),
        );

        // clear the password fields, after successfull password change and remove the spinner
        await _controller?.evaluateJavascript(
          source: '''
            clearPasswordFields();
            // Remove the spinner and enable the button again
            submitButton.disabled = false;
            submitButton.innerHTML = 'Confirm';
            const changePasswordFormCloseButton = document.querySelector('button[type="button"].mfp-close');
            if(changePasswordFormCloseButton){
              changePasswordFormCloseButton.click();
            }
          ''',
        );
      }
    } catch (e) {
      developer.log(
        "Error handling password change data: $e",
        name: 'UserProfileWebView',
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
          // Remove the spinner and enable the confirm button again
          submitButton.disabled = false;
          submitButton.innerHTML = 'Confirm';
        ''',
      );
    }
  }
}
