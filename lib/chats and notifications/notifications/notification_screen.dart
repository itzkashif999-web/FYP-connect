
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ignore: must_be_immutable
class NotificationScreen extends StatefulWidget {
  final RemoteMessage? message;
  const NotificationScreen({super.key, this.message});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _saveNotificationToFirestore(message);
    });
  }

  void _saveNotificationToFirestore(RemoteMessage message) async {
    if (user != null && message.notification != null) {
      // Skip chat notifications
      if (message.data['screen'] == 'chat') {
        print('💬 Chat notification detected, skipping save.');
        return;
      }

      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(user!.uid)
          .collection('notifications')
          .add({
            'title': message.notification!.title ?? 'No title',
            'body': message.notification!.body ?? 'No body',
            'isSeen': false,
            'createdAt': Timestamp.now(),
          });

      print('🔔 Notification saved successfully.');
    }
  }

  // format date nicely
  String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('MMM dd, yyyy – hh:mm a').format(dateTime);
  }

  /// ✅ Mark all as read
  Future<void> _markAllAsRead() async {
    var query =
        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(user!.uid)
            .collection('notifications')
            .where('isSeen', isEqualTo: false)
            .get();

    WriteBatch batch = FirebaseFirestore.instance.batch();

    for (var doc in query.docs) {
      batch.update(doc.reference, {'isSeen': true});
    }

    await batch.commit();
    print('✅ All notifications marked as read.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 24, 81, 91),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Container(
            decoration: BoxDecoration(
              color: Colors.blueGrey,
              borderRadius: BorderRadius.circular(12), // ✅ Rounded corners
            ),
            child: IconButton(
              tooltip: "Mark all as read",
              color: const Color.fromARGB(255, 118, 222, 121),
              icon: const Icon(Icons.done_all),
              onPressed: _markAllAsRead,
            ),
          ),
        ],
      ),
      body: StreamBuilder(
        stream:
            FirebaseFirestore.instance
                .collection('notifications')
                .doc(user!.uid)
                .collection('notifications')
                .orderBy('createdAt', descending: true)
                .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading notifications'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CupertinoActivityIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No Notification found'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            shrinkWrap: true,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              String docId = doc.id;
              String title = doc['title'];
              String body = doc['body'];
              bool isSeen = doc['isSeen'];
              Timestamp createdAt = doc['createdAt'];

              return GestureDetector(
                onTap: () async {
                  await FirebaseFirestore.instance
                      .collection('notifications')
                      .doc(user!.uid)
                      .collection('notifications')
                      .doc(docId)
                      .update({'isSeen': true});
                },
                child: Card(
                  color:
                      isSeen
                          ? const Color.fromARGB(255, 223, 213, 213)
                          : const Color.fromARGB(255, 151, 237, 217),
                  elevation: isSeen ? 0 : 5,
                  child: ListTile(
                    leading: CircleAvatar(
                      child:
                          isSeen
                              ? const Icon(Icons.done)
                              : const Icon(Icons.notifications_active),
                    ),
                    title: Text(title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(body),
                        const SizedBox(height: 4),
                        Text(
                          _formatTimestamp(createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
