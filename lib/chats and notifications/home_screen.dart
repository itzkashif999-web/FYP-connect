import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fyp_connect/StudentDashboard/student_dashboard.dart';
import 'package:fyp_connect/SupervisorDashboard/supervisor_dashboard.dart';
import 'package:fyp_connect/chats%20and%20notifications/helper/pick_image.dart';
import 'package:fyp_connect/chats%20and%20notifications/models/chat_user.dart';
import 'package:fyp_connect/chats%20and%20notifications/notifications/services/notification_service.dart';
import 'package:fyp_connect/chats%20and%20notifications/widgets/chat_user_card.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter/cupertino.dart';
import 'package:fyp_connect/chats%20and%20notifications/controller/auth_controller.dart';
import 'package:fyp_connect/chats%20and%20notifications/controller/profile_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ChatUser> _list = [];
  final List<ChatUser> _searchList = [];
  bool _isSearching = false;

  final AuthController controller = Get.find<AuthController>();
  final ProfileController profileController = Get.put(ProfileController());
  final PickImage pick = Get.find<PickImage>();
  NotificationService notificationService = NotificationService();

  bool? isSupervisor; // ✅ Proper declaration

  @override
  void initState() {
    super.initState();
    controller.getSelfInfo();
  //  notificationService.firebaseInit(context);
    // ✅ Check role on init
    getUserRole().then((_) {
      setState(() {}); // Trigger rebuild once role is determined
    });
    SystemChannels.lifecycle.setMessageHandler((message) {
      if (controller.auth.currentUser != null) {
        if (message.toString().contains('resume')) {
          controller.updateActiveStatus(true);
        }
        if (message.toString().contains('pause')) {
          controller.updateActiveStatus(false);
        }
      }
      return Future.value(message);
    });
  }

  Future<void> getUserRole() async {
    final uid = controller.auth.currentUser?.uid;
    print('🛠️ getUserRole for uid: $uid');
    if (uid == null) return;

    try {
      final doc = await controller.firestore.collection('users').doc(uid).get();
      final role = doc.data()?['role'];
      print('🛠️ User role from Firestore: $role');
      setState(() {
        isSupervisor = role == 'supervisor';
      });
    } catch (e) {
      print('❌ Error fetching role: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🛠️ Building HomeScreen, isSupervisor = $isSupervisor');
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.blue,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
      ),
    );

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: WillPopScope(
        onWillPop: () {
          if (_isSearching) {
            setState(() {
              _isSearching = !_isSearching;
            });
            return Future.value(false);
          } else {
            return Future.value(true);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Color.fromARGB(255, 24, 81, 91),

            iconTheme: const IconThemeData(color: Colors.white),
            titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),

            title:
                _isSearching
                    ? TextField(
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Name, email ..",
                      ),
                      autofocus: true,
                      style: TextStyle(fontSize: 16.sp, letterSpacing: 0.5),
                      onChanged: (val) {
                        _searchList.clear();
                        for (var user in _list) {
                          if (user.name.toLowerCase().contains(
                                val.toLowerCase(),
                              ) ||
                              user.email.toLowerCase().contains(
                                val.toLowerCase(),
                              )) {
                            _searchList.add(user);
                          }
                        }
                        setState(() {}); // Update UI after search
                      },
                    )
                    : const Text("CHAT"),
            leading: IconButton(
              onPressed: () {
                if (isSupervisor == true) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SupervisorDashboard(),
                    ),
                  );
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const StudentDashboard()),
                  );
                }
              },
              icon: const Icon(Icons.arrow_back),
            ),

            actions: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                  });
                },
                icon: Icon(
                  _isSearching
                      ? CupertinoIcons.clear_circled_solid
                      : Icons.search,
                ),
              ),
            ],
          ),

          /// ✅ Wait for role before building the chat list
          body:
              isSupervisor == null
                  ? const Center(child: CircularProgressIndicator())
                  : StreamBuilder<List<ChatUser>>(
                    stream:
                        isSupervisor!
                            ? controller.getStudentsInMyGroups()
                            : controller.getAllLinkedSupervisorsForStudent(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return const Center(
                          child: Text("Something went wrong!"),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text("No users found"));
                      }

                      _list = snapshot.data!;

                      return ListView.builder(
                        padding: EdgeInsets.only(top: 1.w),
                        itemCount:
                            _isSearching ? _searchList.length : _list.length,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          return ChatUserCard(
                            user:
                                _isSearching
                                    ? _searchList[index]
                                    : _list[index],
                          );
                        },
                      );
                    },
                  ),
        ),
      ),
    );
  }
}
