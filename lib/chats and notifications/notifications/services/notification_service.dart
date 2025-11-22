

import 'package:app_settings/app_settings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fyp_connect/chats%20and%20notifications/chat_screen.dart';
import 'package:fyp_connect/chats%20and%20notifications/models/chat_user.dart';
import 'package:fyp_connect/chats%20and%20notifications/notifications/notification_screen.dart';
import 'package:get/get.dart';

@pragma('vm:entry-point')
void onBackgroundNotificationTap(NotificationResponse response) {
  print("📩 Background notification tapped!");
  // Navigate to the Notification Screen
  Get.toNamed('/chats and notifications/notifications/notification_screen');
}

class NotificationService {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  void requestNotificationPermission() async {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: true,
      criticalAlert: true,
      provisional: true,
    );
    //    sound: true);
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      Get.snackbar(
        'Notification permission denied',
        'Please allow notification to receive updates',
        snackPosition: SnackPosition.BOTTOM,
      );
      Future.delayed(Duration(seconds: 2), () {
        AppSettings.openAppSettings(type: AppSettingsType.notification);
      });
    }
  }

  void initTokenListener(String userId) async {
    // Save initial token
    String? token = await messaging.getToken();
    if (token != null) {
      await _saveTokenToFirestore(userId, token);
    }

    // Listen for refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      print("🔄 Token refreshed: $newToken");
      await _saveTokenToFirestore(userId, newToken);
    });
  }

  Future<void> _saveTokenToFirestore(String userId, String token) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'pushToken': token,
    });
  }

  Future<String?> getDeviceToken() async {
    String? token = await messaging.getToken();
    print('token : $token');
    return token;
  }

  void initLocalNotification(
    BuildContext context,
    RemoteMessage message,
  ) async {
    var androidInitSetting = const AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    var iosInitSetting = const DarwinInitializationSettings();
    var initializationSetting = InitializationSettings(
      android: androidInitSetting,
      iOS: iosInitSetting,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSetting,
      onDidReceiveNotificationResponse: (response) {
        print("📩 Foreground notification tapped!");
        handleMessage(context, message);
      },
      onDidReceiveBackgroundNotificationResponse:
          onBackgroundNotificationTap, // ✅ Fix applied
    );
  }

  void firebaseInit(BuildContext context) {
    print("🔔 firebaseInit called");
 
    FirebaseMessaging.onMessage.listen((message) {
      final senderId = message.data['senderId'] ?? '';

      // Debug log
      print(
        "📨 Message from: $senderId, me: ${FirebaseAuth.instance.currentUser?.uid}",
      );

      if (senderId == FirebaseAuth.instance.currentUser?.uid) {
        print("❌ Ignoring my own message notification");
        return;
      }

      // Show notification for others
      initLocalNotification(context, message);
      showNotification(message);
    });
  }

  Future<void> showNotification(RemoteMessage message) async {
    AndroidNotificationChannel channel = AndroidNotificationChannel(
      message.notification!.android!.channelId.toString(),
      message.notification!.android!.channelId.toString(),
      importance: Importance.high,
      showBadge: true,
      playSound: true,
    );
    AndroidNotificationDetails
    androidNotificationDetails = AndroidNotificationDetails(
      channel.id.toString(),
      channel.name.toString(),
      channelDescription: 'Channel Description',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      // sound: channel.sound ?? RawResourceAndroidNotificationSound('default'),
    );
    DarwinNotificationDetails darwinNotificationDetails =
        const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          // presentSound: true,
        );
    NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
    );
    Future.delayed(Duration.zero, () {
      _flutterLocalNotificationsPlugin.show(
        0,
        message.notification!.title.toString(),
        message.notification!.body.toString(),
        notificationDetails,
        payload: 'my_data',
      );
    });
  }

  Future<void> setupInteractMessage(BuildContext context) async {
    // When the app is opened by tapping a notification
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print("🎯 App Opened from Notification: ${message.data}");
      if (message.data.isNotEmpty) {
        handleMessage(context, message);
      } else {
        print("⚠️ No data payload found.");
      }
    });

    // When the app is terminated and opened by tapping a notification
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      print("📲 Initial Message: $message");
      if (message != null && message.data.isNotEmpty) {
        handleMessage(context, message);
      } else {
        print("⚠️ No data in initial message.");
      }
    });
  }

  Future<void> handleMessage(
    BuildContext context,
    RemoteMessage message,
  ) async {
    print('📲 Received Notification Data: ${message.data}');

    if (message.data['screen'] == 'chat') {
      String senderId = message.data['senderId'] ?? '';
      String senderName = message.data['senderName'] ?? 'Unknown';

      if (senderId.isNotEmpty) {
        print('💬 Navigating to ChatScreen with $senderName (ID: $senderId)');

        // Pass user details to ChatScreen
        Get.to(
          () => ChatScreen(
            user: ChatUser(
              id: senderId,
              about: '',
              email: '',
              createdAt: DateTime.now(),
              name: senderName,
              image: '', // Optional: Pass sender profile image if available
              pushToken: '',
              lastActive: DateTime.now(),
              isOnline: true,
            ),
          ),
        );
      } else {
        print('❌ Sender ID is missing, navigation failed.');
      }
    } else {
      print('🔔 Non-chat notification, navigating to NotificationScreen.');
      Get.to(() => NotificationScreen(message: message));
    }
  }

  Future iosForegroundMessage() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          //   sound: true,
        );
  }
}
