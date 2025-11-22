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
    try {
      final credential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userDoc =
          await firestore.collection('users').doc(credential.user!.uid).get();

      if (!userDoc.exists) {
        print("User document doesn't exist in Firestore");
        // Try to recreate the user document using the signup information if possible
        // But don't default to student - let's try to get the original role if it's in auth claims

        // Get the user's display name
        String displayName =
            credential.user!.displayName ?? email.split('@')[0];

        // Create a new timestamp
        final now = DateTime.now();

        // Try to check if we have a custom claim for role
        await credential.user!.getIdTokenResult(true);

        // Default role is now going to be supervisor for testing purposes
        // You may want to change this based on your application's requirements
        String defaultRole = 'supervisor';

        await firestore.collection('users').doc(credential.user!.uid).set({
          'email': email,
          'name': displayName,
          'role': defaultRole,
          'id': credential.user!.uid,
          'createdAt': now,
          'isOnline': true,
          'lastActive': now,
        });

        print("Created new user document with role: $defaultRole");
        return {'credential': credential, 'role': defaultRole};
      }

      final role = userDoc.data()?['role'];
      if (role == null) {
        print("Role field not found in user document");
        // Update the user document to include a role, but make it supervisor
        // for testing purposes
        String defaultRole = 'supervisor';
        await firestore.collection('users').doc(credential.user!.uid).update({
          'role': defaultRole,
        });

        print("Updated user document with role: $defaultRole");
        return {'credential': credential, 'role': defaultRole};
      }

      print("Successfully signed in with role: $role");
      return {'credential': credential, 'role': role};
    } catch (e) {
      print("Error in signIn: $e");
      rethrow;
    }
  }

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String username,
    required String role,
  }) async {
    try {
      print("Starting signup process for: $email with role: $role");

      final credential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await credential.user!.updateDisplayName(username);

      final uid = credential.user!.uid;
      print("Created Firebase Auth user with UID: $uid");

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

      // Make sure role is not empty
      if (role.isEmpty) {
        role = 'student'; // Default role
      }

      // Make sure role is explicitly set and visible in logs
      print("Setting role to: '$role' for user: $uid");

      // Create a merged userData map with role explicitly set
      final userData = {...chatUser.toJson(), 'role': role};

      print("Saving user data with role '$role' to Firestore");
      await firestore.collection('users').doc(uid).set(userData);

      // Add a delay before verifying to ensure Firestore has time to update
      await Future.delayed(const Duration(milliseconds: 500));

      // Verify that the data was saved correctly
      final savedDoc = await firestore.collection('users').doc(uid).get();
      if (savedDoc.exists) {
        final savedRole = savedDoc.data()?['role'];
        print("User data saved successfully. Role in database: $savedRole");
        if (savedRole != role) {
          print("WARNING: Role mismatch! Expected: $role, Got: $savedRole");
          // Try to update the role again to fix any issues
          await firestore.collection('users').doc(uid).update({'role': role});
        }
      } else {
        print("Warning: User document was not found after saving!");
        // Try to create the document again
        await firestore.collection('users').doc(uid).set(userData);
      }

      return credential;
    } catch (e) {
      print("Error in signUp: $e");
      rethrow;
    }
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
    String? skills, // New field for skills
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
      'skills': skills ?? '', // Include the new skills field
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
    String? preferenceAreas, // New field for preference areas
    String?
    projectHistoryCategories, // New field for project history categories
    String? projectCount, // New field for project count
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
          'preferenceAreas':
              preferenceAreas ?? '', // Add new preference areas field
          'projectHistoryCategories':
              projectHistoryCategories ??
              '', // Add new project history categories field
          'projectCount': projectCount ?? '0', // Add project count field
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

  // Future<String> submitProposal({
  //   required String studentName,
  //   required String regNo,
  //   required String groupMembers,
  //   required String projectTitle,

  //   required String supervisorName,
  //   required String facultyId, // Custom faculty ID
  //   required String fileUrl,
  //   required String status,
  // }) async {
  //   final studentUser = firebaseAuth.currentUser;

  //   if (studentUser == null) {
  //     throw FirebaseAuthException(
  //       code: 'not-authenticated',
  //       message: 'Student must be logged in to submit a proposal.',
  //     );
  //   }

  //   // Find supervisor by facultyId
  //   final supervisorQuery =
  //       await firestore
  //           .collection('supervisor_profiles')
  //           .where('id', isEqualTo: facultyId.trim())
  //           .limit(1)
  //           .get();

  //   if (supervisorQuery.docs.isEmpty) {
  //     throw FirebaseAuthException(
  //       code: 'supervisor-not-found',
  //       message: 'No supervisor found with that faculty ID.',
  //     );
  //   }

  //   final supervisorDoc = supervisorQuery.docs.first;
  //   final supervisorUid = supervisorDoc['userId']; // ✅ real UID

  //   final docRef = await firestore.collection('proposals').add({
  //     'studentId': studentUser.uid,
  //     'studentName': studentName,
  //     'registrationNumber': regNo,
  //     'groupMembers': groupMembers,
  //     'projectTitle': projectTitle,
  //     'supervisorName': supervisorName.trim(),
  //     'facultyId': facultyId.trim(),
  //     'supervisorId': supervisorUid, // ✅ Now real UID
  //     'fileUrl': fileUrl,
  //     'status': status,
  //     'submittedAt': FieldValue.serverTimestamp(),
  //   });
  //   return docRef.id;
  // }

  // Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  // fetchProposalsForSupervisor() async {
  //   final supervisorId = firebaseAuth.currentUser?.uid;
  //   if (supervisorId == null) {
  //     throw FirebaseAuthException(
  //       code: 'not-authenticated',
  //       message: 'Supervisor not logged in.',
  //     );
  //   }

  //   final snapshot =
  //       await firestore
  //           .collection('proposals')
  //           .where('supervisorId', isEqualTo: supervisorId)
  //           .get();

  //   return snapshot.docs;
  // }
Future<String> submitProposal({
  required String studentName,
  required String regNo,
  required String groupMembers,
  required String projectTitle,
  required String projectDescription, // NEW FIELD

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
    'projectDescription': projectDescription, // ✅ Save description
    'supervisorName': supervisorName.trim(),
    'facultyId': facultyId.trim(),
    'supervisorId': supervisorUid, // ✅ real UID
    'fileUrl': fileUrl,
    'status': status,
    'submittedAt': FieldValue.serverTimestamp(),
  });

  return docRef.id;
}

Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> fetchProposalsForSupervisor() async {
  final supervisorId = firebaseAuth.currentUser?.uid;
  if (supervisorId == null) {
    throw FirebaseAuthException(
      code: 'not-authenticated',
      message: 'Supervisor not logged in.',
    );
  }

  final snapshot = await firestore
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
