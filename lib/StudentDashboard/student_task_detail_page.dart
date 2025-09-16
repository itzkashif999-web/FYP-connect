import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fyp_connect/auth/cloudinary_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentTaskDetailPage extends StatefulWidget {
  final String projectId;
  final String taskId;

  const StudentTaskDetailPage({
    super.key,
    required this.projectId,
    required this.taskId,
  });

  @override
  State<StudentTaskDetailPage> createState() => _StudentTaskDetailPageState();
}

class _StudentTaskDetailPageState extends State<StudentTaskDetailPage> {
  static const Color primaryDarkTeal = Color.fromARGB(255, 24, 81, 91);
  static const Color primaryLightCyan = Color.fromARGB(255, 133, 213, 231);
  static const Color accentColor = Color.fromARGB(255, 45, 156, 175);
  static const Color backgroundColor = Color.fromARGB(255, 248, 252, 253);

  Map<String, dynamic>? task;
  Map<String, File?> selectedFiles = {};
  Map<String, bool> uploadingFiles = {};
  final String studentUid = FirebaseAuth.instance.currentUser?.uid ?? "unknown";

  @override
  void initState() {
    super.initState();
    _loadTask();
  }

  Future<void> _loadTask() async {
    final doc =
        await FirebaseFirestore.instance
            .collection("projects")
            .doc(widget.projectId)
            .collection("tasks")
            .doc(widget.taskId)
            .get();

    if (doc.exists) {
      setState(() => task = doc.data());
    }
  }

