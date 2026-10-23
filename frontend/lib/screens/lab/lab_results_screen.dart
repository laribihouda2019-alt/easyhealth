import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

class LabResultsScreen extends StatefulWidget {
  const LabResultsScreen({super.key});

  @override
  State<LabResultsScreen> createState() => _LabResultsScreenState();
}

class _LabResultsScreenState extends State<LabResultsScreen> {
  final _api = ApiService();
  List<dynamic> _completedRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCompletedRequests();
  }

  Future<void> _fetchCompletedRequests() async {
    try {
      setState(() => _isLoading = true);
      // Fetch all requests and filter for 'completed'
      final response = await _api.getLabRequests();
      if (mounted) {
        setState(() {
          _completedRequests = response.where((r) => r['status'] == 'completed').toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadResult(String requestId) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() => _isLoading = true);
        
        await _api.uploadTestResult(
          requestId: requestId,
          status: 'Ready',
          fileBytes: result.files.single.bytes,
          fileName: result.files.single.name,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Résultat envoyé avec succès au patient')),
          );
          _fetchCompletedRequests();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'envoi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Résultats d\'analyses'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchCompletedRequests),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _completedRequests.isEmpty
              ? const Center(child: Text('Aucun patient avec test terminé.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _completedRequests.length,
                  itemBuilder: (context, index) {
                    final req = _completedRequests[index];
                    final date = DateFormat('dd/MM HH:mm').format(DateTime.parse(req['created_at']).toLocal());
                    final hasResult = req['result_url'] != null;
                    
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
                                Text('Patient: ${req['patient_name'] ?? 'Inconnu'}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                if (hasResult)
                                  const Icon(Icons.check_circle, color: Colors.green)
                                else
                                  const Icon(Icons.pending, color: Colors.orange),
                              ],
                            ),
                            const Divider(height: 24),
                            Text('Test: ${req['test_type']}', style: const TextStyle(fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            Text('Terminé le: $date', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    hasResult ? 'Résultat déjà envoyé' : 'Résultat en attente d\'envoi',
                                    style: TextStyle(
                                      color: hasResult ? Colors.green : Colors.orange,
                                      fontStyle: FontStyle.italic,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => _uploadResult(req['id'].toString()),
                                  icon: const Icon(Icons.upload_file),
                                  label: Text(hasResult ? 'Remplacer' : 'Uploader'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: hasResult ? Colors.grey : Colors.teal,
                                    foregroundColor: Colors.white,
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
    );
  }
}


