import 'dart:io';

import 'package:fyp_connect/chats%20and%20notifications/models/chat_user.dart';
import 'package:fyp_connect/chats%20and%20notifications/view_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';

class ProfileDialog extends StatelessWidget {
  const ProfileDialog({super.key, required this.user});
  final ChatUser user;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: SizedBox(
        width: 6.w,
        height: 35.h,
        child: Stack(
          children: [
         Align(
  alignment: Alignment.topLeft, // Keep text on the left
  child: Padding(
    padding: EdgeInsets.only(right: 40), // Space for the info icon
    child: Text(
      user.name,
      style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
  ),
),
            user.image.isNotEmpty
                ? Align(
                    alignment: Alignment.center,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20.h),
                      child: Image.file(
                        File(user.image),
                        width: 55.w,
                        height: 25.h,
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                : Align(
                    alignment: Alignment.center,
                    child: CircleAvatar(
                      radius: 50,
                      child: Icon(Icons.person, size: 50),
                    ),
                  ),
            Align(
                alignment: Alignment.topRight,
                child: MaterialButton(
                    onPressed: () {
                      Get.back();
                      Get.to(ViewProfileScreen(user: user));
                    },
                    shape: CircleBorder(),
                    minWidth: 0,
                    padding: EdgeInsets.all(0),
                    child: Align(
                        alignment: Alignment.topRight,
                        child: Icon(Icons.info_outline,
                            color: Colors.blue, size: 30))))
          ],
        ),
      ),
    );
  }
}
