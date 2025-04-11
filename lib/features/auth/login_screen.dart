import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tikitar_demo/features/auth/auth_controller.dart';
import 'package:tikitar_demo/features/webview/dashboard_screen.dart';
import 'package:tikitar_demo/features/webview/task_screen.dart';  // Import SVG package


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthController _authController = AuthController();

  bool _isLoading = false;

  void _handleLogin() async {
    setState(() => _isLoading = true);

    final result = await _authController.login(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!mounted) return;
    print("Login result: $result");

    if (result['status'] == true && result['data']?['token'] != null) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Login failed')),
      );
    }

    setState(() => _isLoading = false);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.15), // Add top spacing
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
                  controller: _emailController,
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
                  controller: _passwordController,
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
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Login', style: TextStyle(color: Colors.white)),
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
