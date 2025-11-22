// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:excel/excel.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: AddUserPage(),
//     );
//   }
// }

// // ---------------- Excel Import + Manage Buttons ----------------
// class AddUserPage extends StatefulWidget {
//   const AddUserPage({super.key});

//   @override
//   State<AddUserPage> createState() => _AddUserPageState();
// }

// class _AddUserPageState extends State<AddUserPage> {
//   bool isUploading = false;

//   Future<void> importExcel() async {
//     try {
//       FilePickerResult? result = await FilePicker.platform.pickFiles(
//         type: FileType.custom,
//         allowedExtensions: ["xlsx"],
//         withData: true,
//       );

//       if (result == null) return;

//       setState(() => isUploading = true);

//       var bytes = result.files.single.bytes;
//       if (bytes == null) throw Exception("Failed to read Excel bytes.");

//       var excel = Excel.decodeBytes(bytes);

//       // Loop through each sheet (role)
//       for (var sheetName in excel.tables.keys) {
//         var table = excel.tables[sheetName];
//         if (table == null || table.rows.isEmpty) continue;

//         String role = sheetName.trim().toLowerCase();

//         String subCollection =
//             role == "students"
//                 ? "add_students"
//                 : role == "supervisors"
//                 ? "add_supervisors"
//                 : "add_admins";

//         // ---------------- Delete previous data for this role ----------------
//         var oldDocs =
//             await FirebaseFirestore.instance
//                 .collection("addusers")
//                 .where("role", isEqualTo: role)
//                 .get();

//         for (var doc in oldDocs.docs) {
//           // Delete subcollection first
//           var subDocs = await doc.reference.collection(subCollection).get();
//           for (var subDoc in subDocs.docs) {
//             await subDoc.reference.delete();
//           }
//           // Delete parent doc
//           await doc.reference.delete();
//         }

//         // ---------------- Upload new data ----------------
//         String parentId =
//             FirebaseFirestore.instance.collection("addusers").doc().id;
//         var parentRef = FirebaseFirestore.instance
//             .collection("addusers")
//             .doc(parentId);

//         await parentRef.set({
//           "uid": parentId,
//           "role": role,
//           "createdAt": FieldValue.serverTimestamp(),
//         });

//         List<Future> futures = [];

//         var rows = table.rows;

//         for (int i = 1; i < rows.length; i++) {
//           var row = rows[i];
//           if (row.every((cell) => cell == null)) continue;

//           String uid =
//               FirebaseFirestore.instance.collection("addusers").doc().id;

//           Map<String, dynamic> data = {
//             "uid": uid,
//             "parentId": parentId,
//             "name": row.isNotEmpty ? row[0]?.value.toString() ?? "" : "",
//             "email": row.length > 3 ? row[3]?.value.toString() ?? "" : "",
//             "role": role,
//             "createdAt": FieldValue.serverTimestamp(),
//           };

//           if (role == "students") {
//             data["department"] =
//                 row.length > 1 ? row[1]?.value.toString() ?? "" : "";
//             data["registrationNo"] =
//                 row.length > 2 ? row[2]?.value.toString() ?? "" : "";
//           } else if (role == "supervisors") {
//             data["department"] =
//                 row.length > 1 ? row[1]?.value.toString() ?? "" : "";
//             data["facultyId"] =
//                 row.length > 2 ? row[2]?.value.toString() ?? "" : "";
//           } else if (role == "admins") {
//             data["adminId"] =
//                 row.length > 1 ? row[1]?.value.toString() ?? "" : "";
//             data["email"] =
//                 row.length > 2
//                     ? row[2]?.value.toString() ?? ""
//                     : ""; // <- Email for admins
//           }

//           futures.add(parentRef.collection(subCollection).doc(uid).set(data));
//         }

