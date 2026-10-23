import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../shared/chat_screen.dart';
import '../../widgets/slot_booking_sheet.dart';

class DoctorListScreen extends StatefulWidget {
  final String? specialty;
  const DoctorListScreen({super.key, this.specialty});

  @override
  State<DoctorListScreen> createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen> {
  final _api = ApiService();
  final _searchController = TextEditingController();
  List<dynamic> _doctors = [];
  bool _isLoading = true;
  late String _searchQuery;

  @override
  void initState() {
    super.initState();
    _searchQuery = widget.specialty ?? '';
    _searchController.text = _searchQuery;
    _fetchDoctors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchDoctors() async {
    setState(() => _isLoading = true);
    try {
      final doctors = await _api.getProfilesByRole('doctor');
      if (mounted) {
        setState(() {
          _doctors = doctors;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des médecins: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredDoctors = _doctors.where((doc) {
      final name = (doc['full_name'] as String? ?? '').toLowerCase();
      final specialty = (doc['specialization'] as String? ?? '').toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) || 
             specialty.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trouver un médecin'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par nom ou spécialité...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredDoctors.isEmpty
                    ? const Center(child: Text('Aucun médecin trouvé'))
                    : ListView.builder(
                        itemCount: filteredDoctors.length,
                        itemBuilder: (context, index) {
                          final doc = filteredDoctors[index];
                          final commune = doc['commune']?.toString().isNotEmpty == true ? doc['commune'] : '';
                          final wilaya = doc['wilaya']?.toString().isNotEmpty == true ? doc['wilaya'] : '';
                          final location = "$commune $wilaya".trim();
                          final spec = doc['specialization'] ?? 'Généraliste';
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.teal.shade100,
                                child: const Icon(Icons.person, color: Colors.teal),
                              ),
                              title: Text(
                                doc['full_name'] ?? 'Médecin',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text('$spec • $location'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => ChatScreen(
                                            recipientId: doc['id'],
                                            recipientName: doc['full_name'],
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.chat_outlined, size: 20),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        builder: (context) => SlotBookingSheet(
                                          doctorId: doc['id'],
                                          doctorName: doc['full_name'] ?? 'Médecin',
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Rendez-vous'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}


