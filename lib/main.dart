import 'package:flutter/material.dart';
import 'package:tikitar_demo/features/auth/login_screen.dart';
import 'package:tikitar_demo/features/other/splash_screen.dart';
import 'package:tikitar_demo/features/webview/company_list_screen.dart';
import 'package:tikitar_demo/features/webview/dashboard_screen.dart';
import 'package:tikitar_demo/features/webview/meeting_list_screen.dart';
import 'package:tikitar_demo/features/webview/my_profile_screen.dart';
import 'package:tikitar_demo/features/webview/task_screen.dart';
import 'features/webview/webview_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 🚨 Ensure this line is there
  //You're calling SharedPreferences.getInstance() before Flutter is fully ready, 
  //most likely before WidgetsFlutterBinding.ensureInitialized() is called.
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/', // initial route when app starts
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/dashboard': (context) => DashboardScreen(),
        '/task': (context) => TaskScreen(),
        '/profile': (context) => MyProfileScreen(),
        '/meetingList': (context) => MeetingListScreen(),
        '/companyList': (context) => CompanyListScreen(),
        '/addTask': (context) => TaskScreen(),
        // Add other screens here like '/profile': (context) => ProfileScreen(),
      },
      // home: WebviewScreen(url: "https://tikidemo.com/tikitar-app/dev/company-list.php#"),
    );
  }
}