//         await Future.wait(futures);
//         print("✅ Sheet $sheetName uploaded successfully!");
//       }

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("Excel imported successfully! Previous data deleted."),
//           backgroundColor: Colors.green,
//         ),
//       );
//     } catch (e, stacktrace) {
//       print("❌ Error uploading Excel: $e");
//       print(stacktrace);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
//       );
//     } finally {
//       setState(() => isUploading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     const Color primaryColor = Colors.teal;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Manage Users"),
//         backgroundColor: primaryColor,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(32.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             // Upload Excel Button
//             isUploading
//                 ? const CircularProgressIndicator()
//                 : ElevatedButton.icon(
//                   onPressed: importExcel,
//                   icon: const Icon(Icons.upload_file),
//                   label: const Text("Upload Excel File"),
//                   style: ElevatedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 20,
//                       vertical: 16,
//                     ),
//                     backgroundColor: primaryColor,
//                   ),
//                 ),
//             const SizedBox(height: 40),

//             // Buttons for Students, Supervisors, Admins
//             ElevatedButton.icon(
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) => const ViewUsersPage(role: "student"),
//                   ),
//                 );
//               },
//               icon: const Icon(Icons.school),
//               label: const Text("View Students"),
//               style: ElevatedButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 40,
//                   vertical: 16,
//                 ),
//                 backgroundColor: primaryColor,
//               ),
//             ),
//             const SizedBox(height: 24),
//             ElevatedButton.icon(
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) => const ViewUsersPage(role: "supervisor"),
//                   ),
//                 );
//               },
//               icon: const Icon(Icons.person_outline),
//               label: const Text("View Supervisors"),
//               style: ElevatedButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 40,
//                   vertical: 16,
//                 ),
//                 backgroundColor: primaryColor,
//               ),
//             ),
//             const SizedBox(height: 24),
//             ElevatedButton.icon(
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) => const ViewUsersPage(role: "admin"),
//                   ),
//                 );
//               },
//               icon: const Icon(Icons.admin_panel_settings),
//               label: const Text("View Admins"),
//               style: ElevatedButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 40,
//                   vertical: 16,
//                 ),
//                 backgroundColor: primaryColor,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ---------------- DataTable ViewUsersPage ----------------
// class ViewUsersPage extends StatefulWidget {
//   final String role;
//   const ViewUsersPage({super.key, required this.role});

//   @override
//   State<ViewUsersPage> createState() => _ViewUsersPageState();
// }

// class _ViewUsersPageState extends State<ViewUsersPage> {
//   static const Color primaryColor = Color(0xFF1E5A5B);
//   static const Color lightAccent = Color(0xFFE8F4F4);

//   Future<List<Map<String, dynamic>>> _fetchUsers() async {
//     List<Map<String, dynamic>> usersList = [];
//     final snapshot =
//         await FirebaseFirestore.instance.collection("addusers").get();

//     for (var doc in snapshot.docs) {
//       if (widget.role == "student") {
//         final students = await doc.reference.collection("add_students").get();
//         for (var s in students.docs) {
//           var data = s.data();
//           data['parentId'] = doc.id;
//           data['uid'] = s.id;
//           usersList.add(data);
//         }
//       } else if (widget.role == "supervisor") {
//         final supervisors =
//             await doc.reference.collection("add_supervisors").get();
//         for (var s in supervisors.docs) {
//           var data = s.data();
//           data['parentId'] = doc.id;
//           data['uid'] = s.id;
//           usersList.add(data);
//         }
//       } else if (widget.role == "admin") {
//         final admins = await doc.reference.collection("add_admins").get();
//         for (var a in admins.docs) {
//           var data = a.data();
//           data['parentId'] = doc.id;
//           data['uid'] = a.id;
//           usersList.add(data);
//         }
//       }
//     }

//     return usersList;
//   }

//   void _refresh() => setState(() {});

//   void _showEditDialog(Map<String, dynamic> user) {
//     final nameController = TextEditingController(text: user['name']);
//     final emailController = TextEditingController(text: user['email']);
//     final deptController = TextEditingController(
//       text: user['department'] ?? "",
//     );
//     final regController = TextEditingController(
//       text: user['registrationNo'] ?? "",
//     );
//     final facultyController = TextEditingController(
//       text: user['facultyId'] ?? "",
//     );
//     final adminController = TextEditingController(text: user['adminId'] ?? "");

