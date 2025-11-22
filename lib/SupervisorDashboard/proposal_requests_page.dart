import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fyp_connect/auth/auth_service.dart';
import 'package:fyp_connect/chats%20and%20notifications/notifications/services/send_notification_service.dart';
import 'webview_page.dart';

class ProposalRequestsPage extends StatefulWidget {
  const ProposalRequestsPage({super.key});

  @override
  State<ProposalRequestsPage> createState() => _ProposalRequestsPageState();
}

class _ProposalRequestsPageState extends State<ProposalRequestsPage> {
  List<QueryDocumentSnapshot<Map<String, dynamic>>> proposals = [];
  bool isLoading = true;
  AuthService authService = AuthService();

  @override
  void initState() {
    super.initState();
    fetchProposals();
  }

  Future<void> fetchProposals() async {
    final supervisorId = FirebaseAuth.instance.currentUser?.uid;

    if (supervisorId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Supervisor not logged in")));
      return;
    }

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('proposals')
              .where('supervisorId', isEqualTo: supervisorId)
              .get();

      setState(() {
        proposals = snapshot.docs;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> updateProposalStatus(String docId, String status) async {
    try {
      final proposalDoc =
          await FirebaseFirestore.instance
              .collection('proposals')
              .doc(docId)
              .get();

      if (!proposalDoc.exists) return;

      final data = proposalDoc.data()!;
      final supervisorName =
          FirebaseAuth.instance.currentUser?.displayName ?? 'Supervisor';
      final studentId = data['studentId'] ?? '';
      final projectTitle = data['projectTitle'] ?? '';
      final fileUrl = data['fileUrl'] ?? '';

      // 1️⃣ Update proposal status
      await FirebaseFirestore.instance
          .collection('proposals')
          .doc(docId)
          .update({'status': status});

      // 2️⃣ Notify student
      // 2️⃣ Notify student
      if (studentId.isNotEmpty) {
        final studentDoc =
            await FirebaseFirestore.instance
                .collection('students')
                .doc(studentId)
                .get();
        final token = studentDoc.data()?['pushToken'] ?? '';

        String notificationBody;
        if (status == 'Accepted') {
          notificationBody =
              'Your proposal "$projectTitle" was Accepted by $supervisorName. Please upload your project proposal file via Send Proposal.';
        } else {
          notificationBody =
              'Your proposal "$projectTitle" was $status by $supervisorName.';
        }

        if (token.isNotEmpty) {
          await SendNotificationService.sendNotificationUsingApi(
            token: token,
            title: 'Proposal $status',
            body: notificationBody,
            data: {'screen': 'proposal'},
          );
        }

        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(studentId)
            .collection('notifications')
            .add({
              'title': 'Proposal $status',
              'body': notificationBody,
              'isSeen': false,
              'createdAt': FieldValue.serverTimestamp(),
            });
      }

      // 3️⃣ If accepted → create or update group
      if (status == 'Accepted') {
        final supervisorId = FirebaseAuth.instance.currentUser?.uid;
        final studentName = data['studentName'] ?? 'Unknown Student';

        // Check if group already exists
        final existingGroupQuery =
            await FirebaseFirestore.instance
                .collection('supervisor_groups')
                .where('studentId', isEqualTo: studentId)
                .where('supervisorId', isEqualTo: supervisorId)
                .limit(1)
                .get();

        if (existingGroupQuery.docs.isNotEmpty) {
          // Update existing group
          final groupDocId = existingGroupQuery.docs.first.id;
          await FirebaseFirestore.instance
              .collection('supervisor_groups')
              .doc(groupDocId)
              .update({
                'fileUrl': fileUrl,
                'projectTitle': projectTitle,
                'updatedAt': FieldValue.serverTimestamp(),
              });
        } else {
          // Create new group
          await FirebaseFirestore.instance.collection('supervisor_groups').add({
            'projectTitle': projectTitle,
            'fileUrl': fileUrl,
            'studentId': studentId,
            'studentName': studentName,
            'registrationNumber': data['registrationNumber'] ?? '',
            'groupMembers': data['groupMembers'] ?? '',
            'supervisorId': supervisorId,
            'supervisorName': supervisorName,
            'status': 'Active',
            'createdAt': FieldValue.serverTimestamp(),
            'proposalId': docId,
          });
        }

        await authService.createProjectFromProposal(
          proposalId: docId,
          title: projectTitle,
          studentId: studentId,
          studentName: studentName,
        );

        await FirebaseFirestore.instance
            .collection('students')
            .doc(studentId)
            .set({
              'supervisorId': supervisorId,
              'supervisorName': supervisorName,
              'projectTitle': projectTitle,
              'projectStatus': 'Active',
            }, SetOptions(merge: true));
      }

      fetchProposals(); // Refresh list

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Proposal $status successfully!')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
    }
  }

  void openFileInWebView(String url, String title) {
    final viewerUrl = 'https://docs.google.com/gview?embedded=true&url=$url';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WebViewPage(title: title, url: viewerUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Proposal Requests',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 24, 81, 91),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : proposals.isEmpty
              ? const Center(child: Text('No proposals submitted to you yet.'))
              : ListView.builder(
                itemCount: proposals.length,
                itemBuilder: (context, index) {
                  final doc = proposals[index];
                  final data = doc.data();
                  final title = data['projectTitle'] ?? 'Untitled';
                  final student = data['studentName'] ?? 'Unknown';
                  final regNo = data['registrationNumber'] ?? 'N/A'; // NEW
                  final description = data['projectDescription'] ?? ''; // NEW
                  final fileUrl = data['fileUrl'] ?? '';
                  final status = data['status'] ?? 'Pending';
                  final docId = doc.id;

                  final normalizedStatus = (status ?? '').toLowerCase();
                  final isActionTaken =
                      normalizedStatus == 'accepted' ||
                      normalizedStatus == 'rejected';

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('Student: $student'),
                          Text('Reg No: $regNo'), // NEW
                          const SizedBox(height: 6),
                          if (description.isNotEmpty) ...[
                            const Text(
                              'Project Description:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(description),
                            const SizedBox(height: 6),
                          ],
                          Row(
                            children: [
                              const Text(
                                'Status: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                status,
                                style: TextStyle(
                                  color:
                                      status == 'Accepted'
                                          ? Colors.green
                                          : status == 'Rejected'
                                          ? Colors.red
                                          : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed:
                                      isActionTaken
                                          ? null
                                          : () => updateProposalStatus(
                                            docId,
                                            'Accepted',
                                          ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    disabledForegroundColor: Colors.grey
                                        .withOpacity(0.38),
                                    disabledBackgroundColor: Colors.grey
                                        .withOpacity(0.12),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  child: const Text('Accept'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed:
                                      isActionTaken
                                          ? null
                                          : () => updateProposalStatus(
                                            docId,
                                            'Rejected',
                                          ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    disabledForegroundColor: Colors.grey
                                        .withOpacity(0.38),
                                    disabledBackgroundColor: Colors.grey
                                        .withOpacity(0.12),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  child: const Text('Reject'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
