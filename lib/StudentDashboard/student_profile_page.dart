import 'package:flutter/material.dart';
import '../auth/auth_service.dart'; // replace with actual path

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _semesterController = TextEditingController();
  final TextEditingController _interestController = TextEditingController();
  final TextEditingController _regNoController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isEditing = true; // Start in edit mode
  bool _hasData = false; // Track if profile has been saved

  @override
  void dispose() {
    _nameController.dispose();
    _departmentController.dispose();
    _semesterController.dispose();
    _interestController.dispose();
    _regNoController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      await _authService.saveStudentProfile(
        name: _nameController.text.trim(),
        department: _departmentController.text.trim(),
        semester: _semesterController.text.trim(),
        interest: _interestController.text.trim(),
        regNo: _regNoController.text.trim(),
      );

      setState(() {
        _isEditing = false;
        _hasData = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('Profile saved successfully!'),
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
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _authService.getStudentProfile();

    if (profile != null) {
      setState(() {
        _nameController.text = profile['name'] ?? '';
        _departmentController.text = profile['department'] ?? '';
        _semesterController.text = profile['semester'] ?? '';
        _interestController.text = profile['interest'] ?? '';
        _regNoController.text = profile['regNo'] ?? '';
        _hasData = true;
        _isEditing = false;
      });
    }
  }

  void _editProfile() {
    setState(() {
      _isEditing = true;
    });
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
    });
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
            _isEditing
                ? TextFormField(
                  controller: controller,
                  validator: validator,
                  keyboardType: keyboardType,
                  maxLines: maxLines,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: hintText ?? 'Enter your $label',
                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: iconColor, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
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
                )
                : Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!, width: 1),
                  ),
                  child: Text(
                    controller.text.isEmpty ? 'Not provided' : controller.text,
                    style: TextStyle(
                      fontSize: 16,
                      color:
                          controller.text.isEmpty
                              ? Colors.grey[500]
                              : Colors.grey[800],
                      fontStyle:
                          controller.text.isEmpty
                              ? FontStyle.italic
                              : FontStyle.normal,
                    ),
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
          'Student Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Color.fromARGB(255, 24, 81, 91),

        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_hasData && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: _editProfile,
            ),
          if (_isEditing && _hasData)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: _cancelEdit,
            ),
        ],
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
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEditing
                                  ? (_hasData
                                      ? 'Edit Your Profile'
                                      : 'Complete Your Profile')
                                  : 'Your Profile',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _isEditing
                                  ? (_hasData
                                      ? 'Update your information'
                                      : 'Add your information to get started')
                                  : 'Profile information',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!_isEditing && _hasData)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Saved',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Form Section
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Profile Avatar Section
                    Container(
                      margin: const EdgeInsets.only(bottom: 30),
                      child: Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [
                                  Color.fromARGB(255, 24, 81, 91),
                                  Color.fromARGB(255, 133, 213, 231),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Color.fromARGB(
                                    255,
                                    133,
                                    213,
                                    231,
                                  ).withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _nameController.text.isEmpty
                                ? 'Student Profile'
                                : _nameController.text,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Form Fields
                    _buildFormField(
                      controller: _nameController,
                      label: 'Student Name',
                      icon: Icons.person_outline,
                      iconColor: Color.fromARGB(255, 133, 213, 231),
                      hintText: 'Enter your full name',
                      validator:
                          (value) =>
                              value!.isEmpty ? 'Please enter your name' : null,
                    ),

                    _buildFormField(
                      controller: _departmentController,
                      label: 'Department',
                      icon: Icons.school_outlined,
                      iconColor: Colors.blue,
                      hintText: 'e.g., Computer Science',
                      validator:
                          (value) =>
                              value!.isEmpty
                                  ? 'Please enter your department'
                                  : null,
                    ),

                    _buildFormField(
                      controller: _semesterController,
                      label: 'Semester',
                      icon: Icons.calendar_today_outlined,
                      iconColor: Colors.green,
                      hintText: 'e.g., 6th Semester',
                      validator:
                          (value) =>
                              value!.isEmpty
                                  ? 'Please enter your semester'
                                  : null,
                    ),

                    _buildFormField(
                      controller: _interestController,
                      label: 'Research Interest',
                      icon: Icons.lightbulb_outline,
                      iconColor: Colors.orange,
                      hintText: 'e.g., Machine Learning, Web Development',
                      maxLines: 3,
                      validator:
                          (value) =>
                              value!.isEmpty
                                  ? 'Please enter your research interest'
                                  : null,
                    ),

                    _buildFormField(
                      controller: _regNoController,
                      label: 'Registration Number',
                      icon: Icons.badge_outlined,
                      iconColor: Colors.purple,
                      hintText: 'SP22-BCS-023',
                    ),

                    const SizedBox(height: 20),

                    // Save Button (only show when editing)
                    if (_isEditing) ...[
                      Container(
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
                          onPressed: _saveProfile,
                          icon: const Icon(
                            Icons.save_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                          label: Text(
                            _hasData ? 'Update Profile' : 'Save Profile',
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

                    // Info Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            _isEditing
                                ? Colors.blue.withOpacity(0.05)
                                : Colors.green.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              _isEditing
                                  ? Colors.blue.withOpacity(0.2)
                                  : Colors.green.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isEditing
                                ? Icons.info_outline
                                : Icons.check_circle_outline,
                            color:
                                _isEditing
                                    ? Colors.blue[600]
                                    : Colors.green[600],
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _isEditing
                                  ? 'Complete your profile to get better supervisor recommendations and project matches.'
                                  : 'Your profile is complete! You can edit it anytime by tapping the edit button.',
                              style: TextStyle(
                                color:
                                    _isEditing
                                        ? Colors.blue[700]
                                        : Colors.green[700],
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
