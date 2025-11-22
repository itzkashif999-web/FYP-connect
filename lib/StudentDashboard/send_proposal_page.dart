// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:fyp_connect/auth/cloudinary_service.dart';

// class SendProposalPage extends StatefulWidget {
//   final String supervisorId;
//   final String supervisorName;

//   const SendProposalPage({
//     super.key,
//     required this.supervisorId,
//     required this.supervisorName,
//   });

//   @override
//   State<SendProposalPage> createState() => _SendProposalPageState();
// }

// class _SendProposalPageState extends State<SendProposalPage> {
//   final CloudinaryService _cloudinaryService = CloudinaryService();

//   File? _selectedFile;
//   String? _uploadedFileName;
//   bool _isUploading = false;

//   Map<String, dynamic>? studentData;

//   @override
//   void initState() {
//     super.initState();
//     _fetchStudentData();
//   }

//   Future<void> _fetchStudentData() async {
//     final uid = FirebaseAuth.instance.currentUser?.uid;
//     if (uid == null) return;

//     final doc =
//         await FirebaseFirestore.instance.collection('students').doc(uid).get();
//     if (!doc.exists) return;

//     setState(() {
//       studentData = doc.data();
//     });
//   }

//   Future<void> _pickFile() async {
//     try {
//       FilePickerResult? result = await FilePicker.platform.pickFiles(
//         type: FileType.custom,
//         allowedExtensions: ['pdf', 'doc', 'docx'],
//       );