//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text("Edit User"),
//           content: SingleChildScrollView(
//             child: Column(
//               children: [
//                 TextField(
//                   controller: nameController,
//                   decoration: const InputDecoration(labelText: "Name"),
//                 ),
//                 TextField(
//                   controller: emailController,
//                   decoration: const InputDecoration(labelText: "Email"),
//                 ),
//                 if (widget.role == "student")
//                   TextField(
//                     controller: regController,
//                     decoration: const InputDecoration(
//                       labelText: "Registration No",
//                     ),
//                   ),
//                 if (widget.role == "supervisor")
//                   TextField(
//                     controller: facultyController,
//                     decoration: const InputDecoration(labelText: "Faculty Id"),
//                   ),
//                 if (widget.role != "admin")
//                   TextField(
//                     controller: deptController,
//                     decoration: const InputDecoration(labelText: "Department"),
//                   ),
//                 if (widget.role == "admin")
//                   TextField(
//                     controller: adminController,
//                     decoration: const InputDecoration(labelText: "Admin Id"),
//                   ),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text("Cancel"),
//             ),
//             ElevatedButton(
//               onPressed: () async {
//                 Map<String, dynamic> updatedData = {
//                   "name": nameController.text,
//                   "email": emailController.text,
//                 };
//                 if (widget.role == "student") {
//                   updatedData["registrationNo"] = regController.text;
//                   updatedData["department"] = deptController.text;
//                 } else if (widget.role == "supervisor") {
//                   updatedData["facultyId"] = facultyController.text;
//                   updatedData["department"] = deptController.text;
//                 } else if (widget.role == "admin") {
//                   updatedData["adminId"] = adminController.text;
//                 }

//                 await FirebaseFirestore.instance
//                     .collection("addusers")
//                     .doc(user['parentId'])
//                     .collection(
//                       widget.role == "student"
//                           ? "add_students"
//                           : widget.role == "supervisor"
//                           ? "add_supervisors"
//                           : "add_admins",
//                     )
//                     .doc(user['uid'])
//                     .update(updatedData);

//                 Navigator.pop(context);
//                 _refresh();
//               },
//               child: const Text("Save"),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     String displayTitle =
//         widget.role == "student"
//             ? "Students"
//             : widget.role == "supervisor"
//             ? "Supervisors"
//             : "Admins";

//     List<DataColumn> columns = [
//       const DataColumn(label: Text("Name")),
//       if (widget.role == "student")
//         const DataColumn(label: Text("Registration No")),
//       if (widget.role == "supervisor")
//         const DataColumn(label: Text("Faculty Id")),
//       if (widget.role == "admin") const DataColumn(label: Text("Admin Id")),
//       const DataColumn(label: Text("Email")),
//       if (widget.role != "admin") const DataColumn(label: Text("Department")),
//       const DataColumn(label: Text("Actions")), // New Actions column
//     ];

