import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fyp_connect/chats%20and%20notifications/notifications/services/notification_service.dart';
import '../chats and notifications/models/chat_user.dart';

class AuthService {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  User? get currentUser => firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final userDoc =
        await firestore.collection('users').doc(credential.user!.uid).get();

    if (!userDoc.exists) {
      throw FirebaseAuthException(
        code: 'user-role-not-found',
        message: 'User role not found in Firestore.',
      );
    }

    final role = userDoc.data()?['role'];
    return {'credential': credential, 'role': role};
  }

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String username,
    required String role,
  }) async {
    final credential = await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await credential.user!.updateDisplayName(username);

    final uid = credential.user!.uid;

    final now = DateTime.now();
    NotificationService notificationService = NotificationService();
    String? userDeviceToken = await notificationService.getDeviceToken();
    // Add ChatUser data to 'users' collection
    final chatUser = ChatUser(
      image: '', // Default or allow upload later
      about: 'Hey there! I am using the app.', // Default about message
      name: username,
      createdAt: now,
      isOnline: true,
      id: uid,
      lastActive: now,
      email: email,
      pushToken: userDeviceToken, // Add push token if available
    );

    // await firestore.collection('users').doc(uid).set(chatUser.toJson());
    await firestore.collection('users').doc(uid).set({
      ...chatUser.toJson(),
      'role': role,
    });

    return credential;
  }

  Future<void> updateUsername({required String username}) async {
    await currentUser!.updateDisplayName(username);
  }

  Future<void> signOutUser() async {
    final uid = currentUser?.uid;
    if (uid == null) return;

    try {
      // Ensure is_online is set to false before signing out
      await firestore.collection('users').doc(uid).update({
        'is_online': false,
        'last_active': FieldValue.serverTimestamp(),
      });

      print("✅ User status updated to offline");

      // Add a short delay to ensure Firestore completes the write
      await Future.delayed(const Duration(milliseconds: 500));

      await firebaseAuth.signOut();

      print("✅ User signed out successfully");
    } catch (e) {
      print("❌ Error signing out: $e");
    }
  }

  Future<void> resetPassword({required String email}) async {
    await firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> saveStudentProfile({
    required String name,
    required String department,
    required String semester,
    required String interest,
    required String regNo,
  }) async {
    final user = firebaseAuth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'No authenticated user found.',
      );
    }

    await firestore.collection('student_profiles').doc(user.uid).set({
      'name': name,
      'department': department,
      'semester': semester,
      'interest': interest,
      'regNo': regNo,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>?> getStudentProfile() async {
    final user = firebaseAuth.currentUser;
    if (user == null) return null;

    final doc =
        await firestore.collection('student_profiles').doc(user.uid).get();
    return doc.exists ? doc.data() : null;
  }

  // Future<void> saveSupervisorProfile({
  //   required String name,
  //   required String department,
  //   required String projectsHistory,
  //   required String specialization,
  //   required String id, // Custom faculty ID like "bcsSp18"
  // }) async {
  //   final user = firebaseAuth.currentUser;
  //   if (user == null) {
  //     throw FirebaseAuthException(
  //       code: 'not-authenticated',
  //       message: 'No authenticated user found.',
  //     );
  //   }

  //   await firestore.collection('supervisor_profiles').doc(user.uid).set({
  //     'name': name,
  //     'department': department,
  //     'projectsHistory': projectsHistory,
  //     'specialization': specialization,
  //     'id': id,
  //     'updatedAt': FieldValue.serverTimestamp(),
  //   });
  // }

  // Future<Map<String, dynamic>?> getSupervisorProfile() async {
  //   final user = firebaseAuth.currentUser;
  //   if (user == null) return null;

  //   final doc =
  //       await firestore.collection('supervisor_profiles').doc(user.uid).get();
  //   return doc.exists ? doc.data() : null;
  // }
  Future<void> saveSupervisorProfile({
    required String name,
    required String department,
    required String projectsHistory,
    required String specialization,
    required String id, // faculty id
  }) async {
    final user = firebaseAuth.currentUser;
    if (user == null) {
      throw Exception("User not logged in");
    }

    await firestore
        .collection('supervisor_profiles')
        .doc(id) // use faculty id as doc id
        .set({
          'id': id, // faculty id
          'userId': user.uid, // 🔑 link to users collection
          'name': name,
          'department': department,
          'projectsHistory': projectsHistory,
          'specialization': specialization,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getSupervisorProfile() async {
    final user = firebaseAuth.currentUser;
    if (user == null) return null;

    // Fetch supervisor profile where userId == uid
    final query =
        await firestore
            .collection('supervisor_profiles')
            .where('userId', isEqualTo: user.uid)
            .limit(1)
            .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first.data();
    }
    return null;
  }

  Future<String> submitProposal({
    required String studentName,
    required String regNo,
    required String groupMembers,
    required String projectTitle,
    required String projectProposal,
    required String supervisorName,
    required String facultyId, // Custom faculty ID
    required String fileUrl,
    required String status,
  }) async {
    final studentUser = firebaseAuth.currentUser;

    if (studentUser == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'Student must be logged in to submit a proposal.',
      );
    }

    // Find supervisor by facultyId
    final supervisorQuery =
        await firestore
            .collection('supervisor_profiles')
            .where('id', isEqualTo: facultyId.trim())
            .limit(1)
            .get();

    if (supervisorQuery.docs.isEmpty) {
      throw FirebaseAuthException(
        code: 'supervisor-not-found',
        message: 'No supervisor found with that faculty ID.',
      );
    }

    final supervisorDoc = supervisorQuery.docs.first;
    final supervisorUid = supervisorDoc['userId']; // ✅ real UID

    final docRef = await firestore.collection('proposals').add({
      'studentId': studentUser.uid,
      'studentName': studentName,
      'registrationNumber': regNo,
      'groupMembers': groupMembers,
      'projectTitle': projectTitle,
      'projectProposal': projectProposal,
      'supervisorName': supervisorName.trim(),
      'facultyId': facultyId.trim(),
      'supervisorId': supervisorUid, // ✅ Now real UID
      'fileUrl': fileUrl,
      'status': status,
      'submittedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  fetchProposalsForSupervisor() async {
    final supervisorId = firebaseAuth.currentUser?.uid;
    if (supervisorId == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'Supervisor not logged in.',
      );
    }

    final snapshot =
        await firestore
            .collection('proposals')
            .where('supervisorId', isEqualTo: supervisorId)
            .get();

    return snapshot.docs;
  }

  Future<void> createProjectFromProposal({
    required String proposalId,
    required String title,
    required String studentId,
    required String studentName,
  }) async {
    try {
      final projectRef = firestore.collection("projects").doc();

      await projectRef.set({
        "projectId": projectRef.id,
        "proposalId": proposalId,
        "title": title,
        "studentName": studentName,
        "supervisorId": currentUser!.uid,
        "studentId": studentId,
        "status": "active",
        "createdAt": FieldValue.serverTimestamp(),
      });

      // 🔹 Update proposal status to accepted
      await firestore.collection("proposals").doc(proposalId).update({
        "status": "accepted",
        "linkedProjectId": projectRef.id,
      });

      print("✅ Project created from proposal: ${projectRef.id}");
    } catch (e) {
      print("❌ Failed to create project: $e");
      rethrow;
    }
  }
}
