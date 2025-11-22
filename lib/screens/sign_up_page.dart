// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:fyp_connect/SupervisorDashboard/supervisor_dashboard.dart';
// import 'package:fyp_connect/screens/Admindashboard/admin_dashboard.dart';
// import '../auth/auth_service.dart';
// import '../StudentDashboard/student_dashboard.dart';
// import 'sign_in_page.dart';

// class SignUpPage extends StatefulWidget {
//   const SignUpPage({super.key});

//   @override
//   State<SignUpPage> createState() => _SignUpPageState();
// }

// class _SignUpPageState extends State<SignUpPage> {
//   final _formKey = GlobalKey<FormState>();

//   final _userNameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _confirmPasswordController = TextEditingController();
//   final _departmentController = TextEditingController();

//   String? _selectedRole;
//   String? _selectedRegNo;
//   String? _selectedFacultyId;
//   String? _selectedAdminId;

//   bool _isPasswordVisible = false;
//   bool _isConfirmPasswordVisible = false;
//   bool _agreeToTerms = false;

//   final _authService = AuthService();

//   @override
//   void dispose() {
//     _userNameController.dispose();
//     _emailController.dispose();
//     _passwordController.dispose();
//     _confirmPasswordController.dispose();
//     _departmentController.dispose();
//     super.dispose();
//   }

//   /// Fetch student registration numbers
//   Future<List<String>> _fetchRegistrationNumbers() async {
//     final snapshot =
//         await FirebaseFirestore.instance.collection('addusers').get();
//     List<String> regNumbers = [];
//     for (var doc in snapshot.docs) {
//       final studentsSnap = await doc.reference.collection('add_students').get();
//       regNumbers.addAll(
//         studentsSnap.docs.map((sDoc) => sDoc['registrationNo'].toString()),
//       );
//     }
//     return regNumbers;
//   }

//   /// Fetch supervisor faculty IDs
//   Future<List<String>> _fetchFacultyId() async {
//     final snapshot =
//         await FirebaseFirestore.instance.collection('addusers').get();
//     List<String> facultyIds = [];
//     for (var doc in snapshot.docs) {
//       final supSnap = await doc.reference.collection('add_supervisors').get();
//       facultyIds.addAll(
//         supSnap.docs.map((sDoc) => sDoc['facultyId'].toString()),
//       );
//     }
//     return facultyIds;
//   }

//   /// Fetch admin IDs
//   Future<List<String>> _fetchAdminIds() async {
//     final snapshot =
//         await FirebaseFirestore.instance.collection('addusers').get();
//     List<String> adminIds = [];
//     for (var doc in snapshot.docs) {
//       final adminSnap = await doc.reference.collection('add_admins').get();
//       adminIds.addAll(adminSnap.docs.map((aDoc) => aDoc['adminId'].toString()));
//     }
//     return adminIds;
//   }

//   /// Fetch name based on selected RegNo / FacultyId / AdminId
//   Future<void> _fetchName() async {
//     if (_selectedRole == null) return;
//     String? name;
//     final addUsersSnapshot =
//         await FirebaseFirestore.instance.collection('addusers').get();

//     for (var doc in addUsersSnapshot.docs) {
//       if (_selectedRole == 'student' && _selectedRegNo != null) {
//         final studentsSnap =
//             await doc.reference.collection('add_students').get();
//         for (var sDoc in studentsSnap.docs) {
//           if (sDoc['registrationNo'].toString() == _selectedRegNo) {
//             name = sDoc['name'];
//             break;
//           }
//         }
//       } else if (_selectedRole == 'supervisor' && _selectedFacultyId != null) {
//         final supSnap = await doc.reference.collection('add_supervisors').get();
//         for (var sDoc in supSnap.docs) {
//           if (sDoc['facultyId'].toString() == _selectedFacultyId) {
//             name = sDoc['name'];
//             break;
//           }
//         }
//       } else if (_selectedRole == 'admin' && _selectedAdminId != null) {
//         final adminSnap = await doc.reference.collection('add_admins').get();
//         for (var aDoc in adminSnap.docs) {
//           if (aDoc['adminId'].toString() == _selectedAdminId) {
//             name = aDoc['name'];
//             break;
//           }
//         }
//       }
//       if (name != null) break;
//     }

//     if (name != null) {
//       setState(() {
//         _userNameController.text = name!;
//       });
//     }
//   }

