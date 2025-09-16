import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditSupervisorProfilePage extends StatefulWidget {
  final String supervisorUserId;
  const EditSupervisorProfilePage({super.key, required this.supervisorUserId});

  @override
  _EditSupervisorProfilePageState createState() =>
      _EditSupervisorProfilePageState();
}

class _EditSupervisorProfilePageState extends State<EditSupervisorProfilePage> {
  final _formKey = GlobalKey<FormState>();

  // Color scheme
  static const Color primaryDark = Color.fromARGB(255, 24, 81, 91);
  static const Color primaryLight = Color.fromARGB(255, 133, 213, 231);

  late TextEditingController nameCtrl;
  late TextEditingController emailCtrl;
  late TextEditingController departmentCtrl;
  late TextEditingController idCtrl;
  late TextEditingController specializationCtrl;
  late TextEditingController projectHistoryCtrl;

  bool loading = true;
  bool saving = false;
  String? profileDocId;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController();
    emailCtrl = TextEditingController();
    idCtrl = TextEditingController();
    departmentCtrl = TextEditingController();
    specializationCtrl = TextEditingController();
    projectHistoryCtrl = TextEditingController();
    _loadData();
  }

  Future<void> _loadData() async {
    final firestore = FirebaseFirestore.instance;

    try {
      var userDoc =
          await firestore
              .collection("users")
              .doc(widget.supervisorUserId)
              .get();
      if (userDoc.exists) {
        nameCtrl.text = userDoc.data()?['name'] ?? '';
        emailCtrl.text = userDoc.data()?['email'] ?? '';
      }

      var query =
          await firestore
              .collection("supervisor_profiles")
              .where("userId", isEqualTo: widget.supervisorUserId)
              .limit(1)
              .get();

      if (query.docs.isNotEmpty) {
        var profileDoc = query.docs.first;
        profileDocId = profileDoc.id;
        departmentCtrl.text = profileDoc.data()['department'] ?? '';
        idCtrl.text = profileDoc.data()['id'] ?? '';
        specializationCtrl.text = profileDoc.data()['specialization'] ?? '';
        projectHistoryCtrl.text = profileDoc.data()['projectsHistory'] ?? '';
      }
    } catch (e) {
      _showSnackBar("Error loading profile: $e", isError: true);
    }

    setState(() => loading = false);
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => saving = true);
    final firestore = FirebaseFirestore.instance;

    try {
      await firestore.collection("users").doc(widget.supervisorUserId).update({
        "name": nameCtrl.text.trim(),
        "email": emailCtrl.text.trim(),
      });

      if (profileDocId != null) {
        await firestore
            .collection("supervisor_profiles")
            .doc(profileDocId)
            .set({
              "department": departmentCtrl.text.trim(),
              "id": idCtrl.text.trim(),
              "specialization": specializationCtrl.text.trim(),
              "projectsHistory": projectHistoryCtrl.text.trim(),
              "userId": widget.supervisorUserId,
            }, SetOptions(merge: true));
      } else {
        await firestore
            .collection("supervisor_profiles")
            .doc(idCtrl.text.trim().isNotEmpty ? idCtrl.text.trim() : null)
            .set({
              "department": departmentCtrl.text.trim(),
              "id": idCtrl.text.trim(),
              "specialization": specializationCtrl.text.trim(),
              "projectsHistory": projectHistoryCtrl.text.trim(),
              "userId": widget.supervisorUserId,
            });
      }

      _showSnackBar("Profile updated successfully!", isError: false);
      Navigator.pop(context);
    } catch (e) {
      _showSnackBar("Error saving changes: $e", isError: true);
    }

    setState(() => saving = false);
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[600] : primaryDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        validator: validator,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: primaryDark),
          labelStyle: TextStyle(color: primaryDark.withOpacity(0.8)),
          filled: true,
          fillColor: primaryLight.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryLight.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryLight.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryDark, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryDark),
                strokeWidth: 3,
              ),
              const SizedBox(height: 16),
              Text(
                "Loading profile...",
                style: TextStyle(
                  color: primaryDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
        title: const Text(
          "Edit Supervisor Profile",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header section with gradient
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [primaryDark, primaryLight.withOpacity(0.1)],
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryDark.withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.person_outline,
                        size: 40,
                        color: primaryDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Update Supervisor Information",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Form section
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Personal Information Section
                    _buildSectionHeader("Personal Information", Icons.person),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: nameCtrl,
                      label: "Full Name",
                      icon: Icons.person_outline,
                      validator:
                          (v) =>
                              v == null || v.isEmpty
                                  ? "Please enter name"
                                  : null,
                    ),

                    _buildTextField(
                      controller: emailCtrl,
                      label: "Email Address",
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.isEmpty) return "Please enter email";
                        if (!v.contains('@')) return "Please enter valid email";
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Professional Information Section
                    _buildSectionHeader("Professional Information", Icons.work),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: idCtrl,
                      label: "Faculty ID",
                      icon: Icons.badge_outlined,
                    ),

                    _buildTextField(
                      controller: departmentCtrl,
                      label: "Department",
                      icon: Icons.business_outlined,
                    ),

                    _buildTextField(
                      controller: specializationCtrl,
                      label: "Specialization",
                      icon: Icons.school_outlined,
                    ),

                    _buildTextField(
                      controller: projectHistoryCtrl,
                      label: "Projects History",
                      icon: Icons.history_outlined,
                      maxLines: 4,
                    ),

                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: saving ? null : _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryDark,
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shadowColor: primaryDark.withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child:
                            saving
                                ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text("Saving Changes..."),
                                  ],
                                )
                                : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.save_outlined, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      "Save Changes",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryLight.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: primaryDark, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: primaryDark,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    idCtrl.dispose();
    departmentCtrl.dispose();
    specializationCtrl.dispose();
    projectHistoryCtrl.dispose();
    super.dispose();
  }
}
