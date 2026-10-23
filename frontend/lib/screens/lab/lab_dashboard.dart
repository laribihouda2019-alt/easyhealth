import 'package:flutter/material.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/stat_card.dart';
import '../../services/auth_service.dart';
import '../shared/chat_list_screen.dart';
import '../../widgets/pending_approval_screen.dart';
import '../../widgets/notification_bell.dart';
import 'lab_requests_screen.dart';
import 'lab_services_screen.dart';
import 'lab_results_screen.dart';

class LabDashboard extends StatefulWidget {
  const LabDashboard({super.key});

  @override
  State<LabDashboard> createState() => _LabDashboardState();
}

class _LabDashboardState extends State<LabDashboard> {
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
        roleDisplayName: 'laboratoire',
        isRefreshing: _isRefreshing,
        onRefresh: _checkApprovalStatus,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace Laboratoire'),
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
              color: Colors.indigo,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: const Icon(
                        Icons.science,
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
                            'Laboratoire',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            user?.fullName ?? 'Laboratoire',
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
                    title: 'Analyses',
                    value: '0', // Dynamic activity tracking placeholder
                    icon: Icons.biotech,
                    color: Colors.indigo,
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
              title: 'Catalogue des analyses',
              subtitle: 'Gerer la liste des tests et prix',
              icon: Icons.list_alt,
              iconColor: Colors.orange,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LabServicesScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            DashboardCard(
              title: 'Résultats d\'analyses',
              subtitle: 'Uploader et envoyer les résultats aux patients',
              icon: Icons.assignment,
              iconColor: Colors.teal,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LabResultsScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            DashboardCard(
              title: 'Demandes analyses',
              subtitle: 'Voir les nouvelles demandes',
              icon: Icons.inbox,
              iconColor: Colors.teal,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LabRequestsScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            DashboardCard(
              title: 'Messagerie',
              subtitle: 'Communiquer avec les patients',
              icon: Icons.chat,
              iconColor: Colors.green,
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