//   Future<void> _handleSignUp() async {
//     if (_formKey.currentState!.validate() && _agreeToTerms) {
//       final email = _emailController.text.trim().toLowerCase();
//       final role = _selectedRole!.toLowerCase();
//       final dept = _departmentController.text.trim().toUpperCase();

//       try {
//         bool isValid = false;

//         final addUsersSnapshot =
//             await FirebaseFirestore.instance.collection('addusers').get();

//         for (var doc in addUsersSnapshot.docs) {
//           if (role == 'student') {
//             final studentsSnap =
//                 await doc.reference.collection('add_students').get();
//             for (var sDoc in studentsSnap.docs) {
//               if (sDoc['email'].toString().toLowerCase() == email &&
//                   sDoc['department'].toString().toUpperCase() == dept &&
//                   sDoc['registrationNo'].toString().toLowerCase() ==
//                       _selectedRegNo!.toLowerCase()) {
//                 isValid = true;
//                 break;
//               }
//             }
//           } else if (role == 'supervisor') {
//             final supSnap =
//                 await doc.reference.collection('add_supervisors').get();
//             for (var sDoc in supSnap.docs) {
//               if (sDoc['email'].toString().toLowerCase() == email &&
//                   sDoc['department'].toString().toUpperCase() == dept &&
//                   sDoc['facultyId'].toString().toLowerCase() ==
//                       _selectedFacultyId!.toLowerCase()) {
//                 isValid = true;
//                 break;
//               }
//             }
//           } else if (role == 'admin') {
//             final adminSnap =
//                 await doc.reference.collection('add_admins').get();
//             for (var aDoc in adminSnap.docs) {
//               if (aDoc['email'].toString().toLowerCase() == email &&
//                   aDoc['adminId'].toString().toLowerCase() ==
//                       _selectedAdminId!.toLowerCase()) {
//                 isValid = true;
//                 break;
//               }
//             }
//           }
//         }

//         if (!isValid) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text("Your details do not match records."),
//               backgroundColor: Colors.redAccent,
//             ),
//           );
//           return;
//         }

//         // Create Firebase Auth account
//         await _authService.signUp(
//           email: email,
//           password: _passwordController.text.trim(),
//           username: _userNameController.text.trim(),
//           role: role,
//         );

//         final currentUser = FirebaseAuth.instance.currentUser!;
//         await FirebaseFirestore.instance
//             .collection('users')
//             .doc(currentUser.uid)
//             .set({
//               'name': _userNameController.text.trim(),
//               'department': role == 'admin' ? null : dept,
//               'registrationNo': role == 'student' ? _selectedRegNo : null,
//               'facultyId': role == 'supervisor' ? _selectedFacultyId : null,
//               'adminId': role == 'admin' ? _selectedAdminId : null,
//             }, SetOptions(merge: true));

