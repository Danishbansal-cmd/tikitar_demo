import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tikitar_demo/core/network/api_base.dart';
import 'package:tikitar_demo/features/data/local/data_strorage.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 300));
      _checkLoginStatus();
    });
  }

  Future<void> _checkLoginStatus() async {
    final token = await DataStorage.getToken();

    if (token != null) {
      ApiBase.setToken(token);
      Get.offNamed('/dashboard');
    } else {
      Get.offNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
