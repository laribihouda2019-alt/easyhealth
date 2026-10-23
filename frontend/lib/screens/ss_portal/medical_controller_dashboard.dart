import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import 'medical_request_review_screen.dart';
import 'package:intl/intl.dart';

class MedicalControllerDashboard extends StatefulWidget {
  const MedicalControllerDashboard({super.key});

  @override
  State<MedicalControllerDashboard> createState() => _MedicalControllerDashboardState();
}

class _MedicalControllerDashboardState extends State<MedicalControllerDashboard> {
  final _api = ApiService();
  List<dynamic> _pendingRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPending();
  }

  Future<void> _fetchPending() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.getPendingMedicalRequests();
      setState(() {
        _pendingRequests = response['data'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = AuthService().currentUser;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(user, theme),
          _buildRequestList(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(user, theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: theme.primaryColor.withOpacity(0.1),
            child: Icon(Icons.medical_services_outlined, color: theme.primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Approbations Médicales',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Examen des demandes de prise en charge',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
          _buildStatBadge('${_pendingRequests.length}', 'En attente', Colors.orange),
          const SizedBox(width: 12),
          IconButton(onPressed: _fetchPending, icon: const Icon(Icons.refresh)),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildRequestList(theme) {
    if (_pendingRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Aucune demande en attente', style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _pendingRequests.length,
      itemBuilder: (context, index) {
        final req = _pendingRequests[index];
        final DateTime date = DateTime.parse(req['created_at']);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => MedicalRequestReviewScreen(request: req)),
              );
              if (result == true) _fetchPending();
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildTypeIcon(req['request_type']),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          req['patient_name'] ?? 'Patient inconnu',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Type: ${req['request_type']} • ${DateFormat('dd MMM, HH:mm').format(date)}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                        if (req['description'] != null && req['description'].toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              req['description'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontStyle: FontStyle.italic),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypeIcon(String type) {
    IconData icon;
    Color color;
    switch (type) {
      case 'medicaments':
        icon = Icons.medication;
        color = Colors.blue;
        break;
      case 'prise_en_charge':
        icon = Icons.biotech;
        color = Colors.teal;
        break;
      default:
        icon = Icons.description;
        color = Colors.indigo;
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 24),
    );
  }
}


