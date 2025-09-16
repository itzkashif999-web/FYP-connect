import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fyp_connect/auth/cloudinary_service.dart';
import 'package:url_launcher/url_launcher.dart';

class SupervisorTaskDetailPage extends StatefulWidget {
  final String projectId;
  final String taskId;

  const SupervisorTaskDetailPage({
    super.key,
    required this.projectId,
    required this.taskId,
  });

  @override
  State<SupervisorTaskDetailPage> createState() =>
      _SupervisorTaskDetailPageState();
}

class _SupervisorTaskDetailPageState extends State<SupervisorTaskDetailPage> {
  static const Color primaryDarkTeal = Color.fromARGB(255, 24, 81, 91);
  static const Color primaryLightCyan = Color.fromARGB(255, 133, 213, 231);
  static const Color accentColor = Color.fromARGB(255, 45, 156, 175);
  static const Color backgroundColor = Color.fromARGB(255, 248, 252, 253);

  Map<String, dynamic>? task;
  final TextEditingController descriptionController = TextEditingController();
  DateTime? pickedDeadline;
  File? selectedFile;

  @override
  void initState() {
    super.initState();
    _loadTask();
  }

  Future<void> _loadTask({bool updateFields = true}) async {
    final doc =
        await FirebaseFirestore.instance
            .collection("projects")
            .doc(widget.projectId)
            .collection("tasks")
            .doc(widget.taskId)
            .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        task = data;
        if (updateFields) {
          descriptionController.text = (data["description"] ?? "").toString();
          pickedDeadline =
              (data["endDate"] is Timestamp)
                  ? (data["endDate"] as Timestamp).toDate()
                  : (data["endDate"] as DateTime?);
        }
      });
    }
  }

  Future<void> _pickDeadline() async {
    final initial = pickedDeadline ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => pickedDeadline = picked);
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null) return;
    final file = result.files.first;
    if (file.path != null) setState(() => selectedFile = File(file.path!));
  }

  Future<void> _uploadTask() async {
    try {
      String? fileUrl;
      String? fileName;
      int? fileSize;

      if (selectedFile != null) {
        fileUrl = await CloudinaryService().uploadFile(selectedFile!);
        fileName = selectedFile!.path.split("/").last;
        fileSize = await selectedFile!.length();
      }

      final docRef = FirebaseFirestore.instance
          .collection("projects")
          .doc(widget.projectId)
          .collection("tasks")
          .doc(widget.taskId);

      // Update main task
      await docRef.set({
        "description": descriptionController.text,
        "endDate": pickedDeadline,
        "released": true,
      }, SetOptions(merge: true));

      // Add a supervisorFiles entry even if no file is uploaded
      await docRef.collection("supervisorFiles").add({
        "name": fileName ?? "",
        "url": fileUrl ?? "",
        "size": fileSize ?? 0,
        "uploadedBy": FirebaseAuth.instance.currentUser?.uid ?? "unknown",
        "uploadedAt": FieldValue.serverTimestamp(),
        "taskDescription": descriptionController.text,
        "endDate": pickedDeadline,
        "status": "Pending",
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Task uploaded successfully"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      setState(() {
        selectedFile = null;
        descriptionController.clear();
        pickedDeadline = null;
      });

      _loadTask(updateFields: false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Upload failed: $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _openUrl(String? url) async {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("No file URL available"),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Could not open file"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _deleteFile(String fileId) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection("projects")
          .doc(widget.projectId)
          .collection("tasks")
          .doc(widget.taskId)
          .collection("supervisorFiles")
          .doc(fileId);

      await docRef.delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Entry deleted successfully"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to delete entry: $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  String _statusForRow(
    Map<String, dynamic> data,
    Map<String, dynamic>? studentData,
    DateTime? endDate,
  ) {
    if (studentData != null &&
        (studentData["url"]?.toString().isNotEmpty ?? false)) {
      return "Submitted";
    }
    if (endDate != null && DateTime.now().isAfter(endDate))
      return "Not Submitted";
    return "Pending";
  }

  String _fmtDate(dynamic tsOrDate) {
    if (tsOrDate == null) return "—";
    DateTime? d;
    if (tsOrDate is Timestamp) d = tsOrDate.toDate();
    if (tsOrDate is DateTime) d = tsOrDate;
    return d != null ? d.toString().split(' ').first : "—";
  }

  @override
  Widget build(BuildContext context) {
    if (task == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryDarkTeal),
                strokeWidth: 3,
              ),
              SizedBox(height: 16),
              Text(
                "Loading task details...",
                style: TextStyle(
                  color: primaryDarkTeal,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryDarkTeal, accentColor],
            ),
          ),
        ),
        title: Text(
          "Task Detail: ${task!["milestoneId"] ?? widget.taskId}",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 8,
        shadowColor: primaryDarkTeal.withOpacity(0.3),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [backgroundColor, primaryLightCyan.withOpacity(0.1)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
              // Task Description Card
              Card(
                elevation: 6,
                shadowColor: primaryDarkTeal.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        primaryLightCyan.withOpacity(0.05),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.description,
                            color: primaryDarkTeal,
                            size: 24,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Task Description",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryDarkTeal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: "Enter new task description...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: primaryLightCyan),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: primaryDarkTeal,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.all(16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Deadline and File Picker Card
              Card(
                elevation: 6,
                shadowColor: primaryDarkTeal.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        primaryLightCyan.withOpacity(0.05),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Deadline picker
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: primaryLightCyan.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: primaryLightCyan.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  color: primaryDarkTeal,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "Deadline: ${pickedDeadline != null ? _fmtDate(pickedDeadline) : 'Not set'}",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: primaryDarkTeal,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _pickDeadline,
                              icon: Icon(Icons.edit_calendar, size: 18),
                              label: Text("Pick Deadline"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryDarkTeal,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 4,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // File picker
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: primaryLightCyan.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: primaryLightCyan.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.attach_file,
                                  color: primaryDarkTeal,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    selectedFile != null
                                        ? selectedFile!.path.split("/").last
                                        : "No file selected",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: primaryDarkTeal,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _pickFile,
                              icon: Icon(Icons.folder_open, size: 18),
                              label: Text("Pick File"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 4,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Upload Button
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      const Color.fromARGB(255, 20, 109, 65),
                      const Color.fromARGB(255, 13, 109, 101),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: primaryDarkTeal.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _uploadTask,
                  icon: Icon(Icons.cloud_upload, size: 24),
                  label: Text(
                    "Upload Task",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Supervisor File History
              Card(
                elevation: 8,
                shadowColor: primaryDarkTeal.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        primaryLightCyan.withOpacity(0.05),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.history, color: primaryDarkTeal, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            "Supervisor File History",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: primaryDarkTeal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      StreamBuilder<QuerySnapshot>(
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
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    primaryDarkTeal,
                                  ),
                                ),
                              ),
                            );
                          }

                          final files = snapshot.data!.docs;
                          if (files.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.folder_open,
                                    size: 64,
                                    color: primaryLightCyan,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "No uploads yet",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: primaryDarkTeal.withOpacity(0.7),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: primaryLightCyan.withOpacity(0.3),
                              ),
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
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
                                    dataRowColor: WidgetStateProperty.all(
                                      Colors.white,
                                    ),
                                    dividerThickness:
                                        1, // horizontal grid lines
                                  ),
                                  child: DataTable(
                                    border: TableBorder.all(
                                      color: const Color.fromARGB(
                                        255,
                                        16,
                                        64,
                                        75,
                                      ),
                                      // grid line color
                                      width: 1, // grid line thickness
                                    ),
                                    headingRowColor: WidgetStateProperty.all(
                                      Color.fromARGB(255, 91, 165, 182),
                                    ),

                                    columns: [
                                      DataColumn(
                                        label: Text(
                                          "File",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: primaryDarkTeal,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          "Description",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: primaryDarkTeal,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          "Start Date",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: primaryDarkTeal,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          "End Date",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: primaryDarkTeal,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          "Status",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: primaryDarkTeal,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          "Action",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: primaryDarkTeal,
                                          ),
                                        ),
                                      ),
                                    ],
                                    rows:
                                        files.map((doc) {
                                          final data =
                                              doc.data()
                                                  as Map<String, dynamic>;
                                          final fileUrl =
                                              data["url"]?.toString() ?? "";
                                          final fileName =
                                              (data["name"]
                                                          ?.toString()
                                                          .isNotEmpty ??
                                                      false)
                                                  ? data["name"].toString()
                                                  : "—";
                                          final startDate = _fmtDate(
                                            data["uploadedAt"],
                                          );
                                          final endDate = data["endDate"];
                                          DateTime? endDateDT;
                                          if (endDate is Timestamp)
                                            endDateDT = endDate.toDate();
                                          if (endDate is DateTime)
                                            endDateDT = endDate;

                                          return DataRow(
                                            color:
                                                WidgetStateProperty.resolveWith<
                                                  Color?
                                                >((Set<WidgetState> states) {
                                                  if (states.contains(
                                                    WidgetState.hovered,
                                                  )) {
                                                    return primaryLightCyan
                                                        .withOpacity(0.1);
                                                  }
                                                  return null;
                                                }),
                                            cells: [
                                              DataCell(
                                                fileUrl.isNotEmpty
                                                    ? TextButton.icon(
                                                      onPressed:
                                                          () =>
                                                              _openUrl(fileUrl),
                                                      icon: Icon(
                                                        Icons.file_download,
                                                        size: 16,
                                                        color: primaryDarkTeal,
                                                      ),
                                                      label: Text(
                                                        fileName,
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                        style: TextStyle(
                                                          color:
                                                              primaryDarkTeal,
                                                        ),
                                                      ),
                                                    )
                                                    : const Text("—"),
                                              ),
                                              DataCell(
                                                SizedBox(
                                                  width: 200,
                                                  child: Text(
                                                    data["taskDescription"]
                                                            ?.toString() ??
                                                        "—",
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color: primaryDarkTeal
                                                          .withOpacity(0.8),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  startDate,
                                                  style: TextStyle(
                                                    color: primaryDarkTeal
                                                        .withOpacity(0.8),
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  _fmtDate(endDateDT),
                                                  style: TextStyle(
                                                    color: primaryDarkTeal
                                                        .withOpacity(0.8),
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                StreamBuilder<DocumentSnapshot>(
                                                  stream:
                                                      FirebaseFirestore.instance
                                                          .collection(
                                                            "projects",
                                                          )
                                                          .doc(widget.projectId)
                                                          .collection("tasks")
                                                          .doc(widget.taskId)
                                                          .collection(
                                                            "studentFiles",
                                                          )
                                                          .doc(doc.id)
                                                          .snapshots(),
                                                  builder: (
                                                    context,
                                                    studentSnap,
                                                  ) {
                                                    final studentData =
                                                        studentSnap.data?.data()
                                                            as Map<
                                                              String,
                                                              dynamic
                                                            >?;
                                                    final status =
                                                        _statusForRow(
                                                          data,
                                                          studentData,
                                                          endDateDT,
                                                        );
                                                    final statusColor =
                                                        status == "Submitted"
                                                            ? Colors.green
                                                            : (status ==
                                                                    "Not Submitted"
                                                                ? Colors.red
                                                                : Colors
                                                                    .orange);

                                                    return Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: statusColor
                                                            .withOpacity(0.1),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                        border: Border.all(
                                                          color: statusColor
                                                              .withOpacity(0.3),
                                                        ),
                                                      ),
                                                      child: Text(
                                                        status,
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: statusColor,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                              DataCell(
                                                StreamBuilder<DocumentSnapshot>(
                                                  stream:
                                                      FirebaseFirestore.instance
                                                          .collection(
                                                            "projects",
                                                          )
                                                          .doc(widget.projectId)
                                                          .collection("tasks")
                                                          .doc(widget.taskId)
                                                          .collection(
                                                            "studentFiles",
                                                          )
                                                          .doc(doc.id)
                                                          .snapshots(),
                                                  builder: (
                                                    context,
                                                    studentSnap,
                                                  ) {
                                                    final studentData =
                                                        studentSnap.data?.data()
                                                            as Map<
                                                              String,
                                                              dynamic
                                                            >?;
                                                    return Row(
                                                      children: [
                                                        // Student submission download
                                                        if (studentData !=
                                                                null &&
                                                            (studentData["url"]
                                                                    ?.toString()
                                                                    .isNotEmpty ??
                                                                false))
                                                          Container(
                                                            decoration: BoxDecoration(
                                                              color: Colors
                                                                  .green
                                                                  .withOpacity(
                                                                    0.1,
                                                                  ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    8,
                                                                  ),
                                                            ),
                                                            child: IconButton(
                                                              icon: Icon(
                                                                Icons.download,
                                                                color:
                                                                    Colors
                                                                        .green,
                                                              ),
                                                              tooltip:
                                                                  "Download student file",
                                                              onPressed:
                                                                  () => _openUrl(
                                                                    studentData["url"],
                                                                  ),
                                                            ),
                                                          )
                                                        else
                                                          Container(
                                                            padding:
                                                                EdgeInsets.all(
                                                                  8,
                                                                ),
                                                            child: Text(
                                                              "—",
                                                              style: TextStyle(
                                                                color:
                                                                    Colors.grey,
                                                              ),
                                                            ),
                                                          ),

                                                        const SizedBox(
                                                          width: 8,
                                                        ),

                                                        // Delete supervisor entry
                                                        Container(
                                                          decoration: BoxDecoration(
                                                            color: Colors.red
                                                                .withOpacity(
                                                                  0.1,
                                                                ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                          ),
                                                          child: IconButton(
                                                            icon: Icon(
                                                              Icons.delete,
                                                              color: Colors.red,
                                                            ),
                                                            tooltip:
                                                                "Delete this supervisor entry",
                                                            onPressed: () async {
                                                              final confirm = await showDialog<
                                                                bool
                                                              >(
                                                                context:
                                                                    context,
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
                                                                      title: Text(
                                                                        "Confirm Delete",
                                                                        style: TextStyle(
                                                                          color:
                                                                              primaryDarkTeal,
                                                                        ),
                                                                      ),
                                                                      content:
                                                                          const Text(
                                                                            "Are you sure you want to delete this entry?",
                                                                          ),
                                                                      actions: [
                                                                        TextButton(
                                                                          onPressed:
                                                                              () => Navigator.pop(
                                                                                context,
                                                                                false,
                                                                              ),
                                                                          child: Text(
                                                                            "Cancel",
                                                                            style: TextStyle(
                                                                              color:
                                                                                  Colors.grey,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        ElevatedButton(
                                                                          onPressed:
                                                                              () => Navigator.pop(
                                                                                context,
                                                                                true,
                                                                              ),
                                                                          style: ElevatedButton.styleFrom(
                                                                            backgroundColor:
                                                                                Colors.red,
                                                                            foregroundColor:
                                                                                Colors.white,
                                                                          ),
                                                                          child: const Text(
                                                                            "Delete",
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                              );
                                                              if (confirm ==
                                                                  true)
                                                                _deleteFile(
                                                                  doc.id,
                                                                );
                                                            },
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  },
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
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