  Future<void> _pickFileForTask(String supervisorFileId) async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(
        () => selectedFiles[supervisorFileId] = File(result.files.single.path!),
      );
    }
  }

  Future<void> _uploadFileForTask(String supervisorFileId) async {
    final file = selectedFiles[supervisorFileId];
    if (file == null) return;
    setState(() => uploadingFiles[supervisorFileId] = true);

    try {
      final fileUrl = await CloudinaryService().uploadFile(file);
      final fileName = file.path.split("/").last;

      final studentFileRef = FirebaseFirestore.instance
          .collection("projects")
          .doc(widget.projectId)
          .collection("tasks")
          .doc(widget.taskId)
          .collection("studentFiles")
          .doc(supervisorFileId);

      // Delete old submission if exists
      final oldDoc = await studentFileRef.get();
      if (oldDoc.exists) {
        await studentFileRef.delete();
      }

      // Save new student file
      await studentFileRef.set({
        "name": fileName,
        "url": fileUrl,
        "uploadedBy": studentUid,
        "uploadedAt": FieldValue.serverTimestamp(),
        "title": task?["title"] ?? "Task File",
        "status": "Submitted",
      });

      // 🔥 Update supervisor file status to "Submitted"
      final supervisorFileRef = FirebaseFirestore.instance
          .collection("projects")
          .doc(widget.projectId)
          .collection("tasks")
          .doc(widget.taskId)
          .collection("supervisorFiles")
          .doc(supervisorFileId);

      await supervisorFileRef.update({"status": "Submitted"});

      setState(() {
        selectedFiles[supervisorFileId] = null;
        uploadingFiles[supervisorFileId] = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("File uploaded successfully")),
      );
    } catch (e) {
      setState(() => uploadingFiles[supervisorFileId] = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
    }
  }

  Future<void> _openUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Could not open file")));
    }
  }

  String _fmtDate(dynamic tsOrDate) {
    if (tsOrDate == null) return "—";
    if (tsOrDate is Timestamp)
      return tsOrDate.toDate().toString().split(' ').first;
    if (tsOrDate is DateTime) return tsOrDate.toString().split(' ').first;
    return "—";
  }

  @override
  Widget build(BuildContext context) {
    if (task == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryDarkTeal),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("Task Detail"),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryDarkTeal, accentColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 8,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection("projects")
                  .doc(widget.projectId)
                  .collection("tasks")
                  .doc(widget.taskId)
                  .collection("supervisorFiles")
                  .orderBy("uploadedAt", descending: true)
                  .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryDarkTeal),
                ),
              );
            }

            final supervisorFiles = snapshot.data!.docs;

            if (supervisorFiles.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.folder_open, size: 64, color: primaryLightCyan),
                    const SizedBox(height: 16),
                    Text(
                      "No supervisor uploads yet",
                      style: TextStyle(color: primaryDarkTeal),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 800),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey.shade400,
                    ), // outer border
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DataTableTheme(
                    data: DataTableThemeData(
                      headingRowColor: WidgetStateProperty.all(
                        const Color.fromARGB(255, 91, 165, 182),
                      ),
                      dataRowColor: WidgetStateProperty.all(Colors.white),
                      dividerThickness: 1, // horizontal grid lines
                    ),
                    child: DataTable(
                      border: TableBorder.all(
                        color: const Color.fromARGB(255, 16, 64, 75),
                        // grid line color
                        width: 1, // grid line thickness
                      ),
                      headingRowColor: WidgetStateProperty.all(
                        Color.fromARGB(255, 91, 165, 182),
                      ),
                      columns: const [
                        DataColumn(label: Text("File")),
                        DataColumn(label: Text("Description")),
                        DataColumn(label: Text("Start Date")),
                        DataColumn(label: Text("End Date")),
                        DataColumn(label: Text("Status")),
                        DataColumn(label: Text("Action")),
                      ],
                      rows:
                          supervisorFiles.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final fileUrl = data["url"] as String? ?? "";
                            final fileName = data["name"] as String? ?? "—";
                            final desc =
                                data["taskDescription"] as String? ?? "—";
                            final startDate = _fmtDate(data["uploadedAt"]);
                            final endDate = _fmtDate(data["endDate"]);

                            return DataRow(
                              cells: [
                                DataCell(
                                  fileUrl.isNotEmpty
                                      ? TextButton.icon(
                                        onPressed: () => _openUrl(fileUrl),
                                        icon: const Icon(
                                          Icons.file_open,
                                          color: primaryDarkTeal,
                                        ),
                                        label: Text(
                                          fileName,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      )
                                      : const Text("—"),
                                ),
                                DataCell(Text(desc)),
                                DataCell(Text(startDate)),
                                DataCell(Text(endDate)),
                                DataCell(
                                  StreamBuilder<DocumentSnapshot>(
                                    stream:
                                        FirebaseFirestore.instance
                                            .collection("projects")
                                            .doc(widget.projectId)
                                            .collection("tasks")
                                            .doc(widget.taskId)
                                            .collection("studentFiles")
                                            .doc(doc.id)
                                            .snapshots(),
                                    builder: (context, studentSnap) {
                                      String status;
                                      final endDate =
                                          data["endDate"] as Timestamp?;
                                      final endDateDT = endDate?.toDate();

                                      if (studentSnap.hasData &&
                                          studentSnap.data!.exists) {
                                        status = "Submitted";
                                      } else if (endDateDT != null &&
                                          DateTime.now().isAfter(endDateDT)) {
                                        status = "Not Submitted"; // changed
                                      } else {
                                        status = "Pending";
                                      }

                                      final statusColor =
                                          status == "Submitted"
                                              ? Colors.green
                                              : (status == "Not Submitted"
                                                  ? Colors.red
                                                  : Colors.orange);

                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: statusColor.withOpacity(0.3),
                                          ),
                                        ),
                                        child: Text(
                                          status,
                                          style: TextStyle(
                                            color: statusColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                DataCell(
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxHeight: 80,
                                    ),
                                    child: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (selectedFiles[doc.id] != null)
                                            Text(
                                              "Selected: ${selectedFiles[doc.id]!.path.split("/").last}",
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                          uploadingFiles[doc.id] == true
                                              ? const CircularProgressIndicator(
                                                strokeWidth: 2,
                                              )
                                              : Builder(
                                                builder: (context) {
                                                  final endDateTS =
                                                      data["endDate"]
                                                          as Timestamp?;
                                                  final endDateDT =
                                                      endDateTS?.toDate();

                                                  // If deadline passed, hide buttons
                                                  if (endDateDT != null &&
                                                      DateTime.now().isAfter(
                                                        endDateDT,
                                                      )) {
                                                    return const Text(
                                                      "Deadline passed",
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    );
                                                  }

                                                  // Otherwise show Choose/Upload buttons
                                                  return Row(
                                                    children: [
                                                      ElevatedButton.icon(
                                                        style:
                                                            ElevatedButton.styleFrom(
                                                              backgroundColor:
                                                                  Colors
                                                                      .deepPurple,
                                                              minimumSize:
                                                                  const Size(
                                                                    100,
                                                                    36,
                                                                  ),
                                                            ),
                                                        onPressed:
                                                            () =>
                                                                _pickFileForTask(
                                                                  doc.id,
                                                                ),
                                                        icon: const Icon(
                                                          Icons.folder_open,
                                                          color: Colors.white,
                                                          size: 18,
                                                        ),
                                                        label: const Text(
                                                          "Choose",
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      ElevatedButton.icon(
                                                        style:
                                                            ElevatedButton.styleFrom(
                                                              backgroundColor:
                                                                  Colors.green,
                                                              minimumSize:
                                                                  const Size(
                                                                    100,
                                                                    36,
                                                                  ),
                                                            ),
                                                        onPressed:
                                                            selectedFiles[doc
                                                                        .id] !=
                                                                    null
                                                                ? () =>
                                                                    _uploadFileForTask(
                                                                      doc.id,
                                                                    )
                                                                : null,
                                                        icon: const Icon(
                                                          Icons.cloud_upload,
                                                          color: Colors.white,
                                                          size: 18,
                                                        ),
                                                        label: const Text(
                                                          "Upload",
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
