import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';  // Import SVG package

class LoginScreen extends StatelessWidget {
  const LoginScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          // Top Left Logo
          Positioned(
            top: 40, // Adjust top padding as needed
            left: 20, // Adjust left padding as needed
            child: Image.asset(
              'assets/images/tikitar-bar.png',  // Top left corner logo
              height: 50,
            ),
          ),
        ]
      ),
    );
  }
}
