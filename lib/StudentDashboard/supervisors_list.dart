
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'submit_proposal_page.dart';

class Supervisor {
  final String name;
  final String department;
  final String expertise;
  final double rating;
  final String interest;
  final List<String> specializations;
  final String availability;
  final String email;
  final String id;

  Supervisor({
    required this.name,
    required this.department,
    required this.expertise,
    required this.rating,
    required this.interest,
    required this.specializations,
    required this.availability,
    required this.email,
    required this.id,
  });
}

class SupervisorListPage extends StatefulWidget {
  const SupervisorListPage({super.key});

  @override
  State<SupervisorListPage> createState() => _SupervisorListPageState();
}

class _SupervisorListPageState extends State<SupervisorListPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  List<Supervisor> supervisors = [];
  bool _canApply = true; // Tracks if Apply button should be enabled

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _fetchSupervisors();
    _listenProposalStatus();
  }

  /// Listen to student's proposals in real-time
  void _listenProposalStatus() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    FirebaseFirestore.instance
        .collection('proposals')
        .where('studentId', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
          bool hasPendingOrAccepted = false;
          for (var doc in snapshot.docs) {
            final status = (doc['status'] ?? '').toString().toLowerCase();
            if (status == 'pending' || status == 'accepted') {
              hasPendingOrAccepted = true;
              break;
            }
          }

          setState(() {
            _canApply =
                !hasPendingOrAccepted; // disables Apply if pending/accepted
          });
        });
  }

  Future<void> _fetchSupervisors() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('supervisor_profiles')
            .get();

    final data =
        snapshot.docs.map((doc) {
          final d = doc.data();
          return Supervisor(
            id: d['id'] ?? doc.id,
            name: d['name'] ?? 'N/A',
            department: d['department'] ?? 'N/A',
            expertise: d['interest'] ?? 'N/A',
            rating: (d['rating'] ?? 0).toDouble(),
            interest: d['projectsHistory'] ?? 'N/A',
            specializations:
                d['specializations'] != null
                    ? List<String>.from(d['specializations'])
                    : [],
            availability: d['availability'] ?? 'Available',
            email: d['email'] ?? 'N/A',
          );
        }).toList();

    setState(() {
      supervisors = data;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getAvailabilityColor(String availability) {
    switch (availability) {
      case 'Available':
        return Colors.green;
      case 'Limited':
        return Colors.orange;
      case 'Busy':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating.floor()
              ? Icons.star
              : index < rating
              ? Icons.star_half
              : Icons.star_border,
          color: Colors.amber,
          size: 16,
        );
      }),
    );
  }

  void _showSupervisorDetails(Supervisor supervisor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 40,
                        backgroundColor: Color.fromARGB(255, 24, 81, 91),
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              supervisor.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 24, 81, 91),
                              ),
                            ),
                            Text(
                              supervisor.department,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildStarRating(supervisor.rating),
                                const SizedBox(width: 8),
                                Text(
                                  '${supervisor.rating} Rating',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  _buildDetailRow('Expertise', supervisor.expertise),
                  _buildDetailRow('Experience', supervisor.interest),
                  _buildDetailRow('Email', supervisor.email),
                  const SizedBox(height: 20),
                  if (supervisor.specializations.isNotEmpty) ...[
                    const Text(
                      'Specializations',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 24, 81, 91),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          supervisor.specializations
                              .map(
                                (spec) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(
                                      255,
                                      133,
                                      213,
                                      231,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: const Color.fromARGB(
                                        255,
                                        133,
                                        213,
                                        231,
                                      ).withOpacity(0.2),
                                    ),
                                  ),
                                  child: Text(
                                    spec,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color.fromARGB(255, 24, 81, 91),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ],
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color.fromARGB(255, 24, 81, 91),
                            Color.fromARGB(255, 133, 213, 231),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ElevatedButton(
                        onPressed:
                            _canApply
                                ? () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => SubmitProposalPage(
                                            supervisorName: supervisor.name,
                                            supervisorId: supervisor.id,
                                          ),
                                    ),
                                  );
                                }
                                : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          'Submit Proposal',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 24, 81, 91),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Available Supervisors',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 24, 81, 91),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child:
            supervisors.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: supervisors.length,
                  itemBuilder: (context, index) {
                    final supervisor = supervisors[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const CircleAvatar(
                                  radius: 32,
                                  backgroundColor: Color.fromARGB(
                                    255,
                                    24,
                                    81,
                                    91,
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        supervisor.name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color.fromARGB(
                                            255,
                                            133,
                                            213,
                                            231,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        supervisor.department,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          _buildStarRating(supervisor.rating),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${supervisor.rating}',
                                            style: const TextStyle(
                                              color: Colors.amber,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getAvailabilityColor(
                                      supervisor.availability,
                                    ).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    supervisor.availability,
                                    style: TextStyle(
                                      color: _getAvailabilityColor(
                                        supervisor.availability,
                                      ),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed:
                                        () =>
                                            _showSupervisorDetails(supervisor),
                                    icon: const Icon(Icons.info_outline),
                                    label: const Text('Details'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed:
                                        _canApply
                                            ? () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (_) => SubmitProposalPage(
                                                        supervisorName:
                                                            supervisor.name,
                                                        supervisorId:
                                                            supervisor.id,
                                                      ),
                                                ),
                                              );
                                            }
                                            : null,
                                    icon: const Icon(Icons.send),
                                    label: const Text('Apply'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
