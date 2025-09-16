import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp_connect/StudentDashboard/student_task_detail_page.dart';

class StudentTrackPage extends StatefulWidget {
  final String projectId;

  const StudentTrackPage({super.key, required this.projectId});

  @override
  State<StudentTrackPage> createState() => _StudentTrackPageState();
}

class _StudentTrackPageState extends State<StudentTrackPage> {
  List<Map<String, dynamic>> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  int parseMilestoneId(String docId) {
    return int.tryParse(docId.replaceAll("m", "")) ?? 0;
  }

  String getMilestoneTitle(int milestoneId) {
    switch (milestoneId) {
      case 10:
        return "Milestone: 01";
      case 30:
        return "Milestone: 02";
      case 60:
        return "Milestone: 03";
      case 100:
        return "Milestone: 04";
      default:
        return "Milestone";
    }
  }

  Future<void> _loadTasks() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection("projects")
            .doc(widget.projectId)
            .collection("tasks")
            .get();

    List<Map<String, dynamic>> tasks = [];

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final supervisorFilesSnapshot =
          await doc.reference.collection("supervisorFiles").get();

      final supervisorFiles =
          supervisorFilesSnapshot.docs.map((d) => d.data()).toList();

      final totalSupervisorFiles = supervisorFiles.length;
      final submittedCount =
          supervisorFiles
              .where(
                (f) =>
                    (f["status"] ?? "").toString().toLowerCase() == "submitted",
              )
              .length;

      final milestoneId = parseMilestoneId(doc.id);

      // Assign Milestone: 01, 02, etc.
      String taskTitle = getMilestoneTitle(milestoneId);

      if (milestoneId == 4) taskTitle = "100% Task";

      final isCompleted =
          (totalSupervisorFiles > 0 && submittedCount == totalSupervisorFiles);

