import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';
import 'medical_request_upload_screen.dart';

class ChifaCardScreen extends StatefulWidget {
  const ChifaCardScreen({super.key});

  @override
  State<ChifaCardScreen> createState() => _ChifaCardScreenState();
}

class _ChifaCardScreenState extends State<ChifaCardScreen> {
  final List<PlatformFile> _selectedFiles = [];
  bool _isUploading = false;
  List<dynamic> _myRequests = [];
  bool _isLoadingRequests = true;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoadingRequests = true);
    try {
      final requests = await ApiService().getMyChifaRequests();
      setState(() {
        _myRequests = requests;
        _isLoadingRequests = false;
      });
    } catch (e) {
      setState(() => _isLoadingRequests = false);
    }
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
    );

    if (result != null) {
      setState(() {
        _selectedFiles.addAll(result.files);
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner au moins un document')),
      );
      return;
    }

    setState(() => _isUploading = true);
    try {
      // 1. Upload real files to server
      final realUrls = await ApiService().uploadChifaDocuments(_selectedFiles);
      
      // 2. Submit request with real URLs
      await ApiService().submitChifaRequest(
        documentUrls: realUrls,
        notes: "Demande de réactivation de carte Chifa",
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demande envoyée avec succès'), backgroundColor: Colors.green),
      );
      
      setState(() => _selectedFiles.clear());
      _fetchRequests();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ma Carte Chifa'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMedicalControlCard(theme),
            const SizedBox(height: 24),
            Text(
              'Réactivation de carte',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            _buildUploadCard(theme),
            const SizedBox(height: 32),
            Text(
              'Mes demandes récentes',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _isLoadingRequests 
              ? const Center(child: CircularProgressIndicator())
              : _myRequests.isEmpty 
                  ? _buildEmptyState()
                  : _buildRequestList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalControlCard(ThemeData theme) {
    return Card(
      elevation: 0,
      color: Colors.teal.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.teal.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.medical_information, color: Colors.teal, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contrôle Médical',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Demandes de prise en charge et remboursements',
                    style: TextStyle(color: Colors.teal.shade800, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const MedicalRequestUploadScreen()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.teal.shade700,
                        side: BorderSide(color: Colors.teal.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Accéder au service'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadCard(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.credit_card_rounded, size: 48, color: Color(0xFF1565C0)),
            const SizedBox(height: 16),
            const Text(
              'Réactivation Carte Chifa',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Téléchargez vos documents (ID, Attestation, etc.)',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            if (_selectedFiles.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedFiles.map((file) => Chip(
                  label: Text(file.name, style: const TextStyle(fontSize: 12)),
                  onDeleted: () => setState(() => _selectedFiles.remove(file)),
                  deleteIconColor: Colors.red,
                )).toList(),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Choisir fichiers'),
                    onPressed: _pickFiles,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.send),
                    label: Text(_isUploading ? 'Envoi...' : 'Soumettre'),
                    onPressed: _isUploading ? null : _handleSubmit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _myRequests.length,
      itemBuilder: (context, index) {
        final req = _myRequests[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(req['status']).withOpacity(0.1),
              child: Icon(Icons.description, color: _getStatusColor(req['status'])),
            ),
            title: Text('Demande du ${DateFormat('dd/MM/yyyy').format(DateTime.parse(req['created_at']))}'),
            subtitle: Text('Status: ${req['status']}'),
            trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.history_rounded, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Aucune demande effectuée',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Acceptée': return Colors.green;
      case 'Rejetée': return Colors.red;
      default: return Colors.orange;
    }
  }
}


