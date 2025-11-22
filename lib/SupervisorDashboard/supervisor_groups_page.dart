import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class SupervisorGroupsPage extends StatelessWidget {
  const SupervisorGroupsPage({super.key});

  /// Open file externally using url_launcher
  /// For PDFs/DOCs, uses Google Docs Viewer to prevent WebView crashes
  Future<void> openFileExternal(String url, BuildContext context) async {
    try {
      Uri uri;
      if (url.endsWith('.pdf')) {
        uri = Uri.parse(url); // Open PDF directly
      } else if (url.endsWith('.doc') || url.endsWith('.docx')) {
        // Use Google Docs Viewer for Word files
        final viewerUrl =
            'https://docs.google.com/gview?embedded=true&url=$url';
        uri = Uri.parse(viewerUrl);
      } else {
        uri = Uri.parse(url); // Fallback
      }

      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Cannot open this file: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                .snapshots(),
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
              final regNo = group['registrationNumber'] ?? "N/A";
              final groupMembers = group['groupMembers'] ?? "N/A";
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
                      const SizedBox(height: 6),
                      Text("Student: $studentName"),
                      Text("Reg No: $regNo"),
                      Text("Group Members: $groupMembers"),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                              fileUrl.isNotEmpty
                                  ? () => openFileExternal(fileUrl, context)
                                  : null,
                          icon: Icon(
                            fileUrl.isNotEmpty
                                ? Icons.remove_red_eye
                                : Icons.hourglass_top,
                            color: Colors.white,
                          ),
                          label: Text(
                            fileUrl.isNotEmpty ? "View Proposal" : "Pending",
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                fileUrl.isNotEmpty
                                    ? const Color.fromARGB(255, 24, 81, 91)
                                    : Colors.orange,
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
