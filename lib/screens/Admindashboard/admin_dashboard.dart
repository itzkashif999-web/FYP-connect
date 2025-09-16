import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp_connect/screens/Admindashboard/Unassign_page.dart';
import 'package:fyp_connect/screens/Admindashboard/milestone_calendar_page.dart';
import 'package:fyp_connect/screens/Admindashboard/proposal_list_page.dart';
import 'package:fyp_connect/screens/Admindashboard/send_notification_page.dart';
import 'package:fyp_connect/screens/sign_in_page.dart';
import 'user_list_page.dart';

class AdminDashboard extends StatelessWidget {
  final String currentUserId;

  const AdminDashboard({super.key, required this.currentUserId});

  static const Color primaryDark = Color.fromARGB(255, 24, 81, 91);
  static const Color primaryLight = Color.fromARGB(255, 133, 213, 231);

  // Check if current user is admin
  Future<bool> _isAdmin() async {
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .get();
    return userDoc['role'] == 'Admin';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isAdmin(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    primaryLight.withOpacity(0.3),
                    primaryDark.withOpacity(0.1),
                  ],
                ),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryDark),
                ),
              ),
            ),
          );
        }
        if (!snapshot.data!) {
          return Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    primaryLight.withOpacity(0.3),
                    primaryDark.withOpacity(0.1),
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, size: 80, color: primaryDark),
                    SizedBox(height: 20),
                    Text(
                      "Access Denied",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: primaryDark,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Admins Only",
                      style: TextStyle(
                        fontSize: 16,
                        color: primaryDark.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              "Admin Dashboard",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Logout',
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => SignInPage()),
                  );
                },
              ),
            ],
            backgroundColor: const Color.fromARGB(255, 24, 81, 91),
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [primaryDark, primaryDark.withOpacity(0.8)],
                ),
              ),
            ),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  primaryLight.withOpacity(0.1),
                  Colors.white,
                  primaryDark.withOpacity(0.05),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
                      margin: EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryLight.withOpacity(0.2),
                            primaryDark.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: primaryDark.withOpacity(0.1),
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.dashboard, size: 40, color: primaryDark),
                          SizedBox(height: 10),
                          Text(
                            "Welcome to Admin Panel",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: primaryDark,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "Manage your system efficiently",
                            style: TextStyle(
                              fontSize: 14,
                              color: primaryDark.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Stats Grid
                    SizedBox(
                      height: 400,
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        physics: NeverScrollableScrollPhysics(),
                        children: [
                          _buildStreamStatCard(
                            "Total Students",
                            FirebaseFirestore.instance
                                .collection('users')
                                .where('role', isEqualTo: 'Student')
                                .snapshots(),
                            [
                              Colors.orange.shade400,
                              const Color.fromARGB(255, 234, 177, 107),
                            ],
                            Icons.school,
                          ),
                          _buildStreamStatCard(
                            "Total Supervisors",
                            FirebaseFirestore.instance
                                .collection('users')
                                .where('role', isEqualTo: 'Supervisor')
                                .snapshots(),
                            [primaryLight, primaryDark],
                            Icons.supervisor_account,
                          ),
                          _buildStreamStatCard(
                            "Active Projects",
                            FirebaseFirestore.instance
                                .collection('projects')
                                .where('status', isEqualTo: 'active')
                                .snapshots(),
                            [
                              const Color.fromARGB(255, 89, 169, 93),
                              const Color.fromARGB(255, 149, 206, 152),
                            ],
                            Icons.trending_up,
                          ),
                          _buildStreamStatCard(
                            "Pending Projects",
                            FirebaseFirestore.instance
                                .collection('proposals')
                                .where('status', isEqualTo: 'pending')
                                .snapshots(),
                            [
                              const Color.fromARGB(255, 228, 170, 169),
                              const Color.fromARGB(255, 229, 98, 95),
                            ],
                            Icons.hourglass_empty,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Quick Actions",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryDark,
                        ),
                      ),
                    ),
                    SizedBox(height: 18),

                    // Manage Users Button
                    _buildActionButton(
                      context,
                      title: "Manage Users",
                      icon: Icons.people,
                      gradient: [
                        const Color.fromARGB(255, 28, 118, 134),
                        const Color.fromARGB(
                          255,
                          150,
                          202,
                          211,
                        ).withOpacity(0.8),
                      ],
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => UserListPage()),
                        );
                      },
                    ),

                    SizedBox(height: 12),

                    // Send Notifications Button
                    _buildActionButton(
                      context,
                      title: "Send Notifications",
                      icon: Icons.notifications_active,
                      gradient: [primaryLight, primaryDark],
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SendNotificationPage(),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: 12),

                    // Milestone Calendar Button
                    _buildActionButton(
                      context,
                      title: "Milestone Calendar",
                      icon: Icons.calendar_today,
                      gradient: [
                        const Color.fromARGB(255, 64, 192, 179),
                        Colors.teal.shade600,
                      ],
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MilestoneCalendarPage(),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: 12),

                    // Unassign Supervisor-Student Button
                    _buildActionButton(
                      context,
                      title: "Unassign Student-Supervisor",
                      icon: Icons.link_off,
                      gradient: [
                        const Color.fromARGB(255, 118, 36, 34),
                        const Color.fromARGB(255, 173, 125, 124),
                      ],
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => UnassignPage()),
                        );
                      },
                    ),

                    SizedBox(height: 12),
                    // Proposal Details Button
                    _buildActionButton(
                      context,
                      title: "View Proposals",
                      icon: Icons.description,
                      gradient: [
                        const Color.fromARGB(255, 54, 121, 184),
                        const Color.fromARGB(255, 142, 181, 219),
                      ],
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ProposalListPage()),
                        );
                      },
                    ),
                    SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStreamStatCard(
    String title,
    Stream<QuerySnapshot> stream,
    List<Color> gradientColors,
    IconData icon,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return _buildStatCard(title, count, gradientColors, icon);
      },
    );
  }

  Widget _buildStatCard(
    String title,
    int count,
    List<Color> gradientColors,
    IconData icon,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradientColors[1].withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, size: 16, color: Colors.white),
                ),
                SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  count.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: gradient[1].withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.7),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
