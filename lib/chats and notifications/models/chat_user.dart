import 'package:cloud_firestore/cloud_firestore.dart';

class ChatUser {
  ChatUser({
    required this.image,
    required this.about,
    required this.name,
    required this.createdAt,
    required this.isOnline,
    required this.id,
    required this.lastActive,
    required this.email,
     this.pushToken,
  });

  late String image;
  late String about;
  late String name;
  late DateTime createdAt;  // 🔹 Change to DateTime
  late bool isOnline;
  late String id;
  late DateTime lastActive; // 🔹 Change to DateTime
  late String email;
  late String? pushToken;

  // 🔹 Handle Firestore Timestamp conversion properly
  ChatUser.fromJson(Map<String, dynamic> json) {
    image = json['image'] ?? '';
    about = json['about'] ?? '';
    name = json['name'] ?? '';

    // ✅ Convert Firestore Timestamp to DateTime
    createdAt = (json['created_at'] != null && json['created_at'] is Timestamp)
        ? (json['created_at'] as Timestamp).toDate()
        : DateTime.now();

    isOnline = json['is_online'] ?? false;
    id = json['id'] ?? '';

    // ✅ Convert Firestore Timestamp to DateTime
    lastActive = (json['last_active'] != null && json['last_active'] is Timestamp)
        ? (json['last_active'] as Timestamp).toDate()
        : DateTime.now();

    email = json['email'] ?? '';
    pushToken = json['push_token'] ?? '';
  }

  // ✅ Ensure timestamps are stored as Firestore Timestamp
  Map<String, dynamic> toJson() {
    return {
      'image': image,
      'about': about,
      'name': name,
      'created_at': Timestamp.fromDate(createdAt),  // ✅ Store DateTime as Firestore Timestamp
      'is_online': isOnline,
      'id': id,
      'last_active': Timestamp.fromDate(lastActive), // ✅ Store DateTime as Firestore Timestamp
      'email': email,
      'push_token': pushToken,
    };
  }
}
