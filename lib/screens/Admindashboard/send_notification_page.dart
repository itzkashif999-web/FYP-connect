// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class SendNotificationPage extends StatefulWidget {
//   const SendNotificationPage({super.key});

//   @override
//   _SendNotificationPageState createState() => _SendNotificationPageState();
// }

// class _SendNotificationPageState extends State<SendNotificationPage> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _titleController = TextEditingController();
//   final TextEditingController _messageController = TextEditingController();
//   final TextEditingController _userIdController = TextEditingController();

//   String _target = "All"; // Default target

//   Future<void> _sendNotification() async {
//     if (_formKey.currentState!.validate()) {
//       String title = _titleController.text.trim();
//       String message = _messageController.text.trim();
//       String userIdInput = _userIdController.text.trim();

//       try {
//         final firestore = FirebaseFirestore.instance;

//         if (_target == "All") {
//           final users = await firestore.collection("users").get();
//           for (var user in users.docs) {
//             await firestore
//                 .collection("notifications")
//                 .doc(user.id)
//                 .collection("notifications")
//                 .add({
//                   "title": title,
//                   "body": message,
//                   "target": "All",
//                   "createdAt": FieldValue.serverTimestamp(),
//                   "isSeen": false,
//                 });
//           }
//         } else if (_target == "Students") {
//           final students =
//               await firestore
//                   .collection("users")
//                   .where("role", isEqualTo: "Student")
//                   .get();
//           for (var student in students.docs) {
//             debugPrint("Student ID: ${student.id}");
//             await firestore
//                 .collection("notifications")
//                 .doc(student.id)
//                 .collection("notifications")
//                 .add({
//                   "title": title,
//                   "body": message,
//                   "target": "Students",
//                   "createdAt": FieldValue.serverTimestamp(),
//                   "isSeen": false,
//                 });
//           }
//         } else if (_target == "Supervisors") {
//           final supervisors =
//               await firestore
//                   .collection("users")
//                   .where("role", isEqualTo: "Supervisor")
//                   .get();
//           for (var supervisor in supervisors.docs) {
//             await firestore
//                 .collection("notifications")
//                 .doc(supervisor.id)
//                 .collection("notifications")
//                 .add({
//                   "title": title,
//                   "body": message,
//                   "target": "Supervisors",
//                   "createdAt": FieldValue.serverTimestamp(),
//                   "isSeen": false,
//                 });
//           }
//         } else if (_target == "Specific User" && userIdInput.isNotEmpty) {
//           String? actualUserId;

//           // 1. Try supervisor_profiles
//           final supDoc =
//               await firestore
//                   .collection("supervisor_profiles")
//                   .where("id", isEqualTo: userIdInput)
//                   .limit(1)
//                   .get();

//           if (supDoc.docs.isNotEmpty) {
//             actualUserId = supDoc.docs.first.data()["userId"];
//             debugPrint("✅ Found supervisor userId: $actualUserId");
//           }

//           // 2. If not found, check student_profiles (doc ID is userId)
//           if (actualUserId == null) {
//             final stuDoc =
//                 await firestore
//                     .collection("student_profiles")
//                     .where("regNo", isEqualTo: userIdInput)
//                     .limit(1)
//                     .get();

//             if (stuDoc.docs.isNotEmpty) {
//               actualUserId = stuDoc.docs.first.id;
//               debugPrint("✅ Found student userId: $actualUserId");
//             }
//           }

//           if (actualUserId != null) {
//             var notificationRef =
//                 firestore
//                     .collection("notifications")
//                     .doc(actualUserId)
//                     .collection("notifications")
//                     .doc(); // auto ID

//             await notificationRef.set({
//               "title": title,
//               "body": message,
//               "isSeen": false,
//               "createdAt": FieldValue.serverTimestamp(),
//             });

//             debugPrint("📩 Notification saved for userId: $actualUserId");
//           } else {
//             throw Exception("❌ User not found for ID: $userIdInput");
//           }
//         }

//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("✅ Notification sent successfully!")),
//         );

