import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:tikitar_demo/common/functions.dart';
import 'package:tikitar_demo/common/webview_common_screen.dart';
import 'package:tikitar_demo/core/network/api_base.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:developer' as developer;


class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  String base64String = '';

  @override
  Widget build(BuildContext context) {
    return WebviewCommonScreen(
      url: "myprofile.php",
      title: "My Profile",
      onLoadStop: (controller, url) async {
        // get the response from the API
        late final Map<String, dynamic>? response;
        try {
          response = await ApiBase.get('/user');
        } catch (e) {
          developer.log("Error fetching user data: $e", name: 'UserProfileWebView', error: e);
          return;
        }
        if (response == null) return;
        developer.log("response: $response", name: 'UserProfileWebView');

        // for the extraction of the data and the address
        final data = response['data']?['user'];
        final address = data['address'] ?? {};

        final dataVirtualContactFile = '''
BEGIN:VCARD
VERSION:3.0
N:${data['last_name']};${data['first_name']};;;
FN:${data['first_name']} ${data['last_name']}
TEL;TYPE=WORK,VOICE:${data['mobile']}
TEL;TYPE=cell,waid=${data['mobile']}:${data['mobile']}
EMAIL:${data['email']}
ADR;TYPE=home:;;${address['line1']};${address['city']};${address['state']};;${address['zip']}
URL:https://tikitar.com
END:VCARD
''';
        base64String = await generateQrCode(dataVirtualContactFile);

        // Inject the user profile data into the webview
        await _injectJSandUserProfile(controller, response);
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
        eyeShape: QrEyeShape.circle,
        color: const ui.Color(0xFF000000),
      ),
      // for the data module or the dots of the QR code
      dataModuleStyle: QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.circle,
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
    Map<String, dynamic> response,
  ) async {
    try {
      final data = response['data']?['user'];
      developer.log("data: $data", name: 'UserProfileWebView');

      if (data != null) {
        final address = data['address'] ?? {};

        String escape(dynamic val) =>
            Functions.escapeJS(val?.toString() ?? 'empty');

        final js = """
          document.getElementById("firstName").value = "${escape(data['first_name'])}";
          document.getElementById("lastName").value = "${escape(data['last_name'])}";
          document.getElementById("mobile").value = "${escape(data['mobile'])}";
          document.getElementById("whatsappnumber").value = "${escape(data['mobile'])}";
          document.getElementById("email").value = "${escape(data['email'])}";
          document.getElementById("jobtitle").value = "${escape(data['designation'])}";
          document.getElementById("address").value = `${escape(address['line1'])}`;
          document.getElementById("city").value = "${escape(address['city'])}";
          document.getElementById("zip").value = "${escape(address['zip'])}";
          document.getElementById("state").value = "${escape(address['state'])}";


          // getting the password fields & clearing their existing values
          const currentPassword = document.getElementById("currentpassword");
          const newPassword = document.getElementById("newpassword");
          const retypePassword = document.getElementById("retypepassword");
          if(currentPassword){
            currentPassword.value = "";
          }
          if(newPassword){
            newPassword.value = "";
          }
          if(retypePassword){
            retypePassword.value = "";
          }


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
              if (newPassword.value !== retypePassword.value || (retypePassword.value == "" && newPassword.value == "")) {
                passwordDoesNotMatch[0].style.display = "block";
              }else {
              passwordDoesNotMatch[0].style.display = "none";}
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
        """;

        await controller.evaluateJavascript(source: js);
      }
    } catch (e) {
      developer.log("Error injecting user data: $e", name: 'UserProfileWebView', error: e);
    }
  }
}
