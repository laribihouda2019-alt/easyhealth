import 'package:flutter/material.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/stat_card.dart';
import '../../services/auth_service.dart';
import '../shared/chat_list_screen.dart';
import '../shared/appointments_screen.dart';
import '../../widgets/notification_bell.dart';

import '../shared/statistics_screen.dart';
import '../../widgets/pending_approval_screen.dart';
import 'qr_scanner_screen.dart';
import '../shared/prescription_list_screen.dart';
import 'disease_observatory.dart';
import '../shared/profile_screen.dart';
import '../../config/api_config.dart';
import 'availability_management_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
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

  Future<void> _showFeeSettingsDialog() async {
    final user = AuthService().currentUser;
    final initialFee = user?.consultationFee?.toString() ?? '';
    final feeController = TextEditingController(text: initialFee);
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Tarification'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Définissez le tarif de votre consultation vidéo (DZD) :',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: feeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tarif (DZD)',
                      prefixIcon: Icon(Icons.monetization_on_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final feeText = feeController.text.trim();
                          if (feeText.isEmpty) return;
                          final feeValue = double.tryParse(feeText);
                          if (feeValue == null) return;

                          setStateDialog(() => isSaving = true);
                          try {
                            await AuthService().updateProfile({
                              'consultation_fee': feeValue,
                            });
                            if (mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Tarif mis à jour avec succès'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Erreur: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            setStateDialog(() => isSaving = false);
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = AuthService().currentUser;

    if (user != null && !user.isApproved) {
      return PendingApprovalScreen(
        roleDisplayName: 'médecin',
        isRefreshing: _isRefreshing,
        onRefresh: _checkApprovalStatus,
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace Medecin'),
        actions: [
          const NotificationBell(),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
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
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.teal,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        backgroundImage: user?.avatarUrl != null 
                          ? CachedNetworkImageProvider(user!.avatarUrl!.startsWith('/') 
                              ? '${ApiConfig.baseUrl.replaceAll('/api', '')}${user.avatarUrl}' 
                              : user.avatarUrl!) 
                          : null,
                        child: user?.avatarUrl == null
                          ? const Icon(
                            Icons.medical_services,
                            size: 32,
                            color: Colors.white,
                          )
                          : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Dr.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              user?.fullName ?? 'Medecin',
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
            ),
            const SizedBox(height: 24),
            Text(
              'Statistiques du jour',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Consultations',
                    value: _isLoadingSummary ? '...' : (_summaryData?['consultationsCount']?.toString() ?? '0'),
                    icon: Icons.people,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: 'En attente',
                    value: _isLoadingSummary ? '...' : (_summaryData?['pendingAppointmentsCount']?.toString() ?? '0'),
                    icon: Icons.pending_actions,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Actions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            DashboardCard(
              title: 'Rendez-vous',
              subtitle: 'Voir et gerer vos rendez-vous',
              icon: Icons.calendar_month,
              iconColor: Colors.blue,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AppointmentsScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            DashboardCard(
              title: 'Messagerie patients',
              subtitle: 'Discuter avec vos patients',
              icon: Icons.chat,
              iconColor: Colors.green,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ChatListScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            DashboardCard(
              title: 'Gestion de Disponibilité',
              subtitle: 'Définissez vos créneaux horaires',
              icon: Icons.access_time_filled,
              iconColor: Colors.teal,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AvailabilityManagementScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            DashboardCard(
              title: 'Scanner QR Patient',
              subtitle: 'Accéder au dossier via QR Code',
              icon: Icons.qr_code_scanner,
              iconColor: Colors.purple,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const QRScannerScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            DashboardCard(
              title: 'Mes Ordonnances',
              subtitle: 'Historique des ordonnances rédigées',
              icon: Icons.history_edu,
              iconColor: Colors.teal,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PrescriptionListScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            DashboardCard(
              title: 'Nouvelle Ordonnance',
              subtitle: 'Scanner un patient pour rédiger une ordonnance',
              icon: Icons.add_task,
              iconColor: Colors.orange,
              onTap: () {
                Navigator.of(context).pushNamed('/create-prescription', arguments: {
                  'patientId': null,
                  'patientName': null,
                  'appointmentId': null,
                });
              },
            ),
            const SizedBox(height: 12),
            DashboardCard(
              title: 'Tarification',
              subtitle: 'Définir le tarif de consultation',
              icon: Icons.payments_outlined,
              iconColor: Colors.orange,
              onTap: _showFeeSettingsDialog,
            ),
            const SizedBox(height: 12),
            DashboardCard(
              title: 'Maladies Récurrentes',
              subtitle: 'Signaler les pathologies observées',
              icon: Icons.analytics_outlined,
              iconColor: Colors.red,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DiseaseObservatoryScreen()),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).pushNamed('/create-prescription', arguments: {
            'patientId': null,
            'patientName': null,
            'appointmentId': null,
          });
        },
        label: const Text('Nouvelle Ordonnance'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.teal,
      ),
    );
  }
}


