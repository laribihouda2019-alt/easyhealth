import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../shared/chat_screen.dart';
import 'pharmacy_order_screen.dart';
import 'lab_order_screen.dart';
import 'package:intl/intl.dart';
import '../../widgets/slot_booking_sheet.dart';


class ProfessionalDiscoveryScreen extends StatefulWidget {
  final String initialRole;
  final bool canContact; // if true, shows "Contacter", otherwise "Prendre RDV" for doctors

  const ProfessionalDiscoveryScreen({
    super.key, 
    this.initialRole = 'doctor',
    this.canContact = true,
  });

  @override
  State<ProfessionalDiscoveryScreen> createState() => _ProfessionalDiscoveryScreenState();
}

class _ProfessionalDiscoveryScreenState extends State<ProfessionalDiscoveryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _api = ApiService();
  final Map<String, List<dynamic>> _profilesByRole = {
    'doctor': [],
    'pharmacy': [],
    'lab': [],
  };
  final Map<String, bool> _isLoading = {
    'doctor': true,
    'pharmacy': true,
    'lab': true,
  };
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    int initialIndex = 0;
    if (widget.initialRole == 'pharmacy') initialIndex = 1;
    if (widget.initialRole == 'lab') initialIndex = 2;

    _tabController = TabController(length: 3, vsync: this, initialIndex: initialIndex);
    _tabController.addListener(_handleTabSelection);
    
    _fetchProfiles('doctor');
    _fetchProfiles('pharmacy');
    _fetchProfiles('lab');
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfiles(String role) async {
    try {
      final profiles = await _api.getProfilesByRole(role);
      if (mounted) {
        setState(() {
          _profilesByRole[role] = profiles;
          _isLoading[role] = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading[role] = false);
      }
    }
  }

  String _getRoleName(String role) {
    switch (role) {
      case 'doctor': return 'Médecins';
      case 'pharmacy': return 'Pharmacies';
      case 'lab': return 'Laboratoires';
      default: return 'Professionnels';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trouver un professionnel'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.medical_services), text: 'Médecins'),
            Tab(icon: Icon(Icons.local_pharmacy), text: 'Pharmacies'),
            Tab(icon: Icon(Icons.science), text: 'Laboratoires'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher par nom...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildList('doctor'),
                _buildList('pharmacy'),
                _buildList('lab'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(String role) {
    final profiles = _profilesByRole[role] ?? [];
    final filtered = profiles.where((p) {
      // Use display_name (backend normalized) or fall back to full_name
      final name = (p['display_name'] as String? ??
                    p['full_name'] as String? ?? '').toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    if (_isLoading[role]!) {
      return const Center(child: CircularProgressIndicator());
    }

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('Aucun résultat trouvé', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final profile = filtered[index];

        // Resolve the display name (backend provides display_name as the normalized name)
        final String displayName = profile['display_name'] as String? ??
            profile['pharmacy_name'] as String? ??
            profile['lab_name'] as String? ??
            profile['full_name'] as String? ??
            'Inconnu';

        // Build location string
        final commune = profile['commune']?.toString().isNotEmpty == true ? profile['commune'] : '';
        final wilaya = profile['wilaya']?.toString().isNotEmpty == true ? profile['wilaya'] : '';
        final locationStr = "$commune $wilaya".trim();

        // Build subtitle based on role
        String subtitle;
        if (role == 'doctor') {
          final spec = profile['specialization'] as String? ?? 'Médecin Généraliste';
          final fee = profile['consultation_fee'];
          subtitle = '$spec • $locationStr';
          if (fee != null) subtitle += ' • $fee DA';
        } else if (role == 'pharmacy') {
          final phone = profile['phone'] as String? ?? '';
          final hours = profile['opening_hours'] as String? ?? '';
          final delivery = profile['delivery_available'] == true ? '🚚 Livraison' : '';
          subtitle = [locationStr, phone, hours, delivery].where((s) => s.isNotEmpty).join(' • ');
        } else {
          // lab
          final phone = profile['phone'] as String? ?? '';
          final tests = profile['tests_available'];
          String testsStr = '';
          if (tests is List && tests.isNotEmpty) {
            testsStr = (tests as List).take(2).join(', ');
          }
          subtitle = [locationStr, phone, testsStr].where((s) => s.isNotEmpty).join(' • ');
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getRoleColor(role).withValues(alpha: 0.1),
                  child: Icon(_getRoleIcon(role), color: _getRoleColor(role)),
                ),
                title: Text(
                  displayName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (role == 'pharmacy' || role == 'lab')
                      TextButton.icon(
                        icon: const Icon(Icons.list_alt, size: 16),
                        label: const Text('Catalogue'),
                        style: TextButton.styleFrom(foregroundColor: _getRoleColor(role)),
                        onPressed: () => _showCatalogSheet(context, profile['id'] as String, role, displayName),
                      ),
                    IconButton(
                      icon: const Icon(Icons.chat),
                      color: _getRoleColor(role),
                      tooltip: 'Envoyer un message',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              recipientId: profile['id'] as String,
                              recipientName: displayName,
                            ),
                          ),
                        );
                      },
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (role == 'doctor' && !widget.canContact) {
                          _showBookingDialog(context, profile['id'] as String, displayName);
                        } else if (role == 'pharmacy') {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PharmacyOrderScreen(pharmacy: profile),
                            ),
                          );
                        } else if (role == 'lab') {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => LabOrderScreen(lab: profile),
                            ),
                          );
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                recipientId: profile['id'] as String,
                                recipientName: displayName,
                              ),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getRoleColor(role),
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        (role == 'doctor' && !widget.canContact) 
                          ? 'Prendre RDV' 
                          : (role == 'pharmacy' ? 'Commander' : (role == 'lab' ? 'Réserver' : 'Contacter'))
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCatalogSheet(BuildContext context, String providerId, String role, String name) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CatalogSheet(providerId: providerId, role: role, providerName: name),
    );
  }

  void _showBookingDialog(BuildContext context, String doctorId, String doctorName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      builder: (context) => SlotBookingSheet(doctorId: doctorId, doctorName: doctorName),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'doctor': return Colors.blue;
      case 'pharmacy': return Colors.green;
      case 'lab': return Colors.teal;
      default: return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'doctor': return Icons.person;
      case 'pharmacy': return Icons.local_pharmacy;
      case 'lab': return Icons.science;
      default: return Icons.person;
    }
  }
}
class _CatalogSheet extends StatefulWidget {
  final String providerId;
  final String role; // 'lab' or 'pharmacy'
  final String providerName;

