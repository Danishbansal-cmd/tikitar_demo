import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tikitar_demo/common/webview_common_screen.dart';
import 'package:tikitar_demo/features/auth/clients_controller.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}


class _DashboardScreenState extends State<DashboardScreen> {
  InAppWebViewController? _controller;

  @override
  void initState() {
    super.initState();
    _checkAndRequestLocationPermission();
  }

  Future<void> _checkAndRequestLocationPermission() async {
    // First request foreground location permission
    var foregroundStatus = await Permission.locationWhenInUse.status;
    if (foregroundStatus.isDenied || foregroundStatus.isRestricted) {
      foregroundStatus = await Permission.locationWhenInUse.request();
    }

    // Then request background location permission (locationAlways)
    var backgroundStatus = await Permission.locationAlways.status;
    if (backgroundStatus.isDenied || backgroundStatus.isRestricted) {
      backgroundStatus = await Permission.locationAlways.request();
    }

    // If permanently denied, show alert
    if (backgroundStatus.isPermanentlyDenied) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("Permission Required"),
            content: Text("Location permission is permanently denied. Please enable it in app settings."),
            actions: [
              TextButton(
                onPressed: () => openAppSettings(),
                child: Text("Open Settings"),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text("Cancel"),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebviewCommonScreen(
      url: "dashboard.php",
      title: "Dashboard",
      onWebViewCreated: (controller) {
        _controller = controller;
      },
      onLoadStop: (controller, url) async {
        await ClientsController.fetchAndStoreClientsData();
      },
    );
  }
}
