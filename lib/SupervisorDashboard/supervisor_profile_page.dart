import 'package:flutter/material.dart';
import 'package:fyp_connect/auth/auth_service.dart';
// import '../auth/auth_service.dart'; // replace with actual path

class SupervisorProfilePage extends StatefulWidget {
  const SupervisorProfilePage({super.key});

  @override
  State<SupervisorProfilePage> createState() => _SupervisorProfilePageState();
}

class _SupervisorProfilePageState extends State<SupervisorProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _projectsHistoryController =
      TextEditingController();
  final TextEditingController _specializationController =
      TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final AuthService _authService = AuthService();
  
  // Project count (display only)
  int _projectCount = 0;
  
  // Selected values for dropdowns
  String _selectedSpecialization = '';
  List<String> _selectedPreferenceAreas = [];
  List<String> _selectedProjectHistoryCategories = [];
  
  // Options for dropdowns
  final List<String> _specializationOptions = [
    'Software Engineering',
    'Machine Learning',
    'Artificial Intelligence',
    'Data Science',
    'Web Development',
    'Mobile Development',
    'Cloud Computing',
    'Cybersecurity',
    'Computer Networks',
    'Database Systems',
    'Computer Vision',
    'Natural Language Processing',
    'Robotics',
    'IoT',
    'Blockchain',
    'Game Development'
  ];
  
  final List<String> _preferenceAreaOptions = [
    'Artificial Intelligence',
    'Machine Learning',
    'Web Development',
    'Mobile Development',
    'Cloud Computing',
    'Cybersecurity',
    'Data Science',
    'IoT',
    'Blockchain',
    'Game Development',
    'Robotics',
    'Natural Language Processing',
    'Computer Vision'
  ];
  
  final List<String> _projectHistoryOptions = [
    'AI',
    'IoT',
    'Web',
    'Mobile',
    'Cloud',
    'Security',
    'Data Science',
    'Blockchain',
    'Game Development',
    'Computer Vision',
    'NLP',
    'Robotics'
  ];

  bool _isEditing = true; // Start in edit mode
  bool _hasData = false; // Track if profile has been saved

  @override
  void dispose() {
    _nameController.dispose();
    _departmentController.dispose();
    _projectsHistoryController.dispose();
    _specializationController.dispose();
    _idController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      // Convert lists to strings for storage
      final preferenceAreasString = _selectedPreferenceAreas.join(', ');
      final projectHistoryString = _selectedProjectHistoryCategories.join(', ');
      
      await _authService.saveSupervisorProfile(
        name: _nameController.text.trim(),
        department: _departmentController.text.trim(),
        projectsHistory: _projectsHistoryController.text.trim(),
        specialization: _selectedSpecialization.isNotEmpty ? _selectedSpecialization : _specializationController.text.trim(),
        id: _idController.text.trim(),
        preferenceAreas: preferenceAreasString, // Add new preference areas field
        projectHistoryCategories: projectHistoryString, // Add new project history categories field
        projectCount: _projectCount.toString(), // Add project count
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
    final profile = await _authService.getSupervisorProfile();

    if (profile != null) {
      // Parse strings to get values for dropdowns
      String specializationString = profile['specialization'] ?? '';
      String preferenceAreasString = profile['preferenceAreas'] ?? '';
      String projectHistoryCategoriesString = profile['projectHistoryCategories'] ?? '';
      
      // Set selected dropdown values
      _selectedSpecialization = specializationString;
      
      _selectedPreferenceAreas = preferenceAreasString.isNotEmpty 
          ? preferenceAreasString.split(', ').where((i) => i.trim().isNotEmpty).toList()
          : [];
          
      _selectedProjectHistoryCategories = projectHistoryCategoriesString.isNotEmpty 
          ? projectHistoryCategoriesString.split(', ').where((s) => s.trim().isNotEmpty).toList()
          : [];
      
      // Try to parse project count
      try {
        _projectCount = int.parse(profile['projectCount'] ?? '0');
      } catch (e) {
        _projectCount = 0;
      }
          
      setState(() {
        _nameController.text = profile['name'] ?? '';
        _departmentController.text = profile['department'] ?? '';
        _projectsHistoryController.text = profile['projectsHistory'] ?? '';
        _specializationController.text = profile['specialization'] ?? '';
        _idController.text = profile['id'] ?? '';
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

  // Single select dropdown for specialization
  Widget _buildSingleSelectDropdown({
    required String label,
    required IconData icon,
    required Color iconColor,
    required List<String> options,
    required String selectedValue,
    required Function(String) onChanged,
    String? hintText,
    bool isRequired = false,
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
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!, width: 1),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedValue.isNotEmpty ? selectedValue : null,
                        hint: Text(
                          hintText ?? 'Select $label',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                        isExpanded: true,
                        icon: Icon(Icons.arrow_drop_down, color: iconColor),
                        items: options.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          if (newValue != null) {
                            onChanged(newValue);
                          }
                        },
                      ),
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
                    child: selectedValue.isEmpty
                        ? Text(
                            'Not provided',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        : Text(
                            selectedValue,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[800],
                            ),
                          ),
                  ),
            if (isRequired && selectedValue.isEmpty && _isEditing)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 12),
                child: Text(
                  'Please select a $label',
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Multi-select dropdown for preference areas and project history
  Widget _buildMultiSelectDropdown({
    required String label,
    required IconData icon,
    required Color iconColor,
    required List<String> options,
    required List<String> selectedValues,
    required Function(List<String>) onChanged,
    String? hintText,
    bool isRequired = false,
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
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
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
                                color: isSelected ? Colors.white : Colors.grey[800],
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
                            },
                            backgroundColor: Colors.grey[100],
                            selectedColor: iconColor,
                            checkmarkColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          );
                        }),
                        if (isRequired && selectedValues.isEmpty && _isEditing)
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
                  )
                : Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!, width: 1),
                    ),
                    child: selectedValues.isEmpty
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
                            children: selectedValues
                                .map(
                                  (value) => Chip(
                                    label: Text(
                                      value,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                    backgroundColor: iconColor.withOpacity(0.8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
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

  // Counter widget for number of projects
  Widget _buildProjectCountField({
    required IconData icon,
    required Color iconColor,
    String? hintText,
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
                const Text(
                  'Number of Projects',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _isEditing
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!, width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                          onPressed: () {
                            if (_projectCount > 0) {
                              setState(() {
                                _projectCount--;
                              });
                            }
                          },
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.teal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _projectCount.toString(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Colors.teal),
                          onPressed: () {
                            setState(() {
                              _projectCount++;
                            });
                          },
                        ),
                      ],
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.teal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _projectCount.toString(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Projects Supervised',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
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
          'Supervisor Profile',
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
              color: Color.fromARGB(255, 24, 81, 91),

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
                          Icons.supervisor_account_outlined,
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
                                  color: const Color(
                                    0xFF8B2E2E,
                                  ).withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.supervisor_account,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _nameController.text.isEmpty
                                ? 'Supervisor Profile'
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
                      label: 'Supervisor Name',
                      icon: Icons.person_outline,
                      iconColor: const Color(0xFF8B2E2E),
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
                      controller: _projectsHistoryController,
                      label: 'Projects History',
                      icon: Icons.history_outlined,
                      iconColor: Colors.green,
                      hintText: 'e.g., 15 projects supervised',
                      validator:
                          (value) =>
                              value!.isEmpty
                                  ? 'Please enter total projects supervised by you'
                                  : null,
                    ),

                    // Single select dropdown for specialization
                    _buildSingleSelectDropdown(
                      label: 'Specialization',
                      icon: Icons.lightbulb_outline,
                      iconColor: Colors.orange,
                      options: _specializationOptions,
                      selectedValue: _selectedSpecialization,
                      onChanged: (newValue) {
                        setState(() {
                          _selectedSpecialization = newValue;
                        });
                      },
                      hintText: 'Select your specialization',
                      isRequired: true,
                    ),
                    
                    // Multi-select dropdown for preference areas
                    _buildMultiSelectDropdown(
                      label: 'Preference Areas',
                      icon: Icons.favorite_outline,
                      iconColor: Colors.pink,
                      options: _preferenceAreaOptions,
                      selectedValues: _selectedPreferenceAreas,
                      onChanged: (newValues) {
                        setState(() {
                          _selectedPreferenceAreas = newValues;
                        });
                      },
                      hintText: 'Select your preferred areas for supervision',
                      isRequired: true,
                    ),
                    
                    // Multi-select dropdown for project history categories
                    _buildMultiSelectDropdown(
                      label: 'Projects History Categories',
                      icon: Icons.history,
                      iconColor: Colors.blue,
                      options: _projectHistoryOptions,
                      selectedValues: _selectedProjectHistoryCategories,
                      onChanged: (newValues) {
                        setState(() {
                          _selectedProjectHistoryCategories = newValues;
                        });
                      },
                      hintText: 'Select categories of past projects',
                    ),
                    
                    // Project count widget
                    _buildProjectCountField(
                      icon: Icons.assignment_turned_in,
                      iconColor: Colors.teal,
                      hintText: 'Number of projects supervised',
                    ),

                    _buildFormField(
                      controller: _idController,
                      label: 'Supervisor ID',
                      icon: Icons.badge_outlined,
                      iconColor: Colors.purple,
                      hintText: 'Enter your ID',
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
                              Color.fromARGB(255, 46, 127, 171),
                              Color(0xFFB45050),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8B2E2E).withOpacity(0.3),
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
                                  ? 'Complete your profile to help students find you and understand your expertise better.'
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

                    const SizedBox(height: 60),
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
