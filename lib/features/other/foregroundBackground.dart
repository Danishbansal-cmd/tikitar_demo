import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:flutter/material.dart';

Future<void> initializeForegroundBackgroundService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStartOnBoot:
          false, // disable auto-start on boot (you don’t want tracking after reboot)
      autoStart: true,
      isForegroundMode: true,
      initialNotificationTitle: 'Location Tracking Enabled',
      initialNotificationContent: 'We are monitoring your location...',
    ),
    iosConfiguration: IosConfiguration(),
  );

  await service.startService();
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized(); // Safe here if called first

  final prefs = await SharedPreferences.getInstance();
  List<String> locationList = prefs.getStringList('location_history') ?? [];

  bool isTracking = true;

  final positionStream = Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.low,
      distanceFilter: 1, // location changes by 50 meters
    ),
  ).listen((position) async {
    if (!isTracking) return;

    final pos = "Lat: ${position.latitude}, Lng: ${position.longitude}";
    locationList.add(pos);
    await prefs.setStringList('location_history', locationList);

    if (service is AndroidServiceInstance) {
      // if (await service.isForegroundService()) {
        service.setForegroundNotificationInfo(
          title: "Tracking ${locationList.length} positions",
          content: locationList.reversed.take(3).join('\n'),
        );
      // }
    }
   

    print("Logged: $pos");
  });

  // Listen for service control events
  service.on('pauseTracking').listen((event) {
    isTracking = false;
    print("Tracking paused.");
  });

  service.on('resumeTracking').listen((event) {
    isTracking = true;
    print("Tracking resumed.");
  });

  service.on('stopService').listen((event) async {
    // await prefs.setStringList('location_history', locationList);
    await prefs.setStringList('location_history', []);
    await positionStream.cancel();
    service.stopSelf();
  });
}
