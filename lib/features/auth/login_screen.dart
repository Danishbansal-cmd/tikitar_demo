import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tikitar_demo/features/webview/dashboard_screen.dart';
import 'package:tikitar_demo/features/webview/task_screen.dart';  // Import SVG package

class LoginScreen extends StatelessWidget {
  const LoginScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset('assets/images/tikitar-bar.png', height: 50), // Logo
                  SizedBox(height: 10),
                  Text("Welcome!", style: TextStyle(color: Colors.white, fontSize: 18)),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.task),
              title: Text("Task"),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => TaskScreen()));
              },
            ),
            ListTile(
              leading: Icon(Icons.dashboard),
              title: Text("Dashboard"),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => DashboardScreen()));
              },
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text("My Profile"),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.video_call),
              title: Text("Meetings"),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.business),
              title: Text("Company List"),
              onTap: () {},
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Image.asset(
                  'assets/images/tikitar-logo.png',  // logo asset
                  height: 200,
                  width: 100,
                ),
                const SizedBox(height: 5),
                // Email Label
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Login Email',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Color(0xFF838383)),
                  ),
                ),
                const SizedBox(height: 5),
                // Email TextField
                TextField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), // Increased border-radius
                      borderSide: BorderSide(color: Color(0xFF838383)), // Border color changed
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Password Label
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Password',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Color(0xFF838383)),
                  ),
                ),
                const SizedBox(height: 5),
                // Password TextField
                TextField(
                  obscureText: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), // Increased border-radius
                      borderSide: BorderSide(color: Color(0xFF838383)), // Border color changed
                    ),
                  ),
                ),
                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(color: Color(0xFF838383)), // Color changed
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Login Button
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 50), // Added padding
                  decoration: BoxDecoration(
                    color: Colors.blue, // Set background color to blue
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextButton(
                    onPressed: () {},
                    child: Text(
                      'Login',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Top Left Logo with Popup Menu
          Positioned(
            top: 40, // Adjust top padding as needed
            left: 20, // Adjust left padding as needed
            child: Builder(
              builder: (context) {
                return GestureDetector(
                  onTap: () {
                    Scaffold.of(context).openDrawer(); // Opens the drawer
                  },
                  child: Image.asset(
                    'assets/images/tikitar-bar.png',
                    height: 50,
                  ),
                );
              },
            ),
          ),
        ]
      ),
    );
  }
}
