import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:fyp_connect/chats%20and%20notifications/controller/auth_controller.dart';
import 'package:fyp_connect/chats%20and%20notifications/helper/pick_image.dart';
import 'package:fyp_connect/chats%20and%20notifications/notifications/notification_screen.dart';
import 'package:fyp_connect/chats%20and%20notifications/notifications/services/notification_service.dart';

import 'package:fyp_connect/firebase_options.dart';
import 'package:fyp_connect/screens/splash_screen.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
// Import your login page

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  print("Background notification handler triggered!");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("✅ Background notification received: ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  // await Firebase.initializeApp();

  await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
  print('Firebase Initialized Successfully');
  Get.put(AuthController());
  Get.put(PickImage());
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  NotificationService notificationService = NotificationService();
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (FirebaseAuth.instance.currentUser != null) {
        notificationService.requestNotificationPermission();
        notificationService.initTokenListener(
          FirebaseAuth.instance.currentUser!.uid,
        );
        notificationService.firebaseInit(context);
        notificationService.setupInteractMessage(context);
      }
    });
    subscribe();
  }

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'FYP CONNECT',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color.fromARGB(255, 107, 183, 204),
            ),
            useMaterial3: true,
            textTheme: GoogleFonts.poppinsTextTheme(),
          ),
          home: const SplashScreen(),

          getPages: [
            GetPage(
              name:
                  '/chats and notifications/notifications/notification_screen',
              page: () => NotificationScreen(),
            ),
          ],
        );
      },
    );
  }
}

void subscribe() {
  if (kIsWeb) {
    print("⚠️ subscribeToTopic is not supported on Web. Skipping...");
    return;
  }
  FirebaseMessaging.instance.subscribeToTopic('all');
  print('Subscribed to all topic');
}
