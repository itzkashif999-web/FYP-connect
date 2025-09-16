// import 'dart:io';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:fyp_connect/chats%20and%20notifications/notifications/services/send_notification_service.dart';
// import 'package:get/get.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// import '../models/chat_user.dart';
// import '../models/message.dart';
// //import '../services/send_notification_service.dart';

// class AuthController extends GetxController {
//   final FirebaseFirestore firestore = FirebaseFirestore.instance;
//   FirebaseAuth auth = FirebaseAuth.instance;

//   ChatUser? me;
//   // 🔹 Current logged-in user
//   User? get currentUser => auth.currentUser;

//   // Fixed user getter to return the authenticated user
//   User? get user => auth.currentUser;

//   @override
//   void onInit() {
//     // TODO: implement onInit
//     super.onInit();
//     getSelfInfo();
//     setupFirebaseMessagingListener();
//   }

//   void setupFirebaseMessagingListener() {
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
//       if (message.notification != null) {
//         print("📩 New Notification: ${message.notification!.title}");

//         // Save to Firestore
//         await FirebaseFirestore.instance
//             .collection('notifications')
//             .doc(user!.uid) // Store under user's ID
//             .collection('notifications')
//             .add({
//               'title': message.notification!.title ?? 'No Title',
//               'body': message.notification!.body ?? 'No Body',
//               'isSeen': false,
//               'createdAt': DateTime.now(),
//             });

//         print("✅ Notification saved to Firestore.");
//       }
//     });
//   }

//   Future<void> getSelfInfo() async {
//     if (user == null) return;

