import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class PharmacyInventoryScreen extends StatefulWidget {
  const PharmacyInventoryScreen({super.key});

  @override
  State<PharmacyInventoryScreen> createState() => _PharmacyInventoryScreenState();
}

class _PharmacyInventoryScreenState extends State<PharmacyInventoryScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _inventory = [];

  @override
  void initState() {
    super.initState();
    _fetchInventory();
  }

  Future<void> _fetchInventory() async {
    setState(() => _isLoading = true);
    try {
      final user = AuthService().currentUser;
      if (user != null) {
        final data = await _apiService.getPharmacyInventory(user.id);
        setState(() {
          _inventory = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e')),
        );
      }
    }
  }

  Future<void> _toggleAvailability(int id, bool currentStatus) async {
    try {
      await _apiService.updateInventoryItemStatus(id, !currentStatus);
      _fetchInventory();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _showAddMedicationDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ajouter un médicament'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nom du médicament (ex: Paracétamol)'),
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
                    await _apiService.addInventoryItem(name, price);
                    _fetchInventory();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Médicament ajouté')),
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
              child: const Text('Sauvegarder'),
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
        title: const Text('Inventaire & Tarifs'),
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddMedicationDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _inventory.isEmpty
              ? const Center(child: Text('Aucun médicament dans le catalogue.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _inventory.length,
                  itemBuilder: (context, index) {
                    final item = _inventory[index];
                    final isAvailable = item['is_available'] == true;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.withOpacity(0.1),
                          child: Icon(Icons.vaccines, color: Colors.green[700]),
                        ),
                        title: Text(
                          item['med_name']?.toString() ?? 'Médicament',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: isAvailable ? null : TextDecoration.lineThrough,
                          ),
                        ),
                        subtitle: Text('Prix: ${item['price']} DZD'),
                        trailing: Switch(
                          value: isAvailable,
                          activeColor: Colors.green,
                          onChanged: (val) => _toggleAvailability(item['id'], isAvailable),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMedicationDialog,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter au catalogue'),
        backgroundColor: Colors.green[700],
      ),
    );
  }
}