//     return Scaffold(
//       backgroundColor: lightAccent,
//       appBar: AppBar(
//         title: Text(
//           displayTitle,
//           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
//         ),
//         backgroundColor: primaryColor,
//         foregroundColor: Colors.white,
//         elevation: 0,
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: FutureBuilder<List<Map<String, dynamic>>>(
//           future: _fetchUsers(),
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const Center(
//                 child: Padding(
//                   padding: EdgeInsets.all(40),
//                   child: CircularProgressIndicator(
//                     valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
//                   ),
//                 ),
//               );
//             }
//             if (!snapshot.hasData || snapshot.data!.isEmpty) {
//               return Center(
//                 child: Padding(
//                   padding: const EdgeInsets.all(40),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Icon(
//                         Icons.people_outline,
//                         size: 64,
//                         color: Colors.grey.shade400,
//                       ),
//                       const SizedBox(height: 16),
//                       Text(
//                         "No $displayTitle Found",
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.grey.shade600,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         "Add some users to see them here",
//                         style: TextStyle(
//                           fontSize: 14,
//                           color: Colors.grey.shade500,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             }

//             final users = snapshot.data!;

//             return SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               child: Container(
//                 padding: const EdgeInsets.all(16),
//                 child: DataTable(
//                   border: TableBorder.all(color: Colors.grey, width: 1),
//                   columns: columns,
//                   rows:
//                       users.map((u) {
//                         List<DataCell> cells = [
//                           DataCell(Text(u['name'] ?? "")),
//                           if (widget.role == "student")
//                             DataCell(Text(u['registrationNo'] ?? "")),
//                           if (widget.role == "supervisor")
//                             DataCell(Text(u['facultyId'] ?? "")),
//                           if (widget.role == "admin")
//                             DataCell(Text(u['adminId'] ?? "")),
//                           DataCell(Text(u['email'] ?? "")),
//                           if (widget.role != "admin")
//                             DataCell(Text(u['department'] ?? "")),
//                           // Actions cell
//                           DataCell(
//                             Row(
//                               children: [
//                                 IconButton(
//                                   icon: const Icon(
//                                     Icons.edit,
//                                     color: Colors.blue,
//                                   ),
//                                   onPressed: () => _showEditDialog(u),
//                                 ),
//                                 IconButton(
//                                   icon: const Icon(
//                                     Icons.delete,
//                                     color: Colors.red,
//                                   ),
//                                   onPressed: () async {
//                                     bool confirm = await showDialog(
//                                       context: context,
//                                       builder:
//                                           (context) => AlertDialog(
//                                             title: const Text("Confirm Delete"),
//                                             content: const Text(
//                                               "Are you sure you want to delete this user?",
//                                             ),
//                                             actions: [
//                                               TextButton(
//                                                 onPressed:
//                                                     () => Navigator.pop(
//                                                       context,
//                                                       false,
//                                                     ),
//                                                 child: const Text("Cancel"),
//                                               ),
//                                               TextButton(
//                                                 onPressed:
//                                                     () => Navigator.pop(
//                                                       context,
//                                                       true,
//                                                     ),
//                                                 child: const Text("Delete"),
//                                               ),
//                                             ],
//                                           ),
//                                     );
//                                     if (confirm) {
//                                       await FirebaseFirestore.instance
//                                           .collection("addusers")
//                                           .doc(u['parentId'])
//                                           .collection(
//                                             widget.role == "student"
//                                                 ? "add_students"
//                                                 : widget.role == "supervisor"
//                                                 ? "add_supervisors"
//                                                 : "add_admins",
//                                           )
//                                           .doc(u['uid'])
//                                           .delete();
//                                       _refresh();
//                                     }
//                                   },
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ];

//                         // Ensure cells match column count
//                         while (cells.length < columns.length)
//                           cells.add(const DataCell(Text("")));
//                         return DataRow(cells: cells);
//                       }).toList(),
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 24, 81, 91),
          brightness: Brightness.light,
        ),
      ),
      home: const AddUserPage(),
    );
  }
}

// Color Theme
class AppColors {
  static const Color primaryDark = Color.fromARGB(255, 24, 81, 91);
  static const Color primaryLight = Color.fromARGB(255, 133, 213, 231);
  static const Color accentGreen = Color.fromARGB(255, 76, 175, 80);
  static const Color accentOrange = Color.fromARGB(255, 255, 152, 0);
  static const Color surfaceLight = Color.fromARGB(255, 245, 250, 250);
  static const Color borderColor = Color.fromARGB(255, 200, 230, 235);
  static const Color textDark = Color.fromARGB(255, 33, 33, 33);
  static const Color textLight = Color.fromARGB(255, 117, 117, 117);
}

// ============= Add User Page =============
class AddUserPage extends StatefulWidget {
  const AddUserPage({super.key});

  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  bool isUploading = false;

