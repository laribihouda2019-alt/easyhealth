import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../services/api_service.dart';
import '../../config/api_config.dart';

class PharmacyOrdersScreen extends StatefulWidget {
  const PharmacyOrdersScreen({super.key});

  @override
  State<PharmacyOrdersScreen> createState() => _PharmacyOrdersScreenState();
}

class _PharmacyOrdersScreenState extends State<PharmacyOrdersScreen> {
  final _api = ApiService();
  List<dynamic> _orders = [];
  bool _isLoading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.getPharmacyOrders();
      if (mounted) {
        setState(() {
          _orders = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Safely parse items — may be a JSON string or already a List
  List<dynamic> _parseItems(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) return raw;
    if (raw is String) {
      try { return jsonDecode(raw) as List; } catch (_) {}
    }
    return [];
  }

  /// Build a full URL for the prescription file
  String? _buildPrescriptionUrl(String? relativeUrl) {
    if (relativeUrl == null || relativeUrl.isEmpty) return null;
    if (relativeUrl.startsWith('http')) return relativeUrl;
    return '${ApiConfig.mediaBaseUrl}$relativeUrl';
  }

  /// Open the prescription in the browser / native viewer
  Future<void> _openPrescription(String? relativeUrl) async {
    final fullUrl = _buildPrescriptionUrl(relativeUrl);
    if (fullUrl == null) return;
    final uri = Uri.parse(fullUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible d\'ouvrir le fichier: $fullUrl'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<dynamic> get _filteredOrders {
    if (_filter == 'all') return _orders;
    return _orders.where((o) => o['status'] == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Commandes Clients'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchOrders),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                _filterChip('all', 'Toutes'),
                const SizedBox(width: 8),
                _filterChip('pending', 'En attente'),
                const SizedBox(width: 8),
                _filterChip('prepared', 'Préparées'),
                const SizedBox(width: 8),
                _filterChip('shipping', 'En cours'),
                const SizedBox(width: 8),
                _filterChip('delivered', 'Livrées'),
                const SizedBox(width: 8),
                _filterChip('paid', 'Payées'),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredOrders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text('Aucune commande', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchOrders,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredOrders.length,
                    itemBuilder: (context, index) => _OrderCard(
                      order: _filteredOrders[index],
                      parseItems: _parseItems,
                      onOpenPrescription: _openPrescription,
                      api: _api,
                      onStatusChanged: _fetchOrders,
                    ),
                  ),
                ),
    );
  }

  Widget _filterChip(String value, String label) {
    final selected = _filter == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = value),
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
      checkmarkColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(
        color: selected ? Theme.of(context).colorScheme.primary : Colors.grey.shade700,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final List<dynamic> Function(dynamic) parseItems;
  final Future<void> Function(String?) onOpenPrescription;
  final ApiService api;
  final VoidCallback onStatusChanged;

  const _OrderCard({
    required this.order,
    required this.parseItems,
    required this.onOpenPrescription,
    required this.api,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM/yyyy HH:mm').format(
      DateTime.parse(order['created_at']).toLocal(),
    );
    final status = order['status'] as String? ?? 'pending';
    final paymentMethod = order['payment_method'] as String? ?? 'cod';
    final prescriptionUrl = order['prescription_url'] as String?;
    final items = parseItems(order['items']);
    final itemNote = items.isNotEmpty ? (items[0]['note'] ?? '') : '';
    final isOnlinePayment = paymentMethod == 'chargily';

    final isPrepared = status == 'prepared';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: isPrepared 
          ? const BorderSide(color: Colors.green, width: 2) 
          : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // — Header row: ID + Status —
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Commande #${order['id'].toString().substring(0, 8).toUpperCase()}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                _StatusBadge(status: status),
              ],
            ),
            const Divider(height: 20),

            // — Patient & Date —
            Row(
              children: [
                const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order['patient_name'] ?? 'Patient inconnu',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),

            // — Items —
            if (itemNote.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.medical_services_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(child: Text(itemNote, style: const TextStyle(fontSize: 13))),
                ],
              ),
            ],

            // — Delivery address —
            if (order['delivery_address'] != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: Colors.red),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Livraison: ${order['delivery_address']}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // — Payment Method Row —
            _PaymentMethodRow(
              paymentMethod: paymentMethod,
              isOnlinePayment: isOnlinePayment,
              orderStatus: status,
            ),

            // — Prescription button —
            if (prescriptionUrl != null && prescriptionUrl.isNotEmpty) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => onOpenPrescription(prescriptionUrl),
                icon: const Icon(Icons.file_present, size: 16),
                label: const Text('Voir l\'ordonnance'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.indigo,
                  side: const BorderSide(color: Colors.indigo),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],

            // --- Action Button: Mark as Prepared ---
            if (status == 'pending' || status == 'accepted') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await api.updateMedicationOrderStatus(order['id'].toString(), 'prepared');
                      onStatusChanged();
                    } catch (e) {
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Mark as Prepared (تم التجهيز)', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ] else if (isPrepared) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Ready for Pickup / Delivery',
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shows whether the payment is COD or online, plus payment status
class _PaymentMethodRow extends StatelessWidget {
  final String paymentMethod;
  final bool isOnlinePayment;
  final String orderStatus;

  const _PaymentMethodRow({
    required this.paymentMethod,
    required this.isOnlinePayment,
    required this.orderStatus,
  });

  @override
  Widget build(BuildContext context) {
    if (isOnlinePayment) {
      // Determine payment status from order status
      final bool isPaid = orderStatus == 'paid';
      final bool isFailed = orderStatus == 'payment_failed';

      final Color statusColor = isPaid ? Colors.green : (isFailed ? Colors.red : Colors.orange);
      final IconData statusIcon = isPaid
          ? Icons.check_circle
          : (isFailed ? Icons.cancel : Icons.hourglass_top);
      final String statusLabel = isPaid
          ? 'Payé'
          : (isFailed ? 'Échec du paiement' : 'En attente de paiement');

      return Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.credit_card, size: 14, color: Colors.indigo),
                SizedBox(width: 4),
                Text('Paiement en ligne', style: TextStyle(fontSize: 12, color: Colors.indigo, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(statusIcon, size: 16, color: statusColor),
          const SizedBox(width: 4),
          Text(statusLabel, style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w600)),
        ],
      );
    } else {
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.money, size: 14, color: Colors.green),
                SizedBox(width: 4),
                Text('Paiement à la livraison', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      );
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'paid': color = Colors.green; label = 'PAYÉ'; break;
      case 'pending': color = Colors.orange; label = 'EN ATTENTE'; break;
      case 'prepared': color = Colors.green; label = 'PRÊT'; break;
      case 'shipping': color = Colors.blue; label = 'EN COURS'; break;
      case 'delivered': color = Colors.grey; label = 'LIVRÉ'; break;
      case 'payment_failed': color = Colors.red; label = 'PAIEMENT ÉCHOUÉ'; break;
      default: color = Colors.grey; label = status.toUpperCase();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }
}


