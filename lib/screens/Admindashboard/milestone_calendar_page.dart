import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MilestoneCalendarPage extends StatefulWidget {
  const MilestoneCalendarPage({super.key});

  @override
  _MilestoneCalendarPageState createState() => _MilestoneCalendarPageState();
}

class _MilestoneCalendarPageState extends State<MilestoneCalendarPage> {
  static const Color primaryDark = Color.fromARGB(255, 24, 81, 91);
  static const Color primaryLight = Color.fromARGB(255, 133, 213, 231);
  static const Color surfaceColor = Color.fromARGB(255, 248, 250, 252);
  static const Color cardColor = Colors.white;

  late Map<DateTime, List<Map<String, dynamic>>> _milestones;
  late DateTime _focusedDay;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay;
    _milestones = {};
    _loadMilestones();
  }

  Future<void> _loadMilestones() async {
    final snapshot =
        await FirebaseFirestore.instance.collection("milestones").get();

    Map<DateTime, List<Map<String, dynamic>>> fetched = {};

    for (var doc in snapshot.docs) {
      DateTime date = (doc['date'] as Timestamp).toDate();
      String title = doc['title'];
      DateTime normalized = DateTime.utc(date.year, date.month, date.day);

      fetched.putIfAbsent(normalized, () => []);
      fetched[normalized]!.add({"id": doc.id, "title": title, "date": date});
    }

    setState(() {
      _milestones = fetched;
    });
  }

  Future<void> _addMilestone(DateTime date, String title) async {
    await FirebaseFirestore.instance.collection("milestones").add({
      "title": title,
      "date": date,
    });
    _loadMilestones();
  }

  Future<void> _editMilestone(String id, DateTime date, String title) async {
    await FirebaseFirestore.instance.collection("milestones").doc(id).update({
      "title": title,
      "date": date,
    });
    _loadMilestones();
  }

  Future<void> _deleteMilestone(String id) async {
    await FirebaseFirestore.instance.collection("milestones").doc(id).delete();
    _loadMilestones();
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _milestones[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  void _showMilestoneDialog({Map<String, dynamic>? milestone}) {
    DateTime pickedDate = milestone != null ? milestone['date'] : _focusedDay;
    TextEditingController controller = TextEditingController(
      text: milestone != null ? milestone['title'] : "",
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryLight.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    milestone == null ? Icons.add_task : Icons.edit_note,
                    color: primaryDark,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    milestone == null ? "Add Milestone" : "Edit Milestone",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: primaryDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: "Milestone Title",
                    labelStyle: TextStyle(color: primaryDark.withOpacity(0.7)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: primaryDark, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: primaryDark, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: primaryDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        DateTime? date = await showDatePicker(
                          context: context,
                          initialDate: pickedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: primaryDark,
                                  onPrimary: Colors.white,
                                  surface: cardColor,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (date != null) {
                          setState(() {
                            pickedDate = date;
                          });
                        }
                      },
                      icon: const Icon(Icons.edit_calendar, size: 16),
                      label: const Text("Change"),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              if (milestone != null)
                TextButton.icon(
                  onPressed: () {
                    _deleteMilestone(milestone['id']);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text("Delete"),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    if (milestone == null) {
                      _addMilestone(pickedDate, controller.text.trim());
                    } else {
                      _editMilestone(
                        milestone['id'],
                        pickedDate,
                        controller.text.trim(),
                      );
                    }
                    Navigator.pop(context);
                  }
                },
                icon: Icon(
                  milestone == null ? Icons.add : Icons.save,
                  size: 18,
                ),
                label: Text(
                  milestone == null ? "Add" : "Save",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(backgroundColor: primaryDark),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Milestone Calendar"),
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      backgroundColor: surfaceColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              /// Calendar
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },

                  // ✅ Force month view only
                  calendarFormat: CalendarFormat.month,
                  availableCalendarFormats: const {
                    CalendarFormat.month: 'Month',
                  },

                  headerStyle: HeaderStyle(
                    formatButtonVisible:
                        false, // ✅ Hide the format toggle button
                    titleCentered: true,
                  ),
                  eventLoader:
                      (day) =>
                          _getEventsForDay(day).map((e) => e['title']).toList(),
                ),
              ),

              /// Milestone header
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_note, size: 20, color: primaryDark),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedDay != null
                            ? "Milestones for ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}"
                            : "Select a date to view milestones",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: primaryDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: primaryDark,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${_getEventsForDay(_selectedDay!).length}",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              /// Events
              _getEventsForDay(_selectedDay!).isEmpty
                  ? Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_available,
                          size: 48,
                          color: primaryDark.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No milestones for this day",
                          style: TextStyle(color: primaryDark.withOpacity(0.6)),
                        ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    shrinkWrap: true, // ✅ Important for scroll inside Column
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _getEventsForDay(_selectedDay!).length,
                    itemBuilder: (context, index) {
                      final event = _getEventsForDay(_selectedDay!)[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text(
                            event['title'],
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: const Text("Milestone"),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed:
                                () => _showMilestoneDialog(milestone: event),
                          ),
                        ),
                      );
                    },
                  ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showMilestoneDialog(),
        backgroundColor: primaryDark,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
