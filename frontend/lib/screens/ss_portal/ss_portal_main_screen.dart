import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import 'ss_dashboard_screen.dart';
import 'medical_controller_dashboard.dart';

class SSPortalMainScreen extends StatefulWidget {
  const SSPortalMainScreen({super.key});

  @override
  State<SSPortalMainScreen> createState() => _SSPortalMainScreenState();
}

class _SSPortalMainScreenState extends State<SSPortalMainScreen> {
  int _selectedIndex = 0;
  late final UserRole _role;

  @override
  void initState() {
    super.initState();
    _role = AuthService().currentUser?.role ?? UserRole.socialSecurity;
    // Set default view based on role
    if (_role == UserRole.medicalController) {
      _selectedIndex = 0; // Medical Approvals
    } else {
      _selectedIndex = 0; // Card Reactivations
    }
  }

  List<Widget> _getScreens() {
    if (_role == UserRole.medicalController) {
      return [
        const MedicalControllerDashboard(),
        const Center(child: Text('Révision Ordonnances (À venir)')),
      ];
    } else if (_role == UserRole.socialSecurity) {
      return [
        const SSDashboardScreen(),
        const Center(child: Text('Dossiers Assurés (À venir)')),
      ];
    } else {
      return [
        const SSDashboardScreen(),
        const MedicalControllerDashboard(),
      ];
    }
  }

  List<Map<String, dynamic>> _getMenuItems() {
    if (_role == UserRole.medicalController) {
      return [
        {'title': 'Approbations Médicales', 'icon': Icons.fact_check_rounded},
        {'title': 'Révision Ordonnances', 'icon': Icons.description_rounded},
      ];
    } else if (_role == UserRole.socialSecurity) {
      return [
        {'title': 'Réactivations Cartes', 'icon': Icons.autorenew_rounded},
        {'title': 'Dossiers Assurés', 'icon': Icons.badge_rounded},
      ];
    } else {
      return [
        {'title': 'Agent (Cartes)', 'icon': Icons.badge_rounded},
        {'title': 'Médecin (Approbs)', 'icon': Icons.medical_services_rounded},
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const ssPrimary = Color(0xFF1A3B5D);
    final user = AuthService().currentUser;
    final menuItems = _getMenuItems();
    final screens = _getScreens();

    return Scaffold(
      body: Row(
        children: [
          // Desktop Sidebar
          Container(
            width: 280,
            color: ssPrimary,
            child: Column(
              children: [
                const SizedBox(height: 48),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.security, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'EasyHealth',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          Text(
                            'SS Portal',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Expanded(
                  child: ListView.builder(
                    itemCount: menuItems.length,
                    itemBuilder: (context, index) {
                      final item = menuItems[index];
                      final isSelected = _selectedIndex == index;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: ListTile(
                          onTap: () => setState(() => _selectedIndex = index),
                          selected: isSelected,
                          selectedTileColor: Colors.white.withOpacity(0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          leading: Icon(item['icon'], color: isSelected ? Colors.white : Colors.white60),
                          title: Text(
                            item['title'],
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white60,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(color: Colors.white10),
                const SizedBox(height: 12),
                ListTile(
                  leading: const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, color: Colors.white, size: 16),
                  ),
                  title: Text(
                    user?.fullName ?? 'Utilisateur',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  subtitle: Text(
                    _role.name.toUpperCase(),
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await AuthService().logout();
                      if (mounted) Navigator.pushReplacementNamed(context, '/ss-portal-login');
                    },
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Déconnexion'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: Scaffold(
               // Nested scaffold to have standard AppBars in dashboards if needed, 
               // but we'll probably remove them from dashboards for better integration
              body: screens[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }
}


