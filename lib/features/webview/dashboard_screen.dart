import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tikitar_demo/common/webview_common_screen.dart';
import 'package:tikitar_demo/features/auth/clients_controller.dart';
import 'package:tikitar_demo/features/webview/meeting_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _checkAndRequestLocationPermission();
  }

  @override
  Widget build(BuildContext context) {
    return WebviewCommonScreen(
      url: "dashboard.php",
      title: "Dashboard",
      onLoadStop: (controller, url) async {
        await handleDashboardLoad(controller);
      },
    );
  }

  // basically a function to handle the multiple await functions
  Future<void> handleDashboardLoad(InAppWebViewController controller) async {
    await ClientsController.fetchAndStoreClientsData();

    // as the name suggest, fetch and insert the meetings data
    await fetchAndInjectMeetings(controller);
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
      // Check if the widget is still mounted before showing the dialog
      // it ensures that the dialog is shown only if the widget is still in the widget tree
      if (!mounted) return;

      if (context.mounted) {
        showDialog(
          context: context,
          builder:
              (_) => AlertDialog(
                title: Text("Permission Required"),
                content: Text(
                  "Location permission is permanently denied. Please enable it in app settings.",
                ),
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
}
