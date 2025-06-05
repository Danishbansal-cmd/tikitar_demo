import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tikitar_demo/features/data/local/data_strorage.dart';

Future<void> initializeForegroundBackgroundService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStartOnBoot: true,
      autoStart: true,
      isForegroundMode: true,
    ),
    iosConfiguration: IosConfiguration(),
  );

  await service.startService();
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  bool isTracking = true;
  SharedPreferences prefs = await DataStorage.getInstace();

  List<String> locationList = prefs.getStringList('location_history') ?? [];

  // Required for accessing platform channels in background isolate
  WidgetsFlutterBinding.ensureInitialized();

  final timer = Timer.periodic(const Duration(seconds: 60*15), (timer) async {
    if (!isTracking) return;

    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        // 🔍 Get current location
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          // final position = await Geolocator.getCurrentPosition();
          try {
            final position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.low,
            );

            final pos = "Lat: ${position.latitude}, Lng: ${position.longitude}";
              locationList.add(pos);

            // Save updated list
            await prefs.setStringList('location_history', locationList);

            // Display all locations (last 5 for brevity)
            String content = locationList.reversed.take(5).join('\n');

            // use position
            service.setForegroundNotificationInfo(
              title: "Tracking ${locationList.length} positions",
              content: content,
            );

            // You can also send this data to a server or save it
            print("Logged: $pos");
          } catch (e) {
            print("Error getting position: $e");
          }
        } else {
          print("Location permission not granted.");
        }
      }
    }
  });

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((even) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((even) {
      service.setAsBackgroundService();
    });

    service.on('pauseTracking').listen((event) {
      isTracking = false;
      print("Tracking paused.");
    });

    service.on('resumeTracking').listen((event) {
      isTracking = true;
      print("Tracking resumed.");
    });
  }

  service.on('stopService').listen((event) async {
    timer.cancel(); // Stop the periodic timer
    await prefs.setStringList('location_history', locationList);
    service.stopSelf();
  });
}
