import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fyp_connect/auth/auth_service.dart';
import 'package:fyp_connect/auth/cloudinary_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp_connect/chats%20and%20notifications/notifications/services/send_notification_service.dart';

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
  final _studentNameController = TextEditingController();
  final _regNoController = TextEditingController();
  final _groupMembersController = TextEditingController();
  final _projectTitleController = TextEditingController();
  final _proposalController = TextEditingController();
  final AuthService _authService = AuthService();

  File? _selectedFile;
  final CloudinaryService _cloudinaryService = CloudinaryService();

  String? _uploadedFileName;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _studentNameController.dispose();
    _regNoController.dispose();
    _groupMembersController.dispose();
    _projectTitleController.dispose();
    _proposalController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _uploadedFileName = result.files.single.name;
          _selectedFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('Error selecting file'),
            ],
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> updateProposalStatus(String docId, String status) async {
    try {
      final proposalDoc =
          await FirebaseFirestore.instance
              .collection('proposals')
              .doc(docId)
              .get();

      if (!proposalDoc.exists) return;

      final data = proposalDoc.data()!;
      final studentName =
          FirebaseAuth.instance.currentUser?.displayName ?? 'Supervisor';

      final supervisorId = data['supervisorId'] ?? '';

      // 2️⃣ Notify only this supervisor
      if (supervisorId.isNotEmpty) {
        final supervisorDoc =
            await FirebaseFirestore.instance
                .collection('students')
                .doc(supervisorId)
                .get();

        final token = supervisorDoc.data()?['pushToken'] ?? '';

        if (token.isNotEmpty) {
          await SendNotificationService.sendNotificationUsingApi(
            token: token,
            title: 'Proposal $status',
            body: 'New Proposal sent by $studentName.',
            data: {'screen': 'proposal'},
          );
        }

        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(supervisorId)
            .collection('notifications')
            .add({
              'title': 'Proposal $status',
              'body': 'New Proposal sent by $studentName.',
              'isSeen': false,
              'createdAt': FieldValue.serverTimestamp(),
            });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
    }
  }

  Future<void> _submitProposal() async {
    if (_formKey.currentState!.validate()) {
      if (_uploadedFileName == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Please upload your proposal file'),
              ],
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        return;
      }

      try {
        setState(() {
          _isSubmitting = true;
        });

        String? uploadedUrl;

        if (_selectedFile != null) {
          uploadedUrl = await _cloudinaryService.uploadFile(_selectedFile!);
        }

        if (uploadedUrl == null) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('File upload failed'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Submit proposal with status 'pending'
        final proposalId = await _authService.submitProposal(
          studentName: _studentNameController.text.trim(),
          regNo: _regNoController.text.trim(),
          groupMembers: _groupMembersController.text.trim(),
          projectTitle: _projectTitleController.text.trim(),
          projectProposal: _proposalController.text.trim(),
          supervisorName: widget.supervisorName,
          facultyId: widget.supervisorId, // e.g., "Fac-65"
          fileUrl: uploadedUrl,
          status: 'pending',
        );

        // -----------------------------
        // SEND NOTIFICATION TO SUPERVISOR
        // -----------------------------
        try {
          final studentName = _studentNameController.text.trim();
          final projectTitle = _projectTitleController.text.trim();

          // 1️⃣ Get supervisor UID using facultyId
          final supervisorProfile =
              await FirebaseFirestore.instance
                  .collection('supervisor_profiles')
                  .doc(widget.supervisorId) // docId = facultyId (e.g. "Fac-65")
                  .get();

          if (!supervisorProfile.exists) {
            debugPrint(
              "❌ Supervisor profile not found for facultyId: ${widget.supervisorId}",
            );
            return;
          }

          final supervisorUid = supervisorProfile.data()?['userId'];
          if (supervisorUid == null || supervisorUid.isEmpty) {
            debugPrint(
              "❌ Supervisor UID missing in profile: ${widget.supervisorId}",
            );
            return;
          }

          // 2️⃣ Save Firestore notification under supervisor UID
          await FirebaseFirestore.instance
              .collection('notifications')
              .doc(supervisorUid) // ✅ correct place
              .collection('notifications')
              .add({
                'title': 'New Proposal Request',
                'body': '$studentName submitted a proposal "$projectTitle"',
                'isSeen': false,
                'createdAt': FieldValue.serverTimestamp(),
                'proposalId': proposalId,
              });

          // 3️⃣ Push notification
          final supervisorDoc =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(supervisorUid)
                  .get();

          final pushToken = supervisorDoc.data()?['pushToken'] ?? '';

          if (pushToken.isNotEmpty) {
            await SendNotificationService.sendNotificationUsingApi(
              token: pushToken,
              title: 'New Proposal Request',
              body: '$studentName submitted a proposal "$projectTitle"',
              data: {'screen': 'proposal_requests'},
            );
          }

          debugPrint("✅ Notification sent to supervisor UID: $supervisorUid");
        } catch (e) {
          debugPrint('❌ Supervisor notification error: $e');
        }

        setState(() {
          _isSubmitting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Proposal submitted successfully! 🎉'),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );

        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pop(context);
        });
      } catch (e) {
        setState(() {
          _isSubmitting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Submission failed. Try again.'),
              ],
            ),
            backgroundColor: Colors.red[600],
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

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color iconColor,
    String? hintText,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Submit Proposal',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 24, 81, 91),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Header Section
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
                          'Submit Your Proposal',
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
                    // Supervisor Info Card
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

                    // Form Fields
                    _buildFormField(
                      controller: _studentNameController,
                      label: 'Student Name',
                      icon: Icons.person_outline,
                      iconColor: const Color.fromARGB(255, 24, 81, 91),
                      hintText: 'Enter your full name',
                      validator:
                          (value) =>
                              value!.isEmpty
                                  ? 'Student name is required'
                                  : null,
                    ),
                    _buildFormField(
                      controller: _regNoController,
                      label: 'Registration Number',
                      icon: Icons.badge_outlined,
                      iconColor: Colors.blue,
                      hintText: 'e.g., SP22-BCS-023',
                      validator:
                          (value) =>
                              value!.isEmpty
                                  ? 'Registration number is required'
                                  : null,
                    ),
                    _buildFormField(
                      controller: _groupMembersController,
                      label: 'Group Members',
                      icon: Icons.group_outlined,
                      iconColor: Colors.green,
                      hintText: 'Name - Reg No (one per line)',
                      maxLines: 3,
                      validator:
                          (value) =>
                              value!.isEmpty
                                  ? 'Group members are required'
                                  : null,
                    ),
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
                    _buildFormField(
                      controller: _proposalController,
                      label: 'Project Proposal',
                      icon: Icons.description_outlined,
                      iconColor: Colors.purple,
                      hintText: 'Describe your project proposal in detail...',
                      maxLines: 8,
                      validator: (value) {
                        if (value == null || value.trim().length < 5) {
                          return 'Proposal must be at least 5 characters';
                        }
                        return null;
                      },
                    ),

                    // File Upload Section
                    Container(
                      margin: const EdgeInsets.only(bottom: 30),
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
                                    color: Colors.teal.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.attach_file_outlined,
                                    color: Colors.teal,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Upload Proposal Document',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_uploadedFileName != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.green.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _uploadedFileName!,
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.green,
                                        size: 18,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _uploadedFileName = null;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _pickFile,
                                icon: const Icon(Icons.upload_file, size: 20),
                                label: Text(
                                  _uploadedFileName != null
                                      ? 'Change File'
                                      : 'Choose File',
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.teal,
                                  side: const BorderSide(color: Colors.teal),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Supported formats: PDF, DOC, DOCX',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Submit Button
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
                          _isSubmitting ? 'Submitting...' : 'Submit Proposal',
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

                    // Info Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue[600],
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Make sure your proposal is detailed and includes all necessary information. You will receive a response within 3-5 business days.',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
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
