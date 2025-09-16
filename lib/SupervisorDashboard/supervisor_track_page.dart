import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp_connect/SupervisorDashboard/supervisor_task_detail_page.dart';

class SupervisorTrackPage extends StatefulWidget {
  final String projectId;
  const SupervisorTrackPage({super.key, required this.projectId});

  @override
  State<SupervisorTrackPage> createState() => _SupervisorTrackPageState();
}

class _SupervisorTrackPageState extends State<SupervisorTrackPage> {
  List<Map<String, dynamic>> _tasks = [];
  String? projectTitle;

  static const Color primaryDark = Color.fromARGB(255, 24, 81, 91);
  static const Color primaryLight = Color.fromARGB(255, 133, 213, 231);
  static const Color accentColor = Color.fromARGB(255, 45, 125, 140);

  @override
  void initState() {
    super.initState();
    _loadProjectTitle();
    _loadTasks();
  }

  Future<void> _loadProjectTitle() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection("projects")
              .doc(widget.projectId)
              .get();

      setState(() {
        final data = doc.data();
        projectTitle =
            (doc.exists && data != null && data["title"] != null)
                ? data["title"]
                : "Project ${widget.projectId}";
      });
    } catch (e) {
      setState(() {
        projectTitle = "Project ${widget.projectId}";
      });
      print("Failed to load project title: $e");
    }
  }

  Future<void> _loadTasks() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection("projects")
            .doc(widget.projectId)
            .collection("tasks")
            .get();

    // Map milestone IDs to formatted milestone titles
    final milestoneTitles = {
      "m10": "Milestone: 01 (10%)",
      "m30": "Milestone: 02 (30%)",
      "m60": "Milestone: 03 (60%)",
      "m100": "Milestone: 04 (100%)",
    };

    final defaultTasks = [
      {"id": "m10", "title": "Milestone: 01"},
      {"id": "m30", "title": "Milestone: 02"},
      {"id": "m60", "title": "Milestone: 03"},
      {"id": "m100", "title": "Milestone: 04"},
    ];

    List<Map<String, dynamic>> loadedTasks = [];

    for (var task in defaultTasks) {
      QueryDocumentSnapshot<Map<String, dynamic>>? doc;

      for (var d
          in snapshot.docs
              .cast<QueryDocumentSnapshot<Map<String, dynamic>>>()) {
        if (d.data()["milestoneId"] == task["id"]) {
          doc = d;
          break;
        }
      }

      if (doc != null) {
        final data = doc.data();
        final supervisorFilesSnapshot =
            await doc.reference.collection("supervisorFiles").get();

        int submittedCount =
            supervisorFilesSnapshot.docs
                .where(
                  (f) =>
                      (f.data()["status"] ?? "").toString().toLowerCase() ==
                      "submitted",
                )
                .length;

        loadedTasks.add({
          "id": data["milestoneId"] ?? task["id"],
          "title": milestoneTitles[data["milestoneId"]] ?? task["title"],
          "supervisorHasFiles": supervisorFilesSnapshot.docs.isNotEmpty,
          "supervisorFileCount": supervisorFilesSnapshot.docs.length,
          "submittedCount": submittedCount,
          "studentFile": data["studentFile"] ?? "",
          "description": data["description"] ?? "",
          "released": data["released"] ?? false,
          "deadline":
              data["endDate"] != null
                  ? (data["endDate"] as Timestamp).toDate()
                  : null,
          "docRef": doc.reference,
        });
      } else {
        loadedTasks.add({
          "id": task["id"],
          "title": milestoneTitles[task["id"]] ?? task["title"],
          "supervisorHasFiles": false,
          "supervisorFileCount": 0,
          "submittedCount": 0,
          "studentFile": "",
          "description": "",
          "released": false,
          "deadline": null,
          "docRef": null,
        });
      }
    }

    setState(() {
      _tasks = loadedTasks;
    });
  }

  Future<void> _createTaskIfMissing(Map<String, dynamic> task) async {
    if (task["docRef"] != null) return;

    final newDoc = FirebaseFirestore.instance
        .collection("projects")
        .doc(widget.projectId)
        .collection("tasks")
        .doc(task["id"]);

    await newDoc.set({
      "milestoneId": task["id"],
      "title": task["title"],
      "description": "",
      "released": false,
      "studentFile": {},
      "endDate": null,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  double calculateMilestoneProgress(Map<String, dynamic> task) {
    int total = task["supervisorFileCount"] ?? 0;
    int submitted = task["submittedCount"] ?? 0;
    return total == 0 ? 0.0 : submitted / total;
  }

  double getMilestoneWeight(String milestoneId) {
    switch (milestoneId) {
      case "m10":
        return 0.1;
      case "m30":
        return 0.3;
      case "m60":
        return 0.6;
      case "m100":
        return 1.0;
      default:
        return 0.0;
    }
  }

  double calculateOverallProgress() {
    double overall = 0.0;
    for (var task in _tasks) {
      final milestoneProgress = calculateMilestoneProgress(task);
      if (milestoneProgress == 1.0) {
        overall = getMilestoneWeight(task["id"]);
      } else {
        break; // Stop at first incomplete milestone
      }
    }
    return overall.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final overallProgress = calculateOverallProgress();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Track Project",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryDark,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryDark, accentColor],
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primaryLight.withOpacity(0.1), Colors.white],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(
                        Icons.track_changes,
                        color: Color.fromARGB(255, 24, 81, 91),
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
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
                        tween: Tween<double>(begin: 0.0, end: overallProgress),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeInOut,
                        builder: (context, value, child) {
                          return LinearProgressIndicator(
                            value: value,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              value == 1.0
                                  ? Colors.green
                                  : const Color.fromARGB(255, 133, 213, 231),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${(overallProgress * 100).toInt()}% Complete",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child:
                  _tasks.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                primaryDark,
                              ),
                              strokeWidth: 3,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Loading tasks...",
                              style: TextStyle(
                                color: primaryDark,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _tasks.length,
                        itemBuilder: (context, index) {
                          final task = _tasks[index];

                          bool isUnlocked = true;
                          for (int i = 0; i < index; i++) {
                            if (_tasks[i]["supervisorHasFiles"] != true) {
                              isUnlocked = false;
                              break;
                            }
                          }

                          final milestoneProgress = calculateMilestoneProgress(
                            task,
                          );
                          final isCompleted = milestoneProgress == 1.0;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Card(
                              elevation: isUnlocked ? 4 : 2,
                              shadowColor: primaryDark.withOpacity(0.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color:
                                      isCompleted
                                          ? Colors.green.withOpacity(0.3)
                                          : isUnlocked
                                          ? primaryLight
                                          : Colors.grey.shade300,
                                  width: 1.5,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          task["title"],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const Spacer(),
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
                                                    ? primaryLight
                                                    : Colors.grey,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            isCompleted
                                                ? "COMPLETED"
                                                : isUnlocked
                                                ? "UNLOCKED"
                                                : "LOCKED",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: milestoneProgress,
                                        minHeight: 10,
                                        backgroundColor: Colors.grey[200],
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              isCompleted
                                                  ? Colors.green
                                                  : primaryLight,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "${(milestoneProgress * 100).toInt()}% Complete",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    if (isUnlocked) ...[
                                      const SizedBox(height: 8),
                                      GestureDetector(
                                        onTap: () async {
                                          await _createTaskIfMissing(task);
                                          if (!mounted) return;
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) =>
                                                      SupervisorTaskDetailPage(
                                                        projectId:
                                                            widget.projectId,
                                                        taskId: task["id"],
                                                      ),
                                            ),
                                          ).then((_) => _loadTasks());
                                        },
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                            horizontal: 16,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                primaryDark,
                                                primaryLight,
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: const Center(
                                            child: Text(
                                              "View Task Details",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
