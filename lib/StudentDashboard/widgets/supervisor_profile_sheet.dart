import 'package:flutter/material.dart';

class SupervisorProfileSheet extends StatelessWidget {
  final Map<String, dynamic> supervisor;

  const SupervisorProfileSheet({Key? key, required this.supervisor}) : super(key: key);

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
    final name = supervisor['name'] ?? 'Unknown Supervisor';
    final department = supervisor['department'] ?? 'Department not specified';
    final specialization = supervisor['specialization'] ?? 'Not specified';
    final preferenceAreas = supervisor['preferenceAreas'] ?? '';
    final projectHistory = supervisor['projectsHistory'] ?? 'Not available';
    final rating = supervisor['rating'] != null
        ? (supervisor['rating'] as num).toDouble()
        : 4.0;

    // Extract specializations for tags
    List<String> specializations = [];
    if (supervisor['preferenceAreas'] != null) {
      if (supervisor['preferenceAreas'] is String) {
        specializations = supervisor['preferenceAreas']
            .toString()
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      } else if (supervisor['preferenceAreas'] is List) {
        specializations = (supervisor['preferenceAreas'] as List)
            .map((s) => s.toString())
            .toList();
      }
    }

    return Container(
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
                        name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 24, 81, 91),
                        ),
                      ),
                      Text(
                        department,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildStarRating(rating),
                          const SizedBox(width: 8),
                          Text(
                            '$rating Rating',
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
            // Show Preference Areas if present
            if (supervisor['preferenceAreas'] != null && supervisor['preferenceAreas'].toString().isNotEmpty)
              _buildDetailRow('Preference Areas', supervisor['preferenceAreas'] is List ? (supervisor['preferenceAreas'] as List).join(', ') : supervisor['preferenceAreas'].toString()),
            // Show Project Categories if present
            if (supervisor['projectHistoryCategories'] != null && supervisor['projectHistoryCategories'].toString().isNotEmpty)
              _buildDetailRow('Project Categories', supervisor['projectHistoryCategories'] is List ? (supervisor['projectHistoryCategories'] as List).join(', ') : supervisor['projectHistoryCategories'].toString()),
            // Show Specializations if present
            if (supervisor['specializations'] != null && supervisor['specializations'].toString().isNotEmpty)
              _buildDetailRow('Specializations', supervisor['specializations'] is List ? (supervisor['specializations'] as List).join(', ') : supervisor['specializations'].toString()),
            // Already present:
            _buildDetailRow('Specialization', specialization),
            _buildDetailRow('Projects History', projectHistory),
            // AI Match Reason
            if (supervisor['matchReason'] != null && supervisor['matchReason'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI Match Reason',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.purple.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        supervisor['matchReason'].toString(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            if (specializations.isNotEmpty) ...[
              const Text(
                'Areas of Interest',
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
                children: specializations.map((spec) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 133, 213, 231).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: const Color.fromARGB(255, 133, 213, 231).withOpacity(0.2),
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
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
