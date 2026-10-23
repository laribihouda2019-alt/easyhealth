import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../models/appointment_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/stat_card.dart';
import '../patient/medication_tracker.dart';
import '../patient/order_history_screen.dart';
import '../patient/medical_records_screen.dart';
import '../patient/patient_test_results_screen.dart';
import '../shared/chat_list_screen.dart';
import '../shared/appointments_screen.dart';

import '../shared/ai_recommendation_screen.dart';
import 'professional_discovery_screen.dart';
import 'payment_screen.dart';
import '../shared/prescription_list_screen.dart';
import '../../widgets/health_trend_card.dart';
import '../shared/profile_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/api_config.dart';
import 'chifa_card_screen.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
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
    final user = AuthService().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('EasyHealth'),
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
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: theme.colorScheme.primary,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ProfileScreen()),
                        );
                      },
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        backgroundImage: user?.avatarUrl != null 
                          ? CachedNetworkImageProvider(user!.avatarUrl!.startsWith('/') 
                              ? '${ApiConfig.baseUrl.replaceAll('/api', '')}${user.avatarUrl}' 
                              : user.avatarUrl!) 
                          : null,
                        child: user?.avatarUrl == null
                          ? const Icon(
                            Icons.person,
                            size: 32,
                            color: Colors.white,
                          )
                          : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bonjour,',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            user?.fullName ?? 'Patient',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (user?.wilaya != null || user?.commune != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Colors.white70,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${user?.wilaya ?? ""}${user?.wilaya != null && user?.commune != null ? ", " : ""}${user?.commune ?? ""}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 4),
                          const Text(
                            'Gerez votre sante en un seul endroit',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const HealthTrendCard(),
            const SizedBox(height: 24),
            _AppointmentRequestsWidget(),
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
                    title: 'Rendez-vous',
                    value: _isLoadingSummary ? '...' : (_summaryData?['upcomingAppointmentsCount']?.toString() ?? '0'),
                    icon: Icons.calendar_today,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ValueListenableBuilder<int>(
                    valueListenable: NotificationService().unreadMessagesCount,
                    builder: (context, unreadCount, child) {
                      final initialMsgCount = int.tryParse(_summaryData?['unreadMessagesCount']?.toString() ?? '0') ?? 0;
                      final totalUnreadMsg = initialMsgCount + unreadCount;
                      
                      return Badge(
                        isLabelVisible: totalUnreadMsg > 0,
                        label: Text(totalUnreadMsg.toString()),
                        alignment: Alignment.topRight,
                        child: StatCard(
                          title: 'Messages',
                          value: _isLoadingSummary ? '...' : totalUnreadMsg.toString(),
                          icon: Icons.chat_bubble_outline,
                          color: Colors.green,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Actions rapides',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            DashboardCard(
              title: 'Prendre rendez-vous',
              subtitle: 'Trouver un specialiste et prendre rendez-vous',
              icon: Icons.calendar_month,
              iconColor: Colors.blue,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfessionalDiscoveryScreen(initialRole: 'doctor', canContact: false)),
                );
              },
            ),
            const SizedBox(height: 12),
            DashboardCard(
              title: 'Messagerie',
              subtitle: 'Discuter avec medecins, pharmacies et laboratoires',
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
              title: 'Recommandation IA - Medecin',
              subtitle:
                  'Decrivez vos symptomes pour obtenir une recommandation',
              icon: Icons.psychology,
              iconColor: Colors.deepPurple,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AiRecommendationScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Suivi sante',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickTile(
                    icon: Icons.medication,
                    label: 'Médicaments',
                    color: Colors.red,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const MedicationTrackerScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickTile(
                    icon: Icons.science,
                    label: 'Résultats labo',
                    color: Colors.teal,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PatientTestResultsScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickTile(
                    icon: Icons.folder,
                    label: 'Dossier Médical',
                    color: Colors.indigo,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const MedicalRecordsScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _QuickTile(
              icon: Icons.history_edu,
              label: 'Mes Ordonnances Digitales',
              color: Colors.teal,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PrescriptionListScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            DashboardCard(
              title: 'Ma Carte Chifa',
              subtitle: 'Réactiver votre carte et suivre vos remboursements',
              icon: Icons.credit_card,
              iconColor: const Color(0xFF1565C0),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ChifaCardScreen()),
                );
              },
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pharmacie & Laboratoire',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
                    );
                  },
                  child: const Text('Tout voir'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ServiceCard(
              title: 'Commander Médicaments',
              subtitle: 'Envoyer votre ordonnance en un clic',
              icon: Icons.medication_liquid,
              color: Colors.blue,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ProfessionalDiscoveryScreen(initialRole: 'pharmacy'),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _ServiceCard(
              title: 'Demander Analyse Labo',
              subtitle: 'Réservez votre créneau et vos tests',
              icon: Icons.biotech,
              color: Colors.teal,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ProfessionalDiscoveryScreen(initialRole: 'lab'),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

class _AppointmentRequestsWidget extends StatefulWidget {
  @override
  State<_AppointmentRequestsWidget> createState() => _AppointmentRequestsWidgetState();
}

class _AppointmentRequestsWidgetState extends State<_AppointmentRequestsWidget> {
  final StreamController<List<AppointmentModel>> _streamController = StreamController<List<AppointmentModel>>.broadcast();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) => _loadData());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _streamController.close();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final response = await ApiService().getMyAppointments();
      final List<dynamic> data = response['data'] ?? response['appointments'] ?? [];
      final appointments = data.map((json) => AppointmentModel.fromJson(json)).toList();
      if (mounted) _streamController.add(appointments);
    } catch (e) {
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppointmentModel>>(
      stream: _streamController.stream,
      builder: (context, snapshot) {
        final appointments = snapshot.data ?? [];
        final pendingOrRecent = appointments.where((a) => 
          a.status == AppointmentStatus.pending || 
          a.status == AppointmentStatus.accepted ||
          a.status == AppointmentStatus.rejected
        ).toList();

        if (pendingOrRecent.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mes demandes de rendez-vous',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: pendingOrRecent.length,
                itemBuilder: (context, index) {
                  final apt = pendingOrRecent[index];
                  return Container(
                    width: 280,
                    margin: const EdgeInsets.only(right: 12, bottom: 4),
                    child: Card(
                      elevation: 4,
                      shadowColor: Colors.black12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: apt.status == AppointmentStatus.accepted 
                              ? Colors.green.withOpacity(0.3) 
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Dr. ${apt.doctorName?.isNotEmpty == true ? apt.doctorName : 'Médecin'}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        DateFormat('dd MMM | HH:mm').format(apt.scheduledAt.toLocal()),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _MiniStatusBadge(status: apt.status),
                              ],
                            ),
                            const Spacer(),
                            if (apt.status == AppointmentStatus.accepted)
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: () {
                                    Navigator.of(context).pushNamed(
                                      '/payment',
                                      arguments: apt,
                                    );
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.blue.shade700,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(0, 40),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.payment, size: 16),
                                      SizedBox(width: 8),
                                      Text('Payer maintenant', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              )
                            else if (apt.status == AppointmentStatus.pending)
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.hourglass_empty, size: 14, color: Colors.orange),
                                    SizedBox(width: 8),
                                    Text(
                                      'En attente de validation',
                                      style: TextStyle(
                                        fontSize: 11, 
                                        color: Colors.orange,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MiniStatusBadge extends StatelessWidget {
  final AppointmentStatus status;
  const _MiniStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case AppointmentStatus.accepted: color = Colors.green; label = 'Accepté'; break;
      case AppointmentStatus.rejected: color = Colors.red; label = 'Refusé'; break;
      case AppointmentStatus.pending: color = Colors.orange; label = 'En attente'; break;
      default: color = Colors.grey; label = status.displayName;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class _QuickTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _QuickTile({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}


