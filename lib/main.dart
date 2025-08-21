import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:tikitar_demo/core/theme/theme.dart';
import 'package:tikitar_demo/features/auth/view/pages/login_screen.dart';
import 'package:tikitar_demo/features/other/splash_screen.dart';
import 'package:tikitar_demo/features/companies/view/pages/company_list_screen.dart';
import 'package:tikitar_demo/features/dashboard/view/pages/dashboard_screen.dart';
import 'package:tikitar_demo/features/meetings/view/pages/meeting_list_screen.dart';
import 'package:tikitar_demo/features/profile/view/pages/my_profile_screen.dart';
import 'package:tikitar_demo/features/task/view/pages/task_screen.dart';
import 'package:clarity_flutter/clarity_flutter.dart';
import 'dart:io' show Platform;

void main() async {
  final config = ClarityConfig(
    projectId: "s8jr5cb4ko",
    // for testing otherwise use "LogLevel.None"
    logLevel:
        LogLevel
            .Verbose, // Note: Use "LogLevel.Verbose" value while testing to debug initialization issues.
  );

  WidgetsFlutterBinding.ensureInitialized(); // Ensure this line is there

  // initialize the firebase only for the android
  if (Platform.isAndroid) {
    await Firebase.initializeApp();
    // other firebase setup
  }

  // Force portrait mode only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown, // optional: allows upside-down portrait
  ]);

  // Ensure system UI (status + nav bar) is visible
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(
    // ClarityWidget(
    //   app: MyApp(), 
    //   clarityConfig: config,
    // ),

    // MultiProvider for Riverpod
    ProviderScope(
      child: MyApp(),
    ),
  );
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // _checkAndRequestLocationPermission();
      Future.delayed(Duration(milliseconds: 500), () {
        // _checkAndRequestLocationPermission();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightThemeMode,
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
}
