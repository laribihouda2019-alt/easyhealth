import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'prescription_form_screen.dart';

class PatientRecordsView extends StatefulWidget {
  final String patientId;
  const PatientRecordsView({super.key, required this.patientId});

  @override
  State<PatientRecordsView> createState() => _PatientRecordsViewState();
}

class _PatientRecordsViewState extends State<PatientRecordsView> {
  final ApiService _api = ApiService();
  List<dynamic> _records = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchRecords();
  }

  Future<void> _fetchRecords() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _api.getPatientMedicalRecords(widget.patientId);
      if (mounted) {
        setState(() {
          _records = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Impossible de charger le dossier. Vérifiez l\'ID ou la connexion.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Dossier Patient Scanné'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _records.isEmpty
                  ? _buildEmptyState()
                  : _buildRecordsList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PrescriptionFormScreen(
                patientId: widget.patientId,
                patientName: "Patient Scanné",
              ),
            ),
          );
        },
        label: const Text('Rédiger Ordonnance'),
        icon: const Icon(Icons.edit_note),
        backgroundColor: Colors.teal,
      ),
    );
  }

  Widget _buildRecordsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _records.length,
      itemBuilder: (context, index) {
        final record = _records[index];
        final date = DateFormat('dd MMM yyyy', 'fr_FR').format(DateTime.parse(record['created_at']));
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.indigo,
              child: Icon(Icons.description, color: Colors.white),
            ),
            title: Text(record['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${record['category']} • $date'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Open record details / image
              _showRecordDetails(record);
            },
          ),
        );
      },
    );
  }

  void _showRecordDetails(dynamic record) {
    final fullUrl = '${ApiConfig.mediaBaseUrl}${record['file_url']}';
    final isImage = record['file_url'].toLowerCase().endsWith('.jpg') || 
                    record['file_url'].toLowerCase().endsWith('.jpeg') || 
                    record['file_url'].toLowerCase().endsWith('.png');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(record['title']),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isImage) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    fullUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 100,
                      color: Colors.grey[200],
                      child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text('Catégorie: ${record['category']}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Notes: ${record['notes'] ?? 'Aucune note'}'),
              const SizedBox(height: 16),
              const Text('Fichier:', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 4),
              InkWell(
                onTap: () => launchUrlString(fullUrl, mode: LaunchMode.externalApplication),
                child: Text(
                  fullUrl,
                  style: const TextStyle(
                    color: Colors.blue, 
                    decoration: TextDecoration.underline,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () => launchUrlString(fullUrl, mode: LaunchMode.externalApplication),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Ouvrir en plein écran'),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: Colors.black87), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _fetchRecords, child: const Text('Réessayer')),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('Ce patient n\'a aucun document dans son dossier.'),
        ],
      ),
    );
  }
}


