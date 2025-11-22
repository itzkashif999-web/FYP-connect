
import 'package:flutter/material.dart';
import '../auth/auth_service.dart'; // replace with actual path
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  // New controllers for skills and interest as strings to store selected values
  final TextEditingController _skillsController = TextEditingController();

  // Selected values for dropdowns
  List<String> _selectedInterests = [];
  List<String> _selectedSkills = [];

  // Controllers for custom inputs
  final TextEditingController _otherInterestController =
      TextEditingController();
  final TextEditingController _otherSkillController = TextEditingController();

  // Flags to track if "Other" option is selected
  bool _otherInterestSelected = false;
  bool _otherSkillSelected = false;

  // Options for dropdowns
  final List<String> _interestOptions = [
    'Artificial Intelligence',
    'Machine Learning',
    'Data Science',
    'Web Development',
    'Mobile Development',
    'Game Development',
    'Software Engineering',
    'UI/UX Design',
    'Database Management',
    'DevOps',
    'Cloud Computing',
    'Cybersecurity',
    'Network Security',
    'Natural Language Processing',
    'Computer Vision',
    'Robotics',
    'Embedded Systems',
    'IoT',
    'Blockchain',
    'Quantum Computing',
    'Augmented Reality (AR)',
    'Virtual Reality (VR)',
    'Mixed Reality (MR)',
    'Digital Twins',
    'Edge Computing',
    'Autonomous Vehicles',
    'Smart Cities',
    'Bioinformatics',
    'FinTech',
    'HealthTech',
    'AgriTech',
    'EdTech',
    'Operating Systems',
    'Compiler Design',
    'Big Data Analytics',
    'Distributed Systems',
    'Systems Programming',
    'Computer Architecture',
    'VLSI Design',
    'Wearable Technology',
    'Technical Writing',
    'Project Management',
    'Research & Innovation',
    'Other',
  ];

  final List<String> _skillsOptions = [
    'Flutter',
    'Python',
    'Java',
    'JavaScript',
    'React',
    'Node.js',
    'C++',
    'C#',
    'Swift',
    'Kotlin',
    'PHP',
    'Ruby',
    'Go',
    'SQL',
    'NoSQL',
    'HTML/CSS',
    'TensorFlow',
    'PyTorch',
    'Docker',
    'Kubernetes',
    'AWS',
    'Azure',
    'Google Cloud',
    'Git',
    'Firebase',
    'MongoDB',
    'TypeScript',
    'Angular',
    'Vue.js',
    'Other',
  ];

  bool _isEditing = true; // Start in edit mode
  bool _hasData = false; // Track if profile has been saved

  @override
  void dispose() {
    _nameController.dispose();
    _departmentController.dispose();
    _semesterController.dispose();
    _interestController.dispose();
    _regNoController.dispose();
    _skillsController.dispose();
    _otherInterestController.dispose();
    _otherSkillController.dispose();
    super.dispose();
  }
