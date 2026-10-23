import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../services/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MedicalRequestReviewScreen extends StatefulWidget {
  final Map<String, dynamic> request;
  const MedicalRequestReviewScreen({super.key, required this.request});

  @override
  State<MedicalRequestReviewScreen> createState() => _MedicalRequestReviewScreenState();
}

class _MedicalRequestReviewScreenState extends State<MedicalRequestReviewScreen> {
  final _commentController = TextEditingController();
  bool _isprocessing = false;
  String? _authToken;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final token = await AuthService().getToken();
    if (mounted) setState(() => _authToken = token);
  }

  String _getFullUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    
    // Normalize path
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final baseUrl = ApiConfig.mediaBaseUrl;
    final fullUrl = '$baseUrl$cleanPath';
    return fullUrl;
  }

  Map<String, String> _getHeaders() {
    return _authToken != null ? {'Authorization': 'Bearer $_authToken'} : {};
  }

  bool _isImage(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.png') || lower.endsWith('.webp');
  }

  Future<void> _openDocument(String path) async {
    final fullUrl = _getFullUrl(path);
    if (_isImage(path)) {
      _showFullImage(path);
    } else {
      final uri = Uri.parse(fullUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impossible d\'ouvrir le fichier PDF')),
          );
        }
      }
    }
  }

  Future<void> _handleDecision(String status) async {
    if (status == 'rejected' && _commentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Un commentaire est requis pour un refus')),
      );
      return;
    }

    setState(() => _isprocessing = true);
    try {
      await ApiService().reviewMedicalRequest(
        requestId: widget.request['id'],
        status: status,
        comment: _commentController.text,
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status == 'approved' ? 'Demande approuvée' : 'Demande refusée'),
          backgroundColor: status == 'approved' ? Colors.green : Colors.red,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isprocessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    final theme = Theme.of(context);
    final List<dynamic> supportingDocs = req['supporting_docs_url'] ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Examen du dossier')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(req),
            const SizedBox(height: 24),
            const Text('Documents Médicaux', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            _buildDocumentItem('Ordonnance', req['prescription_url']),
            if (supportingDocs.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Documents de soutien:', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: supportingDocs.length,
                  itemBuilder: (context, index) => _buildThumbnail(supportingDocs[index]),
                ),
              ),
            ],
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 24),
            const Text('Décision du Contrôle Médical', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Justification (obligatoire en cas de refus)...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isprocessing ? null : () => _handleDecision('rejected'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('REFUSER'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: _isprocessing ? null : () => _handleDecision('approved'),
                    style: FilledButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('APPROUVER'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(Map<String, dynamic> req) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildRow('Patient', req['patient_name'] ?? 'Inconnu'),
            const Divider(height: 24),
            _buildRow('Type de demande', req['request_type']),
            const Divider(height: 24),
            _buildRow('Date', DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(req['created_at']))),
            const Divider(height: 24),
            _buildRow('Description', req['description'] ?? 'Aucune description'),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(width: 16),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
      ],
    );
  }

  Widget _buildDocumentItem(String label, String? url) {
    if (url == null) return const Text('Aucun document');
    final isImg = _isImage(url);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        children: [
          Icon(isImg ? Icons.image : Icons.picture_as_pdf, color: isImg ? Colors.blue : Colors.red),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          TextButton(
            onPressed: () => _openDocument(url),
            child: Text(isImg ? 'Visualiser' : 'Ouvrir PDF'),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(String url) {
    final isImg = _isImage(url);
    final fullUrl = _getFullUrl(url);
    
    return GestureDetector(
      onTap: () => _openDocument(url),
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: isImg 
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: fullUrl,
                httpHeaders: _getHeaders(),
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                errorWidget: (context, url, error) {
                  return const Icon(Icons.error);
                },
              ),
            )
          : const Center(child: Icon(Icons.picture_as_pdf, color: Colors.red, size: 32)),
      ),
    );
  }

  void _showFullImage(String url) {
    final fullUrl = _getFullUrl(url);
    
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(title: const Text('Document'), leading: const CloseButton()),
          body: InteractiveViewer(
            child: Center(
              child: CachedNetworkImage(
                imageUrl: fullUrl,
                httpHeaders: _getHeaders(),
                placeholder: (context, url) => const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Chargement du document...'),
                  ],
                ),
                errorWidget: (context, url, error) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text('Erreur de chargement: $error'),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}


