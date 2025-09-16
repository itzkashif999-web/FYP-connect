import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ProposalListPage extends StatefulWidget {
  const ProposalListPage({super.key});

  @override
  State<ProposalListPage> createState() => _ProposalListPageState();
}

class _ProposalListPageState extends State<ProposalListPage> {
  String _searchQuery = "";

  // 🔹 Get student RegNo from student_profiles
  Future<String> _getRegNo(String studentId) async {
    final doc =
        await FirebaseFirestore.instance
            .collection('student_profiles')
            .doc(studentId)
            .get();
    return doc.exists ? (doc['regNo'] ?? "N/A") : "N/A";
  }

  // 🔹 Get supervisorId from supervisor_profiles
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

  // 🔹 Format Firestore Timestamp → Date String
  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return "N/A";
    try {
      DateTime dateTime;
      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else if (timestamp is DateTime) {
        dateTime = timestamp;
      } else {
        return timestamp.toString(); // fallback
      }
      return DateFormat("dd MMM yyyy, hh:mm a").format(dateTime);
    } catch (e) {
      return "Invalid Date";
    }
  }

  // 🔹 Fetch RegNo + SupervisorId for each row
  Future<Map<String, String>> _fetchIds(
    String studentId,
    String supervisorUserId,
  ) async {
    String regNo = await _getRegNo(studentId);
    String supId = await _getSupervisorId(supervisorUserId);
    return {"regNo": regNo, "supervisorId": supId};
  }

  // 🔹 Delete proposal by documentId
  Future<void> _deleteProposal(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('proposals')
          .doc(docId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Proposal deleted successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to delete proposal: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Proposals"),
        backgroundColor: Color.fromARGB(255, 24, 81, 91),

        foregroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // 🔹 Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: "Search proposals...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('proposals')
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var proposals = snapshot.data!.docs;
                if (proposals.isEmpty) {
                  return const Center(child: Text("No Proposals Found"));
                }

                return FutureBuilder<List<Map<String, dynamic>>>(
                  future: _prepareProposalData(proposals),
                  builder: (context, asyncSnapshot) {
                    if (!asyncSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    var data = asyncSnapshot.data!;

                    // 🔹 Apply search filter
                    var filteredData =
                        data.where((proposal) {
                          return proposal.values.any(
                            (value) => value.toString().toLowerCase().contains(
                              _searchQuery,
                            ),
                          );
                        }).toList();

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        border: TableBorder.all(color: Colors.grey, width: 1),
                        headingRowColor: WidgetStateProperty.all(
                          Color.fromARGB(255, 91, 165, 182),
                        ),
                        headingTextStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        columns: const [
                          DataColumn(label: Text("Student Name")),
                          DataColumn(label: Text("Reg No")),
                          DataColumn(label: Text("Supervisor Name")),
                          DataColumn(label: Text("Supervisor ID")),
                          DataColumn(label: Text("Proposal Title")),
                          DataColumn(label: Text("Status")),
                          DataColumn(label: Text("Submitted At")),
                          DataColumn(label: Text("Actions")),
                        ],
                        rows:
                            filteredData.map((proposal) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(proposal['studentName'] ?? "N/A"),
                                  ),
                                  DataCell(Text(proposal['regNo'] ?? "N/A")),
                                  DataCell(
                                    Text(proposal['supervisorName'] ?? "N/A"),
                                  ),
                                  DataCell(
                                    Text(proposal['supervisorId'] ?? "N/A"),
                                  ),
                                  DataCell(
                                    Text(proposal['projectTitle'] ?? "N/A"),
                                  ),
                                  DataCell(Text(proposal['status'] ?? "N/A")),
                                  DataCell(
                                    Text(proposal['submittedAt'] ?? "N/A"),
                                  ),
                                  DataCell(
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () {
                                        _deleteProposal(proposal['docId']);
                                      },
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Prepare proposals with async RegNo & SupervisorId
  Future<List<Map<String, dynamic>>> _prepareProposalData(
    List<QueryDocumentSnapshot> proposals,
  ) async {
    List<Map<String, dynamic>> dataList = [];

    for (var proposal in proposals) {
      String studentId = proposal['studentId'];
      String supervisorUserId = proposal['supervisorId'];

      var ids = await _fetchIds(studentId, supervisorUserId);

      dataList.add({
        "docId": proposal.id, // store docId for delete
        "studentName": proposal['studentName'],
        "regNo": ids['regNo'],
        "supervisorName": proposal['supervisorName'],
        "supervisorId": ids['supervisorId'],
        "projectTitle": proposal['projectTitle'],
        "status": proposal['status'],
        "submittedAt": _formatDate(proposal['submittedAt']),
      });
    }

    return dataList;
  }
}