  Future<void> importExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ["xlsx"],
        withData: true,
      );

      if (result == null) return;

      setState(() => isUploading = true);

      var bytes = result.files.single.bytes;
      if (bytes == null) throw Exception("Failed to read Excel bytes.");

      var excel = Excel.decodeBytes(bytes);

      for (var sheetName in excel.tables.keys) {
        var table = excel.tables[sheetName];
        if (table == null || table.rows.isEmpty) continue;

        String role = sheetName.trim().toLowerCase();

        String subCollection =
            role == "students"
                ? "add_students"
                : role == "supervisors"
                ? "add_supervisors"
                : "add_admins";

        var oldDocs =
            await FirebaseFirestore.instance
                .collection("addusers")
                .where("role", isEqualTo: role)
                .get();

        for (var doc in oldDocs.docs) {
          var subDocs = await doc.reference.collection(subCollection).get();
          for (var subDoc in subDocs.docs) {
            await subDoc.reference.delete();
          }
          await doc.reference.delete();
        }

        String parentId =
            FirebaseFirestore.instance.collection("addusers").doc().id;
        var parentRef = FirebaseFirestore.instance
            .collection("addusers")
            .doc(parentId);

        await parentRef.set({
          "uid": parentId,
          "role": role,
          "createdAt": FieldValue.serverTimestamp(),
        });

        List<Future> futures = [];

        var rows = table.rows;

        for (int i = 1; i < rows.length; i++) {
          var row = rows[i];
          if (row.every((cell) => cell == null)) continue;

          String uid =
              FirebaseFirestore.instance.collection("addusers").doc().id;

          Map<String, dynamic> data = {
            "uid": uid,
            "parentId": parentId,
            "name": row.isNotEmpty ? row[0]?.value.toString() ?? "" : "",
            "email": row.length > 3 ? row[3]?.value.toString() ?? "" : "",
            "role": role,
            "createdAt": FieldValue.serverTimestamp(),
          };

          if (role == "students") {
            data["department"] =
                row.length > 1 ? row[1]?.value.toString() ?? "" : "";
            data["registrationNo"] =
                row.length > 2 ? row[2]?.value.toString() ?? "" : "";
          } else if (role == "supervisors") {
            data["department"] =
                row.length > 1 ? row[1]?.value.toString() ?? "" : "";
            data["facultyId"] =
                row.length > 2 ? row[2]?.value.toString() ?? "" : "";
          } else if (role == "admins") {
            data["adminId"] =
                row.length > 1 ? row[1]?.value.toString() ?? "" : "";
            data["email"] =
                row.length > 2 ? row[2]?.value.toString() ?? "" : "";
          }

          futures.add(parentRef.collection(subCollection).doc(uid).set(data));
        }

        await Future.wait(futures);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("✅ Excel imported successfully!"),
          backgroundColor: AppColors.accentGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Error: $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } finally {
      setState(() => isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        title: const Text(
          "User Management System",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.surfaceLight, Colors.white],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                // Header Icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppColors.primaryLight, AppColors.primaryDark],
                    ),
                  ),
                  child: const Icon(
                    Icons.people,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Manage Your Users",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Upload Excel files or view and edit users by category",
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.textLight),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Upload Excel Button
                _buildPrimaryButton(
                  isLoading: isUploading,
                  onPressed: importExcel,
                  icon: Icons.upload_file,
                  label: "Upload Excel File",
                  color: AppColors.accentOrange,
                ),
                const SizedBox(height: 32),

                // User Category Cards
                Text(
                  "Select User Category",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 20),

                _buildUserCategoryCard(
                  icon: Icons.school,
                  title: "Students",
                  description: "View and manage student records",
                  color: AppColors.primaryLight,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ViewUsersPage(role: "student"),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                _buildUserCategoryCard(
                  icon: Icons.person,
                  title: "Supervisors",
                  description: "View and manage supervisor records",
                  color: AppColors.primaryLight,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ViewUsersPage(role: "supervisor"),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                _buildUserCategoryCard(
                  icon: Icons.admin_panel_settings,
                  title: "Admins",
                  description: "View and manage admin records",
                  color: AppColors.primaryLight,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ViewUsersPage(role: "admin"),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
    required bool isLoading,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child:
          isLoading
              ? const SizedBox(
                height: 56,
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryDark,
                    ),
                  ),
                ),
              )
              : ElevatedButton.icon(
                onPressed: onPressed,
                icon: Icon(icon, size: 24),
                label: Text(label, style: const TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
    );
  }

  Widget _buildUserCategoryCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            //  border: Border.all(color: AppColors.borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primaryDark, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppColors.primaryDark,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============= View Users Page =============
