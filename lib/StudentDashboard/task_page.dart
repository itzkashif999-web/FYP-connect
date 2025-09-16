import 'package:flutter/material.dart';

class TaskPage extends StatefulWidget {
  final String taskTitle;
  final int taskIndex;
  final bool isUnlocked;
  final List<bool> initialSubtasks;
  final Function(int, List<bool>) onTaskComplete;

  const TaskPage({
    super.key,
    required this.taskTitle,
    required this.taskIndex,
    required this.isUnlocked,
    required this.initialSubtasks,
    required this.onTaskComplete,
  });

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  late List<bool> _subtasksCompleted;

  @override
  void initState() {
    super.initState();
    _subtasksCompleted = List.from(widget.initialSubtasks);
  }

  void _updateTaskStatus() {
    widget.onTaskComplete(widget.taskIndex, _subtasksCompleted);
  }

  @override
  Widget build(BuildContext context) {
    final allDone = _subtasksCompleted.every((done) => done);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.taskTitle),
        backgroundColor: Color.fromARGB(255, 24, 81, 91),
      ),
      body:
          widget.isUnlocked
              ? Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: List.generate(3, (index) {
                    return CheckboxListTile(
                      title: Text('Subtask ${index + 1}'),
                      value: _subtasksCompleted[index],
                      onChanged:
                          allDone
                              ? null
                              : (value) {
                                setState(() {
                                  _subtasksCompleted[index] = value!;
                                  _updateTaskStatus();
                                });
                              },
                    );
                  }),
                ),
              )
              : const Center(
                child: Text(
                  'This task is locked. Complete the previous task first.',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
    );
  }
}
