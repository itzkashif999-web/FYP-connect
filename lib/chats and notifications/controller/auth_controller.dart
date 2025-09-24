
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