class ViewUsersPage extends StatefulWidget {
  final String role;
  const ViewUsersPage({super.key, required this.role});

  @override
  State<ViewUsersPage> createState() => _ViewUsersPageState();
}

class _ViewUsersPageState extends State<ViewUsersPage> {
  Future<List<Map<String, dynamic>>> _fetchUsers() async {
    List<Map<String, dynamic>> usersList = [];
    final snapshot =
        await FirebaseFirestore.instance.collection("addusers").get();

    for (var doc in snapshot.docs) {
      if (widget.role == "student") {
        final students = await doc.reference.collection("add_students").get();
        for (var s in students.docs) {
          var data = s.data();
          data['parentId'] = doc.id;
          data['uid'] = s.id;
          usersList.add(data);
        }
      } else if (widget.role == "supervisor") {
        final supervisors =
            await doc.reference.collection("add_supervisors").get();
        for (var s in supervisors.docs) {
          var data = s.data();
          data['parentId'] = doc.id;
          data['uid'] = s.id;
          usersList.add(data);
        }
      } else if (widget.role == "admin") {
        final admins = await doc.reference.collection("add_admins").get();
        for (var a in admins.docs) {
          var data = a.data();
          data['parentId'] = doc.id;
          data['uid'] = a.id;
          usersList.add(data);
        }
      }
    }

    return usersList;
  }

  void _refresh() => setState(() {});

