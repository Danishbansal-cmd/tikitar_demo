import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
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
    // Stop existing background service
    FlutterBackgroundService().invoke('stopService');

    // Step 1: Check current permission
    LocationPermission permission = await Geolocator.checkPermission();

    // Step 2: Request once if necessary
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    // Step 3: Check again and handle
    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      // Permission granted
      // fetch the locaion in foreground mode which is used to track the user location
      // when the app is open or in the ram (user using other app)
      await initializeForegroundBackgroundService(); // Initialize the background service
    } else if (permission == LocationPermission.deniedForever) {
      // Permission permanently denied
      
      // Check if the widget is still mounted before showing the dialog
      // it ensures that the dialog is shown only if the widget is still in the widget tree
      if (!mounted) return;

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
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
