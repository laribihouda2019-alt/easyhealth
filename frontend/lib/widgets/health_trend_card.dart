import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../screens/patient/health_alert_screen.dart';

class HealthTrendCard extends StatefulWidget {
  const HealthTrendCard({super.key});

  @override
  State<HealthTrendCard> createState() => _HealthTrendCardState();
}

class _HealthTrendCardState extends State<HealthTrendCard> {
  final _api = ApiService();
  Map<String, dynamic>? _latestTrend;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTrends();
  }

  Future<void> _fetchTrends() async {
    try {
      final response = await _api.get('/disease-observatory/trends');
      if (response != null && response['data'] != null && response['data'].isNotEmpty) {
        setState(() {
          _latestTrend = response['data'][0]; // Get the top trend
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();
    if (_latestTrend == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade50, Colors.white],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: ListTile(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const HealthAlertScreen()),
          );
        },
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
        ),
        title: Text(
          'Alerte Santé: ${_latestTrend!['region']}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          _latestTrend!['summary'],
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.orange),
      ),
    );
  }
}


