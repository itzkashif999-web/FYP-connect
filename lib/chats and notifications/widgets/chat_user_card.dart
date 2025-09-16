// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:fyp_connect/chats/chat_screen.dart';
// import 'package:fyp_connect/chats/controller/profile_controller.dart';
// import 'package:fyp_connect/chats/helper/my_date_util.dart';
// import 'package:fyp_connect/chats/helper/pick_image.dart';
// import 'package:fyp_connect/chats/models/chat_user.dart';
// import 'package:fyp_connect/chats/models/message.dart';
// import 'package:fyp_connect/chats/widgets/dialogs/profile_dialog.dart';
// import 'package:get/get.dart';
// import 'package:sizer/sizer.dart';

// // ignore: must_be_immutable
// class ChatUserCard extends StatelessWidget {
//   ChatUser user; // 🔹 Declare as a final instance variable
//   final PickImage pick = Get.find<PickImage>();
//   final ProfileController controller = Get.find<ProfileController>();
//   Message? _message;
//   // 🔹 Constructor to accept user data
//   ChatUserCard({super.key, required this.user});
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: EdgeInsets.symmetric(horizontal: 1.w, vertical: 2.w),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
//       color: const Color.fromARGB(255, 198, 249, 200),
//       elevation: 1,
//       child: InkWell(
//         onTap: () {
//           print("Navigating with user: ${user.toJson()}");
//           Get.to(ChatScreen(user: user));
//         },
//         child: StreamBuilder(
//           stream: controller.authController.getLastMessage(user),
//           builder: (context, snapshot) {
//             final data = snapshot.data?.docs;
//             final list =
//                 data?.map((e) => Message.fromJson(e.data(), e.id)).toList() ??
//                 [];
//             if (list.isNotEmpty) {
//               _message = list[0];
//             }
//             return ListTile(
//               leading: InkWell(
//                 onTap: () {
//                   showDialog(
//                     context: context,
//                     builder: (_) => ProfileDialog(user: user),
//                   );
//                 },
//                 child: CircleAvatar(
//                   radius: 24,
//                   backgroundImage:
//                       user.image.isNotEmpty
//                           ? FileImage(File(user.image))
//                           : AssetImage('assets/appBg.jpeg'),
//                 ),
//               ),
//               title: Text(user.name),
//               subtitle:
//                   _message != null
//                       ? _message!.type == Type.image
//                           ? Row(children: [Icon(Icons.photo), Text('Photo')])
//                           : Text(
//                             _message!.msg,
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                           )
//                       : (user.about.isNotEmpty
//                           ? Text(
//                             user.about,
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                           )
//                           : SizedBox()), // Show nothing if about is empty

//               trailing:
//                   _message == null
//                       ? null
//                       : _message!.read.isEmpty &&
//                           _message!.fromId !=
//                               controller.authController.user!.uid
//                       ? Container(
//                         width: 9, // Fixed size for status indicator
//                         height: 9,
//                         decoration: BoxDecoration(
//                           color:
//                               user.isOnline
//                                   ? Colors.green
//                                   : Colors
//                                       .grey, // Change color based on online status
//                           shape: BoxShape.circle,
//                         ),
//                       )
//                       : Text(
//                         MyDateUtil.getFormattedTime(
//                           context: context,
//                           time: _message!.sent,
//                         ),
//                         style: TextStyle(color: Colors.black54),
//                       ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fyp_connect/chats%20and%20notifications/chat_screen.dart';
import 'package:fyp_connect/chats%20and%20notifications/controller/profile_controller.dart';
import 'package:fyp_connect/chats%20and%20notifications/helper/my_date_util.dart';
import 'package:fyp_connect/chats%20and%20notifications/models/chat_user.dart';
import 'package:fyp_connect/chats%20and%20notifications/models/message.dart';
import 'package:fyp_connect/chats%20and%20notifications/widgets/dialogs/profile_dialog.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';

// ignore: must_be_immutable
class ChatUserCard extends StatelessWidget {
  ChatUser user;
  final ProfileController controller = Get.find<ProfileController>();
  Message? _message;

  ChatUserCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 1.w, vertical: 2.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      color: const Color.fromARGB(255, 198, 249, 200),
      elevation: 1,
      child: InkWell(
        onTap: () {
          print("Navigating with user: ${user.toJson()}");
          Get.to(ChatScreen(user: user));
        },
        child: StreamBuilder(
          stream: controller.authController.getLastMessage(user),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data == null) {
              // No data yet, show basic user info
              return ListTile(
                leading: InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => ProfileDialog(user: user),
                    );
                  },
                  child: CircleAvatar(
                    radius: 24,
                    backgroundImage:
                        user.image.isNotEmpty
                            ? FileImage(File(user.image))
                            : const AssetImage('assets/appBg.jpeg')
                                as ImageProvider,
                  ),
                ),
                title: Text(user.name),
                subtitle:
                    user.about.isNotEmpty
                        ? Text(
                          user.about,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                        : const SizedBox.shrink(),
                trailing: null,
              );
            }

            final data = snapshot.data!.docs;
            final list =
                data.map((e) => Message.fromJson(e.data(), e.id)).toList();

            if (list.isNotEmpty) {
              _message = list[0];
            } else {
              _message = null;
            }

            return ListTile(
              leading: InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => ProfileDialog(user: user),
                  );
                },
                child: CircleAvatar(
                  radius: 24,
                  backgroundImage:
                      user.image.isNotEmpty
                          ? FileImage(File(user.image))
                          : null,
                  backgroundColor: Color.fromARGB(255, 39, 177, 202),
                  child:
                      user.image.isEmpty
                          ? Icon(Icons.person, size: 24, color: Colors.white)
                          : null,
                ),
              ),
              title: Text(user.name),
              subtitle:
                  _message != null
                      ? _message!.type == Type.image
                          ? Row(
                            children: const [
                              Icon(Icons.photo),
                              SizedBox(width: 5),
                              Text('Photo'),
                            ],
                          )
                          : Text(
                            _message!.msg,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                      : user.about.isNotEmpty
                      ? Text(
                        user.about,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                      : const SizedBox.shrink(),
              trailing:
                  _message == null
                      ? null
                      : (_message!.read.isEmpty &&
                          _message!.fromId !=
                              controller.authController.user?.uid)
                      ? Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: user.isOnline ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      )
                      : Text(
                        MyDateUtil.getFormattedTime(
                          context: context,
                          time: _message!.sent,
                        ),
                        style: const TextStyle(color: Colors.black54),
                      ),
            );
          },
        ),
      ),
    );
  }
}