bool _isProfileComplete(Map<String, dynamic> profile) {
  if (profile == null) return false;
  
  // Check required fields
  final requiredFields = ['semester', 'interest', 'skills'];
  for (var field in requiredFields) {
    if (profile[field] == null || profile[field].toString().trim().isEmpty) {
      return false;
    }
  }
  
  return true;
}

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      // Process custom "Other" options if selected
      List<String> finalInterests = List.from(_selectedInterests);
      List<String> finalSkills = List.from(_selectedSkills);

      // Remove "Other" option and add custom value if provided
      if (_otherInterestSelected && _otherInterestController.text.isNotEmpty) {
        finalInterests.remove('Other');
        finalInterests.add(_otherInterestController.text.trim());
      }

      if (_otherSkillSelected && _otherSkillController.text.isNotEmpty) {
        finalSkills.remove('Other');
        finalSkills.add(_otherSkillController.text.trim());
      }

      // Convert lists to strings for storage
      final interestsString = finalInterests.join(', ');
      final skillsString = finalSkills.join(', ');

      await _authService.saveStudentProfile(
        name: _nameController.text.trim(),
        department: _departmentController.text.trim(),
        semester: _semesterController.text.trim(),
        interest:
            interestsString.isNotEmpty
                ? interestsString
                : _interestController.text.trim(),
        regNo: _regNoController.text.trim(),
        skills: skillsString, // Add new skills field
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
    _loadUserInfo();
    _loadProfile();
  }

  // Fetch name, department, regNo from users collection and make read-only
  Future<void> _loadUserInfo() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      setState(() {
        _nameController.text = doc['name'] ?? '';
        _departmentController.text = doc['department'] ?? '';
        _regNoController.text = doc['registrationNo'] ?? '';
      });
    }
  }

  Future<void> _loadProfile() async {
    final profile = await _authService.getStudentProfile();

    if (profile != null) {
      String interestsString = profile['interest'] ?? '';
      String skillsString = profile['skills'] ?? '';

      List<String> interests =
          interestsString.isNotEmpty
              ? interestsString
                  .split(', ')
                  .where((i) => i.trim().isNotEmpty)
                  .toList()
              : [];

      List<String> skills =
          skillsString.isNotEmpty
              ? skillsString
                  .split(', ')
                  .where((s) => s.trim().isNotEmpty)
                  .toList()
              : [];

      _selectedInterests = [];
      List<String> customInterests = [];
      for (String interest in interests) {
        if (_interestOptions.contains(interest)) {
          _selectedInterests.add(interest);
        } else {
          customInterests.add(interest);
        }
      }

      _selectedSkills = [];
      List<String> customSkills = [];
      for (String skill in skills) {
        if (_skillsOptions.contains(skill)) {
          _selectedSkills.add(skill);
        } else {
          customSkills.add(skill);
        }
      }

      if (customInterests.isNotEmpty) {
        _selectedInterests.add('Other');
        _otherInterestController.text = customInterests.join(', ');
        _otherInterestSelected = true;
      }

      if (customSkills.isNotEmpty) {
        _selectedSkills.add('Other');
        _otherSkillController.text = customSkills.join(', ');
        _otherSkillSelected = true;
      }

      setState(() {
        _semesterController.text = profile['semester'] ?? '';
        _interestController.text = profile['interest'] ?? '';
        _skillsController.text = profile['skills'] ?? '';
        // Check if profile is complete
      _hasData = _isProfileComplete(profile); 
      _isEditing = !_hasData; 
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

  // Use your existing _buildMultiSelectDropdown and _buildFormField methods (unchanged)
  // ... Copy everything from your original methods here without modification
  Widget _buildMultiSelectDropdown({
    required String label,
    required IconData icon,
    required Color iconColor,
    required List<String> options,
    required List<String> selectedValues,
    required Function(List<String>) onChanged,
    String? hintText,
    bool isRequired = false,
    bool isInterests = false, // Flag to identify if this is interests dropdown
  }) {
    final bool isOtherSelected = selectedValues.contains('Other');

    // Set the correct state variable based on dropdown type
    if (isInterests) {
      _otherInterestSelected = isOtherSelected;
    } else {
      _otherSkillSelected = isOtherSelected;
    }

    // Get the correct text controller based on dropdown type
    final otherController =
        isInterests ? _otherInterestController : _otherSkillController;

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
                ? Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ...options.map((option) {
                            final isSelected = selectedValues.contains(option);
                            return FilterChip(
                              label: Text(
                                option,
                                style: TextStyle(
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : Colors.grey[800],
                                  fontSize: 14,
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                List<String> newValues = [...selectedValues];
                                if (selected) {
                                  newValues.add(option);
                                } else {
                                  newValues.remove(option);
                                }
                                onChanged(newValues);
                                setState(() {
                                  if (isInterests) {
                                    _otherInterestSelected = newValues.contains(
                                      'Other',
                                    );
                                  } else {
                                    _otherSkillSelected = newValues.contains(
                                      'Other',
                                    );
                                  }
                                });
                              },
                              backgroundColor: Colors.grey[100],
                              selectedColor: iconColor,
                              checkmarkColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            );
                          }),
                          if (isRequired &&
                              selectedValues.isEmpty &&
                              _isEditing)
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                'Please select at least one option',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Display text field for "Other" option if selected
                    if (isOtherSelected)
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        child: TextFormField(
                          controller: otherController,
                          decoration: InputDecoration(
                            hintText:
                                isInterests
                                    ? 'Specify other research interest'
                                    : 'Specify other skill',
                            hintStyle: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: iconColor,
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            contentPadding: const EdgeInsets.all(16),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator:
                              isOtherSelected
                                  ? (value) =>
                                      value!.isEmpty
                                          ? 'Please specify your ${isInterests ? "research interest" : "skill"}'
                                          : null
                                  : null,
                        ),
                      ),
                  ],
                )
                : Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!, width: 1),
                  ),
                  child:
                      selectedValues.isEmpty
                          ? Text(
                            'Not provided',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                          )
                          : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                selectedValues
                                    .map(
                                      (value) => Chip(
                                        label: Text(
                                          value,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                        backgroundColor: iconColor.withOpacity(
                                          0.8,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                          ),
                ),
          ],
        ),
      ),
    );
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
    bool readOnly = false, // Added readOnly param
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
            _isEditing || readOnly
                ? TextFormField(
                  controller: controller,
                  validator: validator,
                  keyboardType: keyboardType,
                  maxLines: maxLines,
                  readOnly: readOnly, // make field read-only
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
          'Profile',
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
                                      : 'Add your information according to your project to get started')
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

                    // Name, Department, RegNo - ReadOnly
                    _buildFormField(
                      controller: _nameController,
                      label: 'Student Name',
                      icon: Icons.person_outline,
                      iconColor: Color.fromARGB(255, 133, 213, 231),
                      readOnly: true,
                    ),

                    _buildFormField(
                      controller: _departmentController,
                      label: 'Department',
                      icon: Icons.school_outlined,
                      iconColor: Colors.blue,
                      readOnly: true,
                    ),

                    _buildFormField(
                      controller: _regNoController,
                      label: 'Registration Number',
                      icon: Icons.badge_outlined,
                      iconColor: Colors.purple,
                      readOnly: true,
                    ),

                    // Editable fields
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

                    _buildMultiSelectDropdown(
                      label: 'Interests',
                      icon: Icons.lightbulb_outline,
                      iconColor: Colors.orange,
                      options: _interestOptions,
                      selectedValues: _selectedInterests,
                      onChanged: (newValues) {
                        setState(() {
                          _selectedInterests = newValues;
                        });
                      },
                      hintText: 'Select your research interests',
                      isRequired: true,
                      isInterests: true,
                    ),

                    _buildMultiSelectDropdown(
                      label: 'Skills',
                      icon: Icons.code,
                      iconColor: Colors.teal,
                      options: _skillsOptions,
                      selectedValues: _selectedSkills,
                      onChanged: (newValues) {
                        setState(() {
                          _selectedSkills = newValues;
                        });
                      },
                      hintText: 'Select your skills',
                      isInterests: false,
                    ),

                    const SizedBox(height: 20),

                    // Save Button
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