//       if (result != null && result.files.single.path != null) {
//         setState(() {
//           _uploadedFileName = result.files.single.name;
//           _selectedFile = File(result.files.single.path!);
//         });
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: const Row(
//             children: [
//               Icon(Icons.error_outline, color: Colors.white, size: 20),
//               SizedBox(width: 12),
//               Text('Error selecting file'),
//             ],
//           ),
//           backgroundColor: Colors.red[600],
//         ),
//       );
//     }
//   }

//   Future<void> _uploadProposal() async {
//     if (_selectedFile == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please select a file first.'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     if (studentData?['projectStatus'] != 'Active') {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(
//             'You cannot upload a proposal. Project status is not Active.',
//           ),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     setState(() => _isUploading = true);

//     try {
//       final uploadedUrl = await _cloudinaryService.uploadFile(_selectedFile!);

//       if (uploadedUrl != null) {
//         final uid = FirebaseAuth.instance.currentUser!.uid;

//         // 1️⃣ Update student's Firestore doc
//         await FirebaseFirestore.instance
//             .collection('students')
//             .doc(uid)
//             .update({
//               'proposalFileUrl': uploadedUrl,
//               'proposalFileName': _uploadedFileName,
//               'proposalSubmittedAt': FieldValue.serverTimestamp(),
//               'supervisorId': widget.supervisorId,
//               'supervisorName': widget.supervisorName,
//             });

//         // 2️⃣ Check if supervisor group already exists
//         final existingGroupQuery =
//             await FirebaseFirestore.instance
//                 .collection('supervisor_groups')
//                 .where('studentId', isEqualTo: uid)
//                 .where('supervisorId', isEqualTo: widget.supervisorId)
//                 .limit(1)
//                 .get();

//         if (existingGroupQuery.docs.isNotEmpty) {
//           // Update existing group
//           final groupDocId = existingGroupQuery.docs.first.id;
//           await FirebaseFirestore.instance
//               .collection('supervisor_groups')
//               .doc(groupDocId)
//               .update({
//                 'fileUrl': uploadedUrl,
//                 'updatedAt': FieldValue.serverTimestamp(),
//               });
//         } else {
//           // Create new group (only if not exists)
//           await FirebaseFirestore.instance.collection('supervisor_groups').add({
//             'studentId': uid,
//             'studentName': studentData?['name'] ?? '',
//             'registrationNumber': studentData?['regNo'] ?? '',
//             'groupMembers': studentData?['groupMembers'] ?? '',
//             'projectTitle': studentData?['projectTitle'] ?? '',
//             'fileUrl': uploadedUrl,
//             'supervisorId': widget.supervisorId,
//             'supervisorName': widget.supervisorName,
//             'createdAt': FieldValue.serverTimestamp(),
//           });
//         }

//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Proposal uploaded successfully! 🎉'),
//             backgroundColor: Colors.green,
//           ),
//         );

//         setState(() {
//           _selectedFile = null;
//           _uploadedFileName = null;
//         });
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('File upload failed.'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error uploading file: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } finally {
//       setState(() => _isUploading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (studentData == null) {
//       return const Scaffold(body: Center(child: CircularProgressIndicator()));
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Send Proposal'),
//         backgroundColor: const Color.fromARGB(255, 24, 81, 91),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Supervisor: ${widget.supervisorName}',
//               style: const TextStyle(fontSize: 16),
//             ),
//             const SizedBox(height: 20),
//             if (_uploadedFileName != null) ...[
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.green.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(
//                     color: Colors.green.withOpacity(0.3),
//                     width: 1,
//                   ),
//                 ),
//                 child: Row(
//                   children: [
//                     const Icon(
//                       Icons.check_circle,
//                       color: Colors.green,
//                       size: 20,
//                     ),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: Text(
//                         _uploadedFileName!,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ),
//                     IconButton(
//                       icon: const Icon(
//                         Icons.close,
//                         color: Colors.green,
//                         size: 18,
//                       ),
//                       onPressed: () {
//                         setState(() {
//                           _uploadedFileName = null;
//                           _selectedFile = null;
//                         });
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 12),
//             ],
//             OutlinedButton.icon(
//               onPressed: _pickFile,
//               icon: const Icon(Icons.upload_file),
//               label: Text(
//                 _uploadedFileName != null ? 'Change File' : 'Choose File',
//               ),
//             ),
//             const SizedBox(height: 20),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: _isUploading ? null : _uploadProposal,
//                 child:
//                     _isUploading
//                         ? const CircularProgressIndicator(color: Colors.white)
//                         : const Text('Upload Proposal'),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fyp_connect/auth/cloudinary_service.dart';

// Color Theme
class AppColors {
  static const Color primaryDark = Color.fromARGB(255, 24, 81, 91);
  static const Color primaryLight = Color.fromARGB(255, 133, 213, 231);
  static const Color accentTeal = Color.fromARGB(255, 76, 175, 159);
  static const Color successGreen = Color.fromARGB(255, 46, 162, 112);
  static const Color warningOrange = Color.fromARGB(255, 255, 152, 0);
  static const Color backgroundLight = Color.fromARGB(255, 245, 248, 250);
  static const Color textDark = Color.fromARGB(255, 33, 33, 33);
  static const Color textLight = Color.fromARGB(255, 117, 117, 117);
  static const Color white = Color.fromARGB(255, 255, 255, 255);
}

class SendProposalPage extends StatefulWidget {
  final String supervisorId;
  final String supervisorName;

  const SendProposalPage({
    super.key,
    required this.supervisorId,
    required this.supervisorName,
  });

  @override
  State<SendProposalPage> createState() => _SendProposalPageState();
}

class _SendProposalPageState extends State<SendProposalPage> {
  final CloudinaryService _cloudinaryService = CloudinaryService();

  File? _selectedFile;
  String? _uploadedFileName;
  bool _isUploading = false;

  Map<String, dynamic>? studentData;

  @override
  void initState() {
    super.initState();
    _fetchStudentData();
  }

  Future<void> _fetchStudentData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc =
        await FirebaseFirestore.instance.collection('students').doc(uid).get();
    if (!doc.exists) return;

    setState(() {
      studentData = doc.data();
    });
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
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text('Error selecting file: $e')),
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

  Future<void> _uploadProposal() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a file first.'),
          backgroundColor: AppColors.warningOrange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (studentData?['projectStatus'] != 'Active') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You cannot upload a proposal. Project status is not Active.',
          ),
          backgroundColor: AppColors.warningOrange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final uploadedUrl = await _cloudinaryService.uploadFile(_selectedFile!);

      if (uploadedUrl != null) {
        final uid = FirebaseAuth.instance.currentUser!.uid;

        // 1️⃣ Update student's Firestore doc
        await FirebaseFirestore.instance
            .collection('students')
            .doc(uid)
            .update({
              'proposalFileUrl': uploadedUrl,
              'proposalFileName': _uploadedFileName,
              'proposalSubmittedAt': FieldValue.serverTimestamp(),
              'supervisorId': widget.supervisorId,
              'supervisorName': widget.supervisorName,
            });

        String proposalId = '';

        // 2️⃣ Check if supervisor group already exists
        final existingGroupQuery =
            await FirebaseFirestore.instance
                .collection('supervisor_groups')
                .where('studentId', isEqualTo: uid)
                .where('supervisorId', isEqualTo: widget.supervisorId)
                .limit(1)
                .get();

        if (existingGroupQuery.docs.isNotEmpty) {
          // Update existing group
          final groupDoc = existingGroupQuery.docs.first;
          proposalId = groupDoc.id;
          await FirebaseFirestore.instance
              .collection('supervisor_groups')
              .doc(proposalId)
              .update({
                'fileUrl': uploadedUrl,
                'updatedAt': FieldValue.serverTimestamp(),
              });
        } else {
          // Create new group (only if not exists)
          final newGroupRef = await FirebaseFirestore.instance
              .collection('supervisor_groups')
              .add({
                'studentId': uid,
                'studentName': studentData?['name'] ?? '',
                'registrationNumber': studentData?['regNo'] ?? '',
                'groupMembers': studentData?['groupMembers'] ?? '',
                'projectTitle': studentData?['projectTitle'] ?? '',
                'fileUrl': uploadedUrl,
                'supervisorId': widget.supervisorId,
                'supervisorName': widget.supervisorName,
                'createdAt': FieldValue.serverTimestamp(),
              });
          proposalId = newGroupRef.id;
        }

        // 3️⃣ Send notification to supervisor
        await _sendProposalNotificationToSupervisor(
          widget.supervisorId,
          proposalId,
          studentData?['projectTitle'] ?? 'Project',
        );

        // 4️⃣ Success snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Expanded(child: Text('Proposal uploaded successfully! 🎉')),
              ],
            ),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );

        setState(() {
          _selectedFile = null;
          _uploadedFileName = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File upload failed.'),
            backgroundColor: AppColors.warningOrange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading file: $e'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // --- Notification Function ---
  Future<void> _sendProposalNotificationToSupervisor(
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
        'title': 'Proposal File Submitted',
        'body': '$studentName submitted a proposal file "$projectTitle"',
        'isSeen': false,
        'createdAt': FieldValue.serverTimestamp(),
        'proposalId': proposalId,
      });
    } catch (e) {
      debugPrint("❌ Error sending proposal notification: $e");
    }
  }

  // Future<void> _uploadProposal() async {
  //   if (_selectedFile == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Please select a file first.'),
  //         backgroundColor: AppColors.warningOrange,
  //         behavior: SnackBarBehavior.floating,
  //       ),
  //     );
  //     return;
  //   }

  //   if (studentData?['projectStatus'] != 'Active') {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text(
  //           'You cannot upload a proposal. Project status is not Active.',
  //         ),
  //         backgroundColor: AppColors.warningOrange,
  //         behavior: SnackBarBehavior.floating,
  //       ),
  //     );
  //     return;
  //   }

  //   setState(() => _isUploading = true);

  //   try {
  //     final uploadedUrl = await _cloudinaryService.uploadFile(_selectedFile!);

  //     if (uploadedUrl != null) {
  //       final uid = FirebaseAuth.instance.currentUser!.uid;

  //       // 1️⃣ Update student's Firestore doc
  //       await FirebaseFirestore.instance
  //           .collection('students')
  //           .doc(uid)
  //           .update({
  //             'proposalFileUrl': uploadedUrl,
  //             'proposalFileName': _uploadedFileName,
  //             'proposalSubmittedAt': FieldValue.serverTimestamp(),
  //             'supervisorId': widget.supervisorId,
  //             'supervisorName': widget.supervisorName,
  //           });

  //       // 2️⃣ Check if supervisor group already exists
  //       final existingGroupQuery =
  //           await FirebaseFirestore.instance
  //               .collection('supervisor_groups')
  //               .where('studentId', isEqualTo: uid)
  //               .where('supervisorId', isEqualTo: widget.supervisorId)
  //               .limit(1)
  //               .get();

  //       if (existingGroupQuery.docs.isNotEmpty) {
  //         // Update existing group
  //         final groupDocId = existingGroupQuery.docs.first.id;
  //         await FirebaseFirestore.instance
  //             .collection('supervisor_groups')
  //             .doc(groupDocId)
  //             .update({
  //               'fileUrl': uploadedUrl,
  //               'updatedAt': FieldValue.serverTimestamp(),
  //             });
  //       } else {
  //         // Create new group (only if not exists)
  //         await FirebaseFirestore.instance.collection('supervisor_groups').add({
  //           'studentId': uid,
  //           'studentName': studentData?['name'] ?? '',
  //           'registrationNumber': studentData?['regNo'] ?? '',
  //           'groupMembers': studentData?['groupMembers'] ?? '',
  //           'projectTitle': studentData?['projectTitle'] ?? '',
  //           'fileUrl': uploadedUrl,
  //           'supervisorId': widget.supervisorId,
  //           'supervisorName': widget.supervisorName,
  //           'createdAt': FieldValue.serverTimestamp(),
  //         });
  //       }

  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: const Row(
  //             children: [
  //               Icon(Icons.check_circle, color: Colors.white, size: 20),
  //               SizedBox(width: 12),
  //               Expanded(child: Text('Proposal uploaded successfully! 🎉')),
  //             ],
  //           ),
  //           backgroundColor: AppColors.successGreen,
  //           behavior: SnackBarBehavior.floating,
  //           shape: RoundedRectangleBorder(
  //             borderRadius: BorderRadius.circular(12),
  //           ),
  //           margin: const EdgeInsets.all(16),
  //         ),
  //       );

  //       setState(() {
  //         _selectedFile = null;
  //         _uploadedFileName = null;
  //       });
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text('File upload failed.'),
  //           backgroundColor: AppColors.warningOrange,
  //           behavior: SnackBarBehavior.floating,
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Error uploading file: $e'),
  //         backgroundColor: Colors.red[600],
  //         behavior: SnackBarBehavior.floating,
  //       ),
  //     );
  //   } finally {
  //     setState(() => _isUploading = false);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    if (studentData == null) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryDark,
            strokeWidth: 3,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Submit Your Proposal',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card with Supervisor Info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryLight, AppColors.accentTeal],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryDark.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_outline,
                            color: AppColors.primaryDark,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Supervisor',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textDark,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.supervisorName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // File Selection Section
              Text(
                'Upload Your Proposal',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Supported formats: PDF, DOC, DOCX',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 20),

              // File Upload Box
              GestureDetector(
                onTap: _pickFile,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 32,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primaryLight.withOpacity(0.4),
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.cloud_upload_outlined,
                          size: 40,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _uploadedFileName != null
                            ? 'Change File'
                            : 'Choose Your File',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to browse or drag and drop',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textLight,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Selected File Display
              if (_uploadedFileName != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.successGreen.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.successGreen.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.description_outlined,
                          color: AppColors.successGreen,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'File Selected',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textLight,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _uploadedFileName!,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.successGreen,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _uploadedFileName = null;
                            _selectedFile = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.successGreen.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: AppColors.successGreen,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _uploadProposal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    disabledBackgroundColor: AppColors.primaryDark.withOpacity(
                      0.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                    shadowColor: AppColors.primaryDark.withOpacity(0.3),
                  ),
                  child:
                      _isUploading
                          ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: AppColors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                          : const Text(
                            'Upload Proposal',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                ),
              ),
              const SizedBox(height: 16),

              // Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryDark.withOpacity(0.12),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.primaryDark,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Make sure your project status is Active before uploading. You can only submit one proposal per supervisor.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
