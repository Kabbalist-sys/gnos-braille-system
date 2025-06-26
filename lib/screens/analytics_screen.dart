import 'package:flutter/material.dart';
import '../services/cloud_storage_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _cloudStorageService = CloudStorageService();
  Map<String, dynamic>? _statistics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _cloudStorageService.getUserStatistics();
      if (!mounted) return;
      setState(() {
        _statistics = stats;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading statistics: [4m${e.toString()}[0m'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: Colors.purple[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _statistics == null
              ? const Center(
                  child: Text('No analytics data available'),
                )
              : RefreshIndicator(
                  onRefresh: _loadStatistics,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Overview Cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Total Translations',
                                _statistics!['totalTranslations']?.toString() ??
                                    '0',
                                Icons.translate,
                                Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                'Characters Translated',
                                _formatNumber(
                                    _statistics!['totalCharacters'] ?? 0),
                                Icons.text_fields,
                                Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Languages Used',
                                _statistics!['languagesUsed']
                                        ?.length
                                        ?.toString() ??
                                    '0',
                                Icons.language,
                                Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                'Braille Standards',
                                _statistics!['brailleStandardsUsed']
                                        ?.length
                                        ?.toString() ??
                                    '0',
                                Icons.accessibility,
                                Colors.purple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Usage Breakdown
                        _buildSectionCard(
                          'Usage Breakdown',
                          Icons.pie_chart,
                          [
                            _buildLanguageBreakdown(),
                            const SizedBox(height: 16),
                            _buildStandardBreakdown(),
                            const SizedBox(height: 16),
                            _buildDirectionBreakdown(),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Recent Activity
                        _buildSectionCard(
                          'Recent Activity',
                          Icons.timeline,
                          [
                            _buildActivityTimeline(),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Performance Metrics
                        _buildSectionCard(
                          'Performance',
                          Icons.speed,
                          [
                            _buildPerformanceMetrics(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.purple[700]),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageBreakdown() {
    final languages = _statistics!['languagesUsed'] as List<dynamic>? ?? [];
    final languageStats =
        _statistics!['languageStats'] as Map<String, dynamic>? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Languages',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...languages.map<Widget>((lang) {
          final count = languageStats[lang] ?? 0;
          final percentage = _statistics!['totalTranslations'] > 0
              ? (count / _statistics!['totalTranslations'] * 100)
              : 0.0;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(_getLanguageName(lang)),
                ),
                Expanded(
                  flex: 3,
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.blue[400]!),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${percentage.toStringAsFixed(1)}%'),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStandardBreakdown() {
    final standards =
        _statistics!['brailleStandardsUsed'] as List<dynamic>? ?? [];
    final standardStats =
        _statistics!['standardStats'] as Map<String, dynamic>? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Braille Standards',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...standards.map<Widget>((standard) {
          final count = standardStats[standard] ?? 0;
          final percentage = _statistics!['totalTranslations'] > 0
              ? (count / _statistics!['totalTranslations'] * 100)
              : 0.0;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(_getStandardName(standard)),
                ),
                Expanded(
                  flex: 3,
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.green[400]!),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${percentage.toStringAsFixed(1)}%'),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDirectionBreakdown() {
    final toBrailleCount = _statistics!['toBrailleCount'] ?? 0;
    final fromBrailleCount = _statistics!['fromBrailleCount'] ?? 0;
    final total = toBrailleCount + fromBrailleCount;

    if (total == 0) {
      return const Text('No translation data available');
    }

    final toBraillePercentage = (toBrailleCount / total * 100);
    final fromBraillePercentage = (fromBrailleCount / total * 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Translation Direction',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Expanded(
              flex: 2,
              child: Text('To Braille'),
            ),
            Expanded(
              flex: 3,
              child: LinearProgressIndicator(
                value: toBraillePercentage / 100,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[400]!),
              ),
            ),
            const SizedBox(width: 8),
            Text('${toBraillePercentage.toStringAsFixed(1)}%'),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Expanded(
              flex: 2,
              child: Text('From Braille'),
            ),
            Expanded(
              flex: 3,
              child: LinearProgressIndicator(
                value: fromBraillePercentage / 100,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.purple[400]!),
              ),
            ),
            const SizedBox(width: 8),
            Text('${fromBraillePercentage.toStringAsFixed(1)}%'),
          ],
        ),
      ],
    );
  }

  Widget _buildActivityTimeline() {
    final recentActivity =
        _statistics!['recentActivity'] as List<dynamic>? ?? [];

    if (recentActivity.isEmpty) {
      return const Text('No recent activity');
    }

    return Column(
      children: recentActivity.take(5).map<Widget>((activity) {
        final timestamp = DateTime.parse(activity['timestamp']);
        final ago = _getTimeAgo(timestamp);

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.purple[100],
            child: Icon(
              activity['isReverse'] ? Icons.visibility : Icons.accessibility,
              color: Colors.purple[700],
            ),
          ),
          title: Text(
            activity['isReverse'] ? 'From Braille' : 'To Braille',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text('${activity['language']} • ${activity['standard']}'),
          trailing: Text(
            ago,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          contentPadding: EdgeInsets.zero,
        );
      }).toList(),
    );
  }

  Widget _buildPerformanceMetrics() {
    final avgTranslationTime = _statistics!['avgTranslationTime'] ?? 0.0;
    final successRate = _statistics!['successRate'] ?? 100.0;
    final totalApiCalls = _statistics!['totalApiCalls'] ?? 0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMetricItem(
              'Avg. Time',
              '${avgTranslationTime.toStringAsFixed(1)}s',
              Icons.timer,
            ),
            _buildMetricItem(
              'Success Rate',
              '${successRate.toStringAsFixed(1)}%',
              Icons.check_circle,
            ),
            _buildMetricItem(
              'API Calls',
              _formatNumber(totalApiCalls),
              Icons.api,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.purple[700], size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }

  String _getLanguageName(String code) {
    const languageNames = {
      'en': 'English',
      'es': 'Spanish',
      'fr': 'French',
      'de': 'German',
      'it': 'Italian',
      'pt': 'Portuguese',
      'ru': 'Russian',
      'zh': 'Chinese',
      'ja': 'Japanese',
      'ar': 'Arabic',
    };
    return languageNames[code] ?? code.toUpperCase();
  }

  String _getStandardName(String code) {
    const standardNames = {
      'grade1': 'Grade 1',
      'grade2': 'Grade 2',
      'grade3': 'Grade 3',
      'computer': 'Computer',
      'math': 'Math/Science',
      'music': 'Music',
    };
    return standardNames[code] ?? code;
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
