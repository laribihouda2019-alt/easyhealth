import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../services/api_service.dart';

class HealthAlertScreen extends StatefulWidget {
  const HealthAlertScreen({super.key});

  @override
  State<HealthAlertScreen> createState() => _HealthAlertScreenState();
}

class _HealthAlertScreenState extends State<HealthAlertScreen> {
  final _api = ApiService();
  List<dynamic> _alerts = [];
  bool _isLoading = true;
  bool _isGeneratingAdvice = false;

  @override
  void initState() {
    super.initState();
    _fetchDetailedAlerts();
  }

  Future<void> _fetchDetailedAlerts() async {
    try {
      final response = await _api.get('/disease-observatory/detailed-alerts');
      if (response != null && response['success'] == true) {
        setState(() {
          _alerts = response['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showAIAdvice(String symptom, String region) async {
    setState(() => _isGeneratingAdvice = true);
    
    try {
      final response = await _api.get(
        '/disease-observatory/ai-preventive-advice',
        queryParameters: {'symptom': symptom, 'region': region},
      );

      if (mounted) {
        setState(() => _isGeneratingAdvice = false);
        
        if (response != null && response['success'] == true) {
          final advice = response['data']['advice'];
          final source = response['data']['source'];

          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.blue),
                      const SizedBox(width: 12),
                      Text(
                        'Conseils IA ($symptom)',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  Expanded(
                    child: Markdown(
                      data: advice,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Source : $source',
                    style: const TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Le service de conseil IA est temporairement indisponible. Veuillez réessayer plus tard.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGeneratingAdvice = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Oups ! Une erreur est survenue lors de la génération des conseils.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Observatoire de Santé IA')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _alerts.isEmpty
              ? const Center(child: Text('Aucune alerte active pour le moment'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _alerts.length,
                  itemBuilder: (context, index) {
                    final alert = _alerts[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 24),
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.red.shade400, Colors.red.shade700],
                              ),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Alerte : ${alert['region']}',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                      ),
                                      Text(
                                        'Fréquence : ${alert['percentage']}% des consultations',
                                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Condition Prevalente',
                                  style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  alert['dominant_symptom'],
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: FilledButton.icon(
                                    onPressed: _isGeneratingAdvice 
                                        ? null 
                                        : () => _showAIAdvice(alert['dominant_symptom'], alert['region']),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.blue.shade600,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                    icon: _isGeneratingAdvice 
                                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                        : const Icon(Icons.auto_awesome),
                                    label: const Text(
                                      'Obtenir Conseils IA',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}


