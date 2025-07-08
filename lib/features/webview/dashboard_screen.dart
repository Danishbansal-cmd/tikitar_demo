import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tikitar_demo/common/functions.dart';
import 'package:tikitar_demo/common/webview_common_screen.dart';
import 'package:tikitar_demo/controllers/auth_controller.dart';
import 'package:tikitar_demo/controllers/categories_controller.dart';
import 'package:tikitar_demo/controllers/user_controller.dart';
import 'package:tikitar_demo/features/data/local/data_strorage.dart';
import 'package:tikitar_demo/features/webview/meeting_list_screen.dart';
import 'dart:developer' as developer;
import 'package:tikitar_demo/network/firebase_api.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>{
  int userId = 0;
  bool? fetchShowGaugesBoolFromPreferences;
  int daysInMonth = 0;

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
    _fetchCategoriesAndStore(); // to get the categories Option and Store it
    initializePushNotifications();
    fetchAndSendLocationHistoryData(); // Fetch and send location history data from shared preferences key of 'location_history'
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
    // Get userData from SharedPreferences, to finally get the userId
    final userData = await DataStorage.getUserData();
    if (userData != null) {
      final decoded = jsonDecode(userData);
      userId = int.tryParse(decoded['id'].toString()) ?? 0;
    }
    developer.log("Extracted userId: $userId", name: "DashboardScreen");

    // Get gauges data from SharedPreferences, to finally decide whether to show gauges or not
    fetchShowGaugesBoolFromPreferences =
        await DataStorage.getShowGaugesBoolean();
    developer.log(
      "Extracted fetchShowGaugesBoolFromPreferences: $fetchShowGaugesBoolFromPreferences",
      name: "DashboardScreen",
    );
    
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
    String tableRowsJS = '''
      <tr>
        <th>Rank</th>
        <th>Employee Name</th>
        <th>Role</th>
        <th>View</th>
      </tr>
    ''';
    try {
      final response = await UserController.specificEmployeesReporting(userId);
      final users = response['employees'];

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

      // as there are users, that are reporting to this logged in user
      // then show the two gauges, that are under the main gauge, and update
      // the variable in shared Preferences
      Functions.fetchMonthlyData(controller: controller, daysInMonth: daysInMonth);

      // If no preference is set, default to showing gauges
      if (fetchShowGaugesBoolFromPreferences == null ||
          fetchShowGaugesBoolFromPreferences == false) {
        DataStorage.saveShowGaugesBoolean(true);
      }
    } catch (e) {
      developer.log("Error: $e", name: "$pageName");

      fetchAndInjectMeetings(
        controller: controller,
        pageName: pageName,
        userId: userId,
      );

      // If there are no users reporting to this user, then hide the gauges
      // and update the variable in shared Preferences
      if (fetchShowGaugesBoolFromPreferences == null ||
          fetchShowGaugesBoolFromPreferences == true) {
        DataStorage.saveShowGaugesBoolean(false);
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
    // for Personal Target Value
    String personalTargetJS = '';
    final personalTargetData = await AuthController.fetchPersonalTarget();
    if (personalTargetData['status'] == true) {
      personalTargetJS = "";
      developer.log(
        "personalTargetData: $personalTargetData",
        name: "fetchIndividualData",
      );
      final int totalMeetings =
          int.tryParse(
            personalTargetData['data']['total_meetings'].toString(),
          ) ??
          0;
      final int meetingTarget =
          int.tryParse(
            personalTargetData['data']['meeting_target'].toString(),
          ) ??
          0;
      // Guard against division by zero
      int personalTargetValueDisplay = 0;
      if (meetingTarget > 0) {
        personalTargetValueDisplay = ((totalMeetings / daysInMonth)/ meetingTarget).round();
      }
      personalTargetJS = """
        var insertPersonalTargetValue = document.getElementById('personalTargetValue');
        insertPersonalTargetValue.textContent = "$personalTargetValueDisplay";
        updatePersonalTargetValue();
      """;
    } else {
      personalTargetJS = """
        updatePersonalTargetValue();
      """;
    }
    await controller.evaluateJavascript(source: personalTargetJS);

    // for Bonus Metric Value
    String bonusMetricJS = '';
    final bonusMetricData = await AuthController.fetchBonusMetric();
    if (bonusMetricData['status'] == true) {
      developer.log(
        "bonusMetricData: $bonusMetricData",
        name: "fetchIndividualData",
      );
      final targetCompletion = int.tryParse(
        bonusMetricData['data']['target_completion'].toString(),
        ) ??
        0;
      if(targetCompletion <= 0){
        DataStorage.saveShowBonusMetricBoolean(false);
        bonusMetricJS = """
          updateBonusMetricValue();
        """;
      }else{
        DataStorage.saveShowBonusMetricBoolean(true);
        bonusMetricJS = """
          document.getElementById('bonusMetricGauge').style.display = 'block'; 
          var insertBonusMetricValue = document.getElementById('bonusMetricValue');
          insertBonusMetricValue.textContent = "$targetCompletion";
          updateBonusMetricValue();
        """;
      }
    } else {
      bonusMetricJS = """
        updateBonusMetricValue();
      """;
    }
    await controller.evaluateJavascript(source: bonusMetricJS);
  }

  // fetch all the available categories and store in shared preferences
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
