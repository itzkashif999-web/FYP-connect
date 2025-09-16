import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SupervisorMeetingPage extends StatelessWidget {
  final String studentId;

  const SupervisorMeetingPage({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    final supervisorId = FirebaseAuth.instance.currentUser!.uid;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "All Meetings",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color.fromARGB(255, 24, 81, 91),
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Color.fromARGB(179, 141, 135, 135),
            indicatorColor: Colors.white,
            tabs: [Tab(text: "Outgoing"), Tab(text: "Incoming")],
          ),
        ),
        body: TabBarView(
          children: [
            // Outgoing Requests (sent by supervisor)
            _buildMeetingsList(
              query: FirebaseFirestore.instance
                  .collection("meetings")
                  .where("studentId", isEqualTo: studentId)
                  .where("supervisorId", isEqualTo: supervisorId)
                  .where("requestedBy", isEqualTo: "supervisor"),
              isIncoming: false,
            ),

            // Incoming Requests (sent by student)
            _buildMeetingsList(
              query: FirebaseFirestore.instance
                  .collection("meetings")
                  .where("studentId", isEqualTo: studentId)
                  .where("supervisorId", isEqualTo: supervisorId)
                  .where("requestedBy", isEqualTo: "student"),
              isIncoming: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeetingsList({required Query query, required bool isIncoming}) {
    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "No meetings found.",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        final meetings = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: meetings.length,
          itemBuilder: (context, index) {
            final doc = meetings[index];
            final data = doc.data() as Map<String, dynamic>;
            final dateTime = (data["dateTime"] as Timestamp).toDate();
            final status = data["status"] ?? "pending";

            Color statusColor;
            switch (status) {
              case "accepted":
                statusColor = Colors.green;
                break;
              case "rejected":
                statusColor = Colors.red;
                break;
              default:
                statusColor = Colors.orange;
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "📅 ${DateFormat("MMM d, yyyy").format(dateTime)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text("⏰ ${DateFormat("hh:mm a").format(dateTime)}"),
                    const SizedBox(height: 4),
                    Text("🎯 Purpose: ${data["purpose"] ?? ""}"),
                    const SizedBox(height: 8),
                    Text(
                      "📌 Status: $status",
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Show accept/reject buttons only for incoming pending requests
                    if (isIncoming && status == "pending")
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                _updateStatus(doc.id, "accepted", context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              child: const Text("Accept"),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                _updateStatus(doc.id, "rejected", context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Text("Reject"),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _updateStatus(
    String docId,
    String newStatus,
    BuildContext context,
  ) async {
    try {
      await FirebaseFirestore.instance.collection("meetings").doc(docId).update(
        {"status": newStatus},
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Meeting $newStatus successfully!"),
          backgroundColor: newStatus == "accepted" ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error updating status: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
