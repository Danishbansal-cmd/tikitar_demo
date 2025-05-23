import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tikitar_demo/common/functions.dart';
import 'package:tikitar_demo/common/webview_common_screen.dart';
import 'package:tikitar_demo/features/auth/categories_controller.dart';
import 'package:tikitar_demo/features/auth/clients_controller.dart';
import 'package:tikitar_demo/features/auth/user_controller.dart';
import 'package:tikitar_demo/features/data/local/data_strorage.dart';
import 'package:tikitar_demo/features/webview/meeting_list_screen.dart';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int userId = 0;

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
    _checkAndRequestLocationPermission();
    _fetchCategoriesAndStore(); // to get the categories Option and Store it
    _fetchAllStates(); // to get or fetch all the states
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

    // as the name suggest, fetch and insert the Users Data which are reporting to this user
    await fetchAndInjectUsers(
      controller: controller,
      pageName: "DashboardScreen",
    );
  }

  Future<void> _initializeDashboard() async {
    // Get userData from SharedPreferences, to finally get the userId
    final userData = await DataStorage.getUserData();
    if (userData != null) {
      final decoded = jsonDecode(userData);
      userId = int.tryParse(decoded['id'].toString()) ?? 0;
    }
    developer.log("Extracted userId: $userId", name: "DashboardScreen");
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

  Future<void> fetchAndInjectUsers({
    required InAppWebViewController controller,
    String? pageName,
  }) async {
    try {
      final response = await UserController.specificEmployeesReporting(userId);
      final users = response['employees'];

      String tableRowsJS = '';
      for (int i = 0; i < users.length; i++) {
        final user = users[i];
        final rank = i + 1;
        final name = Functions.escapeJS(user['name'] ?? '');
        final role = Functions.escapeJS(user['role'] ?? '');
        final id = Functions.escapeJS(user['id'].toString());
        tableRowsJS += """
            <tr>
              <td>$rank</td>
              <td>$name</td>
              <td>$role</td>
              <td>
                <span class="material-symbols-outlined" style="cursor:pointer;" 
                      onclick="window.flutter_inappwebview.callHandler('onUserViewClick', '$id', '$name')">
                  visibility
                </span>
              </td>
            </tr>
          """;
      }

      // to insert the data into the table, the user will be navigated to the other page
      // to let the current user view all the meetings of the user
      // that works under or below them
      injectTableData(
        controller: controller,
        tableRowsDataJS: tableRowsJS,
        pageName: pageName,
      );
    } catch (e) {
      developer.log("Error: $e", name: "$pageName");

      fetchAndInjectMeetings(
        controller: controller,
        pageName: pageName,
        userId: userId,
      );
    }
  }

  Future<void> injectTableData({
    required controller,
    required String tableRowsDataJS,
    String? pageName,
  }) async {
    try {
      final fullJS = """
          const table = document.querySelector('.reporttable');
          const rows = table.querySelectorAll('tr');
          for (let i = rows.length - 1; i > 0; i--) {
            table.deleteRow(i);
          }
          table.insertAdjacentHTML('beforeend', `$tableRowsDataJS`); 
        """;
      await controller.evaluateJavascript(source: fullJS);
    } catch (e) {
      developer.log("Invalid JS Code: $e", name: "$pageName");
    }
  }

  Future<void> _fetchCategoriesAndStore() async {
    try {
      // Fetch categories first
      final categories = await CategoryController.fetchCategories();
      developer.log("categories data $categories", name: "DashboardScreen");
      // save it in sharedPreference store
      DataStorage.saveCategoryOptionsData(jsonEncode(categories));
    } catch (e) {
      developer.log(
        "Error _fetchCategoriesAndStore(): $e",
        name: "DashboardScreen",
      );
    }
  }

  Future<void> _fetchAllStates() async {
    const String url =
        'https://api.data.gov.in/resource/a71e60f0-a21d-43de-a6c5-fa5d21600cdb';
    const String apiKey =
        '579b464db66ec23bdd000001cdc3b564546246a772a26393094f5645';

    var response = await http.get(
      Uri.parse('$url?api-key=$apiKey&offset=0&limit=all&format=json'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      developer.log('Title: ${data['title']}', name: "DashboardScreen");

      List records = data['records'] ?? [];
      // Extract and store unique state names
      List<String> stateNames =
          records
              .map((record) => record['state_name_english'] as String?)
              .whereType<String>() // filters out nulls
              .toSet() // optional: remove duplicates
              .toList();

      developer.log(
        "states name data: ${stateNames.toString()}",
        name: "DashboardScreen",
      );
      await DataStorage.saveStateNames(stateNames);
    } else {
      developer.log(
        'Failed to load Sates name data: ${response.statusCode}',
        name: "DashboardScreen",
      );
    }
  }
}