//     bool exists = await checkUserExists(user!.uid);
//     if (exists) {
//       DocumentSnapshot userDoc =
//           await firestore.collection('users').doc(user!.uid).get();
//       me = ChatUser.fromJson(userDoc.data() as Map<String, dynamic>);
//       updateActiveStatus(true);
//       // 🔹 Load locally stored profile image (PER USER)
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? savedImagePath = prefs.getString(
//         'profile_image_path_${user!.uid}',
//       );
//       if (savedImagePath != null && File(savedImagePath).existsSync()) {
//         me!.image = savedImagePath;
//       }
//     }
//   }

//   Future<void> updateActiveStatus(bool isOnline) async {
//     if (user == null) return;
//     firestore.collection('users').doc(user!.uid).update({
//       'is_online': isOnline,
//       'last_active': FieldValue.serverTimestamp(),
//       'push_token': me?.pushToken ?? '',
//     });
//   }

//   // 🔹 Check if User Exists in Firestore
//   Future<bool> checkUserExists(String uid) async {
//     DocumentSnapshot userDoc =
//         await firestore.collection('users').doc(uid).get();
//     return userDoc.exists;
//   }

//   // 🔹 Generate Conversation ID
//   String getConversationID(String id) {
//     final currentUid = currentUser?.uid ?? '';
//     if (currentUid.isEmpty) return '';
//     return currentUid.hashCode <= id.hashCode
//         ? '${currentUid}_$id'
//         : '${id}_$currentUid';
//   }

//   // 🔹 Get All Users (except current)
//   Stream<List<ChatUser>> getAllUsers() {
//     return firestore.collection('users').snapshots().map((snapshot) {
//       return snapshot.docs
//           .map((doc) => ChatUser.fromJson(doc.data()))
//           .where((user) => user.id != currentUser?.uid)
//           .toList();
//     });
//   }

//   // 🔹 Get All Messages for a User
//   Stream<QuerySnapshot<Map<String, dynamic>>> getMessages(ChatUser user) {
//     final conversationId = getConversationID(user.id);
//     if (conversationId.isEmpty) {
//       // Return an empty stream if invalid conversationId
//       return const Stream.empty();
//     }
//     return firestore
//         .collection('chats/$conversationId/messages')
//         .orderBy('sent', descending: true)
//         .snapshots();
//   }

//   // 🔹 Send Message
//   Future<void> sendMessage(
//     String msg,
//     ChatUser chatUser, {
//     Type type = Type.text,
//   }) async {
//     if (currentUser == null || chatUser.id.isEmpty) {
//       print("❌ Error: User is not authenticated or toId is missing!");
//       return;
//     }

//     final conversationID = getConversationID(chatUser.id);
//     if (conversationID.isEmpty) {
//       print("❌ Error: Conversation ID is empty!");
//       return;
//     }

//     final ref = firestore.collection('chats/$conversationID/messages').doc();

//     final Message message = Message(
//       id: ref.id,
//       toId: chatUser.id,
//       msg: msg,
//       read: '',
//       type: type,
//       fromId: currentUser!.uid,
//       sent: null,
//     );

//     await ref.set({...message.toJson(), 'sent': FieldValue.serverTimestamp()});

//     //🔔 Send Push Notification
//     String notificationBody = (type == Type.image) ? '📸 Image' : msg;
//     if (chatUser.pushToken!.isNotEmpty) {
//       await SendNotificationService.sendNotificationUsingApi(
//         token: chatUser.pushToken!,
//         title: '💬 New Message from ${currentUser!.displayName}',
//         body: notificationBody,
//         data: {'screen': 'chat'},
//       );
//     }
//   }

//   // 🔹 Send Image Message
//   Future<void> sendChatImage(ChatUser chatUser, File file) async {
//     if (currentUser == null || chatUser.id.isEmpty) return;

//     final appDir = await getApplicationDocumentsDirectory();
//     final localFile = File(
//       '${appDir.path}/chat_${DateTime.now().millisecondsSinceEpoch}.png',
//     );
//     await file.copy(localFile.path);

//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     await prefs.setString('chat_image_${localFile.path}', localFile.path);

//     await sendMessage(localFile.path, chatUser, type: Type.image);
//   }

//   // 🔹 Update Read Status
//   Future<void> updateMessageReadStatus(Message message) async {
//     try {
//       final chatId = getConversationID(message.fromId);
//       if (chatId.isEmpty) return;

//       final docRef = firestore
//           .collection('chats')
//           .doc(chatId)
//           .collection('messages')
//           .doc(message.id);

//       final docSnapshot = await docRef.get();
//       if (!docSnapshot.exists) return;

//       await docRef.update({'read': FieldValue.serverTimestamp()});
//     } catch (e) {
//       print("❌ Firestore Error updating read status: $e");
//     }
//   }

//   // 🔹 Get Last Message (for chat list preview)
//   Stream<QuerySnapshot<Map<String, dynamic>>> getLastMessage(ChatUser user) {
//     final conversationId = getConversationID(user.id);
//     if (conversationId.isEmpty) {
//       return const Stream.empty();
//     }
//     return firestore
//         .collection('chats/$conversationId/messages')
//         .orderBy('sent', descending: true)
//         .limit(1)
//         .snapshots();
//   }

//   // 🔹 Get Realtime User Info
//   Stream<QuerySnapshot<Map<String, dynamic>>> getUserInfo(ChatUser user) {
//     return firestore
//         .collection('users')
//         .where('id', isEqualTo: user.id)
//         .snapshots();
//   }

//   //groups controller
//   Stream<List<ChatUser>> getStudentsInMyGroups() {
//     final supervisorId = auth.currentUser?.uid;
//     print('🛠️ getStudentsInMyGroups called, supervisorId: $supervisorId');
//     if (supervisorId == null) {
//       print('❌ supervisorId null');
//       return const Stream.empty();
//     }
//     return firestore
//         .collection('supervisor_groups')
//         .where('supervisorId', isEqualTo: supervisorId)
//         .snapshots()
//         .asyncMap((groupSnapshot) async {
//           List<String> studentIds =
//               groupSnapshot.docs
//                   .map((doc) => doc['studentId'] as String?)
//                   .whereType<String>()
//                   .where((id) => id.isNotEmpty)
//                   .toSet()
//                   .toList();

//           print("🧪 Found student IDs: $studentIds");

//           if (studentIds.isEmpty) return [];

//           final userQuery =
//               await firestore
//                   .collection('users')
//                   .where('id', whereIn: studentIds)
//                   .get();

//           print("👥 Matched user count: ${userQuery.docs.length}");

//           return userQuery.docs
//               .map((doc) => ChatUser.fromJson(doc.data()))
//               .toList();
//         });
//   }

//   Stream<List<ChatUser>> getAllLinkedSupervisorsForStudent() async* {
//     final currentUid = currentUser?.uid;
//     if (currentUid == null) yield [];

//     // Step 1: Get all supervisor IDs linked to this student
//     final groupSnapshot =
//         await firestore
//             .collection('supervisor_groups')
//             .where('studentId', isEqualTo: currentUid)
//             .get();

//     final supervisorIds =
//         groupSnapshot.docs
//             .map((doc) => doc['supervisorId'] as String)
//             .toSet()
//             .toList();

//     if (supervisorIds.isEmpty) {
//       yield [];
//       return;
//     }

//     // Step 2: Fetch supervisors by IDs
//     yield* firestore
//         .collection('users')
//         .where('id', whereIn: supervisorIds)
//         .snapshots()
//         .map(
//           (snapshot) =>
//               snapshot.docs
//                   .map((doc) => ChatUser.fromJson(doc.data()))
//                   .toList(),
//         );
//   }
// }
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fyp_connect/chats%20and%20notifications/notifications/services/send_notification_service.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_user.dart';
import '../models/message.dart';

class AuthController extends GetxController {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;

  ChatUser? me;

  User? get currentUser => auth.currentUser;

  // Fixed user getter to return the authenticated user
  User? get user => auth.currentUser;

  @override
  void onInit() {
    super.onInit();
    getSelfInfo();
    setupFirebaseMessagingListener();
  }

  void setupFirebaseMessagingListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if (message.notification != null) {
        print("📩 New Notification: ${message.notification!.title}");

        // Save notification under recipient's Firestore node
        await firestore
            .collection('notifications')
            .doc(currentUser!.uid)
            .collection('notifications')
            .add({
              'title': message.notification!.title ?? 'No Title',
              'body': message.notification!.body ?? 'No Body',
              'isSeen': false,
              'createdAt': FieldValue.serverTimestamp(),
            });

        print("✅ Notification saved to Firestore.");
      }
    });
  }

  Future<void> getSelfInfo() async {
    if (currentUser == null) return;

    final userDoc =
        await firestore.collection('users').doc(currentUser!.uid).get();
    if (userDoc.exists) {
      me = ChatUser.fromJson(userDoc.data() as Map<String, dynamic>);
      updateActiveStatus(true);

      // Load locally stored profile image
      final prefs = await SharedPreferences.getInstance();
      final savedImagePath = prefs.getString(
        'profile_image_path_${currentUser!.uid}',
      );
      if (savedImagePath != null && File(savedImagePath).existsSync()) {
        me!.image = savedImagePath;
      }
    }
  }

  Future<void> updateActiveStatus(bool isOnline) async {
    if (currentUser == null) return;
    await firestore.collection('users').doc(currentUser!.uid).update({
      'is_online': isOnline,
      'last_active': FieldValue.serverTimestamp(),
      'push_token': me?.pushToken ?? '',
    });
  }

  String getConversationID(String id) {
    final currentUid = currentUser?.uid ?? '';
    if (currentUid.isEmpty) return '';
    return currentUid.hashCode <= id.hashCode
        ? '${currentUid}_$id'
        : '${id}_$currentUid';
  }

  Stream<List<ChatUser>> getAllUsers() {
    return firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatUser.fromJson(doc.data()))
          .where((user) => user.id != currentUser?.uid)
          .toList();
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getMessages(ChatUser user) {
    final conversationId = getConversationID(user.id);
    if (conversationId.isEmpty) return const Stream.empty();
    return firestore
        .collection('chats/$conversationId/messages')
        .orderBy('sent', descending: true)
        .snapshots();
  }

  /// ✅ Corrected sendMessage to mimic Schedule Meeting notifications
  Future<void> sendMessage(
    String msg,
    ChatUser chatUser, {
    Type type = Type.text,
  }) async {
    if (currentUser == null || chatUser.id.isEmpty) {
      print("❌ Error: User not logged in or invalid recipient!");
      return;
    }

    final conversationID = getConversationID(chatUser.id);
    if (conversationID.isEmpty) return;

    final ref = firestore.collection('chats/$conversationID/messages').doc();
    final message = Message(
      id: ref.id,
      toId: chatUser.id,
      msg: msg,
      read: '',
      type: type,
      fromId: currentUser!.uid,
      sent: null,
    );

    // Save message
    await ref.set({...message.toJson(), 'sent': FieldValue.serverTimestamp()});

    // Store notification per recipient
    await firestore
        .collection('notifications')
        .doc(chatUser.id) // recipient's notifications
        .collection('notifications')
        .doc(ref.id) // use message ID
        .set({
          'title': '💬 New Message from ${currentUser!.displayName}',
          'body': (type == Type.image) ? '📸 Image' : msg,
          'isSeen': false,
          'createdAt': FieldValue.serverTimestamp(),
          'messageId': ref.id,
          'senderId': currentUser!.uid,
          'type': 'chat',
        });

    print("✅ Notification saved for recipient ${chatUser.name}");

    // Send FCM only if token exists and is different from current device
    if (chatUser.pushToken != null &&
        chatUser.pushToken!.isNotEmpty &&
        chatUser.pushToken != me?.pushToken) {
      await SendNotificationService.sendNotificationUsingApi(
        token: chatUser.pushToken!,
        title: '💬 New Message from ${currentUser!.displayName}',
        body: (type == Type.image) ? '📸 Image' : msg,
        data: {'screen': 'chat', 'senderId': currentUser!.uid},
      );
      print("✅ FCM sent to ${chatUser.name}");
    }
  }

  Future<void> sendChatImage(ChatUser chatUser, File file) async {
    if (currentUser == null || chatUser.id.isEmpty) return;

    final appDir = await getApplicationDocumentsDirectory();
    final localFile = File(
      '${appDir.path}/chat_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.copy(localFile.path);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chat_image_${localFile.path}', localFile.path);

    await sendMessage(localFile.path, chatUser, type: Type.image);
  }

  Future<void> updateMessageReadStatus(Message message) async {
    try {
      final chatId = getConversationID(message.fromId);
      if (chatId.isEmpty) return;

      final docRef = firestore
          .collection('chats/$chatId/messages')
          .doc(message.id);
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) return;

      await docRef.update({'read': FieldValue.serverTimestamp()});
    } catch (e) {
      print("❌ Firestore Error updating read status: $e");
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getLastMessage(ChatUser user) {
    final conversationId = getConversationID(user.id);
    if (conversationId.isEmpty) return const Stream.empty();
    return firestore
        .collection('chats/$conversationId/messages')
        .orderBy('sent', descending: true)
        .limit(1)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getUserInfo(ChatUser user) {
    return firestore
        .collection('users')
        .where('id', isEqualTo: user.id)
        .snapshots();
  }

  // Groups
  Stream<List<ChatUser>> getStudentsInMyGroups() {
    final supervisorId = currentUser?.uid;
    if (supervisorId == null) return const Stream.empty();

    return firestore
        .collection('supervisor_groups')
        .where('supervisorId', isEqualTo: supervisorId)
        .snapshots()
        .asyncMap((groupSnapshot) async {
          final studentIds =
              groupSnapshot.docs
                  .map((doc) => doc['studentId'] as String?)
                  .whereType<String>()
                  .where((id) => id.isNotEmpty)
                  .toSet()
                  .toList();

          if (studentIds.isEmpty) return [];

          final userQuery =
              await firestore
                  .collection('users')
                  .where('id', whereIn: studentIds)
                  .get();

          return userQuery.docs
              .map((doc) => ChatUser.fromJson(doc.data()))
              .toList();
        });
  }

  Stream<List<ChatUser>> getAllLinkedSupervisorsForStudent() async* {
    final currentUid = currentUser?.uid;
    if (currentUid == null) yield [];

    final groupSnapshot =
        await firestore
            .collection('supervisor_groups')
            .where('studentId', isEqualTo: currentUid)
            .get();

    final supervisorIds =
        groupSnapshot.docs
            .map((doc) => doc['supervisorId'] as String)
            .toSet()
            .toList();

    if (supervisorIds.isEmpty) {
      yield [];
      return;
    }

    yield* firestore
        .collection('users')
        .where('id', whereIn: supervisorIds)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => ChatUser.fromJson(doc.data()))
                  .toList(),
        );
  }
}
