import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tikitar_demo/features/auth/login_screen.dart';
import 'package:tikitar_demo/features/other/database.dart';
import 'package:tikitar_demo/features/other/splash_screen.dart';
import 'package:tikitar_demo/features/webview/company_list_screen.dart';
import 'package:tikitar_demo/features/webview/dashboard_screen.dart';
import 'package:tikitar_demo/features/webview/meeting_list_screen.dart';
import 'package:tikitar_demo/features/webview/my_profile_screen.dart';
import 'package:tikitar_demo/features/webview/task_screen.dart';
import 'dart:developer' as developer;

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure this line is there
  //You're calling SharedPreferences.getInstance() before Flutter is fully ready,
  //most likely before WidgetsFlutterBinding.ensureInitialized() is called.

  await Firebase.initializeApp();
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  // Force portrait mode only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown, // optional: allows upside-down portrait
  ]);

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp>{
  DatabaseHelper dbHelper = DatabaseHelper.privateConstructor();
  List<Map<String, dynamic>> _locations = [];
  
  @override
  void initState() {
    super.initState();
    _performDatabaseOperations();
  }


  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/', // initial route when app starts
      getPages: [
        GetPage(name: '/', page: () => SplashScreen()),
        GetPage(name: '/login', page: () => LoginScreen()),
        GetPage(name: '/dashboard', page: () => DashboardScreen()),
        GetPage(name: '/task', page: () => TaskScreen()),
        GetPage(name: '/profile', page: () => MyProfileScreen()),
        GetPage(name: '/meetingList', page: () => MeetingListScreen()),
        GetPage(name: '/companyList', page: () => CompanyListScreen()),
        GetPage(name: '/addTask', page: () => TaskScreen()),
      ],
    );
  }

  

Future<void> _performDatabaseOperations() async {
    // Insert sample data
    int insertedId = await dbHelper.insertData({
      'name': 'Sample Place',
      'latitude': '28.7041',
      'longitude': '77.1025',
    });
    developer.log('Inserted ID: $insertedId');

    // Retrieve all rows
    List<Map<String, dynamic>> allRows = await dbHelper.retrieveAllData();
    developer.log('All rows: $allRows', name: "Main.dart");

    // Update the inserted row
    await dbHelper.updateData({
      '_id': insertedId,
      'name': 'Updated Place',
      'latitude': '28.7000',
      'longitude': '77.1000',
    });

    // Retrieve again
    List<Map<String, dynamic>> updatedRows = await dbHelper.retrieveAllData();
    developer.log('After update: $updatedRows', name: "Main.dart");

    // Delete the row
    await dbHelper.deleteData(insertedId);

    // Check final state
    List<Map<String, dynamic>> finalRows = await dbHelper.retrieveAllData();
    developer.log('After delete: $finalRows', name: "Main.dart");

    // Update UI with current DB data
    setState(() {
      _locations = finalRows;
    });
  }
}
