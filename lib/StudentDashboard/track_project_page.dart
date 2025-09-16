import 'package:flutter/material.dart';
import 'task_page.dart';

class TrackProjectPage extends StatefulWidget {
  const TrackProjectPage({super.key});

  @override
  State<TrackProjectPage> createState() => _TrackProjectPageState();
}

class _TrackProjectPageState extends State<TrackProjectPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final String _projectStatus = 'Pending';

  final List<Map<String, dynamic>> _tasks = [
    {
      'title': '10% Task',
      'progress': 0.0,
      'completed': false,
      'subtasks': [false, false, false],
    },
    {
      'title': '30% Task',
      'progress': 0.0,
      'completed': false,
      'subtasks': [false, false, false],
    },
    {
      'title': '60% Task',
      'progress': 0.0,
      'completed': false,
      'subtasks': [false, false, false],
    },
    {
      'title': 'Final Task',
      'progress': 0.0,
      'completed': false,
      'subtasks': [false, false, false],
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _handleTaskCompletion(int index, List<bool> subtasks) {
    setState(() {
      final completedCount = subtasks.where((e) => e).length;
      final progress = completedCount / 3;

      _tasks[index]['progress'] = progress;
      _tasks[index]['completed'] = progress == 1.0;
      _tasks[index]['subtasks'] = subtasks;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Track Project',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color.fromARGB(255, 24, 81, 91),
        iconTheme: const IconThemeData(color: Colors.white),

        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [Tab(text: 'Project Status'), Tab(text: 'Milestones')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Project Status Tab
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Current Project Status:',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 10),
                Chip(
                  label: Text(
                    _projectStatus,
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.orange,
                ),
              ],
            ),
          ),

          // Milestones Tab
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _tasks.length,
            itemBuilder: (context, index) {
              final task = _tasks[index];
              final isUnlocked =
                  index == 0 || _tasks[index - 1]['completed'] == true;

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  title: Text(task['title']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinearProgressIndicator(
                        value: task['progress'],
                        backgroundColor: Colors.grey[300],
                        color: isUnlocked ? Colors.green : Colors.grey,
                        minHeight: 8,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task['completed'] ? 'Completed' : 'In Progress',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              task['completed'] ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  trailing: Icon(
                    task['completed'] ? Icons.check_circle : Icons.lock_open,
                    color: task['completed'] ? Colors.green : Colors.grey,
                  ),
                  onTap: () {
                    if (task['completed']) return; // prevent reopening

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => TaskPage(
                              taskTitle: task['title'],
                              taskIndex: index,
                              isUnlocked: isUnlocked,
                              initialSubtasks: List<bool>.from(
                                task['subtasks'],
                              ),
                              onTaskComplete: _handleTaskCompletion,
                            ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
