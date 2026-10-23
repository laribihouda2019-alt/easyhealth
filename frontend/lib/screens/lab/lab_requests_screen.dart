import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';

class LabRequestsScreen extends StatefulWidget {
  const LabRequestsScreen({super.key});

  @override
  State<LabRequestsScreen> createState() => _LabRequestsScreenState();
}

class _LabRequestsScreenState extends State<LabRequestsScreen> {
  final _api = ApiService();
  List<dynamic> _requests = [];
  bool _isLoading = true;
  final Set<String> _processingIds = {}; // Pour l'indicateur de chargement par item

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    try {
      setState(() => _isLoading = true);
      final response = await _api.getLabRequests();
      if (mounted) {
        setState(() {
          // Filtrer pour ne montrer que ce qui n'est pas encore terminé
          _requests = response.where((r) => r['status'] != 'completed').toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsCompleted(String requestId) async {
    try {
      setState(() => _processingIds.add(requestId));
      await _api.updateLabRequestStatus(requestId, 'completed');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demande marquée comme terminée'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processingIds.remove(requestId));
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demandes d\'examens'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchRequests),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? const Center(child: Text('Aucune demande pour le moment'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _requests.length,
                  itemBuilder: (context, index) {
                    final req = _requests[index];
                    final date = DateFormat('dd/MM HH:mm').format(DateTime.parse(req['created_at']).toLocal());
                    final status = req['status'] as String;
                    final isPaid = status == 'paid';
                    
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
                                Text('Demande #${req['id'].toString().substring(0, 8)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                _buildStatusBadge(status),
                              ],
                            ),
                            const Divider(height: 24),
                            Text('Patient: ${req['patient_name'] ?? 'Inconnu'}',
                                style: const TextStyle(fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            Text('Date: $date', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 12),
                            Text('Test: ${req['test_type']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                              if (isPaid || status == 'pending')
                                Row(
                                  children: [
                                    if (isPaid) ...[
                                      const Icon(Icons.check_circle, color: Colors.green, size: 16),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: Text('Paiement confirmé', 
                                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ] else ...[
                                      const Icon(Icons.hourglass_empty, color: Colors.orange, size: 16),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: Text('En attente paiement', 
                                          style: TextStyle(color: Colors.orange),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                    ElevatedButton.icon(
                                      onPressed: _processingIds.contains(req['id']) 
                                          ? null 
                                          : () => _markAsCompleted(req['id'].toString()), 
                                      icon: _processingIds.contains(req['id'])
                                          ? const SizedBox(
                                              width: 14, 
                                              height: 14, 
                                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                            )
                                          : const Icon(Icons.check_circle_outline, size: 16),
                                      label: const Text('Terminé'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.indigo,
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(0, 32),
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

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'paid': color = Colors.green; label = 'PAYÉ'; break;
      case 'pending': color = Colors.orange; label = 'EN ATTENTE'; break;
      case 'completed': color = Colors.blue; label = 'COMPLÉTÉ'; break;
      default: color = Colors.grey; label = status.toUpperCase();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}


