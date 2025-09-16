import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'webview_page.dart'; // Make sure you have this page for opening PDFs

class SupervisorGroupsPage extends StatelessWidget {
  const SupervisorGroupsPage({super.key});

  /// Opens file in Google Docs viewer inside WebView
  void openFileInWebView(BuildContext context, String url, String title) {
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
    final supervisorId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Groups"),
        backgroundColor: const Color.fromARGB(255, 24, 81, 91),
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('supervisor_groups')
                .where('supervisorId', isEqualTo: supervisorId)
                .orderBy('createdAt', descending: true)
                .snapshots(), // ✅ Listen in real-time
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No groups yet."));
          }

          final groups = snapshot.data!.docs;

          return ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index].data() as Map<String, dynamic>;
              final projectTitle = group['projectTitle'] ?? "Untitled";
              final studentName = group['studentName'] ?? "Unknown";

              final fileUrl = group['fileUrl'] ?? "";

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        projectTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text("Student: $studentName"),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (fileUrl.isNotEmpty) {
                              openFileInWebView(context, fileUrl, projectTitle);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("File URL missing"),
                                ),
                              );
                            }
                          },
                          icon: const Icon(
                            Icons.remove_red_eye,
                            color: Colors.white,
                          ),
                          label: const Text("View Proposal"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              255,
                              24,
                              81,
                              91,
                            ),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
