import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fyp_connect/chats%20and%20notifications/controller/auth_controller.dart';
import 'package:fyp_connect/chats%20and%20notifications/helper/my_date_util.dart';
import 'package:fyp_connect/chats%20and%20notifications/models/message.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';

bool isLocalImage(String path) {
  return File(path).existsSync();
}

class MessageCard extends StatelessWidget {
  final Message message;

  MessageCard({super.key, required this.message});

  final AuthController authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    final currentUserId = authController.user?.uid;

    // If user is not logged in or user info not ready, return empty widget
    if (currentUserId == null) {
      return SizedBox.shrink();
    }

    return currentUserId == message.fromId ? _greenMesage() : _blueMessage();
  }

  Widget _blueMessage() {
    if (message.read.isEmpty) {
      authController.updateMessageReadStatus(message);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Container(
            padding: EdgeInsets.all(message.type == Type.image ? 1.w : 3.w),
            margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 174, 213, 244),
              border: Border.all(color: Colors.blue),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child:
                message.type == Type.text
                    ? Text(
                      message.msg,
                      style: TextStyle(fontSize: 18.sp, color: Colors.black87),
                    )
                    : ClipRRect(
                      borderRadius: BorderRadius.circular(3.h),
                      child: CachedNetworkImage(
                        imageUrl: message.msg, // Always Cloudinary URL
                        width: 50.w,
                        height: 30.h,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(),
                            ),
                        errorWidget:
                            (context, url, error) =>
                                Icon(Icons.broken_image, size: 50.sp),
                      ),
                    ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(right: 4.w),
          child: Text(
            MyDateUtil.getFormattedTime(
              context: Get.context!,
              time: message.sent,
            ),
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ),
      ],
    );
  }

  Widget _greenMesage() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            SizedBox(width: 2.w),
            if (message.read.isNotEmpty)
              Icon(Icons.done_all_rounded, color: Colors.blue, size: 20.sp),
            SizedBox(width: 2.w),
            Text(
              MyDateUtil.getFormattedTime(
                context: Get.context!,
                time: message.sent,
              ),
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
        Flexible(
          child: Container(
            padding: EdgeInsets.all(message.type == Type.image ? 1.w : 3.w),
            margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 169, 248, 173),
              border: Border.all(color: Colors.green),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
                bottomLeft: Radius.circular(30),
              ),
            ),
            child:
                message.type == Type.text
                    ? Text(
                      message.msg,
                      style: TextStyle(fontSize: 18.sp, color: Colors.black87),
                    )
                    : ClipRRect(
                      borderRadius: BorderRadius.circular(3.h),
                      child:
                          isLocalImage(message.msg)
                              ? Image.file(
                                File(message.msg), // Local Image
                                width: 50.w,
                                height: 30.h,
                                fit: BoxFit.cover,
                              )
                              : CachedNetworkImage(
                                imageUrl: message.msg,
                                width: 50.w,
                                height: 30.h,
                                fit: BoxFit.cover,
                                placeholder:
                                    (context, url) => Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                errorWidget:
                                    (context, url, error) =>
                                        Icon(Icons.broken_image, size: 50.sp),
                              ),
                    ),
          ),
        ),
      ],
    );
  }
}
