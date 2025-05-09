import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:tikitar_demo/common/webview_common_screen.dart';
import 'package:tikitar_demo/core/network/api_base.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  InAppWebViewController? _controller;
  String base64String = '';

  @override
  Widget build(BuildContext context) {
    return WebviewCommonScreen(
      url: "myprofile.php",
      title: "My Profile",
      onWebViewCreated: (controller) {
        _controller = controller;
      },
      onLoadStop: (controller, url) async {
        // get the response from the API
        late final Map<String, dynamic>? response;
        try {
          response = await ApiBase.get('/user');
        } catch (e) {
          print("Error fetching user data: $e");
          return;
        }
        if (response == null) return;

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
        await _injectUserProfile(controller, response);

        print('base64String: $base64String');
      },
    );
  }

  Future<String> generateQrCode(String data) async {
    final QrValidationResult = QrValidator.validate(
      data: data,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.L,
    );

    if (QrValidationResult.status != QrValidationStatus.valid) {
      throw Exception("QR Code generation failed");
    }

    final qrCode = QrValidationResult.qrCode!;
    final painter = QrPainter.withQr(
      qr: qrCode,
      gapless: true,
      color: const Color(0xFF000000),
      emptyColor: const ui.Color(0xFFFFFFFF),
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

  Future<void> _injectUserProfile(
    InAppWebViewController controller,
    Map<String, dynamic> response,
  ) async {
    try {
      final data = response['data']?['user'];

      if (data != null) {
        final address = data['address'] ?? {};

        final js = """
          document.getElementById("firstName").value = "${_escapeJS(data['first_name'])}";
          document.getElementById("lastName").value = "${_escapeJS(data['last_name'])}";
          document.getElementById("mobile").value = "${_escapeJS(data['mobile'])}";
          document.getElementById("whatsappnumber").value = "${_escapeJS(data['mobile'])}";
          document.getElementById("email").value = "${_escapeJS(data['email'])}";
          document.getElementById("jobtitle").value = "${_escapeJS(data['designation'])}";
          document.getElementById("address").value = `${_escapeJS(address['line1'])}`;
          document.getElementById("city").value = "${_escapeJS(address['city'])}";
          document.getElementById("zip").value = "${_escapeJS(address['zip'])}";
          document.getElementById("state").value = "${_escapeJS(address['state'])}";



          setTimeout(function() {
            console.log("Injecting QR...");
            document.getElementById("viewqrcode").innerHTML = 
              '<img style="width:100%" src="data:image/png;base64,$base64String" />';
            console.log("QR injected!");
          }, 500);
        """;

        await controller.evaluateJavascript(source: js);
      }
    } catch (e) {
      print("Error injecting user data: $e");
    }
  }

  /// Escapes strings to safely inject into JavaScript
  String _escapeJS(String? value) {
    if (value == null) return '';
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll(r'"', r'\"')
        .replaceAll(r'\n', r'\\n')
        .replaceAll("'", r"\'");
  }
}