//         // Navigation
//         if (role == 'student') {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (_) => const StudentDashboard()),
//           );
//         } else if (role == 'supervisor') {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (_) => const SupervisorDashboard()),
//           );
//         } else if (role == 'admin') {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(
//               builder: (_) => AdminDashboard(currentUserId: currentUser.uid),
//             ),
//           );
//         }
//       } on FirebaseAuthException catch (e) {
//         String message = 'Signup failed';
//         if (e.code == 'email-already-in-use') {
//           message = 'Email already in use.';
//         } else if (e.code == 'weak-password') {
//           message = 'Password is too weak.';
//         }
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: const BoxDecoration(
//           image: DecorationImage(
//             image: AssetImage("assets/appBg.jpeg"),
//             fit: BoxFit.cover,
//           ),
//         ),
//         child: SafeArea(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(24.0),
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 children: [
//                   const SizedBox(height: 40),
//                   const Text(
//                     'Create Account',
//                     style: TextStyle(
//                       fontSize: 28,
//                       fontWeight: FontWeight.bold,
//                       color: Color.fromARGB(255, 9, 58, 53),
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   const Text(
//                     'Sign up to get started',
//                     style: TextStyle(
//                       color: Color.fromARGB(255, 190, 187, 187),
//                       fontSize: 16,
//                     ),
//                   ),
//                   const SizedBox(height: 32),

//                   /// Name field (auto fetched)
//                   _buildTextField(
//                     controller: _userNameController,
//                     hint: 'Name will be auto-filled',
//                     icon: Icons.person,
//                     readOnly: true,
//                     validator:
//                         (v) => v!.isEmpty ? 'Name could not be fetched' : null,
//                   ),
//                   const SizedBox(height: 16),

//                   /// EMAIL with new validation
//                   _buildTextField(
//                     controller: _emailController,
//                     hint: 'Enter your email',
//                     icon: Icons.email,
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter email';
//                       }

//                       String pattern =
//                           r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';

//                       if (!RegExp(pattern).hasMatch(value.trim())) {
//                         return 'Enter a valid email address';
//                       }

//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 16),

//                   _buildRoleDropdown(),
//                   const SizedBox(height: 16),

//                   if (_selectedRole != 'admin') _buildDepartmentDropdown(),
//                   if (_selectedRole != 'admin') const SizedBox(height: 16),

//                   if (_selectedRole == 'student') _buildRegDropdown(),
//                   if (_selectedRole == 'supervisor') _buildFacIdDropdown(),
//                   if (_selectedRole == 'admin') _buildAdminIdDropdown(),
//                   const SizedBox(height: 16),

//                   /// PASSWORD with strong validation
//                   _buildPasswordField(
//                     controller: _passwordController,
//                     hint: 'Enter your password',
//                     visible: _isPasswordVisible,
//                     toggle:
//                         () => setState(
//                           () => _isPasswordVisible = !_isPasswordVisible,
//                         ),
//                   ),
//                   const SizedBox(height: 16),

//                   _buildPasswordField(
//                     controller: _confirmPasswordController,
//                     hint: 'Confirm your password',
//                     visible: _isConfirmPasswordVisible,
//                     toggle:
//                         () => setState(
//                           () =>
//                               _isConfirmPasswordVisible =
//                                   !_isConfirmPasswordVisible,
//                         ),
//                     confirm: true,
//                   ),
//                   const SizedBox(height: 16),

//                   Row(
//                     children: [
//                       Checkbox(
//                         value: _agreeToTerms,
//                         onChanged: (v) => setState(() => _agreeToTerms = v!),
//                       ),
//                       Expanded(
//                         child: GestureDetector(
//                           onTap: () {
//                             showDialog(
//                               context: context,
//                               builder: (context) {
//                                 return AlertDialog(
//                                   title: const Text("Terms & Conditions"),
//                                   content: SingleChildScrollView(
//                                     child: Text("""
// 1. You must provide authentic details to sign up.
// 2. Accounts are role-based (Student / Supervisor / Admin).
// 3. Do not share your login credentials.
// 4. Data is stored securely and used only for academic purposes.
// 5. Misuse of the platform may result in account termination.
// 6. The app is a support tool; developers are not responsible for academic results.
//                                     """),
//                                   ),
//                                   actions: [
//                                     TextButton(
//                                       onPressed: () => Navigator.pop(context),
//                                       child: const Text("Close"),
//                                     ),
//                                   ],
//                                 );
//                               },
//                             );
//                           },
//                           child: const Text(
//                             'I agree to the Terms & Conditions',
//                             style: TextStyle(
//                               fontSize: 14,
//                               decoration: TextDecoration.underline,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),

//                   const SizedBox(height: 24),

//                   ElevatedButton(
//                     onPressed: _handleSignUp,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color.fromARGB(255, 24, 81, 91),
//                       foregroundColor: Colors.white,
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 100,
//                         vertical: 16,
//                       ),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     child: const Text(
//                       'Sign Up',
//                       style: TextStyle(fontSize: 18),
//                     ),
//                   ),
//                   const SizedBox(height: 16),

//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       const Text("Already have an account? "),
//                       GestureDetector(
//                         onTap: () {
//                           Navigator.pushReplacement(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) => const SignInPage(),
//                             ),
//                           );
//                         },
//                         child: const Text(
//                           "Sign In",
//                           style: TextStyle(
//                             color: Color(0xFFFF8A50),
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   /// ---------- Widgets ----------
//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String hint,
//     required IconData icon,
//     String? Function(String?)? validator,
//     bool readOnly = false,
//   }) => Container(
//     decoration: _boxDecoration(),
//     child: TextFormField(
//       controller: controller,
//       readOnly: readOnly,
//       decoration: InputDecoration(
//         hintText: hint,
//         prefixIcon: Icon(icon, color: const Color.fromARGB(255, 133, 213, 231)),
//         border: InputBorder.none,
//         contentPadding: const EdgeInsets.symmetric(
//           horizontal: 16,
//           vertical: 16,
//         ),
//       ),
//       validator: validator,
//     ),
//   );

//   Widget _buildPasswordField({
//     required TextEditingController controller,
//     required String hint,
//     required bool visible,
//     required VoidCallback toggle,
//     bool confirm = false,
//   }) => Container(
//     decoration: _boxDecoration(),
//     child: TextFormField(
//       controller: controller,
//       obscureText: !visible,
//       decoration: InputDecoration(
//         hintText: hint,
//         prefixIcon: const Icon(
//           Icons.lock,
//           color: Color.fromARGB(255, 133, 213, 231),
//         ),
//         suffixIcon: IconButton(
//           icon: Icon(
//             visible ? Icons.visibility : Icons.visibility_off,
//             color: Colors.grey,
//           ),
//           onPressed: toggle,
//         ),
//         border: InputBorder.none,
//         contentPadding: const EdgeInsets.symmetric(
//           horizontal: 16,
//           vertical: 16,
//         ),
//       ),

//       /// 🔥 NEW STRONG PASSWORD VALIDATION HERE
//       validator: (value) {
//         if (value == null || value.isEmpty) {
//           return confirm ? 'Please confirm password' : 'Please enter password';
//         }

//         if (value.length < 6) {
//           return 'Password must be at least 6 characters';
//         }
//         if (!RegExp(r'[A-Z]').hasMatch(value)) {
//           return 'Must include an uppercase letter';
//         }
//         if (!RegExp(r'[a-z]').hasMatch(value)) {
//           return 'Must include a lowercase letter';
//         }
//         if (!RegExp(r'\d').hasMatch(value)) {
//           return 'Must include a number';
//         }
//         if (!RegExp(r'[!@#\$&*~%^()\-_=+{};:,.<>]').hasMatch(value)) {
//           return 'Must include a special character';
//         }

//         if (confirm && value != _passwordController.text) {
//           return 'Passwords do not match';
//         }

//         return null;
//       },
//     ),
//   );

//   Widget _buildRoleDropdown() => Container(
//     decoration: _boxDecoration(),
//     child: DropdownButtonFormField<String>(
//       value: _selectedRole,
//       items:
//           ['student', 'supervisor', 'admin']
//               .map(
//                 (role) => DropdownMenuItem(
//                   value: role,
//                   child: Text(role.toUpperCase()),
//                 ),
//               )
//               .toList(),
//       onChanged: (v) {
//         setState(() {
//           _selectedRole = v;
//           _selectedRegNo = null;
//           _selectedFacultyId = null;
//           _selectedAdminId = null;
//           _userNameController.clear();
//         });
//       },
//       decoration: const InputDecoration(
//         hintText: 'Select Role',
//         prefixIcon: Icon(Icons.work, color: Color.fromARGB(255, 133, 213, 231)),
//         border: InputBorder.none,
//         contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//       ),
//       validator: (v) => v == null ? 'Please select role' : null,
//     ),
//   );

//   Widget _buildDepartmentDropdown() => Container(
//     decoration: _boxDecoration(),
//     child: DropdownButtonFormField<String>(
//       value:
//           _departmentController.text.isEmpty
//               ? null
//               : _departmentController.text,
//       items:
//           ['CS', 'SE']
//               .map((dept) => DropdownMenuItem(value: dept, child: Text(dept)))
//               .toList(),
//       onChanged: (v) => setState(() => _departmentController.text = v!),
//       decoration: const InputDecoration(
//         hintText: 'Select Department',
//         prefixIcon: Icon(
//           Icons.apartment,
//           color: Color.fromARGB(255, 133, 213, 231),
//         ),
//         border: InputBorder.none,
//         contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//       ),
//       validator: (v) => v == null ? 'Please select department' : null,
//     ),
//   );

//   Widget _buildRegDropdown() => FutureBuilder<List<String>>(
//     future: _fetchRegistrationNumbers(),
//     builder: (context, snapshot) {
//       if (snapshot.connectionState == ConnectionState.waiting) {
//         return const Center(child: CircularProgressIndicator());
//       }
//       if (!snapshot.hasData || snapshot.data!.isEmpty) {
//         return const Text("No registration numbers found");
//       }
//       return Container(
//         decoration: _boxDecoration(),
//         child: DropdownButtonFormField<String>(
//           value: _selectedRegNo,
//           items:
//               snapshot.data!
//                   .map(
//                     (regNo) =>
//                         DropdownMenuItem(value: regNo, child: Text(regNo)),
//                   )
//                   .toList(),
//           onChanged: (v) async {
//             setState(() => _selectedRegNo = v);
//             await _fetchName();
//           },
//           decoration: const InputDecoration(
//             hintText: 'Select Registration No',
//             prefixIcon: Icon(
//               Icons.confirmation_number,
//               color: Color.fromARGB(255, 133, 213, 231),
//             ),
//             border: InputBorder.none,
//             contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//           ),
//           validator:
//               (v) => v == null ? 'Please select a registration number' : null,
//         ),
//       );
//     },
//   );

//   Widget _buildFacIdDropdown() => FutureBuilder<List<String>>(
//     future: _fetchFacultyId(),
//     builder: (context, snapshot) {
//       if (snapshot.connectionState == ConnectionState.waiting) {
//         return const Center(child: CircularProgressIndicator());
//       }
//       if (!snapshot.hasData || snapshot.data!.isEmpty) {
//         return const Text("No Faculty Id found");
//       }
//       return Container(
//         decoration: _boxDecoration(),
//         child: DropdownButtonFormField<String>(
//           value: _selectedFacultyId,
//           items:
//               snapshot.data!
//                   .map(
//                     (facId) =>
//                         DropdownMenuItem(value: facId, child: Text(facId)),
//                   )
//                   .toList(),
//           onChanged: (v) async {
//             setState(() => _selectedFacultyId = v);
//             await _fetchName();
//           },
//           decoration: const InputDecoration(
//             hintText: 'Select Faculty Id',
//             prefixIcon: Icon(
//               Icons.confirmation_number,
//               color: Color.fromARGB(255, 133, 213, 231),
//             ),
//             border: InputBorder.none,
//             contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//           ),
//           validator: (v) => v == null ? 'Please select a Faculty Id' : null,
//         ),
//       );
//     },
//   );

//   Widget _buildAdminIdDropdown() => FutureBuilder<List<String>>(
//     future: _fetchAdminIds(),
//     builder: (context, snapshot) {
//       if (snapshot.connectionState == ConnectionState.waiting) {
//         return const Center(child: CircularProgressIndicator());
//       }
//       if (!snapshot.hasData || snapshot.data!.isEmpty) {
//         return const Text("No Admin Id found");
//       }
//       return Container(
//         decoration: _boxDecoration(),
//         child: DropdownButtonFormField<String>(
//           value: _selectedAdminId,
//           items:
//               snapshot.data!
//                   .map((aid) => DropdownMenuItem(value: aid, child: Text(aid)))
//                   .toList(),
//           onChanged: (v) async {
//             setState(() => _selectedAdminId = v);
//             await _fetchName();
//           },
//           decoration: const InputDecoration(
//             hintText: 'Select Admin Id',
//             prefixIcon: Icon(
//               Icons.admin_panel_settings,
//               color: Color.fromARGB(255, 133, 213, 231),
//             ),
//             border: InputBorder.none,
//             contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//           ),
//           validator: (v) => v == null ? 'Please select an Admin Id' : null,
//         ),
//       );
//     },
//   );

//   BoxDecoration _boxDecoration() => BoxDecoration(
//     color: Colors.grey[50],
//     borderRadius: BorderRadius.circular(12),
//     border: Border.all(color: Colors.grey[200]!),
//   );
// }
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp_connect/SupervisorDashboard/supervisor_dashboard.dart';
import 'package:fyp_connect/screens/Admindashboard/admin_dashboard.dart';
import '../auth/auth_service.dart';
import '../StudentDashboard/student_dashboard.dart';
import 'sign_in_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();

  final _userNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _departmentController = TextEditingController();

  String? _selectedRole;
  String? _selectedRegNo;
  String? _selectedFacultyId;
  String? _selectedAdminId;

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _agreeToTerms = false;

  final _authService = AuthService();

  @override
  void dispose() {
    _userNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  /// Fetch student registration numbers
  Future<List<String>> _fetchRegistrationNumbers() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('addusers').get();
    List<String> regNumbers = [];
    for (var doc in snapshot.docs) {
      final studentsSnap = await doc.reference.collection('add_students').get();
      regNumbers.addAll(
        studentsSnap.docs.map((sDoc) => sDoc['registrationNo'].toString()),
      );
    }
    return regNumbers;
  }

  /// Fetch supervisor faculty IDs
  Future<List<String>> _fetchFacultyId() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('addusers').get();
    List<String> facultyIds = [];
    for (var doc in snapshot.docs) {
      final supSnap = await doc.reference.collection('add_supervisors').get();
      facultyIds.addAll(
        supSnap.docs.map((sDoc) => sDoc['facultyId'].toString()),
      );
    }
    return facultyIds;
  }

  /// Fetch admin IDs
  Future<List<String>> _fetchAdminIds() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('addusers').get();
    List<String> adminIds = [];
    for (var doc in snapshot.docs) {
      final adminSnap = await doc.reference.collection('add_admins').get();
      adminIds.addAll(adminSnap.docs.map((aDoc) => aDoc['adminId'].toString()));
    }
    return adminIds;
  }

  /// Fetch name based on selected RegNo / FacultyId / AdminId
  Future<void> _fetchName() async {
    if (_selectedRole == null) return;
    String? name;
    final addUsersSnapshot =
        await FirebaseFirestore.instance.collection('addusers').get();

    for (var doc in addUsersSnapshot.docs) {
      if (_selectedRole == 'student' && _selectedRegNo != null) {
        final studentsSnap =
            await doc.reference.collection('add_students').get();
        for (var sDoc in studentsSnap.docs) {
          if (sDoc['registrationNo'].toString() == _selectedRegNo) {
            name = sDoc['name'];
            break;
          }
        }
      } else if (_selectedRole == 'supervisor' && _selectedFacultyId != null) {
        final supSnap = await doc.reference.collection('add_supervisors').get();
        for (var sDoc in supSnap.docs) {
          if (sDoc['facultyId'].toString() == _selectedFacultyId) {
            name = sDoc['name'];
            break;
          }
        }
      } else if (_selectedRole == 'admin' && _selectedAdminId != null) {
        final adminSnap = await doc.reference.collection('add_admins').get();
        for (var aDoc in adminSnap.docs) {
          if (aDoc['adminId'].toString() == _selectedAdminId) {
            name = aDoc['name'];
            break;
          }
        }
      }
      if (name != null) break;
    }

    if (name != null) {
      setState(() {
        _userNameController.text = name!;
      });
    }
  }

  Future<void> _handleSignUp() async {
    if (_formKey.currentState!.validate() && _agreeToTerms) {
      final email = _emailController.text.trim().toLowerCase();
      final role = _selectedRole!.toLowerCase();
      final dept = _departmentController.text.trim().toUpperCase();

      try {
        bool isValid = false;

        final addUsersSnapshot =
            await FirebaseFirestore.instance.collection('addusers').get();

        for (var doc in addUsersSnapshot.docs) {
          if (role == 'student') {
            final studentsSnap =
                await doc.reference.collection('add_students').get();
            for (var sDoc in studentsSnap.docs) {
              if (sDoc['email'].toString().toLowerCase() == email &&
                  sDoc['department'].toString().toUpperCase() == dept &&
                  sDoc['registrationNo'].toString().toLowerCase() ==
                      _selectedRegNo!.toLowerCase()) {
                isValid = true;
                break;
              }
            }
          } else if (role == 'supervisor') {
            final supSnap =
                await doc.reference.collection('add_supervisors').get();
            for (var sDoc in supSnap.docs) {
              if (sDoc['email'].toString().toLowerCase() == email &&
                  sDoc['department'].toString().toUpperCase() == dept &&
                  sDoc['facultyId'].toString().toLowerCase() ==
                      _selectedFacultyId!.toLowerCase()) {
                isValid = true;
                break;
              }
            }
          } else if (role == 'admin') {
            final adminSnap =
                await doc.reference.collection('add_admins').get();
            for (var aDoc in adminSnap.docs) {
              if (aDoc['email'].toString().toLowerCase() == email &&
                  aDoc['adminId'].toString().toLowerCase() ==
                      _selectedAdminId!.toLowerCase()) {
                isValid = true;
                break;
              }
            }
          }
        }

        if (!isValid) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Your details do not match records."),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        }

        // Create Firebase Auth account
        await _authService.signUp(
          email: email,
          password: _passwordController.text.trim(),
          username: _userNameController.text.trim(),
          role: role,
        );

        final currentUser = FirebaseAuth.instance.currentUser!;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .set({
              'name': _userNameController.text.trim(),
              'department': role == 'admin' ? null : dept,
              'registrationNo': role == 'student' ? _selectedRegNo : null,
              'facultyId': role == 'supervisor' ? _selectedFacultyId : null,
              'adminId': role == 'admin' ? _selectedAdminId : null,
            }, SetOptions(merge: true));

        // Navigation
        if (role == 'student') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const StudentDashboard()),
          );
        } else if (role == 'supervisor') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const SupervisorDashboard()),
          );
        } else if (role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => AdminDashboard(currentUserId: currentUser.uid),
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        String message = 'Signup failed';
        if (e.code == 'email-already-in-use') {
          message = 'Email already in use.';
        } else if (e.code == 'weak-password') {
          message = 'Password is too weak.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
        );
      }
    } else {
      // If terms not agreed, show message
      if (!_agreeToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("You must agree to Terms & Conditions."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/appBg.jpeg"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 9, 58, 53),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign up to get started',
                    style: TextStyle(
                      color: Color.fromARGB(255, 190, 187, 187),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 32),

                  /// Name field (auto fetched)
                  _buildTextField(
                    controller: _userNameController,
                    hint: 'Name will be auto-filled',
                    icon: Icons.person,
                    readOnly: true,
                    validator:
                        (v) => v!.isEmpty ? 'Name could not be fetched' : null,
                  ),
                  const SizedBox(height: 16),

                  /// EMAIL with validation
                  _buildTextField(
                    controller: _emailController,
                    hint: 'Enter your email',
                    icon: Icons.email,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter email';
                      }

                      String pattern =
                          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';

                      if (!RegExp(pattern).hasMatch(value.trim())) {
                        return 'Enter a valid email address';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildRoleDropdown(),
                  const SizedBox(height: 16),

                  if (_selectedRole != 'admin') _buildDepartmentDropdown(),
                  if (_selectedRole != 'admin') const SizedBox(height: 16),

                  if (_selectedRole == 'student') _buildRegDropdown(),
                  if (_selectedRole == 'supervisor') _buildFacIdDropdown(),
                  if (_selectedRole == 'admin') _buildAdminIdDropdown(),
                  const SizedBox(height: 16),

                  /// PASSWORD with single combined validation message
                  _buildPasswordField(
                    controller: _passwordController,
                    hint: 'Enter your password',
                    visible: _isPasswordVisible,
                    toggle:
                        () => setState(
                          () => _isPasswordVisible = !_isPasswordVisible,
                        ),
                  ),
                  const SizedBox(height: 16),

                  _buildPasswordField(
                    controller: _confirmPasswordController,
                    hint: 'Confirm your password',
                    visible: _isConfirmPasswordVisible,
                    toggle:
                        () => setState(
                          () =>
                              _isConfirmPasswordVisible =
                                  !_isConfirmPasswordVisible,
                        ),
                    confirm: true,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Checkbox(
                        value: _agreeToTerms,
                        onChanged: (v) => setState(() => _agreeToTerms = v!),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text("Terms & Conditions"),
                                  content: SingleChildScrollView(
                                    child: Text("""
1. You must provide authentic details to sign up.
2. Accounts are role-based (Student / Supervisor / Admin).
3. Do not share your login credentials.
4. Data is stored securely and used only for academic purposes.
5. Misuse of the platform may result in account termination.
6. The app is a support tool; developers are not responsible for academic results.
                                    """),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("Close"),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: const Text(
                            'I agree to the Terms & Conditions',
                            style: TextStyle(
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: _handleSignUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 24, 81, 91),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 100,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account? "),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SignInPage(),
                            ),
                          );
                        },
                        child: const Text(
                          "Sign In",
                          style: TextStyle(
                            color: Color(0xFFFF8A50),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ---------- Widgets ----------
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) => Container(
    decoration: _boxDecoration(),
    child: TextFormField(
      controller: controller,
      readOnly: readOnly,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color.fromARGB(255, 133, 213, 231)),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      validator: validator,
    ),
  );

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool visible,
    required VoidCallback toggle,
    bool confirm = false,
  }) => Container(
    decoration: _boxDecoration(),
    child: TextFormField(
      controller: controller,

      obscureText: !visible,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(
          Icons.lock,
          color: Color.fromARGB(255, 133, 213, 231),
        ),
        errorMaxLines: 3,
        suffixIcon: IconButton(
          icon: Icon(
            visible ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey,
          ),
          onPressed: toggle,
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),

      /// Single combined password validator (Option A)
      validator: (value) {
        if (value == null || value.isEmpty) {
          return confirm ? 'Please confirm password' : 'Please enter password';
        }

        // Required checks
        final hasUpper = RegExp(r'[A-Z]').hasMatch(value);
        final hasLower = RegExp(r'[a-z]').hasMatch(value);
        final hasDigit = RegExp(r'\d').hasMatch(value);
        final hasSpecial = RegExp(
          r'[!@#\$&*~%^()\-_=+{};:,.<>]',
        ).hasMatch(value);
        final minLen = value.length >= 6;

        if (!(minLen && hasUpper && hasLower && hasDigit && hasSpecial)) {
          return 'Password must be 6+ characters and include uppercase, lowercase, number & special character';
        }

        // Confirm password specific check
        if (confirm && value != _passwordController.text) {
          return 'Passwords do not match';
        }

        return null;
      },
    ),
  );

  Widget _buildRoleDropdown() => Container(
    decoration: _boxDecoration(),
    child: DropdownButtonFormField<String>(
      value: _selectedRole,
      items:
          ['student', 'supervisor', 'admin']
              .map(
                (role) => DropdownMenuItem(
                  value: role,
                  child: Text(role.toUpperCase()),
                ),
              )
              .toList(),
      onChanged: (v) {
        setState(() {
          _selectedRole = v;
          _selectedRegNo = null;
          _selectedFacultyId = null;
          _selectedAdminId = null;
          _userNameController.clear();
        });
      },
      decoration: const InputDecoration(
        hintText: 'Select Role',
        prefixIcon: Icon(Icons.work, color: Color.fromARGB(255, 133, 213, 231)),
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (v) => v == null ? 'Please select role' : null,
    ),
  );

  Widget _buildDepartmentDropdown() => Container(
    decoration: _boxDecoration(),
    child: DropdownButtonFormField<String>(
      value:
          _departmentController.text.isEmpty
              ? null
              : _departmentController.text,
      items:
          ['CS', 'SE']
              .map((dept) => DropdownMenuItem(value: dept, child: Text(dept)))
              .toList(),
      onChanged: (v) => setState(() => _departmentController.text = v!),
      decoration: const InputDecoration(
        hintText: 'Select Department',
        prefixIcon: Icon(
          Icons.apartment,
          color: Color.fromARGB(255, 133, 213, 231),
        ),
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (v) => v == null ? 'Please select department' : null,
    ),
  );

  Widget _buildRegDropdown() => FutureBuilder<List<String>>(
    future: _fetchRegistrationNumbers(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return const Text("No registration numbers found");
      }
      return Container(
        decoration: _boxDecoration(),
        child: DropdownButtonFormField<String>(
          value: _selectedRegNo,
          items:
              snapshot.data!
                  .map(
                    (regNo) =>
                        DropdownMenuItem(value: regNo, child: Text(regNo)),
                  )
                  .toList(),
          onChanged: (v) async {
            setState(() => _selectedRegNo = v);
            await _fetchName();
          },
          decoration: const InputDecoration(
            hintText: 'Select Registration No',
            prefixIcon: Icon(
              Icons.confirmation_number,
              color: Color.fromARGB(255, 133, 213, 231),
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator:
              (v) => v == null ? 'Please select a registration number' : null,
        ),
      );
    },
  );

  Widget _buildFacIdDropdown() => FutureBuilder<List<String>>(
    future: _fetchFacultyId(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return const Text("No Faculty Id found");
      }
      return Container(
        decoration: _boxDecoration(),
        child: DropdownButtonFormField<String>(
          value: _selectedFacultyId,
          items:
              snapshot.data!
                  .map(
                    (facId) =>
                        DropdownMenuItem(value: facId, child: Text(facId)),
                  )
                  .toList(),
          onChanged: (v) async {
            setState(() => _selectedFacultyId = v);
            await _fetchName();
          },
          decoration: const InputDecoration(
            hintText: 'Select Faculty Id',
            prefixIcon: Icon(
              Icons.confirmation_number,
              color: Color.fromARGB(255, 133, 213, 231),
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: (v) => v == null ? 'Please select a Faculty Id' : null,
        ),
      );
    },
  );

  Widget _buildAdminIdDropdown() => FutureBuilder<List<String>>(
    future: _fetchAdminIds(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return const Text("No Admin Id found");
      }
      return Container(
        decoration: _boxDecoration(),
        child: DropdownButtonFormField<String>(
          value: _selectedAdminId,
          items:
              snapshot.data!
                  .map((aid) => DropdownMenuItem(value: aid, child: Text(aid)))
                  .toList(),
          onChanged: (v) async {
            setState(() => _selectedAdminId = v);
            await _fetchName();
          },
          decoration: const InputDecoration(
            hintText: 'Select Admin Id',
            prefixIcon: Icon(
              Icons.admin_panel_settings,
              color: Color.fromARGB(255, 133, 213, 231),
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: (v) => v == null ? 'Please select an Admin Id' : null,
        ),
      );
    },
  );

  BoxDecoration _boxDecoration() => BoxDecoration(
    color: Colors.grey[50],
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.grey[200]!),
  );
}
