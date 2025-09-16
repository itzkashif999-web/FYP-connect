import 'dart:io';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/services.dart';
import 'package:fyp_connect/chats%20and%20notifications/controller/profile_controller.dart';
import 'package:fyp_connect/chats%20and%20notifications/helper/my_date_util.dart';
import 'package:fyp_connect/chats%20and%20notifications/helper/pick_image.dart';
import 'package:fyp_connect/chats%20and%20notifications/models/chat_user.dart';
import 'package:fyp_connect/chats%20and%20notifications/models/message.dart';
import 'package:fyp_connect/chats%20and%20notifications/view_profile_screen.dart';
import 'package:fyp_connect/chats%20and%20notifications/widgets/message_card.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  final ChatUser user;
  ChatScreen({super.key, required this.user});

  final TextEditingController _textController = TextEditingController();
  final ProfileController controller = Get.find<ProfileController>();
  final PickImage pick = Get.find<PickImage>();
  final RxBool _showEmoji = false.obs;
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.white, // Match this to AppBar background
        statusBarIconBrightness: Brightness.dark, // Icon color
      ),
    );
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SafeArea(
        child: WillPopScope(
          onWillPop: () async {
            if (_showEmoji.value) {
              _showEmoji.value = !_showEmoji.value;
              return Future.value(false);
            }
            return Future.value(true);
          },
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.white,

              //  automaticallyImplyLeading: false,
              iconTheme: const IconThemeData(color: Colors.white),
              titleTextStyle: const TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
              flexibleSpace: _appBar(),
            ),
            backgroundColor: const Color.fromARGB(255, 201, 222, 239),
            body: Column(
              children: [
                Expanded(
                  child: StreamBuilder(
                    stream: controller.authController.getMessages(user),
                    builder: (context, snapshot) {
                      switch (snapshot.connectionState) {
                        case ConnectionState.waiting:
                        case ConnectionState.none:
                          return SizedBox();
                        case ConnectionState.active:
                        case ConnectionState.done:
                      }
                      final data = snapshot.data?.docs;
                      List<Message> list =
                          data
                              ?.map((e) => Message.fromJson(e.data(), e.id))
                              .toList() ??
                          [];
                      if (list.isNotEmpty) {
                        return ListView.builder(
                          reverse: true,
                          padding: EdgeInsets.only(top: 1.w),
                          itemCount: list.length,
                          physics: const BouncingScrollPhysics(),
                          itemBuilder: (context, index) {
                            return MessageCard(message: list[index]);
                          },
                        );
                      } else {
                        return Center(
                          child: Text(
                            'Say Hi!👋',
                            style: TextStyle(fontSize: 18.sp),
                          ),
                        );
                      }
                    },
                  ),
                ),
                _chatInput(),
                Obx(
                  () =>
                      _showEmoji.value
                          ? SizedBox(
                            child: EmojiPicker(
                              textEditingController: _textController,
                              config: Config(
                                height: 35.h,
                                checkPlatformCompatibility: true,
                                emojiViewConfig: EmojiViewConfig(
                                  columns: 8,
                                  emojiSizeMax:
                                      28 *
                                      (foundation.defaultTargetPlatform ==
                                              TargetPlatform.iOS
                                          ? 1.20
                                          : 1.0),
                                ),
                              ),
                            ),
                          )
                          : SizedBox(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _appBar() {
    return InkWell(
      onTap: () {
        Get.to(ViewProfileScreen(user: user));
      },
      child: StreamBuilder(
        stream: controller.authController.getUserInfo(user),
        builder: (context, snapshot) {
          final data = snapshot.data?.docs;
          final list =
              data?.map((e) => ChatUser.fromJson(e.data())).toList() ?? [];

          return Row(
            children: [
              IconButton(
                onPressed: () {
                  Get.back();
                },
                icon: Icon(Icons.arrow_back, color: Colors.black54),
              ),

              CircleAvatar(
                radius: 24,
                backgroundImage:
                    user.image.isNotEmpty ? FileImage(File(user.image)) : null,
                backgroundColor: Color.fromARGB(255, 39, 177, 202),
                child:
                    user.image.isEmpty
                        ? Icon(Icons.person, size: 24, color: Colors.white)
                        : null,
              ),
              SizedBox(width: 2.w),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    list.isNotEmpty ? list[0].name : user.name,
                    style: TextStyle(
                      fontSize: 18.sp,
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    (list.isNotEmpty
                        ? list[0].isOnline
                            ? 'Online'
                            : MyDateUtil.formatTime(
                              list[0].lastActive,
                            ) // Convert DateTime to String
                        : MyDateUtil.formatTime(user.lastActive)),
                    style: TextStyle(fontSize: 14.sp, color: Colors.black54),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  //
  Widget _chatInput() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 0.25.w),
      child: Row(
        children: [
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: Row(
                children: [
                  Obx(
                    () => IconButton(
                      onPressed: () {
                        FocusScope.of(Get.context!).unfocus();
                        _showEmoji.value = !_showEmoji.value;
                      },
                      icon: Icon(
                        Icons.emoji_emotions,
                        color:
                            _showEmoji.value
                                ? Colors.orange
                                : Color.fromARGB(255, 39, 177, 202),
                        size: 24.sp,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      onTap: () {
                        if (_showEmoji.value) {
                          _showEmoji.value = false;
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Type Something',
                        hintStyle: TextStyle(
                          color: const Color.fromARGB(255, 150, 180, 231),
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      List<String> savedImagePaths = await pick
                          .pickAndSaveChatImages(ImageSource.gallery);

                      if (savedImagePaths.isNotEmpty) {
                        for (String path in savedImagePaths) {
                          await controller.authController.sendChatImage(
                            user,
                            File(path),
                          );
                        }
                      }
                    },
                    icon: Icon(
                      Icons.image,
                      color: Color.fromARGB(255, 39, 177, 202),
                      size: 24.sp,
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      await pick.pickAndSaveChatImage(ImageSource.camera);

                      String? savedImagePath =
                          await pick.getSavedChatImagePath();

                      File imageFile = File(savedImagePath!);
                      await controller.authController.sendChatImage(
                        user,
                        imageFile,
                      );
                      print("✅ Chat image sent successfully.");
                    },
                    icon: Icon(
                      Icons.camera_alt_rounded,
                      color: Color.fromARGB(255, 39, 177, 202),
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 2.w),
                ],
              ),
            ),
          ),
          MaterialButton(
            color: Colors.green,
            shape: CircleBorder(),
            onPressed: () {
              print("📌 Debug: Sending message to user ID -> ${user.id}");
              if (_textController.text.isNotEmpty) {
                controller.authController.sendMessage(
                  _textController.text,
                  user,
                );
                _textController.text = '';
              }
            },
            minWidth: 0,
            padding: EdgeInsets.only(top: 10, right: 5, bottom: 10, left: 10),
            child: Icon(Icons.send, color: Colors.white, size: 23.sp),
          ),
        ],
      ),
    );
  }
}
