import 'package:flutter/material.dart';
import 'package:fyp_connect/SupervisorDashboard/supervisor_meeting_page.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SupervisorScheduleMeetingPage extends StatefulWidget {
  final String studentId;

  const SupervisorScheduleMeetingPage({super.key, required this.studentId});

  @override
  State<SupervisorScheduleMeetingPage> createState() =>
      _SupervisorScheduleMeetingPageState();
}

class _SupervisorScheduleMeetingPageState
    extends State<SupervisorScheduleMeetingPage> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final _purposeController = TextEditingController();

  @override
  void dispose() {
    _purposeController.dispose();
    super.dispose();
  }

  Future<void> _scheduleMeeting() async {
    if (_selectedDate == null ||
        _selectedTime == null ||
        _purposeController.text.trim().isEmpty) {
      _showSnackBar("Please fill in all required fields", isError: true);
      return;
    }

    final selectedDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    try {
      final supervisorId = FirebaseAuth.instance.currentUser!.uid;

      // Save meeting and get document reference
      final meetingDoc = await FirebaseFirestore.instance
          .collection("meetings")
          .add({
            "studentId": widget.studentId,
            "supervisorId": supervisorId,
            "dateTime": selectedDateTime,
            "purpose": _purposeController.text.trim(),
            "status": "pending",
            "requestedBy": "supervisor",
            "createdAt": FieldValue.serverTimestamp(),
          });

      // Send notification to student
      _sendNotificationToStudent(widget.studentId, meetingDoc.id);

      _showSnackBar("Meeting request sent successfully!", isError: false);

      setState(() {
        _selectedDate = null;
        _selectedTime = null;
        _purposeController.clear();
      });
    } catch (e) {
      _showSnackBar("Error scheduling meeting: $e", isError: true);
    }
  }

  void _sendNotificationToStudent(String studentId, String meetingId) async {
    try {
      var notificationRef = FirebaseFirestore.instance
          .collection('notifications')
          .doc(studentId)
          .collection('notifications')
          .doc(meetingId); // Use meetingId as document ID

      var supervisorDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser?.uid)
              .get();
      String supervisorName =
          supervisorDoc.data()?['name'] ?? 'Your supervisor';

      await notificationRef.set({
        'title': 'New Meeting Request',
        'body': '$supervisorName requested a meeting',
        'isSeen': false,
        'createdAt': FieldValue.serverTimestamp(),
        'meetingId': meetingId,
      });

      debugPrint(
        "✅ Notification saved for student: $studentId, meetingId: $meetingId",
      );
    } catch (e) {
      debugPrint("❌ Error sending notification to student: $e");
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Schedule Meeting',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 24, 81, 91),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildFormUI(),
    );
  }

  Widget _buildFormUI() {
    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 24),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _buildDateCard(),
                _buildTimeCard(),
                _buildPurposeCard(),
                _buildScheduleButton(),
                _buildViewMeetingsButton(),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.fromARGB(255, 24, 81, 91),
          Color.fromARGB(255, 133, 213, 231),
        ],
      ),
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(30),
        bottomRight: Radius.circular(30),
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.event_available,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Book Meeting with Student',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Schedule a meeting with your student',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildDateCard() => _buildCard(
    icon: Icons.calendar_today_rounded,
    iconColor: const Color.fromARGB(255, 133, 213, 231),
    title: "Select Date",
    subtitle:
        _selectedDate != null
            ? DateFormat('EEEE, MMMM d, y').format(_selectedDate!)
            : "Choose your preferred date",
    onTap: () async {
      final date = await showDatePicker(
        context: context,
        initialDate: DateTime.now().add(const Duration(days: 1)),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 30)),
      );
      if (date != null) setState(() => _selectedDate = date);
    },
  );

  Widget _buildTimeCard() => _buildCard(
    icon: Icons.access_time_rounded,
    iconColor: Colors.blue,
    title: "Select Time",
    subtitle: _selectedTime?.format(context) ?? "Choose your preferred time",
    onTap: () async {
      final time = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 10, minute: 0),
      );
      if (time != null) setState(() => _selectedTime = time);
    },
  );

  Widget _buildPurposeCard() => Container(
    margin: const EdgeInsets.only(bottom: 30),
    decoration: _cardDecoration(),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.description_rounded,
                  color: Colors.green,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                "Meeting Purpose",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _purposeController,
            maxLines: 4,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: "Describe the purpose of your meeting...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildScheduleButton() => Container(
    width: double.infinity,
    height: 56,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [
          Color.fromARGB(255, 24, 81, 91),
          Color.fromARGB(255, 133, 213, 231),
        ],
      ),
      borderRadius: BorderRadius.circular(16),
    ),
    child: ElevatedButton.icon(
      onPressed: _scheduleMeeting,
      icon: const Icon(
        Icons.event_available_rounded,
        color: Colors.white,
        size: 24,
      ),
      label: const Text(
        'Schedule Meeting',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );

  Widget _buildViewMeetingsButton() => Container(
    width: double.infinity,
    height: 56,
    margin: const EdgeInsets.only(top: 16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [
          Color.fromARGB(255, 133, 213, 231),
          Color.fromARGB(255, 24, 81, 91),
        ],
      ),
      borderRadius: BorderRadius.circular(16),
    ),
    child: ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => SupervisorMeetingPage(studentId: widget.studentId),
          ),
        );
      },
      icon: const Icon(Icons.meeting_room, color: Colors.white),
      label: const Text(
        'View Meetings',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );

  Widget _buildCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) => Container(
    margin: const EdgeInsets.only(bottom: 20),
    decoration: _cardDecoration(),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            subtitle.contains("Choose")
                                ? Colors.grey[500]
                                : Colors.grey[700],
                        fontWeight:
                            subtitle.contains("Choose")
                                ? FontWeight.normal
                                : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
    ),
  );

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: Colors.grey.withOpacity(0.08),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );
}
