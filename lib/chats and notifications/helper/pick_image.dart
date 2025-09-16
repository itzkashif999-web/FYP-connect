import 'dart:io';
import '../controller/auth_controller.dart';
import 'package:fyp_connect/chats%20and%20notifications/controller/auth_controller.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PickImage extends GetxController {
  final ImagePicker _picker = ImagePicker();
  final AuthController controller = Get.find<AuthController>();
  bool isProcessing = false;
  // 🔹 Pick and save image, return path to caller
  Future<String?> pickAndSaveImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) return null;

    File imageFile = File(pickedFile.path);

    // 🔹 Save the path in SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'profile_image_path_${controller.currentUser!.uid}', imageFile.path);

    return imageFile.path; // ✅ Return image path to caller
  }

  // 🔹 Retrieve saved image path
  Future<String?> getSavedImagePath() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('profile_image_path_${controller.currentUser!.uid}');
  }

  Future<String?> pickAndSaveChatImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) return null;

    File imageFile = File(pickedFile.path);
    isProcessing = false;

    // 🔹 Save the path in SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'chat_images_${controller.currentUser!.uid}', imageFile.path);

    return imageFile.path; // ✅ Return image path to caller
  }

  Future<String?> getSavedChatImagePath() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('chat_images_${controller.currentUser!.uid}');
  }

  Future<List<String>> pickAndSaveChatImages(ImageSource source) async {
    final List<XFile>? pickedFiles = await _picker.pickMultiImage();

    if (pickedFiles == null || pickedFiles.isEmpty) return [];

    List<String> savedImagePaths = [];
    SharedPreferences prefs = await SharedPreferences.getInstance();

    for (XFile file in pickedFiles) {
      File imageFile = File(file.path);
      savedImagePaths.add(imageFile.path);
    }

    // 🔹 Save the paths in SharedPreferences (optional)
    await prefs.setStringList(
        'chat_images_${controller.currentUser!.uid}', savedImagePaths);

    return savedImagePaths; // ✅ Return all selected image paths
  }

  Future<List<String>?> getSavedChatImagePaths() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('chat_images_${controller.currentUser!.uid}');
  }
}

