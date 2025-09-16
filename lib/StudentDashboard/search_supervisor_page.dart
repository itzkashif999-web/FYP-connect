import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'submit_proposal_page.dart';

class SearchSupervisorPage extends StatefulWidget {
  const SearchSupervisorPage({super.key});

  @override
  State<SearchSupervisorPage> createState() => _SearchSupervisorPageState();
}

class _SearchSupervisorPageState extends State<SearchSupervisorPage> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _hasPendingOrAcceptedProposal = false; // 🔹 flag to disable all buttons

  @override
  void initState() {
    super.initState();
    _checkProposalStatus();
  }

  void _checkProposalStatus() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    FirebaseFirestore.instance
        .collection('proposals')
        .where('studentId', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
          bool disableButtons = false;

          for (var doc in snapshot.docs) {
            final status = (doc['status'] ?? '').toString().toLowerCase();
            if (status == 'pending' || status == 'accepted') {
              disableButtons = true;
              break; // one pending/accepted proposal is enough
            }
          }

          setState(() {
            _hasPendingOrAcceptedProposal = disableButtons;
          });
        });
  }

  void _search() async {
    final query = _searchController.text.toLowerCase();
    final snapshot =
        await FirebaseFirestore.instance
            .collection('supervisor_profiles')
            .get();

    setState(() {
      _results =
          snapshot.docs
              .map((doc) => doc.data())
              .where(
                (data) =>
                    data['name'].toString().toLowerCase().contains(query) ||
                    data['specialization'].toString().toLowerCase().contains(
                      query,
                    ) ||
                    data['department'].toString().toLowerCase().contains(query),
              )
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Search Supervisor',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 24, 81, 91),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Header + Search Field
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
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
              child: Column(
                children: [
                  const Text(
                    'Find the perfect supervisor for your project',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Search by name/specialization/department',
                        labelStyle: TextStyle(color: Colors.grey[600]),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color.fromARGB(255, 133, 213, 231),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(
                            Icons.search,
                            color: Color.fromARGB(255, 133, 213, 231),
                          ),
                          onPressed: _search,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Results or Empty State
          Expanded(
            child:
                _results.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search, size: 80, color: Colors.grey[400]),
                          const SizedBox(height: 20),
                          Text(
                            'Start searching for supervisors',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Enter keywords to find matching supervisors',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final supervisor = _results[index];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                // Avatar
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
                                const SizedBox(width: 15),
                                // Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        supervisor['name'],
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color.fromARGB(
                                            255,
                                            24,
                                            81,
                                            91,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        supervisor['department'] ?? '',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Apply Button
                                Container(
                                  decoration: BoxDecoration(
                                    color:
                                        _hasPendingOrAcceptedProposal
                                            ? Colors.grey
                                            : null,
                                    gradient:
                                        _hasPendingOrAcceptedProposal
                                            ? null
                                            : const LinearGradient(
                                              colors: [
                                                Color.fromARGB(255, 24, 81, 91),
                                                Color.fromARGB(
                                                  255,
                                                  133,
                                                  213,
                                                  231,
                                                ),
                                              ],
                                            ),
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: ElevatedButton(
                                    onPressed:
                                        _hasPendingOrAcceptedProposal
                                            ? null
                                            : () async {
                                              await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (_) => SubmitProposalPage(
                                                        supervisorName:
                                                            supervisor['name'],
                                                        supervisorId:
                                                            supervisor['id'],
                                                      ),
                                                ),
                                              );
                                            },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 10,
                                      ),
                                    ),
                                    child: Text(
                                      _hasPendingOrAcceptedProposal
                                          ? 'Disabled'
                                          : 'Apply',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
