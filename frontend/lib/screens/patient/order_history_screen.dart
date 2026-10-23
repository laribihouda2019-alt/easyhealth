import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';

class OrderHistoryScreen extends StatefulWidget {
  final String initialTab; // 'meds' or 'lab'

  const OrderHistoryScreen({super.key, this.initialTab = 'meds'});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _api = ApiService();
  
  List<dynamic> _medOrders = [];
  List<dynamic> _labRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab == 'meds' ? 0 : 1);
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final meds = await _api.getMyMedicationOrders();
      final labs = await _api.getMyLabRequests();
      if (mounted) {
        setState(() {
          _medOrders = meds;
          _labRequests = labs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Historique'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Médicaments', icon: Icon(Icons.medication)),
            Tab(text: 'Laboratoire', icon: Icon(Icons.science)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMedList(),
                _buildLabList(),
              ],
            ),
    );
  }

  Widget _buildMedList() {
    if (_medOrders.isEmpty) return const Center(child: Text('Aucune commande de médicaments.'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _medOrders.length,
      itemBuilder: (context, index) {
        final order = _medOrders[index];
        final date = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(order['created_at']).toLocal());
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Pharmacie: ${order['pharmacy_name']}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildStatusBadge(order['status']),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(date, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        order['delivery_address'] ?? 'Adresse non spécifiée',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLabList() {
    if (_labRequests.isEmpty) return const Center(child: Text('Aucune demande de laboratoire.'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _labRequests.length,
      itemBuilder: (context, index) {
        final req = _labRequests[index];
        return Card(
          child: ListTile(
            title: Text('${req['test_type']} chez ${req['lab_name']}'),
            subtitle: Text(DateFormat('dd/MM/yyyy').format(DateTime.parse(req['created_at']))),
            trailing: _buildStatusBadge(req['status']),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'paid': 
        color = Colors.green; 
        label = 'PAYÉ'; 
        break;
      case 'prepared': 
        color = Colors.green; 
        label = 'جاهز للاستلام (Ready)'; 
        break;
      case 'accepted':
        color = Colors.blue;
        label = 'قيد التحضير (Preparing)';
        break;
      case 'pending': 
        color = Colors.orange; 
        label = 'EN ATTENTE'; 
        break;
      case 'shipping':
        color = Colors.purple;
        label = 'LIVRAISON EN COURS';
        break;
      case 'delivered':
        color = Colors.grey;
        label = 'LIVRÉ';
        break;
      default: 
        color = Colors.grey; 
        label = status.toUpperCase();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12), 
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5), width: 0.5),
      ),
      child: Text(
        label, 
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.3),
      ),
    );
  }
}


