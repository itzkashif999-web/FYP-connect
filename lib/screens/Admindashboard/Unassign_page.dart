import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UnassignPage extends StatefulWidget {
  const UnassignPage({super.key});

  @override
  State<UnassignPage> createState() => _UnassignPageState();
}

class _UnassignPageState extends State<UnassignPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';

  static const Color primaryDark = Color.fromARGB(255, 24, 81, 91);
  static const Color primaryLight = Color.fromARGB(255, 133, 213, 231);

  Future<void> _unassign(
    String studentId,
    String supervisorId,
    String proposalDocId,
  ) async {
    try {
      // 1. Delete the proposal
      await _firestore.collection('proposals').doc(proposalDocId).delete();

      // 2. Delete matching projects by proposalId
      final projectsSnapshot =
          await _firestore
              .collection('projects')
              .where('proposalId', isEqualTo: proposalDocId)
              .get();

      for (var doc in projectsSnapshot.docs) {
        await _firestore.collection('projects').doc(doc.id).delete();
      }

      // 3. Delete from supervisor_groups by proposalId
      final groupsSnapshot =
          await _firestore
              .collection('supervisor_groups')
              .where('proposalId', isEqualTo: proposalDocId)
              .get();

      for (var doc in groupsSnapshot.docs) {
        await _firestore.collection('supervisor_groups').doc(doc.id).delete();
      }

      // 4. Delete the student document entirely
      await _firestore.collection('students').doc(studentId).delete();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Unassigned successfully!")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error while unassigning: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Unassign Student & Supervisor",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
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
        elevation: 0,
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
        child: Column(
          children: [
            // Search Box
            Container(
              margin: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryDark.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: TextField(
                  decoration: InputDecoration(
                    labelText: "Search here",
                    hintText: "Search by project, student, or supervisor...",
                    prefixIcon: Icon(
                      Icons.search,
                      color: primaryDark.withOpacity(0.7),
                    ),
                    labelStyle: TextStyle(color: primaryDark.withOpacity(0.7)),
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: primaryLight.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: primaryDark,
                        width: 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: primaryLight.withOpacity(0.3),
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
            ),

            // DataTable Section
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: primaryDark.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: StreamBuilder<QuerySnapshot>(
                    stream:
                        _firestore
                            .collection('proposals')
                            .where('status', isEqualTo: 'accepted')
                            .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              primaryDark,
                            ),
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.assignment_outlined,
                                size: 64,
                                color: primaryLight.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "No active projects found.",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: primaryDark.withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final projects = snapshot.data!.docs;

                      List<Map<String, String>> tableData = [];
                      for (var project in projects) {
                        String projectTitle = project['projectTitle'];
                        String studentId = project['studentId'];
                        String supervisorId = project['supervisorId'];

                        tableData.add({
                          'projectTitle': projectTitle,
                          'studentName': '',
                          'regNo': '',
                          'supervisorName': '',
                          'supervisorId': supervisorId,
                          'projectDocId': project.id,
                          'studentId': studentId,
                        });
                      }

                      return FutureBuilder<List<Map<String, String>>>(
                        future: _fillNames(tableData),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  primaryDark,
                                ),
                              ),
                            );
                          }

                          List<Map<String, String>> filteredData =
                              snapshot.data!.where((row) {
                                return row.values.any(
                                  (value) => value.toLowerCase().contains(
                                    _searchQuery,
                                  ),
                                );
                              }).toList();

                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  dataTableTheme: DataTableThemeData(
                                    headingRowColor: WidgetStateProperty.all(
                                      primaryLight.withOpacity(0.2),
                                    ),
                                    headingTextStyle: TextStyle(
                                      color: primaryDark,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                    dataTextStyle: TextStyle(
                                      color: Colors.grey.shade800,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                child: DataTable(
                                  border: TableBorder.all(
                                    color: primaryLight.withOpacity(0.3),
                                    width: 1,
                                  ),
                                  columns: const [
                                    DataColumn(label: Text("Project Name")),
                                    DataColumn(label: Text("Student Name")),
                                    DataColumn(label: Text("Student ID")),
                                    DataColumn(label: Text("Supervisor Name")),
                                    DataColumn(label: Text("Supervisor ID")),
                                    DataColumn(label: Text("Actions")),
                                  ],
                                  rows:
                                      filteredData.map((row) {
                                        return DataRow(
                                          cells: [
                                            DataCell(
                                              Text(row['projectTitle']!),
                                            ),
                                            DataCell(Text(row['studentName']!)),
                                            DataCell(Text(row['regNo']!)),
                                            DataCell(
                                              Text(row['supervisorName']!),
                                            ),
                                            DataCell(
                                              Text(row['supervisorId']!),
                                            ),
                                            DataCell(
                                              Wrap(
                                                children: [
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons.delete_outline,
                                                      color:
                                                          Colors.red.shade600,
                                                      size: 20,
                                                    ),
                                                    onPressed: () {
                                                      showDialog(
                                                        context: context,
                                                        builder:
                                                            (
                                                              context,
                                                            ) => AlertDialog(
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      16,
                                                                    ),
                                                              ),
                                                              title: Row(
                                                                children: [
                                                                  Icon(
                                                                    Icons
                                                                        .warning_amber_rounded,
                                                                    color:
                                                                        Colors
                                                                            .orange
                                                                            .shade600,
                                                                    size: 28,
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 12,
                                                                  ),
                                                                  const Expanded(
                                                                    child: Text(
                                                                      "Confirm Unassign",
                                                                      style: TextStyle(
                                                                        fontWeight:
                                                                            FontWeight.w600,
                                                                      ),
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              content: const Text(
                                                                "Are you sure you want to unassign this student from this supervisor? All related projects, groups, and proposals will also be deleted.",
                                                                style:
                                                                    TextStyle(
                                                                      fontSize:
                                                                          16,
                                                                    ),
                                                              ),
                                                              actions: [
                                                                TextButton(
                                                                  onPressed:
                                                                      () => Navigator.pop(
                                                                        context,
                                                                      ),
                                                                  child:
                                                                      const Text(
                                                                        "Cancel",
                                                                      ),
                                                                ),
                                                                ElevatedButton(
                                                                  onPressed: () {
                                                                    Navigator.pop(
                                                                      context,
                                                                    );
                                                                    _unassign(
                                                                      row['studentId']!,
                                                                      row['supervisorId']!,
                                                                      row['projectDocId']!,
                                                                    );
                                                                  },
                                                                  style: ElevatedButton.styleFrom(
                                                                    backgroundColor:
                                                                        Colors
                                                                            .red
                                                                            .shade600,
                                                                    foregroundColor:
                                                                        Colors
                                                                            .white,
                                                                    shape: RoundedRectangleBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            8,
                                                                          ),
                                                                    ),
                                                                  ),
                                                                  child: const Text(
                                                                    "Unassign",
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Fetch student and supervisor names asynchronously
  Future<List<Map<String, String>>> _fillNames(
    List<Map<String, String>> data,
  ) async {
    for (var row in data) {
      var studentSnapshot =
          await _firestore
              .collection('student_profiles')
              .doc(row['studentId'])
              .get();
      if (studentSnapshot.exists) {
        row['studentName'] = studentSnapshot['name'] ?? 'No Name';
        row['regNo'] = studentSnapshot['regNo'] ?? 'N/A';
      } else {
        row['studentName'] = 'N/A';
        row['regNo'] = 'N/A';
      }

      var supervisorSnapshot =
          await _firestore
              .collection('supervisor_profiles')
              .where('userId', isEqualTo: row['supervisorId'])
              .get();
      if (supervisorSnapshot.docs.isNotEmpty) {
        row['supervisorName'] =
            supervisorSnapshot.docs.first['name'] ?? 'No Name';
        row['supervisorId'] =
            supervisorSnapshot.docs.first['id'] ?? row['supervisorId']!;
      } else {
        row['supervisorName'] = 'N/A';
      }
    }
    return data;
  }
}
