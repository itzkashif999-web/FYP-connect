import 'package:flutter/material.dart';
import 'package:fyp_connect/StudentDashboard/recommendation_tracking_service.dart';

class MetricsDashboardPage extends StatefulWidget {
  const MetricsDashboardPage({super.key});

  @override
  State<MetricsDashboardPage> createState() => _MetricsDashboardPageState();
}

class _MetricsDashboardPageState extends State<MetricsDashboardPage> {
  final RecommendationTrackingService _trackingService =
      RecommendationTrackingService();
  bool _isLoading = true;
  Map<String, dynamic>? _summary;
  Map<String, dynamic>? _precisionMetrics;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final summary = await _trackingService.getTrackingSummary();
      final precision = await _trackingService.calculatePrecisionMetrics(k: 5);

      setState(() {
        _summary = summary;
        _precisionMetrics = precision;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load metrics: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Recommendation Metrics',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 24, 81, 91),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadMetrics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color.fromARGB(255, 24, 81, 91),
              ),
            )
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadMetrics,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 24, 81, 91),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color.fromARGB(255, 24, 81, 91),
                              Color.fromARGB(255, 133, 213, 231),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.analytics, color: Colors.white, size: 32),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'System Performance Metrics',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Measuring recommendation accuracy and effectiveness',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Precision Metrics
                      if (_precisionMetrics != null) ...[
                        _buildSectionTitle('Precision Metrics'),
                        _buildMetricCard(
                          title: 'Overall Precision@5',
                          value: _precisionMetrics!['percentage'] ?? 'N/A',
                          subtitle:
                              'Success rate of recommendations (top 5)',
                          icon: Icons.track_changes,
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricCard(
                                title: 'AI RAG Precision',
                                value: _precisionMetrics!['ai_rag_precision'] !=
                                        null
                                    ? '${(_precisionMetrics!['ai_rag_precision'] * 100).toStringAsFixed(1)}%'
                                    : 'N/A',
                                subtitle:
                                    '${_precisionMetrics!['ai_rag_samples'] ?? 0} samples',
                                icon: Icons.psychology,
                                color: Colors.purple,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMetricCard(
                                title: 'Pattern Precision',
                                value: _precisionMetrics![
                                            'pattern_matching_precision'] !=
                                        null
                                    ? '${(_precisionMetrics!['pattern_matching_precision'] * 100).toStringAsFixed(1)}%'
                                    : 'N/A',
                                subtitle:
                                    '${_precisionMetrics!['pattern_matching_samples'] ?? 0} samples',
                                icon: Icons.pattern,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Acceptance Rates
                      if (_summary != null) ...[
                        _buildSectionTitle('Acceptance Rates'),
                        _buildMetricCard(
                          title: 'Overall Acceptance',
                          value: '${_summary!['acceptance_rate'] ?? '0.0'}%',
                          subtitle:
                              '${_summary!['total_accepted'] ?? 0} / ${_summary!['total_shown'] ?? 0} shown',
                          icon: Icons.check_circle,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricCard(
                                title: 'AI RAG',
                                value:
                                    '${_summary!['ai_acceptance_rate'] ?? '0.0'}%',
                                subtitle:
                                    '${_summary!['ai_rag_accepted'] ?? 0} / ${_summary!['ai_rag_shown'] ?? 0}',
                                icon: Icons.auto_awesome,
                                color: Colors.purple,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMetricCard(
                                title: 'Pattern',
                                value:
                                    '${_summary!['pattern_acceptance_rate'] ?? '0.0'}%',
                                subtitle:
                                    '${_summary!['pattern_accepted'] ?? 0} / ${_summary!['pattern_shown'] ?? 0}',
                                icon: Icons.analytics_outlined,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Explanation Card
                      _buildInfoCard(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(255, 24, 81, 91),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                'About These Metrics',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            'Precision@5',
            'Percentage of times the accepted supervisor was in the top 5 recommendations',
          ),
          const SizedBox(height: 8),
          _buildInfoItem(
            'Acceptance Rate',
            'Percentage of shown recommendations that led to proposal submissions',
          ),
          const SizedBox(height: 8),
          _buildInfoItem(
            'Samples',
            'Number of recommendation events analyzed for each method',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '• $title:',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }
}
