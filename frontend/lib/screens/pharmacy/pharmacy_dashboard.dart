import 'package:flutter/material.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/stat_card.dart';
import '../../services/auth_service.dart';
import '../shared/chat_list_screen.dart';
import '../../widgets/pending_approval_screen.dart';
import '../../widgets/notification_bell.dart';
import 'pharmacy_orders_screen.dart';
import 'pharmacy_inventory_screen.dart';

class PharmacyDashboard extends StatefulWidget {
  const PharmacyDashboard({super.key});

  @override
  State<PharmacyDashboard> createState() => _PharmacyDashboardState();
}

class _PharmacyDashboardState extends State<PharmacyDashboard> {
  bool _isRefreshing = false;
  Map<String, dynamic>? _summaryData;
  bool _isLoadingSummary = true;
  
  @override
  void initState() {
    super.initState();
    _checkApprovalStatus();
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

  Future<void> _checkApprovalStatus() async {
    final user = AuthService().currentUser;
    if (user != null && !user.isApproved) {
      if (mounted) setState(() => _isRefreshing = true);
      await AuthService().refreshProfile();
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = AuthService().currentUser;

    if (user != null && !user.isApproved) {
      return PendingApprovalScreen(
        roleDisplayName: 'pharmacie',
        isRefreshing: _isRefreshing,
        onRefresh: _checkApprovalStatus,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace Pharmacie'),
        actions: [
          const NotificationBell(),
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
              color: Colors.green[700],
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: const Icon(
                        Icons.local_pharmacy,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pharmacie',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            user?.fullName ?? 'Pharmacie',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Statistiques',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Messages',
                    value: _isLoadingSummary ? '...' : (_summaryData?['unreadMessagesCount']?.toString() ?? '0'),
                    icon: Icons.chat_bubble_outline,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: 'Activites',
                    value: '0', // Dynamic activity tracking placeholder
                    icon: Icons.local_shipping,
                    color: Colors.blue,
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
              title: 'Stock medicaments',
              subtitle: 'Gerer la disponibilite des medicaments',
              icon: Icons.inventory,
              iconColor: Colors.green,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PharmacyInventoryScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            DashboardCard(
              title: 'Livraisons',
              subtitle: 'Gerer les demandes de livraison',
              icon: Icons.local_shipping,
              iconColor: Colors.blue,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PharmacyOrdersScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            DashboardCard(
              title: 'Vérifier Ordonnance',
              subtitle: 'Scanner le QR Code pour vérifier l\'authenticité',
              icon: Icons.qr_code_scanner,
              iconColor: Colors.orange,
              onTap: () {
                Navigator.of(context).pushNamed('/verify-prescription');
              },
            ),
            const SizedBox(height: 12),
            DashboardCard(
              title: 'Messagerie patients',
              subtitle: 'Repondre aux questions des patients',
              icon: Icons.chat,
              iconColor: Colors.purple,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ChatListScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}


