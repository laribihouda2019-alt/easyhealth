import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../config/api_config.dart';

class MedicalRecordsScreen extends StatefulWidget {
  const MedicalRecordsScreen({super.key});

  @override
  State<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _api = ApiService();
  
  List<dynamic> _allRecords = [];
  bool _isLoading = true;
  final List<String> _categories = ['Tout', 'Analyses', 'Radios', 'Ordonnances', 'Autres'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _fetchRecords();
  }

  Future<void> _fetchRecords() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.getMyMedicalRecords();
      if (mounted) {
        setState(() {
          _allRecords = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _filteredRecords {
    final category = _categories[_tabController.index];
    if (category == 'Tout') return _allRecords;
    return _allRecords.where((r) => r['category'] == category).toList();
  }

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );

    if (result != null) {
      _showUploadDialog(result.files.single);
    }
  }

  void _showUploadDialog(PlatformFile file) {
    String selectedCategory = 'Analyses';
    final titleController = TextEditingController(text: file.name);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Ajouter au dossier'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Titre du document'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: _categories.skip(1).map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setModalState(() => selectedCategory = val!),
                decoration: const InputDecoration(labelText: 'Catégorie'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                setState(() => _isLoading = true);
                try {
                  await _api.uploadMedicalRecord(
                    title: titleController.text,
                    category: selectedCategory,
                    fileBytes: file.bytes,
                    fileName: file.name,
                  );
                  _fetchRecords();
                } catch (e) {
                  setState(() => _isLoading = false);
                }
              },
              child: const Text('Télécharger'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Mon Dossier Médical'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // QR Sharing Header Placeholder
          _buildQRHeader(),

          // Tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: theme.primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: theme.primaryColor,
              tabs: _categories.map((c) => Tab(text: c)).toList(),
            ),
          ),

          // Records List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRecords.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredRecords.length,
                        itemBuilder: (context, index) {
                          final record = _filteredRecords[index];
                          return _buildRecordCard(record);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickAndUpload,
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Ajouter un document'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildQRHeader() {
    final user = AuthService().currentUser;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.indigo, Colors.blueAccent]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.qr_code_scanner, size: 48, color: Colors.indigo[700]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Partage Sécurisé',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Partagez votre ID avec un médecin pour lecture directe.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => _showQRDialog(user?.id ?? ''),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.indigo,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Générer mon QR Code'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showQRDialog(String patientId) {
    if (patientId == null || patientId.isEmpty || patientId == 'null') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID Patient non disponible. Veuillez vous reconnecter.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text('Votre ID Médical'),
        content: SizedBox(
          width: 250,
          height: 320, // Explicit height for the dialog content
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Montrez ce code à votre médecin pour qu\'il accède à votre dossier.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              // Rigidity confirmed: SizedBox with fixed dimensions
              SizedBox(
                width: 200,
                height: 200,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.indigo.withOpacity(0.1)),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: QrImageView(
                    data: patientId,
                    version: QrVersions.auto,
                    size: 200.0,
                    gapless: false,
                    foregroundColor: Colors.indigo,
                    errorStateBuilder: (cxt, err) {
                      return const Center(
                        child: Text(
                          'Erreur QR Code',
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Text(
                'ID: ${patientId.length > 8 ? patientId.substring(0, 8) : patientId}...',
                style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(dynamic record) {
    final date = DateFormat('dd MMM yyyy', 'fr_FR').format(DateTime.parse(record['created_at']));
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
          child: Icon(_getCategoryIcon(record['category']), color: Colors.indigo),
        ),
        title: Text(record['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${record['category']} • $date'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: () async {
            await _api.deleteMedicalRecord(record['id']);
            _fetchRecords();
          },
        ),
        onTap: () => _showRecordDetails(record),
      ),
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
              const Text('Lien du fichier:', style: TextStyle(color: Colors.grey, fontSize: 12)),
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
            label: const Text('Ouvrir'),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Analyses': return Icons.analytics_outlined;
      case 'Radios': return Icons.settings_accessibility;
      case 'Ordonnances': return Icons.description_outlined;
      default: return Icons.folder_open;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_copy_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('Aucun document dans cette catégorie', style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }
}


