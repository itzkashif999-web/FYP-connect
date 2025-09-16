// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:fyp_connect/SupervisorDashboard/supervisor_track_page.dart';

// class SupervisorProjectsPage extends StatelessWidget {
//   const SupervisorProjectsPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final supervisorId = FirebaseAuth.instance.currentUser?.uid;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("My Projects"),
//         backgroundColor: const Color.fromARGB(255, 24, 81, 91),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('projects')
//             .where('supervisorId', isEqualTo: supervisorId)
//             .where('status', isEqualTo: 'active') // ✅ Only accepted ones
//             .snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(child: Text("No projects assigned yet"));
//           }

//           final projects = snapshot.data!.docs;

//           return ListView.builder(
//             itemCount: projects.length,
//             itemBuilder: (context, index) {
//               final data = projects[index].data() as Map<String, dynamic>;

//               return Card(
//                 margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                 child: ListTile(
//                   title: Text(data['title'] ?? 'Untitled Project'),
//                   subtitle: Text("Status: ${data['status']}"),
//                   trailing: const Icon(Icons.arrow_forward_ios),
//                   onTap: () {
//                     // 👉 Navigate with projectId
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => SupervisorTrackPage(
//                           projectId: data['projectId'],
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fyp_connect/SupervisorDashboard/supervisor_track_page.dart';

class SupervisorProjectsPage extends StatelessWidget {
  const SupervisorProjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final supervisorId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "My Projects",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 24, 81, 91),
                Color.fromARGB(255, 133, 213, 231),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 240, 248, 255),
              Color.fromARGB(255, 225, 245, 254),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('projects')
              .where('supervisorId', isEqualTo: supervisorId)
              .where('status', isEqualTo: 'active')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color.fromARGB(255, 24, 81, 91),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Loading projects...",
                      style: TextStyle(
                        color: Color.fromARGB(255, 24, 81, 91),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.folder_open,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No projects assigned yet",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Projects will appear here once assigned",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              );
            }

            final projects = snapshot.data!.docs;

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: projects.length,
                itemBuilder: (context, index) {
                  final data = projects[index].data() as Map<String, dynamic>;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [
                              Colors.white,
                              Color.fromARGB(255, 250, 253, 255),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: const Color.fromARGB(255, 133, 213, 231).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(20),
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color.fromARGB(255, 24, 81, 91),
                                  Color.fromARGB(255, 133, 213, 231),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.assignment,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          title: Text(
                            data['title'] ?? 'Untitled Project',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 24, 81, 91),
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(255, 133, 213, 231).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color.fromARGB(255, 133, 213, 231),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    "Status: ${data['status']}",
                                    style: const TextStyle(
                                      color: Color.fromARGB(255, 24, 81, 91),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 133, 213, 231).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.arrow_forward_ios,
                              color: Color.fromARGB(255, 24, 81, 91),
                              size: 18,
                            ),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SupervisorTrackPage(
                                  projectId: data['projectId'],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