  void _showEditDialog(Map<String, dynamic> user) {
    final nameController = TextEditingController(text: user['name']);
    final emailController = TextEditingController(text: user['email']);
    final deptController = TextEditingController(
      text: user['department'] ?? "",
    );
    final regController = TextEditingController(
      text: user['registrationNo'] ?? "",
    );
    final facultyController = TextEditingController(
      text: user['facultyId'] ?? "",
    );
    final adminController = TextEditingController(text: user['adminId'] ?? "");

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit User"),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildEditTextField(nameController, "Name"),
                _buildEditTextField(emailController, "Email"),
                if (widget.role == "student")
                  _buildEditTextField(regController, "Registration No"),
                if (widget.role == "supervisor")
                  _buildEditTextField(facultyController, "Faculty Id"),
                if (widget.role != "admin")
                  _buildEditTextField(deptController, "Department"),
                if (widget.role == "admin")
                  _buildEditTextField(adminController, "Admin Id"),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: () async {
                Map<String, dynamic> updatedData = {
                  "name": nameController.text,
                  "email": emailController.text,
                };
                if (widget.role == "student") {
                  updatedData["registrationNo"] = regController.text;
                  updatedData["department"] = deptController.text;
                } else if (widget.role == "supervisor") {
                  updatedData["facultyId"] = facultyController.text;
                  updatedData["department"] = deptController.text;
                } else if (widget.role == "admin") {
                  updatedData["adminId"] = adminController.text;
                }

                await FirebaseFirestore.instance
                    .collection("addusers")
                    .doc(user['parentId'])
                    .collection(
                      widget.role == "student"
                          ? "add_students"
                          : widget.role == "supervisor"
                          ? "add_supervisors"
                          : "add_admins",
                    )
                    .doc(user['uid'])
                    .update(updatedData);

                Navigator.pop(context);
                _refresh();
              },
              child: const Text("Save", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEditTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.primaryDark),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: AppColors.primaryDark,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String displayTitle =
        widget.role == "student"
            ? "Students"
            : widget.role == "supervisor"
            ? "Supervisors"
            : "Admins";

    IconData displayIcon =
        widget.role == "student"
            ? Icons.school
            : widget.role == "supervisor"
            ? Icons.person
            : Icons.admin_panel_settings;

    List<DataColumn> columns = [
      const DataColumn(
        label: Text("Name", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      if (widget.role == "student")
        const DataColumn(
          label: Text("Reg. No", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      if (widget.role == "supervisor")
        const DataColumn(
          label: Text(
            "Faculty Id",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      if (widget.role == "admin")
        const DataColumn(
          label: Text(
            "Admin Id",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      const DataColumn(
        label: Text("Email", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      if (widget.role != "admin")
        const DataColumn(
          label: Text(
            "Department",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      const DataColumn(
        label: Text("Actions", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        title: Text(
          displayTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Loading $displayTitle...",
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryLight.withOpacity(0.2),
                    ),
                    child: Icon(
                      displayIcon,
                      size: 64,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "No $displayTitle Found",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Upload an Excel file to add $displayTitle",
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            );
          }

          final users = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: DataTable(
                  border: TableBorder(
                    top: BorderSide(color: AppColors.borderColor, width: 1.5),
                    verticalInside: BorderSide(
                      color: AppColors.borderColor,
                      width: 1.5,
                    ),
                    horizontalInside: BorderSide(
                      color: AppColors.borderColor,
                      width: 1.5,
                    ),
                  ),
                  headingRowColor: WidgetStateProperty.all(
                    AppColors.primaryLight.withOpacity(0.3),
                  ),
                  headingRowHeight: 56,
                  dataRowHeight: 64,
                  columns: columns,
                  rows:
                      users.map((u) {
                        List<DataCell> cells = [
                          DataCell(
                            Text(
                              u['name'] ?? "",
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          if (widget.role == "student")
                            DataCell(
                              Text(
                                u['registrationNo'] ?? "",
                                style: const TextStyle(
                                  color: AppColors.textLight,
                                ),
                              ),
                            ),
                          if (widget.role == "supervisor")
                            DataCell(
                              Text(
                                u['facultyId'] ?? "",
                                style: const TextStyle(
                                  color: AppColors.textLight,
                                ),
                              ),
                            ),
                          if (widget.role == "admin")
                            DataCell(
                              Text(
                                u['adminId'] ?? "",
                                style: const TextStyle(
                                  color: AppColors.textLight,
                                ),
                              ),
                            ),
                          DataCell(
                            Text(
                              u['email'] ?? "",
                              style: const TextStyle(
                                color: AppColors.textLight,
                              ),
                            ),
                          ),
                          if (widget.role != "admin")
                            DataCell(
                              Text(
                                u['department'] ?? "",
                                style: const TextStyle(
                                  color: AppColors.textLight,
                                ),
                              ),
                            ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Tooltip(
                                  message: "Edit",
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                      size: 20,
                                    ),
                                    onPressed: () => _showEditDialog(u),
                                  ),
                                ),
                                Tooltip(
                                  message: "Delete",
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    onPressed: () async {
                                      bool? confirm = await showDialog<bool>(
                                        context: context,
                                        builder:
                                            (context) => AlertDialog(
                                              title: const Text(
                                                "Confirm Delete",
                                              ),
                                              content: const Text(
                                                "Are you sure you want to delete this user?",
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed:
                                                      () => Navigator.pop(
                                                        context,
                                                        false,
                                                      ),
                                                  child: const Text("Cancel"),
                                                ),
                                                ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.red,
                                                      ),
                                                  onPressed:
                                                      () => Navigator.pop(
                                                        context,
                                                        true,
                                                      ),
                                                  child: const Text(
                                                    "Delete",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                      );

                                      if (confirm ?? false) {
                                        await FirebaseFirestore.instance
                                            .collection("addusers")
                                            .doc(u['parentId'])
                                            .collection(
                                              widget.role == "student"
                                                  ? "add_students"
                                                  : widget.role == "supervisor"
                                                  ? "add_supervisors"
                                                  : "add_admins",
                                            )
                                            .doc(u['uid'])
                                            .delete();
                                        _refresh();
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ];

                        while (cells.length < columns.length) {
                          cells.add(const DataCell(Text("")));
                        }

                        return DataRow(
                          color: WidgetStateProperty.all(
                            users.indexOf(u).isEven
                                ? Colors.white
                                : AppColors.surfaceLight,
                          ),
                          cells: cells,
                        );
                      }).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
