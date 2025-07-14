import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:tikitar_demo/features/common/view/widgets/tapper.dart';
import 'package:tikitar_demo/services/providers/auth_provider.dart';
import 'package:tikitar_demo/services/providers/profile_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscureText = true; // Toggle state

  void _handleLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );

    final result = await authProvider.login(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      profileProvider: profileProvider,
    );

    if (!mounted) return;
    print("Login result: $result");

    if (result['status'] == true) {
      Get.offNamed('/dashboard');
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result['message'])));
  }

  @override
  Widget build(BuildContext context) {
    final loginSuperHeadingStyle = TextStyle(
      color: Color.fromARGB(255, 85, 73, 28),
      fontSize: 28,
      fontWeight: FontWeight.bold,
    );
    final loginFormFieldLabelStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    );
    final loginFormFieldHintStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Colors.grey.shade600,
    );

    return Scaffold(
      body: SafeArea(
        top: true,
        bottom: false,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(color: Colors.white),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 20.0), // Add top spacing
                  // Logo
                  Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Image.asset(
                      'assets/images/tikitar-logo.png',
                      height: 200,
                      width: 200,
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Welcome Text
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Welcome, trackify",
                          style: loginSuperHeadingStyle,
                        ),
                        Text("Users Portal", style: loginSuperHeadingStyle),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Email address',
                      style: loginFormFieldLabelStyle,
                    ),
                  ),
                  const SizedBox(height: 5),
                  // Email TextField
                  TextFormField(
                    controller: _emailController,
                    maxLines: 1,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          12,
                        ), // Increased border-radius
                        borderSide: BorderSide(
                          color: Color(0xFFD8DADC),
                        ), // Border color changed
                      ),
                      hintText: "Your Email",
                      hintStyle: loginFormFieldHintStyle,
                      hintMaxLines: 1,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter Your Email';
                      }

                      // Basic email pattern
                      final emailRegex = RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      );
                      if (!emailRegex.hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  // Password Label
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Password', style: loginFormFieldLabelStyle),
                  ),
                  const SizedBox(height: 5),
                  // Password TextField
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscureText,
                    maxLines: 1,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF838383)),
                      ),
                      hintText: "Password",
                      hintStyle: loginFormFieldHintStyle,
                      hintMaxLines: 1,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 35.0),
                  // Login Button
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, _) {
                      return Tapper(
                        borderRadius: BorderRadius.circular(8.0),
                        backgroundColor: Color(0xFFFECC00),
                        rippleColor: Colors.grey.withOpacity(0.4),
                        onTap:
                            authProvider.isLoading
                                ? () => {}
                                : () => _handleLogin(),
                        child: Container(
                          width: double.infinity,
                          alignment: Alignment.center,
                          height: 50.0,
                          padding: EdgeInsets.symmetric(
                            horizontal: 50,
                          ), // Added padding
                          child:
                              authProvider.isLoading
                                  ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Text(
                                    'Login',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 15.0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
