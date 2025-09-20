import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_student_profile_page.dart';
import 'edit_supervisor_profile_page.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  String studentSearch = "";
  String supervisorSearch = "";

  final TextEditingController _studentSearchController =
      TextEditingController();
  final TextEditingController _supervisorSearchController =
      TextEditingController();

  static const Color primaryDark = Color.fromARGB(255, 24, 81, 91);
  static const Color primaryLight = Color.fromARGB(255, 133, 213, 231);

  Future<void> _deleteUser(
    BuildContext context,
    String userId,
    String role,
  ) async {
    final firestore = FirebaseFirestore.instance;
    try {
      if (role.toLowerCase() == 'student') {
        await firestore.collection('student_profiles').doc(userId).delete();
        await firestore.collection('students').doc(userId).delete();

        final groupDocs =
            await firestore
                .collection('supervisor_groups')
                .where('studentId', isEqualTo: userId)
                .get();
        for (var group in groupDocs.docs) {
          await group.reference.delete();
        }

        final proposalDocs =
            await firestore
                .collection('proposals')
                .where('studentId', isEqualTo: userId)
                .get();
        for (var doc in proposalDocs.docs) {
          await doc.reference.delete();
        }

        final projectDocs =
            await firestore
                .collection('projects')
                .where('studentId', isEqualTo: userId)
                .get();
        for (var doc in projectDocs.docs) {
          await doc.reference.delete();
        }

        final meetingsDocs =
            await firestore
                .collection('meetings')
                .where('studentId', isEqualTo: userId)
                .get();
        for (var doc in meetingsDocs.docs) {
          await doc.reference.delete();
        }
      }
      if (role.toLowerCase() == 'supervisor') {
        final supervisorDocs =
            await firestore
                .collection('supervisor_profiles')
                .where('userId', isEqualTo: userId)
                .get();
        for (var doc in supervisorDocs.docs) {
          await doc.reference.delete();
        }

        final groupDocs =
            await firestore
                .collection('supervisor_groups')
                .where('supervisorId', isEqualTo: userId)
                .get();
        for (var group in groupDocs.docs) {
          await group.reference.delete();
        }

        final studentDocs =
            await firestore
                .collection('students')
                .where('supervisorId', isEqualTo: userId)
                .get();
        for (var student in studentDocs.docs) {
          await student.reference.delete();
        }

        final proposalDocs =
            await firestore
                .collection('proposals')
                .where('supervisorId', isEqualTo: userId)
                .get();
        for (var doc in proposalDocs.docs) {
          await doc.reference.delete();
        }

        final projectDocs =
            await firestore
                .collection('projects')
                .where('supervisorId', isEqualTo: userId)
                .get();
        for (var doc in projectDocs.docs) {
          await doc.reference.delete();
        }

        final meetingsDocs =
            await firestore
                .collection('meetings')
                .where('supervisorId', isEqualTo: userId)
                .get();
        for (var doc in meetingsDocs.docs) {
          await doc.reference.delete();
        }
      }
      await firestore.collection('users').doc(userId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User deleted successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error deleting user: $e")));
    }
  }

  void _editUser(BuildContext context, String userId, String role) {
    if (role == "student") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EditStudentProfilePage(userId: userId),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EditSupervisorProfilePage(supervisorUserId: userId),
        ),
      );
    }
  }

  Future<String> _getRegNo(String studentId) async {
    final doc =
        await FirebaseFirestore.instance
            .collection('student_profiles')
            .doc(studentId)
            .get();
    return doc.exists ? doc['regNo'] ?? "N/A" : "N/A";
  }

  Future<String> _getSupervisorId(String supervisorUserId) async {
    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('supervisor_profiles')
            .where("userId", isEqualTo: supervisorUserId)
            .limit(1)
            .get();

    if (querySnapshot.docs.isNotEmpty) {
      final doc = querySnapshot.docs.first;
      return doc.data()['id'] ?? "N/A";
    } else {
      return "N/A";
    }
  }

  Future<int> _getActiveProjectsCount(String supervisorId) async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('projects')
            .where('supervisorId', isEqualTo: supervisorId)
            .where('status', isEqualTo: 'active')
            .get();
    return snapshot.docs.length;
  }

  Future<String> _getProposalStatus(String studentId) async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('proposals')
            .where('studentId', isEqualTo: studentId)
            .limit(1)
            .get();
    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.data()['status'] ?? "N/A";
    }
    return "N/A";
  }

  Widget _buildSearchBar({
    required TextEditingController controller,
    required String hintText,
    required String searchValue,
    required Function(String) onChanged,
    required VoidCallback onClear,
  }) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, primaryLight.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: primaryDark.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: primaryDark.withOpacity(0.6)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          prefixIcon: Icon(Icons.search, color: primaryDark),
          suffixIcon:
              searchValue.isNotEmpty
                  ? IconButton(
                    icon: Icon(Icons.clear, color: primaryDark),
                    onPressed: onClear,
                  )
                  : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDataTable({
    required List<Map<String, dynamic>> data,
    required String role,
  }) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          'No ${role.toLowerCase()}s found',
          style: const TextStyle(fontSize: 16),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        border: TableBorder.all(color: Colors.grey, width: 1),
        headingRowColor: WidgetStateProperty.all(
          Color.fromARGB(255, 91, 165, 182),
        ),
        columns: [
          const DataColumn(label: Text('Name')),
          DataColumn(label: Text(role == 'student' ? 'Reg No' : 'Faculty ID')),
          if (role == 'supervisor')
            const DataColumn(label: Text('Active Projects')),
          if (role == 'student')
            const DataColumn(label: Text('Proposal Status')),
          const DataColumn(label: Text('Actions')),
        ],
        rows:
            data.map((user) {
              return DataRow(
                cells: [
                  DataCell(Text(user['name'])),
                  DataCell(
                    Text(
                      role == 'student' ? user['regNo'] : user['supervisorId'],
                    ),
                  ),
                  if (role == 'supervisor')
                    DataCell(Text(user['activeProjects'].toString())),
                  if (role == 'student') DataCell(Text(user['proposalStatus'])),
                  DataCell(
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editUser(context, user['id'], role),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed:
                              () => _deleteUser(context, user['id'], role),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryDark),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading users...',
            style: TextStyle(color: primaryDark.withOpacity(0.7), fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: primaryDark.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: primaryDark.withOpacity(0.7), fontSize: 16),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Manage Users",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryDark, primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Color.fromARGB(179, 255, 255, 255),
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(icon: Icon(Icons.person), text: "Supervisors"),
              Tab(icon: Icon(Icons.school), text: "Students"),
            ],
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryLight.withOpacity(0.05), Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: TabBarView(
            children: [
              RefreshIndicator(
                onRefresh: () async {
                  setState(() {}); // rebuild to refresh FutureBuilders
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: Column(
                  children: [
                    _buildSearchBar(
                      controller: _supervisorSearchController,
                      hintText: "Search by Name or Faculty ID",
                      searchValue: supervisorSearch,
                      onChanged: (val) {
                        setState(() {
                          supervisorSearch = val.toLowerCase();
                        });
                      },
                      onClear: () {
                        _supervisorSearchController.clear();
                        setState(() {
                          supervisorSearch = "";
                        });
                      },
                    ),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream:
                            FirebaseFirestore.instance
                                .collection('users')
                                .where('role', isEqualTo: 'supervisor')
                                .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return _buildLoadingWidget();
                          }
                          var supervisors = snapshot.data!.docs;

                          if (supervisors.isEmpty) {
                            return _buildEmptyState('No supervisors found');
                          }

                          return FutureBuilder<List<Map<String, dynamic>>>(
                            future: Future.wait(
                              supervisors.map((user) async {
                                String supervisorId = await _getSupervisorId(
                                  user.id,
                                );
                                int activeProjects =
                                    await _getActiveProjectsCount(user.id);
                                return {
                                  "id": user.id,
                                  "name": user['name'] ?? 'No Name',
                                  "supervisorId": supervisorId,
                                  "activeProjects": activeProjects,
                                };
                              }),
                            ),
                            builder: (context, futureSnap) {
                              if (!futureSnap.hasData) {
                                return _buildLoadingWidget();
                              }
                              var data = futureSnap.data!;

                              var filtered =
                                  data.where((item) {
                                    return supervisorSearch.isEmpty ||
                                        item["name"].toLowerCase().contains(
                                          supervisorSearch,
                                        ) ||
                                        item["supervisorId"]
                                            .toLowerCase()
                                            .contains(supervisorSearch);
                                  }).toList();

                              return SingleChildScrollView(
                                child: _buildDataTable(
                                  data: filtered,
                                  role: 'supervisor',
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // Students tab
              Column(
                children: [
                  _buildSearchBar(
                    controller: _studentSearchController,
                    hintText: "Search by Name or Registration No",
                    searchValue: studentSearch,
                    onChanged: (val) {
                      setState(() {
                        studentSearch = val.toLowerCase();
                      });
                    },
                    onClear: () {
                      _studentSearchController.clear();
                      setState(() {
                        studentSearch = "";
                      });
                    },
                  ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('users')
                              .where('role', isEqualTo: 'student')
                              .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return _buildLoadingWidget();
                        }
                        var students = snapshot.data!.docs;

                        if (students.isEmpty) {
                          return _buildEmptyState('No students found');
                        }

                        return FutureBuilder<List<Map<String, dynamic>>>(
                          future: Future.wait(
                            students.map((student) async {
                              String regNo = await _getRegNo(student.id);
                              String proposalStatus = await _getProposalStatus(
                                student.id,
                              );
                              return {
                                'id': student.id,
                                'name': student['name'] ?? 'No Name',
                                'regNo': regNo,
                                'proposalStatus': proposalStatus,
                              };
                            }),
                          ),
                          builder: (context, regDataSnapshot) {
                            if (!regDataSnapshot.hasData) {
                              return _buildLoadingWidget();
                            }
                            var studentData = regDataSnapshot.data!;

                            var filteredStudents =
                                studentData.where((s) {
                                  return studentSearch.isEmpty ||
                                      s['name'].toLowerCase().contains(
                                        studentSearch,
                                      ) ||
                                      s['regNo'].toLowerCase().contains(
                                        studentSearch,
                                      );
                                }).toList();

                            return SingleChildScrollView(
                              child: _buildDataTable(
                                data: filteredStudents,
                                role: 'student',
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
