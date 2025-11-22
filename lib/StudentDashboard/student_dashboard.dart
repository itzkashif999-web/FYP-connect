import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart' as badges;
import 'package:flutter/services.dart';
import 'package:fyp_connect/StudentDashboard/send_proposal_page.dart';
import 'package:fyp_connect/StudentDashboard/student_track_page.dart';
import 'package:fyp_connect/auth/auth_service.dart';
import 'package:fyp_connect/chats%20and%20notifications/controller/auth_controller.dart';
import 'package:fyp_connect/chats%20and%20notifications/controller/notification_controller.dart';
import 'package:fyp_connect/chats%20and%20notifications/home_screen.dart';
import 'package:fyp_connect/chats%20and%20notifications/notifications/notification_screen.dart';
import 'package:fyp_connect/chats%20and%20notifications/notifications/services/get_server_key.dart';
import 'package:fyp_connect/chats%20and%20notifications/notifications/services/notification_service.dart';

import 'package:fyp_connect/screens/sign_in_page.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ai_recommendation_page.dart';
import 'search_supervisor_page.dart';
import 'schedule_meeting_page.dart';
import 'supervisors_list.dart';
import 'student_profile_page.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final NotificationService notificationService = NotificationService();
  final GetServerKey _serverKey = GetServerKey();
  final NotificationController notificationController = Get.put(
    NotificationController(),
  );
  final AuthController controller = Get.find<AuthController>();
  AuthService authService = AuthService();
  final AuthService auth = AuthService();
  bool _showProfileMessage = true;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<String>> events = {};
  Map<DateTime, List<String>> milestones = {};

  /// 🔹 Normalize to year-month-day only
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// 🔹 Fetch milestones from Firestore
  Future<void> _loadMilestones() async {
    final snapshot =
        await FirebaseFirestore.instance.collection("milestones").get();

    Map<DateTime, List<String>> fetched = {};

    for (var doc in snapshot.docs) {
      DateTime date = (doc['date'] as Timestamp).toDate();
      String title = doc['title'];

      DateTime normalized = _normalizeDate(date);

      fetched.putIfAbsent(normalized, () => []);
      fetched[normalized]!.add(title);
    }

    setState(() {
      milestones = fetched;
    });

    debugPrint("✅ Loaded milestones: $milestones");
  }

  /// 🔹 Get events for specific day
  List<String> _getEventsForDay(DateTime day) {
    return milestones[_normalizeDate(day)] ?? [];
  }

  Future<String?> _getProjectIdForStudent(String uid) async {
    final projectSnapshot =
        await FirebaseFirestore.instance
            .collection('projects')
            .where('studentId', isEqualTo: uid)
            .limit(1)
            .get();

    if (projectSnapshot.docs.isNotEmpty) {
      return projectSnapshot.docs.first.id;
    }
    return null;
  }

  Future<String?> _getSupervisorIdForStudent(String uid) async {
    final projectSnapshot =
        await FirebaseFirestore.instance
            .collection('projects')
            .where('studentId', isEqualTo: uid)
            .limit(1)
            .get();

    if (projectSnapshot.docs.isNotEmpty) {
      return projectSnapshot.docs.first.data()['supervisorId'];
    }
    return null;
  }

  Future<Map<String, String>?> _getSupervisorInfo(String studentId) async {
    final doc =
        await FirebaseFirestore.instance
            .collection('students')
            .doc(studentId)
            .get();
    if (!doc.exists) return null;
    final data = doc.data();
    final supervisorId = data?['supervisorId'] ?? '';
    final supervisorName = data?['supervisorName'] ?? '';
    if (supervisorId.isEmpty || supervisorName.isEmpty) return null;
    return {'id': supervisorId, 'name': supervisorName};
  }

  Future<Map<String, dynamic>?> _getStudentData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final doc =
        await FirebaseFirestore.instance.collection('students').doc(uid).get();
    if (!doc.exists) return null;

    return doc.data();
  }

  /// 🔹 Fetch overall progress from Firestore tasks
  Future<double> _fetchOverallProgress(String projectId) async {
    final taskSnapshot =
        await FirebaseFirestore.instance
            .collection('projects')
            .doc(projectId)
            .collection('tasks')
            .get();

    if (taskSnapshot.docs.isEmpty) return 0.0;

    List<Map<String, dynamic>> tasks = [];

    for (final doc in taskSnapshot.docs) {
      // final data = doc.data();
      final supervisorFilesSnapshot =
          await doc.reference.collection("supervisorFiles").get();

      final supervisorFiles =
          supervisorFilesSnapshot.docs.map((d) => d.data()).toList();

      final submittedCount =
          supervisorFiles
              .where(
                (f) =>
                    (f["status"] ?? "").toString().toLowerCase() == "submitted",
              )
              .length;

      int milestoneId = int.tryParse(doc.id.replaceAll("m", "")) ?? 0;

      tasks.add({
        "milestoneId": milestoneId,
        "supervisorFileCount": supervisorFiles.length,
        "submittedCount": submittedCount,
      });
    }

    tasks.sort((a, b) => a["milestoneId"].compareTo(b["milestoneId"]));

    double overallProgress = 0.0;
    final milestoneIds =
        tasks.map((t) => t["milestoneId"] as int).toSet().toList()..sort();

    double getMilestoneWeight(int id) {
      switch (id) {
        case 10:
          return 0.1;
        case 30:
          return 0.3;
        case 60:
          return 0.6;
        case 100:
          return 1.0;
        default:
          return 0.0;
      }
    }

    for (final id in milestoneIds) {
      final milestoneTasks =
          tasks.where((t) => t["milestoneId"] == id).toList();
      bool milestoneCompleted = milestoneTasks.every(
        (task) =>
            (task["supervisorFileCount"] ?? 0) > 0 &&
            (task["submittedCount"] ?? 0) == (task["supervisorFileCount"] ?? 0),
      );

      if (milestoneCompleted) {
        overallProgress = getMilestoneWeight(id);
      }
    }

    return overallProgress.clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();
    _checkProfileStatus();
    controller.getSelfInfo();
    notificationService.requestNotificationPermission();
    notificationService.getDeviceToken();
    notificationService.firebaseInit(context);
    notificationService.setupInteractMessage(context);
    _serverKey.getServerKeyToken();
    _loadMilestones();
    SystemChannels.lifecycle.setMessageHandler((message) {
      log('Message: $message');
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

  Future<void> _checkProfileStatus() async {
    final profile = await AuthService().getStudentProfile();
    setState(() {
      // Show message if profile is null or incomplete
      _showProfileMessage = profile == null || !_isProfileComplete(profile);
    });
  }

  bool _isProfileComplete(Map<String, dynamic> profile) {
    final requiredFields = ['semester', 'interest', 'skills'];
    for (var field in requiredFields) {
      if (profile[field] == null || profile[field].toString().trim().isEmpty) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 24, 81, 91),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                if (currentUser != null)
                  StreamBuilder<QuerySnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('notifications')
                            .doc(currentUser.uid)
                            .collection('notifications')
                            .where('isSeen', isEqualTo: false)
                            .snapshots(),
                    builder: (context, snapshot) {
                      int unreadCount =
                          snapshot.hasData ? snapshot.data!.docs.length : 0;
                      return badges.Badge(
                        label:
                            unreadCount > 0
                                ? Text(
                                  unreadCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                )
                                : null,
                        isLabelVisible: unreadCount > 0,
                        backgroundColor: Colors.redAccent,
                        alignment: Alignment.topRight,
                        offset: const Offset(-5, 5),
                        child: IconButton(
                          icon: const Icon(
                            Icons.notifications,
                            color: Colors.white,
                          ),
                          onPressed:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => NotificationScreen(),
                                ),
                              ),
                        ),
                      );
                    },
                  ),
                GestureDetector(
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StudentProfilePage(),
                        ),
                      ),
                  child: const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      color: Color.fromARGB(255, 6, 75, 88),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child:
            currentUser == null
                ? const Center(child: Text("User not logged in"))
                : FutureBuilder<Map<String, dynamic>?>(
                  future: _getStudentData(),
                  builder: (context, snapshot) {
                    final studentData = snapshot.data;

                    final features = [
                      {
                        'title': 'Search Supervisor',
                        'icon': Icons.search,
                        'page': const SearchSupervisorPage(),
                      },
                      {
                        'title': 'AI Recommendations',
                        'icon': Icons.lightbulb,
                        'page': const AIRecommendationPage(),
                      },
                      {
                        'title': 'Supervisors List',
                        'icon': Icons.school,
                        'page': SupervisorListPage(),
                      },
                      {
                        'title': 'Chat with Supervisor',
                        'icon': Icons.chat,
                        'page': const HomeScreen(),
                      },
                      {
                        'title': 'Send Proposal',
                        'icon': Icons.upload_file,
                        'onTap': () async {
                          if (studentData == null) return;
                          final supervisorInfo = {
                            'id': studentData['supervisorId'] ?? '',
                            'name': studentData['supervisorName'] ?? '',
                          };
                          if (supervisorInfo['id']!.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => SendProposalPage(
                                      supervisorId: supervisorInfo['id']!,
                                      supervisorName: supervisorInfo['name']!,
                                    ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Supervisor not assigned yet!"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      },
                      {
                        'title': 'Schedule Meeting',
                        'icon': Icons.schedule,
                        'onTap': () async {
                          final supervisorId =
                              studentData?['supervisorId'] ?? '';
                          if (supervisorId.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => ScheduleMeetingPage(
                                      supervisorId: supervisorId,
                                    ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Supervisor not assigned yet"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      },
                      {
                        'title': 'Track Project',
                        'icon': Icons.track_changes,
                        'page': StudentTrackPage(
                          projectId: studentData?['projectId'] ?? '',
                        ),
                      },
                      {
                        'title': 'Log Out',
                        'icon': Icons.logout,
                        'page': const SignInPage(),
                      },
                    ];

                    return ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        const DrawerHeader(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color.fromARGB(255, 24, 81, 91),
                                Color.fromARGB(255, 133, 213, 231),
                              ],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.white,
                                child: Icon(
                                  Icons.person,
                                  size: 35,
                                  color: Color.fromARGB(255, 24, 81, 91),
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Welcome, Student!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'FYP Connect',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...features.map((feature) {
                          final isLogout = feature['title'] == 'Log Out';
                          final featurePage = feature['page'] as Widget?;
                          return ListTile(
                            leading: Icon(
                              feature['icon'] as IconData,
                              color: const Color.fromARGB(255, 24, 81, 91),
                            ),
                            title: Text(feature['title'] as String),
                            onTap: () async {
                              Navigator.pop(context);

                              if (feature['title'] == 'Log Out') {
                                authService.signOutUser();
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => feature['page'] as Widget,
                                  ),
                                );
                              } else if (feature['onTap'] != null) {
                                await (feature['onTap']
                                    as Future<void> Function())();
                              } else if (featurePage != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => featurePage,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Project not assigned yet!"),
                                  ),
                                );
                              }
                            },
                          );
                        }),
                      ],
                    );
                  },
                ),
      ),
      body:
          currentUser == null
              ? const Center(child: Text("User not logged in"))
              : FutureBuilder<String?>(
                future: _getProjectIdForStudent(currentUser.uid),
                builder: (context, projectSnapshot) {
                  if (projectSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final projectId = projectSnapshot.data ?? "";

                  return FutureBuilder<double>(
                    future: _fetchOverallProgress(projectId),
                    builder: (context, progressSnapshot) {
                      final projectProgress =
                          progressSnapshot.data != null
                              ? progressSnapshot.data!
                              : 0.0;

                      return StreamBuilder<DocumentSnapshot>(
                        stream:
                            FirebaseFirestore.instance
                                .collection('students')
                                .doc(currentUser.uid)
                                .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final studentData =
                              snapshot.data!.data() as Map<String, dynamic>?;
                          final supervisorName =
                              studentData?['supervisorName'] ?? 'Not Assigned';
                          final projectStatus =
                              studentData?['projectStatus'] ?? 'Pending';

                          return RefreshIndicator(
                            onRefresh: () async {
                              await _loadMilestones(); // 🔹 reload milestones from Firestore
                              setState(() {}); // rebuild UI
                            },
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color.fromARGB(255, 24, 81, 91),
                                    Colors.white,
                                  ],
                                  stops: [0.0, 0.3],
                                ),
                              ),
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 🔹 Welcome Section
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          const CircleAvatar(
                                            radius: 30,
                                            backgroundColor: Color.fromARGB(
                                              255,
                                              24,
                                              81,
                                              91,
                                            ),
                                            child: Icon(
                                              Icons.person,
                                              color: Colors.white,
                                              size: 30,
                                            ),
                                          ),
                                          const SizedBox(width: 15),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Welcome Back!',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color.fromARGB(
                                                      255,
                                                      24,
                                                      81,
                                                      91,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  'Supervisor: $supervisorName',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                const SizedBox(height: 5),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green
                                                        .withOpacity(0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    projectStatus,
                                                    style: const TextStyle(
                                                      color: Colors.green,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    FutureBuilder<Map<String, dynamic>?>(
                                      future: AuthService().getStudentProfile(),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const SizedBox(); // or CircularProgressIndicator
                                        }

                                        final profile = snapshot.data;

                                        // Show message if profile is null OR incomplete
                                        if (profile == null ||
                                            !_isProfileComplete(profile)) {
                                          return Container(
                                            padding: const EdgeInsets.all(16),
                                            margin: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.orange[100],
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              children: const [
                                                Icon(
                                                  Icons.info_outline,
                                                  color: Colors.orange,
                                                ),
                                                SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    "Complete your profile to get better supervisor recommendations and project matches.",
                                                    style: TextStyle(
                                                      color: Colors.orange,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }

                                        return const SizedBox(); // profile exists and complete → hide message
                                      },
                                    ),
                                    // 🔹 Progress Pie Chart
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 0,
                                      ),
                                      child: Card(
                                        elevation: 4,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color.fromARGB(
                                                  255,
                                                  81,
                                                  163,
                                                  173,
                                                ),
                                                Color.fromARGB(
                                                  255,
                                                  147,
                                                  185,
                                                  195,
                                                ),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: const [
                                                  Icon(
                                                    Icons.track_changes,
                                                    color: Color.fromARGB(
                                                      255,
                                                      24,
                                                      81,
                                                      91,
                                                    ),
                                                    size: 24,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    "Overall Progress",
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Color.fromARGB(
                                                        255,
                                                        24,
                                                        81,
                                                        91,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 16),
                                              Center(
                                                child: SizedBox(
                                                  height: 150,
                                                  width: 150,
                                                  child: PieChart(
                                                    PieChartData(
                                                      sections: [
                                                        PieChartSectionData(
                                                          value:
                                                              projectProgress *
                                                              100,
                                                          color:
                                                              const Color.fromARGB(
                                                                255,
                                                                50,
                                                                185,
                                                                106,
                                                              ),
                                                          radius: 50,
                                                          title:
                                                              '${(projectProgress * 100).toInt()}%',
                                                          titleStyle:
                                                              const TextStyle(
                                                                fontSize: 18,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color:
                                                                    Color.fromARGB(
                                                                      255,
                                                                      20,
                                                                      48,
                                                                      53,
                                                                    ),
                                                              ),
                                                        ),
                                                        PieChartSectionData(
                                                          value:
                                                              (1 -
                                                                  projectProgress) *
                                                              100,
                                                          color:
                                                              Colors
                                                                  .grey
                                                                  .shade200, // <-- updated
                                                          radius: 50,
                                                          title: '',
                                                        ),
                                                      ],
                                                      sectionsSpace: 0,
                                                      centerSpaceRadius: 40,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 20),

                                    // Calendar Section
                                    const Text(
                                      'Milestone Calendar',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Color.fromARGB(255, 24, 81, 91),
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                    Card(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      elevation: 5,
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          children: [
                                            TableCalendar<String>(
                                              firstDay: DateTime.utc(
                                                2020,
                                                1,
                                                1,
                                              ),
                                              lastDay: DateTime.utc(
                                                2030,
                                                12,
                                                31,
                                              ),
                                              focusedDay: _focusedDay,
                                              eventLoader: _getEventsForDay,
                                              startingDayOfWeek:
                                                  StartingDayOfWeek.monday,
                                              selectedDayPredicate:
                                                  (day) => isSameDay(
                                                    _selectedDay,
                                                    day,
                                                  ),
                                              onDaySelected: (
                                                selectedDay,
                                                focusedDay,
                                              ) {
                                                setState(() {
                                                  _selectedDay = selectedDay;
                                                  _focusedDay = focusedDay;
                                                });
                                              },
                                              onPageChanged: (focusedDay) {
                                                _focusedDay = focusedDay;
                                              },
                                              headerStyle: const HeaderStyle(
                                                formatButtonVisible: false,
                                                titleCentered: true,
                                                titleTextStyle: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),

                                              // 🔹 Customize milestone appearance
                                              calendarBuilders: CalendarBuilders(
                                                // ✅ Dot under milestone day
                                                markerBuilder: (
                                                  context,
                                                  day,
                                                  events,
                                                ) {
                                                  if (events.isNotEmpty) {
                                                    return Positioned(
                                                      bottom: 4,
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children:
                                                            events.map((e) {
                                                              return Container(
                                                                margin:
                                                                    const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          1.5,
                                                                    ),
                                                                width: 6,
                                                                height: 6,
                                                                decoration: const BoxDecoration(
                                                                  shape:
                                                                      BoxShape
                                                                          .circle,
                                                                  color:
                                                                      Colors
                                                                          .teal,
                                                                ),
                                                              );
                                                            }).toList(),
                                                      ),
                                                    );
                                                  }
                                                  return null;
                                                },

                                                // ✅ Highlight milestone day with circle
                                                defaultBuilder: (
                                                  context,
                                                  day,
                                                  focusedDay,
                                                ) {
                                                  final events =
                                                      _getEventsForDay(day);
                                                  if (events.isNotEmpty) {
                                                    return Container(
                                                      margin:
                                                          const EdgeInsets.all(
                                                            6,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.teal
                                                            .withOpacity(0.15),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      alignment:
                                                          Alignment.center,
                                                      child: Text(
                                                        '${day.day}',
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.teal,
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                  return null; // use default style otherwise
                                                },
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            if (_selectedDay != null &&
                                                _getEventsForDay(
                                                  _selectedDay!,
                                                ).isNotEmpty)
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color.fromARGB(
                                                    255,
                                                    24,
                                                    81,
                                                    91,
                                                  ).withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Events on ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}:',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Color.fromARGB(
                                                          255,
                                                          24,
                                                          81,
                                                          91,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 5),
                                                    ..._getEventsForDay(
                                                      _selectedDay!,
                                                    ).map(
                                                      (event) => Padding(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              vertical: 2,
                                                            ),
                                                        child: Row(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            const Icon(
                                                              Icons.circle,
                                                              size: 8,
                                                              color:
                                                                  Color.fromARGB(
                                                                    255,
                                                                    24,
                                                                    81,
                                                                    91,
                                                                  ),
                                                            ),
                                                            const SizedBox(
                                                              width: 8,
                                                            ),
                                                            Expanded(
                                                              // 🔹 prevents RenderFlex overflow
                                                              child: Text(
                                                                event,
                                                                softWrap: true,
                                                                overflow:
                                                                    TextOverflow
                                                                        .visible,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
    );
  }
}
