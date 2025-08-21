import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/route_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tikitar_demo/features/common/functions.dart';
import 'package:tikitar_demo/features/common/repositories/category_repository.dart';
import 'package:tikitar_demo/features/common/repositories/monthly_data_repository.dart';
import 'package:tikitar_demo/features/common/repositories/personal_data_repository.dart';
import 'package:tikitar_demo/features/common/view/pages/webview_common_screen.dart';
import 'package:tikitar_demo/features/dashboard/repositories/employee_reportings_repository.dart';
import 'package:tikitar_demo/features/meetings/view/pages/meeting_list_screen.dart';
import 'dart:developer' as developer;
import 'dart:io' show Platform;
import 'package:tikitar_demo/core/abstractions/firebase_api.dart';
import 'package:tikitar_demo/features/other/foregroundBackground.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>{
  bool? fetchShowGaugesBoolFromPreferences;
  int daysInMonth = 0;

  @override
  void initState() {
    super.initState();
    _initializeDashboard();

    // Asynchronous initialization
    _asyncInitialization();
  }

  void _asyncInitialization() async {
    // 1. First, initialize categories
    ref.read(categoryProvider);

    // 2. Request and handle push notification permissions.
    // The code will wait here until the user responds to the dialog.
    await initializePushNotifications();

    // 3. Request and handle location permissions.
    // This will only be called AFTER the push notification dialog is handled.
    await _checkAndRequestLocationPermission();

    // 4. Finally, fetch and send location history data
    // from shared preferences key of 'location_history'
    await fetchAndSendLocationHistoryData();
  }

  Future<void> _checkAndRequestLocationPermission() async {
    LocationPermission? permission;

    // Step 1: Check current permission
    if (Platform.isAndroid || Platform.isIOS) {
      permission = await Geolocator.checkPermission();
    } else {
      return; // unsupported platform
    }

    // Step 2: Request once if necessary
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    // Step 3: Check again and handle
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      // Permission granted, start the background service
      // _startLocationServiceSafely();
    } else if (permission == LocationPermission.deniedForever) {
      // Permission permanently denied

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
                    onPressed: () => Get.back(),
                    child: Text("Cancel"),
                  ),
                ],
              ),
        );
      }
    }
  }
  
  /// Starts the location tracking service without blocking UI
  /// // fetch the locaion in foreground mode which is used to track the user location
    // when the app is open or in the ram (user using other app)
  void _startLocationServiceSafely() {
    Future.microtask(() async {
      final service = FlutterBackgroundService();
      if (!(await service.isRunning())) {
        await initializeForegroundBackgroundService(); // Initialize the background service
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WebviewCommonScreen(
      url: "dashboard.php",
      title: "Dashboard",
      onLoadStop: (controller, url) async {
        // Handle the dashboard load logic
        await handleDashboardLoad(controller);
      },
    );
  }

  // basically a function to handle the multiple await functions
  Future<void> handleDashboardLoad(InAppWebViewController controller) async {
    // as the name suggest, fetch and insert the Users Data which are reporting to this user
    await fetchAndInjectUsers(
      controller: controller,
      pageName: "DashboardScreen",
    );

    // fetch data related to individual like personalTarget and bonusMetric
    await fetchIndividualData(controller: controller);
  }

  Future<void> _initializeDashboard() async {
    // Get the current year and month
    final DateTime now = DateTime.now();
    final int currentYear = now.year;
    final int currentMonth = now.month;
    // Calculate the number of days in the current month
    daysInMonth = DateUtils.getDaysInMonth(currentYear, currentMonth);
  }

  
  Future<void> fetchAndInjectUsers({
    required InAppWebViewController controller,
    String? pageName,
  }) async {
    // access to the boolean values
    final showGaugesBoolean = ref.watch(showGaugesBooleanProvider);
    
    String tableRowsJS = '''
      <tr>
        <th>Rank</th>
        <th>Employee Name</th>
        <th>Role</th>
        <th>View</th>
      </tr>
    ''';

    try {
      final employeeReportingList = await ref.read(employeeReportingsProvider.future);
      debugPrint("employeeReportingList: $employeeReportingList");

      if(employeeReportingList.isEmpty){
        // will make the throw the exception, then the catch statement executes
        // where the current user meetings will be listed or injected here
        throw Exception("No employees reporting to this user");
      }

      for (int i = 0; i < employeeReportingList.length; i++) {
        final user = employeeReportingList[i];
        final rank = i + 1;
        final name = Functions.escapeJS(user.name);
        final role = Functions.escapeJS(user.role);
        final id = Functions.escapeJS(user.id.toString());
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

      // as there are users, that are reporting to this logged in user
      // then show the two gauges, that are under the main gauge, and update
      // the variable in riverpod state management
      await ref.read(monthlyDataProvider.notifier).fetchMonthlyData(daysInMonth: daysInMonth);
      final webViewHelper = MonthlyDataWebViewHelper(controller);
      // show the gauges
      await webViewHelper.showGauges();
      
      // store the montlyData of gauges
      final monthlyDataState = ref.watch(monthlyDataProvider);

      // update or set the value of the gauges
      webViewHelper.insertCurrentMonthMeetingsValue(
        monthlyDataState.currentMonthMeetingsValueDisplay,
      );
      webViewHelper.insertCurrentMonthTargetValue(monthlyDataState.averageMeetings);

      // default to showing gauges
      if (showGaugesBoolean == false) {
        ref.read(showGaugesBooleanProvider.notifier).state = true;
      }
    } catch (e) {
      developer.log("Error: $e", name: "$pageName");

      fetchAndInjectMeetings(
        ref: ref,
        controller: controller,
        pageName: pageName,
      );

      // If there are no users reporting to this user, then hide the gauges
      // and update the variable in riverpod state management
      if (showGaugesBoolean == true) {
        ref.read(showGaugesBooleanProvider.notifier).state = false;
      }
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
          
          //❌ Remove loading spinner
          var loaderToRemove = document.getElementById('dataLoader');
          if (loaderToRemove) loaderToRemove.remove(); 
        """;
      await controller.evaluateJavascript(source: fullJS);
    } catch (e) {
      developer.log("Invalid JS Code: $e", name: "$pageName");
    }
  }

  Future<void> fetchIndividualData({
    required InAppWebViewController controller,
  }) async {
    // instance of the PersonalDataWebViewHelper class
    final webViewHelper = PersonalDataWebViewHelper(controller);

    // fetching or getting the personal Target Value using the apis
    await ref.read(personalDataProvider.notifier).fetchPersonalTargetData();
    
    // fetching or getting the bonusMetricValue using the apis
    await ref.read(personalDataProvider.notifier).fetchBonusMetricData();

    // store the montlyData of gauges
    final personalDataState = ref.read(personalDataProvider);

    // inserting the personalTarget Value
    webViewHelper.insertPersonalTargetValue(
      personalDataState.personalTargetValueDisplay
    );
    
    // inserting the bonusMetric Data
    webViewHelper.insertBonusMetricValue(
      personalDataState.bonusMetricTargetCompletion
    );
  }

  Future<void> initializePushNotifications() async {
    final permissionStatus = await Permission.notification.status;
    debugPrint("🔍 Current notification permission: $permissionStatus");

    if (permissionStatus.isDenied || permissionStatus.isRestricted) {
      final result = await Permission.notification.request();
      debugPrint("🔔 Requested notification permission: $result");

      if (!result.isGranted) {
        debugPrint("❌ Notification permission not granted.");
        return;
      }
    }

    debugPrint("✅ Notification permission granted. Initializing Firebase...");
    await FirebaseApi.initNotifications();
  }

  Future<void> fetchAndSendLocationHistoryData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> locationList = prefs.getStringList('location_history') ?? [];

    // send location list history data logic
    if (locationList.isNotEmpty) {
      print("📍 Location History (${locationList.length} entries):");
      for (var i = 0; i < locationList.length; i++) {
        print("[$i] ${locationList[i]}");
      }

      // await FirebaseApi.sendLocationHistory(
      //   userId: userId,
      //   locationData: locationList,
      // );
    }

    // Clear the location history after sending
    prefs.setStringList('location_history', []);
    debugPrint("📍 Location history data sent and cleared.");
  }
}
