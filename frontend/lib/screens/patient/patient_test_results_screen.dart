import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/api_config.dart';

class PatientTestResultsScreen extends StatefulWidget {
  const PatientTestResultsScreen({super.key});

  @override
  State<PatientTestResultsScreen> createState() => _PatientTestResultsScreenState();
}

class _PatientTestResultsScreenState extends State<PatientTestResultsScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _requests = [];

  @override
  void initState() {
    super.initState();
    _fetchMyTestResults();
  }

  Future<void> _fetchMyTestResults() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.getMyLabRequests();
      setState(() {
        // Filter out those that don't have results yet, or just show everything with a badge
        _requests = response; 
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _openResultFile(String urlPath) async {
    // Assuming backend serves static files at ApiConfig.baseUrl
    // The urlPath might be '/uploads/lab_results/xyz.pdf'
    // We need to resolve the full URL.
    try {
      final String fullUrl = urlPath.startsWith('http') 
          ? urlPath 
          : '${ApiConfig.mediaBaseUrl}$urlPath';
      final Uri uri = Uri.parse(fullUrl);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'Impossible d\'ouvrir le fichier $fullUrl';
      }
    } catch (e) {
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur d\'ouverture du fichier')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Résultats d\'Analyses'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? const Center(child: Text('Aucune demande d\'analyse trouvée.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _requests.length,
                  itemBuilder: (context, index) {
                    final req = _requests[index];
                    final date = req['created_at'] != null 
                        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(req['created_at']).toLocal())
                        : '';
                    
                    final resultUrl = req['result_url'] as String?;
                    final isCompleted = req['status'] == 'completed';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  req['test_type'] ?? 'Analyse',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isCompleted ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isCompleted ? 'COMPLÉTÉ' : 'EN COURS',
                                    style: TextStyle(
                                      color: isCompleted ? Colors.blue : Colors.orange,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Date: $date', style: const TextStyle(color: Colors.grey)),
                            const SizedBox(height: 16),
                            if (isCompleted && resultUrl != null)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _openResultFile(resultUrl),
                                  icon: const Icon(Icons.download),
                                  label: const Text('Télécharger / Voir le Résultat'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.indigo,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              )
                            else if (!isCompleted)
                              const Text(
                                'En attente des résultats du laboratoire...',
                                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}


