import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as badges;
import 'package:fyp_connect/SupervisorDashboard/supervisor_groups_page.dart';
import 'package:fyp_connect/SupervisorDashboard/supervisor_projects_page.dart';
import 'package:fyp_connect/auth/auth_service.dart';
import 'package:fyp_connect/chats and notifications/home_screen.dart';
import 'package:fyp_connect/chats and notifications/notifications/notification_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:fyp_connect/screens/sign_in_page.dart';
import 'package:fyp_connect/SupervisorDashboard/supervisor_profile_page.dart';
import 'package:fyp_connect/SupervisorDashboard/proposal_requests_page.dart';
import 'package:fyp_connect/SupervisorDashboard/schedule_meeting_page.dart';

class SupervisorDashboard extends StatefulWidget {
  const SupervisorDashboard({super.key});

  @override
  State<SupervisorDashboard> createState() => _SupervisorDashboardState();
}

class _SupervisorDashboardState extends State<SupervisorDashboard> {
  double overallProgress = 0.65; // demo value
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  AuthService authService = AuthService();

  /// 🔹 Milestones map: normalized date → list of titles
  Map<DateTime, List<String>> milestones = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadMilestones();
  }

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

  @override
  Widget build(BuildContext context) {
    final features = [
      {
        'title': 'Proposal Requests',
        'icon': Icons.view_agenda,
        'page': const ProposalRequestsPage(),
      },
      {
        'title': 'My Groups',
        'icon': Icons.school,
        'page': const SupervisorGroupsPage(),
      },
      {
        'title': 'Track Projects',
        'icon': Icons.track_changes,
        'page': const SupervisorProjectsPage(),
      },
      {
        'title': 'Chat with Students',
        'icon': Icons.chat,
        'page': const HomeScreen(),
      },
      {
        'title': 'Schedule Meeting',
        'icon': Icons.schedule,
        'page': null, // handled manually
      },
      {'title': 'Log Out', 'icon': Icons.logout, 'page': const SignInPage()},
    ];

    final supervisorId = FirebaseAuth.instance.currentUser?.uid;

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
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('notifications')
                          .doc(FirebaseAuth.instance.currentUser!.uid)
                          .collection('notifications')
                          .where('isSeen', isEqualTo: false)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError || !snapshot.hasData) {
                      return IconButton(
                        icon: const Icon(
                          Icons.notifications,
                          color: Colors.white,
                        ),
                        onPressed: () {},
                      );
                    }
                    int unreadCount = snapshot.data!.docs.length;

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
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NotificationScreen(),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SupervisorProfilePage(),
                      ),
                    );
                  },
                  child: const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      color: Color.fromARGB(255, 24, 81, 91),
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
        child: ListView(
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
                      Icons.school,
                      size: 35,
                      color: Color.fromARGB(255, 24, 81, 91),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Welcome, Supervisor!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'FYP Connect - Supervisor',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            ...features.map((feature) {
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
                  } else if (feature['title'] == 'Schedule Meeting') {
                    if (supervisorId != null) {
                      final querySnapshot =
                          await FirebaseFirestore.instance
                              .collection("projects")
                              .where("supervisorId", isEqualTo: supervisorId)
                              .get();

                      if (querySnapshot.docs.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("No students found")),
                        );
                      } else {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return Dialog(
                              insetPadding: const EdgeInsets.all(16),
                              child: Container(
                                height:
                                    MediaQuery.of(context).size.height * 0.7,
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Select a Student",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: querySnapshot.docs.length,
                                        itemBuilder: (context, index) {
                                          final project =
                                              querySnapshot.docs[index].data();
                                          final studentId =
                                              project['studentId'] ?? '';
                                          final studentName =
                                              project['studentName'] ??
                                              'Unknown';
                                          final projectTitle =
                                              project['title'] ?? 'No Title';

                                          return Card(
                                            margin: const EdgeInsets.symmetric(
                                              vertical: 6,
                                            ),
                                            child: ListTile(
                                              title: Text(studentName),
                                              subtitle: Text(
                                                'Project: $projectTitle',
                                              ),
                                              trailing: const Icon(
                                                Icons.arrow_forward_ios,
                                              ),
                                              onTap: () {
                                                Navigator.pop(context);
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (_) =>
                                                            SupervisorScheduleMeetingPage(
                                                              studentId:
                                                                  studentId,
                                                            ),
                                                  ),
                                                );
                                              },
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }
                    }
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => feature['page'] as Widget,
                      ),
                    );
                  }
                },
              );
            }),
          ],
        ),
      ),

      body: RefreshIndicator(
        onRefresh: () async {
          await _loadMilestones(); // 🔹 reload milestones from Firestore
          setState(() {}); // rebuild UI
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color.fromARGB(255, 24, 81, 91), Colors.white],
              stops: [0.0, 0.3],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Welcome Section
                StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection("proposals")
                          .where("supervisorId", isEqualTo: supervisorId)
                          .snapshots(),
                  builder: (context, snapshot) {
                    int activeProjects = 0;
                    int pendingProposals = 0;

                    if (snapshot.hasData) {
                      for (var doc in snapshot.data!.docs) {
                        if (doc["status"] == "accepted") activeProjects++;
                        if (doc["status"] == "pending") pendingProposals++;
                      }
                    }

                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 30,
                            backgroundColor: Color.fromARGB(255, 24, 81, 91),
                            child: Icon(
                              Icons.school,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Welcome, Supervisor!',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 24, 81, 91),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Active Projects: $activeProjects',
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Pending: $pendingProposals',
                                        style: const TextStyle(
                                          color: Colors.orange,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                const SizedBox(height: 20),

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
                          firstDay: DateTime.utc(2020, 1, 1),
                          lastDay: DateTime.utc(2030, 12, 31),
                          focusedDay: _focusedDay,
                          eventLoader: _getEventsForDay,
                          startingDayOfWeek: StartingDayOfWeek.monday,
                          selectedDayPredicate:
                              (day) => isSameDay(_selectedDay, day),
                          onDaySelected: (selectedDay, focusedDay) {
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
                            markerBuilder: (context, day, events) {
                              if (events.isNotEmpty) {
                                return Positioned(
                                  bottom: 4,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children:
                                        events.map((e) {
                                          return Container(
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 1.5,
                                            ),
                                            width: 6,
                                            height: 6,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.teal,
                                            ),
                                          );
                                        }).toList(),
                                  ),
                                );
                              }
                              return null;
                            },

                            // ✅ Highlight milestone day with circle
                            defaultBuilder: (context, day, focusedDay) {
                              final events = _getEventsForDay(day);
                              if (events.isNotEmpty) {
                                return Container(
                                  margin: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${day.day}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal,
                                    ),
                                  ),
                                );
                              }
                              return null; // use default style otherwise
                            },
                          ),
                        ),
                        const SizedBox(height: 15),

                        // 🔹 Show milestones of selected day
                        if (_selectedDay != null &&
                            _getEventsForDay(_selectedDay!).isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Events on ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}:",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color.fromARGB(255, 24, 81, 91),
                                ),
                              ),
                              const SizedBox(height: 8),
                              ..._getEventsForDay(_selectedDay!).map(
                                (event) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.circle,
                                        size: 8,
                                        color: Color.fromARGB(255, 24, 81, 91),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        // 🔹 prevents RenderFlex overflow
                                        child: Text(
                                          event,
                                          softWrap: true,
                                          overflow: TextOverflow.visible,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          const Padding(
                            padding: EdgeInsets.all(8),
                            child: Text(
                              "No milestones for this day.",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