      tasks.add({
        "taskId": doc.id,
        "title": taskTitle,
        "milestoneId": milestoneId,
        "isReleased": data["released"] == true,
        "supervisorFiles": supervisorFiles,
        "supervisorFileCount": totalSupervisorFiles,
        "submittedCount": submittedCount,
        "completed": isCompleted,
      });
    }

    tasks.sort((a, b) => a["milestoneId"].compareTo(b["milestoneId"]));

    setState(() {
      _tasks = tasks;
    });
  }

  /// ✅ Fixed: each milestone returns its OWN weight (not cumulative)
  double getMilestoneWeight(int milestoneId) {
    switch (milestoneId) {
      case 10:
        return 0.1; // 10%
      case 30:
        return 0.3; // 30%
      case 60:
        return 0.6; // 60%
      case 100:
        return 1.0; // 100%
      default:
        return 0.0;
    }
  }

  double calculateMilestoneProgress(int milestoneId) {
    final milestoneTasks =
        _tasks.where((t) => t["milestoneId"] == milestoneId).toList();

    if (milestoneTasks.isEmpty) return 0.0;

    double totalProgress = 0.0;

    for (var task in milestoneTasks) {
      final supervisorFiles =
          task["supervisorFiles"] as List<Map<String, dynamic>>? ?? [];

      if (supervisorFiles.isNotEmpty) {
        final submittedCount =
            supervisorFiles
                .where(
                  (f) =>
                      (f["status"]?.toString().toLowerCase() ?? "") ==
                      "submitted",
                )
                .length;

        totalProgress += submittedCount / supervisorFiles.length;
      }
    }

    return totalProgress / milestoneTasks.length;
  }

  double calculateOverallProgress() {
    if (_tasks.isEmpty) return 0.0;

    double overallProgress = 0.0;

    final milestoneIds =
        _tasks.map((t) => t["milestoneId"] as int).toSet().toList()..sort();

    for (final id in milestoneIds) {
      final milestoneTasks =
          _tasks.where((t) => t["milestoneId"] == id).toList();

      // consider milestone completed only if ALL its tasks are submitted
      bool milestoneCompleted = milestoneTasks.every(
        (task) =>
            (task["supervisorFileCount"] ?? 0) > 0 &&
            (task["submittedCount"] ?? 0) == (task["supervisorFileCount"] ?? 0),
      );

      if (milestoneCompleted) {
        overallProgress = getMilestoneWeight(id);
      }
    }

    return overallProgress.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    double progress = calculateOverallProgress();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Track Project",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
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
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 245, 250, 252),
              Color.fromARGB(255, 230, 245, 250),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [
                        Colors.white,
                        Color.fromARGB(255, 248, 252, 253),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.track_changes,
                            color: Color.fromARGB(255, 24, 81, 91),
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "Overall Progress",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color.fromARGB(255, 24, 81, 91),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 12,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: Colors.grey[200],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0.0, end: progress),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeInOut,
                            builder: (context, value, child) {
                              return LinearProgressIndicator(
                                value: value,
                                backgroundColor: Colors.transparent,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  value == 1.0
                                      ? Colors.green
                                      : const Color.fromARGB(
                                        255,
                                        133,
                                        213,
                                        231,
                                      ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${(progress * 100).toInt()}% Complete",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadTasks,
                color: const Color.fromARGB(255, 24, 81, 91),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _tasks.length,
                  itemBuilder: (context, index) {
                    final task = _tasks[index];
                    final isUnlocked = (task["supervisorFileCount"] ?? 0) > 0;

                    final milestoneProgress = calculateMilestoneProgress(
                      task["milestoneId"],
                    );
                    final isCompleted = milestoneProgress == 1.0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color:
                                isCompleted
                                    ? Colors.green.withOpacity(0.3)
                                    : isUnlocked
                                    ? const Color.fromARGB(
                                      255,
                                      133,
                                      213,
                                      231,
                                    ).withOpacity(0.3)
                                    : Colors.grey.withOpacity(0.2),
                            width: 2,
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: [
                                Colors.white,
                                isCompleted
                                    ? Colors.green.withOpacity(0.05)
                                    : isUnlocked
                                    ? const Color.fromARGB(
                                      255,
                                      133,
                                      213,
                                      231,
                                    ).withOpacity(0.05)
                                    : Colors.grey.withOpacity(0.02),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            isCompleted
                                                ? Colors.green
                                                : isUnlocked
                                                ? const Color.fromARGB(
                                                  255,
                                                  133,
                                                  213,
                                                  231,
                                                )
                                                : Colors.grey,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        isCompleted
                                            ? "COMPLETED"
                                            : isUnlocked
                                            ? "UNLOCKED"
                                            : "LOCKED",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(
                                      isCompleted
                                          ? Icons.check_circle
                                          : isUnlocked
                                          ? Icons.lock_open
                                          : Icons.lock,
                                      color:
                                          isCompleted
                                              ? Colors.green
                                              : isUnlocked
                                              ? const Color.fromARGB(
                                                255,
                                                24,
                                                81,
                                                91,
                                              )
                                              : Colors.grey,
                                      size: 24,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  task["title"],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Color.fromARGB(255, 24, 81, 91),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "This milestone contributes ${(getMilestoneWeight(task["milestoneId"]) * 100).toInt()}%",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: Colors.grey[200],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: milestoneProgress,
                                      backgroundColor: Colors.transparent,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        milestoneProgress == 1.0
                                            ? Colors.green
                                            : const Color.fromARGB(
                                              255,
                                              133,
                                              213,
                                              231,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(
                                      (task["supervisorFileCount"] ?? 0) > 0
                                          ? Icons.file_present
                                          : Icons.hourglass_empty,
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        (task["supervisorFileCount"] ?? 0) > 0
                                            ? "Supervisor uploaded task files"
                                            : "Waiting for supervisor",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (isUnlocked) ...[
                                  const SizedBox(height: 16),
                                  GestureDetector(
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) => StudentTaskDetailPage(
                                                projectId: widget.projectId,
                                                taskId: task["taskId"],
                                              ),
                                        ),
                                      );
                                      await _loadTasks();
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                        horizontal: 20,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color.fromARGB(255, 24, 81, 91),
                                            Color.fromARGB(255, 133, 213, 231),
                                          ],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color.fromARGB(
                                              255,
                                              24,
                                              81,
                                              91,
                                            ).withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.visibility,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            "View Task Details",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color:
                                          isCompleted
                                              ? Colors.green.withOpacity(0.1)
                                              : const Color.fromARGB(
                                                255,
                                                133,
                                                213,
                                                231,
                                              ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color:
                                            isCompleted
                                                ? Colors.green.withOpacity(0.3)
                                                : const Color.fromARGB(
                                                  255,
                                                  133,
                                                  213,
                                                  231,
                                                ).withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isCompleted
                                              ? Icons.check_circle_outline
                                              : Icons.upload_file,
                                          size: 16,
                                          color:
                                              isCompleted
                                                  ? Colors.green
                                                  : const Color.fromARGB(
                                                    255,
                                                    24,
                                                    81,
                                                    91,
                                                  ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            isCompleted
                                                ? "You have submitted this task."
                                                : "You can upload your file in task details.",
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color:
                                                  isCompleted
                                                      ? Colors.green[700]
                                                      : const Color.fromARGB(
                                                        255,
                                                        24,
                                                        81,
                                                        91,
                                                      ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
