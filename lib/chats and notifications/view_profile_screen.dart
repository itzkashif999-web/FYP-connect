import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fyp_connect/chats%20and%20notifications/controller/profile_controller.dart';
import 'package:fyp_connect/chats%20and%20notifications/models/chat_user.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
// Import your ChatUser model

// ignore: must_be_immutable
class ViewProfileScreen extends StatelessWidget {
  final ChatUser user;
  ProfileController controller = Get.find<ProfileController>();
  ViewProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(user.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Image
            Stack(
              children: [
                user.image.isNotEmpty
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(10.h),
                      child: Image.file(
                        File(user.image),
                        width: 45.w,
                        height: 20.h,
                        fit: BoxFit.cover,
                      ),
                    )
                    : CircleAvatar(
                      radius: 50,
                      child: Icon(Icons.person, size: 40),
                    ),
              ],
            ),
            SizedBox(height: 5.h),

            // Name
            Center(
              child: Text(
                user.email, // ✅ Ensure the selected user's name is shown
                style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 5.h),

            // About
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "About:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 2.w),
                Text(
                  user.about.isNotEmpty ? user.about : "No bio available",
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            SizedBox(height: 30.h),

            // Joined On
            Text(
              "Joined On:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              DateFormat('dd MMM yyyy').format(user.createdAt), // ✅ Format date
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
