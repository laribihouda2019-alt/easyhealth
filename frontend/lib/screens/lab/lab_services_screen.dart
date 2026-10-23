import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class LabServicesScreen extends StatefulWidget {
  const LabServicesScreen({super.key});

  @override
  State<LabServicesScreen> createState() => _LabServicesScreenState();
}

class _LabServicesScreenState extends State<LabServicesScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _services = [];

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    setState(() => _isLoading = true);
    try {
      final user = AuthService().currentUser;
      if (user != null) {
        final data = await _apiService.getLabServices(user.id);
        setState(() {
          _services = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des services: $e')),
        );
      }
    }
  }

  void _showAddServiceDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ajouter une analyse'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nom du test (ex: NFS)'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Prix (DZD)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final price = double.tryParse(priceController.text.trim());
                if (name.isNotEmpty && price != null) {
                  Navigator.pop(context);
                  try {
                    await _apiService.addLabService(name, price);
                    _fetchServices();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Test ajouté avec succès')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erreur: $e')),
                      );
                    }
                  }
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalogue des analyses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddServiceDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _services.isEmpty
              ? const Center(child: Text('Aucun service enregistré.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _services.length,
                  itemBuilder: (context, index) {
                    final service = _services[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.indigo.withOpacity(0.1),
                          child: const Icon(Icons.science, color: Colors.indigo),
                        ),
                        title: Text(
                          service['test_name']?.toString() ?? 'Test',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Prix: ${service['price']} DZD'),
                        trailing: Icon(
                          service['is_available'] == true
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: service['is_available'] == true
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddServiceDialog,
        icon: const Icon(Icons.add),
        label: const Text('Nouveau Test'),
        backgroundColor: Colors.indigo,
      ),
    );
  }
}