//         _titleController.clear();
//         _messageController.clear();
//         _userIdController.clear();
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("❌ Failed to send notification: $e")),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Send Notification"),
//         backgroundColor: Colors.blueGrey[900],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: SingleChildScrollView(
//             child: Column(
//               children: [
//                 TextFormField(
//                   controller: _titleController,
//                   decoration: const InputDecoration(
//                     labelText: "Notification Title",
//                     border: OutlineInputBorder(),
//                   ),
//                   validator: (value) => value!.isEmpty ? "Enter a title" : null,
//                 ),
//                 const SizedBox(height: 16),

//                 TextFormField(
//                   controller: _messageController,
//                   decoration: const InputDecoration(
//                     labelText: "Notification Message",
//                     border: OutlineInputBorder(),
//                   ),
//                   maxLines: 3,
//                   validator:
//                       (value) => value!.isEmpty ? "Enter a message" : null,
//                 ),
//                 const SizedBox(height: 16),

//                 DropdownButtonFormField<String>(
//                   value: _target,
//                   items:
//                       ["All", "Students", "Supervisors", "Specific User"].map((
//                         target,
//                       ) {
//                         return DropdownMenuItem(
//                           value: target,
//                           child: Text(target),
//                         );
//                       }).toList(),
//                   onChanged: (value) {
//                     setState(() {
//                       _target = value!;
//                     });
//                   },
//                   decoration: const InputDecoration(
//                     labelText: "Send To",
//                     border: OutlineInputBorder(),
//                   ),
//                 ),
//                 const SizedBox(height: 16),

//                 if (_target == "Specific User")
//                   TextFormField(
//                     controller: _userIdController,
//                     decoration: const InputDecoration(
//                       labelText: "Enter User ID (UID or Email)",
//                       border: OutlineInputBorder(),
//                     ),
//                     validator: (value) {
//                       if (_target == "Specific User" &&
//                           (value == null || value.isEmpty)) {
//                         return "Enter User ID";
//                       }
//                       return null;
//                     },
//                   ),
//                 const SizedBox(height: 24),

//                 ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blueGrey[800],
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 40,
//                       vertical: 15,
//                     ),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(15),
//                     ),
//                   ),
//                   onPressed: _sendNotification,
//                   child: const Text(
//                     "Send Notification",
//                     style: TextStyle(fontSize: 16),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SendNotificationPage extends StatefulWidget {
  const SendNotificationPage({super.key});

  @override
  _SendNotificationPageState createState() => _SendNotificationPageState();
}

class _SendNotificationPageState extends State<SendNotificationPage> {
  static const Color primaryDark = Color.fromARGB(255, 24, 81, 91);
  static const Color primaryLight = Color.fromARGB(255, 133, 213, 231);

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _userIdController = TextEditingController();

  String _target = "All";
  bool _isLoading = false; // Added loading state

  Future<void> _sendNotification() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      String title = _titleController.text.trim();
      String message = _messageController.text.trim();
      String userIdInput = _userIdController.text.trim();

