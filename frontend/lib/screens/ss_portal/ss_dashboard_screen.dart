import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../config/api_config.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

class SSDashboardScreen extends StatefulWidget {
  const SSDashboardScreen({super.key});

  @override
  State<SSDashboardScreen> createState() => _SSDashboardScreenState();
}

class _SSDashboardScreenState extends State<SSDashboardScreen> {
  Map<String, dynamic>? _stats;
  List<dynamic> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final statsRes = await ApiService().getChifaStats();
      final requestsRes = await ApiService().getAllChifaRequests();
      
      setState(() {
        _stats = statsRes['stats'];
        _requests = requestsRes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String requestId, String status) async {
    try {
      await ApiService().updateChifaRequestStatus(requestId, status);
      _fetchData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Demande $status avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  String _getFullUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    
    // Normalize path: remove leading slash if present
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    
    // Get host part from baseUrl (e.g., http://localhost:5000)
    final uri = Uri.parse(ApiConfig.baseUrl);
    final hostUrl = '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
    
    final fullUrl = '$hostUrl/$cleanPath';
    return fullUrl;
  }

  bool _isImage(String url) {
    if (url.isEmpty) return false;
    final lower = url.toLowerCase();
    return lower.contains('.jpg') || 
           lower.contains('.jpeg') || 
           lower.contains('.png') || 
           lower.contains('.webp') ||
           lower.contains('.gif');
  }

  void _viewImage(String url) {
    final fullUrl = _getFullUrl(url);
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: const Text('Visualisation Document'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          backgroundColor: Colors.black,
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 5,
              child: CachedNetworkImage(
                imageUrl: fullUrl,
                placeholder: (context, url) => const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 10),
                    Text('Chargement...', style: TextStyle(color: Colors.white)),
                  ],
                ),
                errorWidget: (context, url, error) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.broken_image, color: Colors.white, size: 60),
                      const SizedBox(height: 10),
                      Text('Erreur de chargement\n$fullUrl', 
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ],
                  );
                },
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const ssPrimary = Color(0xFF1A3B5D);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Gestion de la Carte Chifa',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: ssPrimary),
              ),
              IconButton(onPressed: _fetchData, icon: const Icon(Icons.refresh, color: ssPrimary)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _StatCard(
                title: 'Demandes en attente',
                value: _stats?['pendingRequests']?.toString() ?? '0',
                icon: Icons.pending_actions,
                color: Colors.orange,
              ),
              const SizedBox(width: 20),
              _StatCard(
                title: 'Total traitées',
                value: ((_stats?['totalRequests'] ?? 0) - (_stats?['pendingRequests'] ?? 0)).toString(),
                icon: Icons.check_circle_outline,
                color: Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'Liste des demandes de réactivation',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ssPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: _requests.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Center(child: Text('Aucune demande pour le moment')),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _requests.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final req = _requests[index];
                      final isPending = req['status'] == 'En cours';

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        title: Text(
                          req['patient_name'] ?? 'Patient inconnu',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(req['patient_email'] ?? ''),
                            const SizedBox(height: 4),
                            Text(
                              'Soumis le: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(req['created_at']))}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _StatusChip(status: req['status']),
                            if (isPending) ...[
                              const SizedBox(width: 12),
                              IconButton(
                                icon: const Icon(Icons.visibility_outlined, color: Colors.blue),
                                onPressed: () => _showReviewDialog(req),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showReviewDialog(Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.rate_review_outlined, color: Color(0xFF1A3B5D)),
            const SizedBox(width: 12),
            Expanded(child: Text('Révision: ${request['patient_name']}')),
          ],
        ),
        titlePadding: const EdgeInsets.all(20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 12),
                const Text('Documents fournis :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 180,
                  width: double.maxFinite,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: (request['document_urls'] as List).length,
                    itemBuilder: (context, i) {
                      final url = request['document_urls'][i];
                      final isImg = _isImage(url);

                      return GestureDetector(
                        onTap: () {
                          if (isImg) {
                            _viewImage(url);
                          } else {
                            launchUrl(Uri.parse(_getFullUrl(url)));
                          }
                        },
                        child: Container(
                          width: 140,
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, spreadRadius: 1)
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: isImg
                                ? CachedNetworkImage(
                                    imageUrl: _getFullUrl(url),
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                    errorWidget: (context, url, error) => const Icon(Icons.error),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.picture_as_pdf, color: Colors.red, size: 48),
                                      const SizedBox(height: 8),
                                      const Text('Voir PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    ],
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                if (request['notes'] != null && request['notes'].isNotEmpty) ...[
                  const Text('Note du patient :', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blueGrey[100]!),
                    ),
                    child: Text(request['notes'], style: const TextStyle(height: 1.5)),
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.all(20),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _updateStatus(request['id'], 'Rejetée');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Rejeter', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _updateStatus(request['id'], 'Acceptée');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Valider', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'Acceptée': color = Colors.green; break;
      case 'Rejetée': color = Colors.red; break;
      default: color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}


