import 'dart:convert';
import 'dart:developer' as developer;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:tikitar_demo/features/data/local/token_storage.dart';

Future<void> handleBackgroundMessage(RemoteMessage message) async {
  developer.log(
    name: "handle_background_message", "title = ${message.notification!.title} ===== body = ${message.notification!.body} ===== payload = ${message.data}",
  );
}

class FirebaseApi {
  FirebaseApi._();

  static final firebaseMessaging = FirebaseMessaging.instance;

  static const androidChannel = AndroidNotificationChannel(
    "high_importance_channel",
    "High Importance Notifications",
    description: "This channel is used for notifications",
    importance: Importance.defaultImportance,
  );
  static final localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> handleMessage(
    RemoteMessage? message, {
    required bool fromTerminated,
  }) async {
    if (message == null) return;
    developer.log(
      name: "handle_background_message", "title = ${message.notification!.title} ===== body = ${message.notification!.body} ===== payload = ${message.data}",
    );
    if (message.data.containsKey("type") &&
        message.data.containsKey("component_id")) {
      if (await TokenStorage.getToken() != null &&
          message.data["type"] == "task") {
        // if (fromTerminated == false) {
        //   Navigator.of(context).pushNamedAndRemoveUntil(
        //     '/dashboard',
        //     (route) => false,
        //   );
        // }
        // while (Get.currentRoute != AppRoutes.routeDashboard) {
        //   await Future.delayed(const Duration(milliseconds: 500));
        // }
        // if (message.data["type"] == "task") {
        //   Get.toNamed(
        //     AppRoutes.routeTaskDetail,
        //     arguments: {
        //       AppConsts.keyTaskId:
        //           message.data["component_id"] is String
        //               ? int.tryParse(message.data["component_id"])
        //               : message.data["component_id"],
        //     },
        //   );
        // }
        // if (message.data["type"] == "project") {
        //   Get.toNamed(
        //     AppRoutes.routeProjectDetail,
        //     arguments: {
        //       AppConsts.keyProjectId: int.tryParse(
        //         message.data["component_id"],
        //       ),
        //     },
        //   );
        // }
      }
    }
  }

  static Future initLocalNotifications() async {
    const iOS = DarwinInitializationSettings();
    const android = AndroidInitializationSettings("@mipmap/ic_launcher");
    const settings = InitializationSettings(android: android, iOS: iOS);

    await localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        final message = RemoteMessage.fromMap(jsonDecode(response.payload!));
        handleMessage(message, fromTerminated: false);
      },
    );

    final platform =
        localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    await platform!.createNotificationChannel(androidChannel);
  }

  static Future initPushNotifications() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        handleMessage(message, fromTerminated: true);
      }
    });
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      handleMessage(message, fromTerminated: false);
    });
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            androidChannel.id,
            androidChannel.name,
            channelDescription: androidChannel.description,
            icon: "@mipmap/ic_launcher",
          ),
        ),
        payload: jsonEncode(message.toMap()),
      );
    });
  }

  static Future<void> initNotifications() async {
    NotificationSettings settings = await firebaseMessaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

     if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      developer.log('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      developer.log('User granted provisional permission');
    } else {
      developer.log('User declined or has not accepted permission');
      return;
    }
    final fCMToken = await firebaseMessaging.getToken();
    developer.log(
        name: "firebase_api_init_notifications", "fcm_token = $fCMToken");
    initPushNotifications();
    initLocalNotifications();
  }
}
