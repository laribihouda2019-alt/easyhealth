import 'package:flutter/material.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/stat_card.dart';
import '../../services/auth_service.dart';
import '../shared/frequent_diseases_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  Map<String, dynamic>? _summaryData;
  bool _isLoadingSummary = true;

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  Future<void> _fetchSummary() async {
    try {
      if (mounted) setState(() => _isLoadingSummary = true);
      final response = await AuthService().getDashboardSummary();
      if (mounted) {
        setState(() {
          _summaryData = response['data'];
          _isLoadingSummary = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSummary = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.deepPurple,
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white24,
                      child: Icon(
                        Icons.admin_panel_settings,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Panneau Admin',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Gerez les utilisateurs et verifications',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Vue d\'ensemble',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Utilisateurs',
                    value: _isLoadingSummary ? '...' : (_summaryData?['totalUsersCount']?.toString() ?? '0'),
                    icon: Icons.people,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: 'En attente',
                    value: _isLoadingSummary ? '...' : (_summaryData?['pendingVerificationsCount']?.toString() ?? '0'),
                    icon: Icons.pending_actions,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Medecins',
                    value: _isLoadingSummary ? '...' : (_summaryData?['doctorsCount']?.toString() ?? '0'),
                    icon: Icons.medical_services,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: 'Pharmacies',
                    value: _isLoadingSummary ? '...' : (_summaryData?['pharmaciesCount']?.toString() ?? '0'),
                    icon: Icons.local_pharmacy,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Gestion',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            DashboardCard(
              title: 'Demandes de verification',
              subtitle: 'Valider les comptes medecins, pharmacies et labs',
              icon: Icons.verified_user,
              iconColor: Colors.orange,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const VerificationRequestsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            DashboardCard(
              title: 'Utilisateurs',
              subtitle: 'Gerer tous les utilisateurs de la plateforme',
              icon: Icons.people,
              iconColor: Colors.blue,
              onTap: () {},
            ),
            const SizedBox(height: 12),
            DashboardCard(
              title: 'Statistiques IA - Maladies frequentes',
              subtitle: 'Alertes et tendances analysees par IA',
              icon: Icons.analytics,
              iconColor: Colors.purple,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const FrequentDiseasesScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            DashboardCard(
              title: 'Paiements',
              subtitle: 'Suivre les transactions Chargily',
              icon: Icons.payment,
              iconColor: Colors.indigo,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class VerificationRequestsScreen extends StatefulWidget {
  const VerificationRequestsScreen({super.key});

  @override
  State<VerificationRequestsScreen> createState() =>
      _VerificationRequestsScreenState();
}

class _VerificationRequestsScreenState
    extends State<VerificationRequestsScreen> {
  final List<Map<String, dynamic>> _requests = [
    {
      'id': 1,
      'name': 'Dr. Ahmed Benali',
      'role': 'doctor',
      'document': 'diplome_medecine.pdf',
      'status': 'pending',
      'confidence': 85.0,
    },
    {
      'id': 2,
      'name': 'Pharmacie El Amal',
      'role': 'pharmacy',
      'document': 'agrement_pharmacie.pdf',
      'status': 'pending',
      'confidence': 92.0,
    },
    {
      'id': 3,
      'name': 'Labo Central',
      'role': 'lab',
      'document': 'certification_labo.pdf',
      'status': 'pending',
      'confidence': 78.0,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Demandes de verification')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _requests.length,
        itemBuilder: (context, index) {
          final request = _requests[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: _getRoleColor(request['role']),
                        child: Icon(
                          _getRoleIcon(request['role']),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              request['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              _getRoleLabel(request['role']),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'IA: ${request['confidence'].toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.attach_file,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        request['document'],
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _handleReject(request['id']),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Rejeter'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => _handleApprove(request['id']),
                          child: const Text('Approuver'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'doctor':
        return Colors.teal;
      case 'pharmacy':
        return Colors.green;
      case 'lab':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'doctor':
        return Icons.medical_services;
      case 'pharmacy':
        return Icons.local_pharmacy;
      case 'lab':
        return Icons.science;
      default:
        return Icons.person;
    }
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'doctor':
        return 'Medecin';
      case 'pharmacy':
        return 'Pharmacie';
      case 'lab':
        return 'Laboratoire';
      default:
        return 'Inconnu';
    }
  }

  void _handleApprove(int id) {
    setState(() {
      _requests.removeWhere((r) => r['id'] == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Compte approuve avec succes'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _handleReject(int id) {
    setState(() {
      _requests.removeWhere((r) => r['id'] == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Demande rejetee'),
        backgroundColor: Colors.red,
      ),
    );
  }
}