      try {
        final firestore = FirebaseFirestore.instance;

        if (_target == "All") {
          final users = await firestore.collection("users").get();
          for (var user in users.docs) {
            await firestore
                .collection("notifications")
                .doc(user.id)
                .collection("notifications")
                .add({
                  "title": title,
                  "body": message,
                  "target": "All",
                  "createdAt": FieldValue.serverTimestamp(),
                  "isSeen": false,
                });
          }
        } else if (_target == "Students") {
          final students =
              await firestore
                  .collection("users")
                  .where("role", isEqualTo: "Student")
                  .get();
          for (var student in students.docs) {
            debugPrint("Student ID: ${student.id}");
            await firestore
                .collection("notifications")
                .doc(student.id)
                .collection("notifications")
                .add({
                  "title": title,
                  "body": message,
                  "target": "Students",
                  "createdAt": FieldValue.serverTimestamp(),
                  "isSeen": false,
                });
          }
        } else if (_target == "Supervisors") {
          final supervisors =
              await firestore
                  .collection("users")
                  .where("role", isEqualTo: "Supervisor")
                  .get();
          for (var supervisor in supervisors.docs) {
            await firestore
                .collection("notifications")
                .doc(supervisor.id)
                .collection("notifications")
                .add({
                  "title": title,
                  "body": message,
                  "target": "Supervisors",
                  "createdAt": FieldValue.serverTimestamp(),
                  "isSeen": false,
                });
          }
        } else if (_target == "Specific User" && userIdInput.isNotEmpty) {
          String? actualUserId;

          final supDoc =
              await firestore
                  .collection("supervisor_profiles")
                  .where("id", isEqualTo: userIdInput)
                  .limit(1)
                  .get();

          if (supDoc.docs.isNotEmpty) {
            actualUserId = supDoc.docs.first.data()["userId"];
            debugPrint("✅ Found supervisor userId: $actualUserId");
          }

          if (actualUserId == null) {
            final stuDoc =
                await firestore
                    .collection("student_profiles")
                    .where("regNo", isEqualTo: userIdInput)
                    .limit(1)
                    .get();

            if (stuDoc.docs.isNotEmpty) {
              actualUserId = stuDoc.docs.first.id;
              debugPrint("✅ Found student userId: $actualUserId");
            }
          }

          if (actualUserId != null) {
            var notificationRef =
                firestore
                    .collection("notifications")
                    .doc(actualUserId)
                    .collection("notifications")
                    .doc();

            await notificationRef.set({
              "title": title,
              "body": message,
              "isSeen": false,
              "createdAt": FieldValue.serverTimestamp(),
            });

            debugPrint("📩 Notification saved for userId: $actualUserId");
          } else {
            throw Exception("❌ User not found for ID: $userIdInput");
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text("Notification sent successfully!"),
              ],
            ),
            backgroundColor: primaryDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        _titleController.clear();
        _messageController.clear();
        _userIdController.clear();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text("Failed to send notification: $e")),
              ],
            ),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Send Notification",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: primaryDark,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryDark, primaryLight.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryLight.withOpacity(0.1), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [primaryLight.withOpacity(0.2), Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: primaryDark,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.notifications_active,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Notification Center",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 24, 81, 91),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "Send notifications to users",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildStyledTextField(
                    controller: _titleController,
                    label: "Notification Title",
                    icon: Icons.title,
                    validator:
                        (value) => value!.isEmpty ? "Enter a title" : null,
                  ),
                  const SizedBox(height: 20),

                  _buildStyledTextField(
                    controller: _messageController,
                    label: "Notification Message",
                    icon: Icons.message,
                    maxLines: 4,
                    validator:
                        (value) => value!.isEmpty ? "Enter a message" : null,
                  ),
                  const SizedBox(height: 20),

                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryLight.withOpacity(0.5)),
                      color: Colors.white,
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _target,
                      items:
                          [
                            "All",
                            "Students",
                            "Supervisors",
                            "Specific User",
                          ].map((target) {
                            return DropdownMenuItem(
                              value: target,
                              child: Row(
                                children: [
                                  Icon(
                                    _getTargetIcon(target),
                                    color: primaryDark,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(target),
                                ],
                              ),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _target = value!;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: "Send To",
                        labelStyle: TextStyle(color: primaryDark),
                        prefixIcon: Icon(Icons.group, color: primaryDark),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      dropdownColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),

                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: _target == "Specific User" ? null : 0,
                    child:
                        _target == "Specific User"
                            ? _buildStyledTextField(
                              controller: _userIdController,
                              label: "Enter User ID (UID or Email)",
                              icon: Icons.person_search,
                              validator: (value) {
                                if (_target == "Specific User" &&
                                    (value == null || value.isEmpty)) {
                                  return "Enter User ID";
                                }
                                return null;
                              },
                            )
                            : const SizedBox.shrink(),
                  ),
                  if (_target == "Specific User") const SizedBox(height: 32),
                  if (_target != "Specific User") const SizedBox(height: 32),

                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [primaryDark, primaryLight],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryDark.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _isLoading ? null : _sendNotification,
                      child:
                          _isLoading
                              ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    "Sending...",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              )
                              : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.send,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Send Notification",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: primaryLight.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: primaryDark),
          prefixIcon: Icon(icon, color: primaryDark),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryLight.withOpacity(0.5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryLight.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryDark, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  IconData _getTargetIcon(String target) {
    switch (target) {
      case "All":
        return Icons.public;
      case "Students":
        return Icons.school;
      case "Supervisors":
        return Icons.supervisor_account;
      case "Specific User":
        return Icons.person;
      default:
        return Icons.group;
    }
  }
}
