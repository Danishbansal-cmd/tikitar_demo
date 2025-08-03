import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:tikitar_demo/core/network/api_base.dart';
import 'package:tikitar_demo/core/local/data_strorage.dart';
import 'package:tikitar_demo/features/profile/repositories/profile_repository.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
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
      // read the data from the storage, reuturns string
      final userData = await DataStorage.getUserData();
      ApiBase.setToken(token);
      // setting the profileProvider or profile with the userData
      ref.read(profileProvider.notifier).setProfile(jsonDecode(userData) as Map<String, dynamic>);
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
