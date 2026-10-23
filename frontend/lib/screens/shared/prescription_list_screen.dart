import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/prescription_model.dart';
import 'prescription_view_screen.dart';
import 'package:intl/intl.dart';

class PrescriptionListScreen extends StatefulWidget {
  const PrescriptionListScreen({super.key});

  @override
  State<PrescriptionListScreen> createState() => _PrescriptionListScreenState();
}

class _PrescriptionListScreenState extends State<PrescriptionListScreen> {
  final _api = ApiService();
  bool _isLoading = true;
  List<PrescriptionModel> _prescriptions = [];

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();
  }

  Future<void> _loadPrescriptions() async {
    try {
      final data = await _api.getMyPrescriptions();
      if (mounted) {
        setState(() {
          _prescriptions = data.map((e) => PrescriptionModel.fromJson(e)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Ordonnances Digitales'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _prescriptions.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _prescriptions.length,
                  itemBuilder: (context, index) {
                    final item = _prescriptions[index];
                    final dateStr = DateFormat('dd MMMM yyyy').format(item.prescriptionDate);
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.teal,
                          child: Icon(Icons.description, color: Colors.white),
                        ),
                        title: Text(item.doctorName ?? 'Médecin'),
                        subtitle: Text(dateStr),
                        trailing: const Icon(Icons.download, color: Colors.teal),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PrescriptionViewScreen(prescription: item),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_edu, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('Aucune ordonnance trouvée.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}