  const _CatalogSheet({
    required this.providerId,
    required this.role,
    required this.providerName,
  });

  @override
  State<_CatalogSheet> createState() => _CatalogSheetState();
}

class _CatalogSheetState extends State<_CatalogSheet> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _fetchCatalog();
  }

  Future<void> _fetchCatalog() async {
    try {
      final items = widget.role == 'lab' 
          ? await _api.getLabServices(widget.providerId)
          : await _api.getPharmacyInventory(widget.providerId);
      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Catalogue - ${widget.providerName}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? const Center(child: Text('Le catalogue est vide.'))
                    : ListView.builder(
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          final isLab = widget.role == 'lab';
                          final name = isLab ? item['test_name'] : item['med_name'];
                          final price = item['price'];
                          // For pharmacy, check if it's available
                          final isAvailable = isLab || (item['is_available'] == true);

                          return ListTile(
                            leading: Icon(
                              isLab ? Icons.science : Icons.vaccines,
                              color: isAvailable ? Colors.teal : Colors.grey,
                            ),
                            title: Text(
                              name?.toString() ?? 'Inconnu',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                decoration: isAvailable ? null : TextDecoration.lineThrough,
                                color: isAvailable ? Colors.black : Colors.grey,
                              ),
                            ),
                            subtitle: Text('$price DZD'),
                            trailing: isAvailable 
                                ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                                : const Text('Rupture', style: TextStyle(color: Colors.red, fontSize: 12)),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}


