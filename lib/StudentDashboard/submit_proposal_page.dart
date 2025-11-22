import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/auth_service.dart'; // replace with your actual path
import 'recommendation_tracking_service.dart';

class SubmitProposalPage extends StatefulWidget {
  final String supervisorName;
  final String supervisorId;

  const SubmitProposalPage({
    super.key,
    required this.supervisorName,
    required this.supervisorId,
  });

  @override
  State<SubmitProposalPage> createState() => _SubmitProposalPageState();
}

class _SubmitProposalPageState extends State<SubmitProposalPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _studentNameController = TextEditingController();
  final TextEditingController _regNoController = TextEditingController();
  final TextEditingController _projectTitleController = TextEditingController();
  final TextEditingController _projectDescriptionController =
      TextEditingController(); // New field

  final AuthService _authService = AuthService();
  final RecommendationTrackingService _trackingService = RecommendationTrackingService();
  bool _isSubmitting = false;

  List<Map<String, String>> _availableStudents = [];
  final List<String?> _selectedMemberUids = [];

  @override
  void initState() {
    super.initState();
    _loadStudentInfo();
    _loadStudents();
  }

  Future<void> _loadStudentInfo() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        setState(() {
          _studentNameController.text = doc['name'] ?? '';
          _regNoController.text = doc['registrationNo'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading student info: $e');
    }
  }

  Future<void> _loadStudents() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser!.uid;
      List<Map<String, String>> students = [];

      final snapshot =
          await FirebaseFirestore.instance.collection('addusers').get();

      for (var doc in snapshot.docs) {
        final studentsSnap =
            await doc.reference.collection('add_students').get();
        for (var sDoc in studentsSnap.docs) {
          final studentUid = sDoc['uid'] ?? '';
          if (studentUid != currentUserId) {
            students.add({
              'name': sDoc['name'] ?? '',
              'regNo': sDoc['registrationNo'] ?? '',
              'uid': studentUid,
            });
          }
        }
      }

      setState(() {
        _availableStudents = students;
      });
    } catch (e) {
      debugPrint("❌ Error loading students: $e");
    }
  }

  @override
  void dispose() {
    _studentNameController.dispose();
    _regNoController.dispose();
    _projectTitleController.dispose();
    _projectDescriptionController.dispose(); // Dispose new field
    super.dispose();
  }

  Future<void> _submitProposal() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedMemberUids.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least 1 group member'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      try {
        setState(() => _isSubmitting = true);

        // Convert selected UIDs to student info string
        final groupMembersText = _selectedMemberUids
            .map((uid) {
              final student = _availableStudents.firstWhere(
                (s) => s['uid'] == uid,
              );
              return '${student['name']} - ${student['regNo']}';
            })
            .join('\n');

        final proposalId = await _authService.submitProposal(
          studentName: _studentNameController.text.trim(),
          regNo: _regNoController.text.trim(),
          groupMembers: groupMembersText,
          projectTitle: _projectTitleController.text.trim(),
          projectDescription:
              _projectDescriptionController.text.trim(), // Added field
          supervisorName: widget.supervisorName,
          facultyId: widget.supervisorId,
          fileUrl: '',
          status: 'pending',
        );

        final supervisorProfile =
            await FirebaseFirestore.instance
                .collection('supervisor_profiles')
                .doc(widget.supervisorId)
                .get();

        final supervisorUid = supervisorProfile.data()?['userId'] ?? '';
        if (supervisorUid.isNotEmpty) {
          _sendProposalNotificationToSupervisor(
            supervisorUid,
            proposalId,
            _projectTitleController.text.trim(),
          );
        }

        // Track supervisor acceptance for precision calculation
        await _trackingService.trackSupervisorAccepted(
          supervisorId: widget.supervisorId,
        );

        setState(() => _isSubmitting = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Proposal submitted successfully! 🎉'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );

        Future.delayed(
          const Duration(seconds: 1),
          () => Navigator.pop(context),
        );
      } catch (e) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Submission failed. Try again.'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  void _sendProposalNotificationToSupervisor(
    String supervisorId,
    String proposalId,
    String projectTitle,
  ) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (supervisorId == currentUserId) return;

      final notificationRef = FirebaseFirestore.instance
          .collection('notifications')
          .doc(supervisorId)
          .collection('notifications')
          .doc(proposalId);

      final studentDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUserId)
              .get();
      final studentName = studentDoc.data()?['name'] ?? 'A student';

      await notificationRef.set({
        'title': 'New Proposal Request',
        'body': '$studentName submitted a proposal request "$projectTitle"',
        'isSeen': false,
        'createdAt': FieldValue.serverTimestamp(),
        'proposalId': proposalId,
      });
    } catch (e) {
      debugPrint("❌ Error sending proposal notification: $e");
    }
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color iconColor,
    String? hintText,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool readOnly = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controller,
              validator: validator,
              keyboardType: keyboardType,
              maxLines: maxLines,
              readOnly: readOnly,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: hintText ?? 'Enter $label',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: iconColor, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red, width: 1),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                contentPadding: const EdgeInsets.all(16),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupMemberDropdown(int index) {
    String? selectedUid =
        index < _selectedMemberUids.length ? _selectedMemberUids[index] : null;

    List<DropdownMenuItem<String>> items =
        _availableStudents
            .where(
              (s) =>
                  !(_selectedMemberUids.contains(s['uid']) &&
                      s['uid'] != selectedUid),
            )
            .map(
              (student) => DropdownMenuItem<String>(
                value: student['uid'],
                child: Text('${student['name']} - ${student['regNo']}'),
              ),
            )
            .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonFormField<String>(
        hint: Text('Select Member ${index + 1}'),
        value: selectedUid,
        items: items,
        onChanged: (value) {
          if (value == null) return;
          setState(() {
            if (index < _selectedMemberUids.length) {
              _selectedMemberUids[index] = value;
            } else {
              _selectedMemberUids.add(value);
            }
          });
        },
        validator:
            (value) => value == null ? 'Select member ${index + 1}' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Submit Proposal Request',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 24, 81, 91),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
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
                      Icons.assignment_turned_in,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Submit Your Proposal Request',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'To: ${widget.supervisorName}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
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
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Student info card
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.08),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Color.fromARGB(255, 24, 81, 91),
                                  Color.fromARGB(255, 133, 213, 231),
                                ],
                              ),
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Submitting to:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.supervisorName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2D3748),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildFormField(
                      controller: _studentNameController,
                      label: 'Student Name',
                      icon: Icons.person_outline,
                      iconColor: const Color.fromARGB(255, 24, 81, 91),
                      readOnly: true,
                    ),
                    _buildFormField(
                      controller: _regNoController,
                      label: 'Registration Number',
                      icon: Icons.badge_outlined,
                      iconColor: Colors.blue,
                      readOnly: true,
                    ),
                    _buildGroupMemberDropdown(0),
                    _buildGroupMemberDropdown(1),
                    _buildFormField(
                      controller: _projectTitleController,
                      label: 'Project Title',
                      icon: Icons.title_outlined,
                      iconColor: Colors.orange,
                      hintText: 'Enter your project title',
                      validator:
                          (value) =>
                              value!.isEmpty
                                  ? 'Project title is required'
                                  : null,
                    ),
                    // NEW: Project Description field
                    _buildFormField(
                      controller: _projectDescriptionController,
                      label: 'Project Description',
                      icon: Icons.description_outlined,
                      iconColor: Colors.purple,
                      hintText:
                          'Enter a brief project description (max 1 paragraph)',
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Project description is required';
                        }
                        if (value.trim().contains('\n\n')) {
                          return 'Only one paragraph allowed';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    // Submit button
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color.fromARGB(255, 24, 148, 51),
                            Color.fromARGB(255, 90, 153, 205),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromARGB(
                              255,
                              139,
                              46,
                              46,
                            ).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submitProposal,
                        icon:
                            _isSubmitting
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Icon(
                                  Icons.send_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                        label: Text(
                          _isSubmitting
                              ? 'Submitting...'
                              : 'Submit Proposal Request',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
