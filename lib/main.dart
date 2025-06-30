import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tikitar_demo/features/auth/login_screen.dart';
import 'package:tikitar_demo/features/other/foregroundBackground.dart';
import 'package:tikitar_demo/features/other/splash_screen.dart';
import 'package:tikitar_demo/features/webview/company_list_screen.dart';
import 'package:tikitar_demo/features/webview/dashboard_screen.dart';
import 'package:tikitar_demo/features/webview/meeting_list_screen.dart';
import 'package:tikitar_demo/features/webview/my_profile_screen.dart';
import 'package:tikitar_demo/features/webview/task_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure this line is there
  //You're calling SharedPreferences.getInstance() before Flutter is fully ready,
  //most likely before WidgetsFlutterBinding.ensureInitialized() is called.

  await Firebase.initializeApp();

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

class _MyAppState extends State<MyApp> {
  
  @override
  void initState() {
    super.initState();
    _checkAndRequestLocationPermission();
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

  Future<void> _checkAndRequestLocationPermission() async {
    FlutterBackgroundService().invoke('stopService'); // Clear any existing

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

    if (foregroundStatus.isGranted) {
      // fetch the locaion in foreground mode which is used to track the user location
      // when the app is open or in the ram (user using other app)
      await initializeForegroundBackgroundService(); // Initialize the background service
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
                    onPressed: () => Get.back(),
                    child: Text("Cancel"),
                  ),
                ],
              ),
        );
      }
    }
  }
}
