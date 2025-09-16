import 'dart:developer';
import 'dart:io';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'auth_controller.dart';
import '../helper/pick_image.dart';

class ProfileController extends GetxController {
  final AuthController authController = Get.find<AuthController>();
  final PickImage pickImageController = Get.find<PickImage>();

  var isEditing = false.obs;
  var updatedName = ''.obs;
  var updatedAbout = ''.obs;
  var userEmail = ''.obs;
  var userImage = ''.obs; // Stores local image path or Firestore URL

  @override
  void onInit() {
    super.onInit();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final user = authController.currentUser; // Get current logged-in user

    if (user != null) {
      // Fetch user document from Firestore
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final userData = doc.data();
        if (userData != null) {
          updatedName.value = userData['name'] ?? '';
          updatedAbout.value = userData['about'] ?? '';
          userEmail.value = userData['email'] ?? '';
          userImage.value =
              userData['image'] ?? ''; // Load profile image from Firestore

          // 🔹 Load locally stored profile image
          SharedPreferences prefs = await SharedPreferences.getInstance();
          String localImagePath =
              prefs.getString('profile_image_path_${user.uid}') ?? '';

          if (localImagePath.isNotEmpty && File(localImagePath).existsSync()) {
            userImage.value = localImagePath;
          }
        }
      }
    }
  }

  // 🔹 Update the profile image (Upload to Firebase Storage)
  Future<void> updateProfileImage() async {
    String? savedPath = await pickImageController.getSavedImagePath();
    if (savedPath == null) return;

    String userId = authController.currentUser!.uid;
    userImage.value = savedPath; // 🔹 Update UI immediately

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'profile_image_path_$userId', savedPath); // 🔹 Save locally

    try {
      // 🔹 Upload to Firebase
      String imageUrl = await _uploadImageToFirebase(savedPath);

      // 🔹 Update Firestore for the correct user
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'image': imageUrl});

      userImage.value = imageUrl; // ✅ Update UI with Firestore image URL
      Get.snackbar("Success", "Profile picture updated!");
    } catch (e) {
      Get.snackbar("Error", "Failed to update profile image.");
    }
  }

  // 🔹 Upload Image to Firebase Storage
  Future<String> _uploadImageToFirebase(String imagePath) async {
    File imageFile = File(imagePath);
    String fileName = "${authController.currentUser!.uid}.png"; // Unique filename
    Reference storageRef =
        FirebaseStorage.instance.ref().child("profile_pics/$fileName");
    log('${fileName}');
    await storageRef.putFile(imageFile);
    return await storageRef.getDownloadURL();
  }

  // 🔹 Update Firestore when the user updates their name/about info
  Future<void> updateProfile(String newName, String newAbout) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(authController.currentUser!.uid) // Use UID, not email
          .update({'name': newName, 'about': newAbout});

      updatedName.value = newName;
      updatedAbout.value = newAbout;
      isEditing.value = false; // Exit edit mode
      Get.snackbar("Success", "Profile updated successfully!");
    } catch (e) {
      Get.snackbar("Error", "Failed to update profile.");
    }
  }

  void toggleEditing() {
    isEditing.value = !isEditing.value;
  }
}
