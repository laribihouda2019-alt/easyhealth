import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';

class MedicalRequestUploadScreen extends StatefulWidget {
  const MedicalRequestUploadScreen({super.key});

  @override
  State<MedicalRequestUploadScreen> createState() => _MedicalRequestUploadScreenState();
}

class _MedicalRequestUploadScreenState extends State<MedicalRequestUploadScreen> {
  final _api = ApiService();
  final _descriptionController = TextEditingController();
  
  PlatformFile? _prescriptionFile;
  List<PlatformFile> _supportingDocs = [];
  String _requestType = 'medicaments';
  
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
      final response = await _api.getMyMedicalRequests();
      setState(() {
        _myRequests = response['data'] ?? [];
        _isLoadingRequests = false;
      });
    } catch (e) {
      setState(() => _isLoadingRequests = false);
    }
  }

  Future<void> _pickPrescription() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
    );
    if (result != null) {
      setState(() => _prescriptionFile = result.files.first);
    }
  }

  Future<void> _pickSupportingDocs() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
    );
    if (result != null) {
      setState(() => _supportingDocs.addAll(result.files));
    }
  }

  Future<void> _handleSubmit() async {
    if (_prescriptionFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner votre ordonnance')),
      );
      return;
    }

    setState(() => _isUploading = true);
    try {
      final data = await _api.submitMedicalRequest(
        requestType: _requestType,
        description: _descriptionController.text,
        prescription: _prescriptionFile!,
        supportingDocs: _supportingDocs,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demande envoyée au contrôle médical'), backgroundColor: Colors.green),
      );
      
      setState(() {
        _prescriptionFile = null;
        _supportingDocs.clear();
        _descriptionController.clear();
      });
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
        title: const Text('Prise en Charge Médicale'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUploadForm(theme),
            const SizedBox(height: 32),
            Text(
              'Mes demandes de prise en charge',
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

  Widget _buildUploadForm(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nouvelle demande',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _requestType,
              decoration: const InputDecoration(labelText: 'Type de demande'),
              items: const [
                DropdownMenuItem(value: 'medicaments', child: Text('Médicaments')),
                DropdownMenuItem(value: 'prise_en_charge', child: Text('Prise en Charge (Soins/Analyse)')),
                DropdownMenuItem(value: 'appareillage', child: Text('Appareillage')),
              ],
              onChanged: (val) => setState(() => _requestType = val!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description / Notes supplémentaires',
                hintText: 'Précisez votre demande...',
              ),
            ),
            const SizedBox(height: 24),
            const Text('Documents requis', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            // Prescription Upload
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.receipt_long, color: theme.primaryColor),
              title: const Text('Ordonnance (Obligatoire)'),
              subtitle: Text(_prescriptionFile?.name ?? 'Aucun fichier choisi'),
              trailing: IconButton(
                icon: const Icon(Icons.add_photo_alternate_outlined),
                onPressed: _pickPrescription,
              ),
            ),
            
            // Supporting Docs Upload
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.file_present, color: Colors.teal),
              title: const Text('Documents de soutien'),
              subtitle: Text('${_supportingDocs.length} fichiers sélectionnés'),
              trailing: IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: _pickSupportingDocs,
              ),
            ),
            
            if (_supportingDocs.isNotEmpty)
              Wrap(
                spacing: 8,
                children: _supportingDocs.map((f) => Chip(
                  label: Text(f.name, style: const TextStyle(fontSize: 10)),
                  onDeleted: () => setState(() => _supportingDocs.remove(f)),
                )).toList(),
              ),
              
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.cloud_upload_outlined),
                label: Text(_isUploading ? 'Envoi en cours...' : 'Soumettre au contrôle médical'),
                onPressed: _isUploading ? null : _handleSubmit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
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
        final DateTime date = DateTime.parse(req['created_at']);
        final status = req['status'];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(status).withOpacity(0.1),
              child: Icon(_getStatusIcon(status), color: _getStatusColor(status)),
            ),
            title: Text(req['request_type'] == 'medicaments' ? 'Médicaments' : 'Soins médicaux'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Date: ${DateFormat('dd/MM/yyyy HH:mm').format(date)}'),
                if (req['controller_comment'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Note: ${req['controller_comment']}',
                      style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                    ),
                  ),
              ],
            ),
            trailing: _StatusBadge(status: status),
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
          Icon(Icons.history_edu_rounded, size: 64, color: Colors.grey[200]),
          const SizedBox(height: 16),
          const Text('Aucune demande de prise en charge'),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.orange;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'approved': return Icons.check_circle_outline;
      case 'rejected': return Icons.cancel_outlined;
      default: return Icons.hourglass_top_rounded;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    String label = 'En attente';
    Color color = Colors.orange;
    
    if (status == 'approved') {
      label = 'Validé';
      color = Colors.green;
    } else if (status == 'rejected') {
      label = 'Refusé';
      color = Colors.red;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}


