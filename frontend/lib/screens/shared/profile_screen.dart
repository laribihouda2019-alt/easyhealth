import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _apiService = ApiService();
  final _authService = AuthService();
  bool _isLoading = false;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final stats = await _apiService.getProfileStats();
      setState(() {
        _stats = stats;
      });
    } catch (e) {
    }
  }

  Future<void> _updateProfilePicture() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() => _isLoading = true);
      try {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          await _apiService.updateProfileAvatar(
            bytes: bytes,
            fileName: image.name,
          );
        } else {
          await _apiService.updateProfileAvatar(path: image.path);
        }
        
        await _authService.refreshProfile();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo de profil mise à jour')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Utilisateur non trouvé')));

    final theme = Theme.of(context);
    final primaryColor = const Color(0xFF2E5BFF); // Medical Blue
    final secondaryColor = const Color(0xFF00C09E); // Medical Green

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Mon Profil'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            // Top Section: Profile Picture and Basic Info
            _buildHeader(user, primaryColor),
            const SizedBox(height: 30),

            // Activity Summary
            _buildActivitySummary(user, primaryColor, secondaryColor),
            const SizedBox(height: 30),

            // Specific Fields Section
            _buildSpecificFields(user, theme),
            const SizedBox(height: 30),

            // Common Features: Account Settings
            _buildAccountSettings(user, theme),
            const SizedBox(height: 30),

            // Logout Button
            _buildLogoutButton(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(UserModel user, Color primaryColor) {
    String avatarUrl = user.avatarUrl ?? '';
    if (avatarUrl.startsWith('/')) {
      avatarUrl = '${ApiConfig.baseUrl.replaceAll('/api', '')}$avatarUrl';
    }

    return Column(
      children: [
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[200],
                backgroundImage: avatarUrl.isNotEmpty
                    ? CachedNetworkImageProvider(avatarUrl)
                    : null,
                child: avatarUrl.isEmpty
                    ? Icon(Icons.person, size: 60, color: Colors.grey[400])
                    : null,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: InkWell(
                onTap: _isLoading ? null : _updateProfilePicture,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.edit, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          user.fullName ?? 'Utilisateur',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            user.role.displayName,
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildActivitySummary(UserModel user, Color blue, Color green) {
    if (user.role == UserRole.doctor) {
      return _buildStatCard(
        title: 'Rapports Soumis',
        value: _stats?['reportsCount']?.toString() ?? '0',
        subtitle: 'Contributions à l\'observatoire',
        icon: Icons.analytics,
        color: green,
      );
    } else if (user.role == UserRole.patient) {
      return _buildStatCard(
        title: 'Consultations IA',
        value: _stats?['aiConsultationsCount']?.toString() ?? '0',
        subtitle: 'Analyses de symptômes effectuées',
        icon: Icons.psychology,
        color: blue,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  value,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecificFields(UserModel user, ThemeData theme) {
    return _buildSection(
      title: 'Informations Professionnelles',
      child: Column(
        children: [
          if (user.role == UserRole.doctor) ...[
            _buildFieldTile(Icons.medical_services, 'Spécialité', user.specialty ?? 'Non renseigné'),
            _buildFieldTile(Icons.business, 'Hôpital / Clinique', user.hospitalClinic ?? 'Non renseigné'),
            _buildFieldTile(Icons.badge, 'ID Matricale', user.licenseNumber ?? 'Non renseigné'),
            _buildFieldTile(Icons.location_on, 'Localisation', '${user.wilaya ?? "-"}, ${user.commune ?? "-"}'),
            _buildScheduleSummary(user.availableDays, user.availableHours),
          ] else if (user.role == UserRole.patient) ...[
            _buildFieldTile(Icons.cake, 'Âge', _calculateAge(user.dateOfBirth)),
            _buildFieldTile(Icons.opacity, 'Groupe Sanguin', user.bloodType ?? 'Non renseigné'),
            _buildFieldTile(Icons.contact_phone, 'Contact d\'urgence', user.emergencyContact ?? 'Non renseigné'),
            if (user.emergencyPhone != null)
              _buildFieldTile(Icons.phone_android, 'Tél. urgence', user.emergencyPhone!),
          ],
        ],
      ),
    );
  }

  Widget _buildScheduleSummary(dynamic days, dynamic hours) {
    String summary = 'Non renseigné';
    if (days != null && hours != null) {
      if (days is List && days.isNotEmpty) {
        summary = '${days.length} jours par semaine';
      } else if (days is String) {
        summary = days;
      }
    }
    return _buildFieldTile(Icons.schedule, 'Emploi du temps', summary);
  }

  String _calculateAge(String? dob) {
    if (dob == null) return 'Non renseigné';
    try {
      final birthDate = DateTime.parse(dob);
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return '$age ans';
    } catch (e) {
      return dob;
    }
  }

  Widget _buildAccountSettings(UserModel user, ThemeData theme) {
    return _buildSection(
      title: 'Paramètres du compte',
      child: Column(
        children: [
          _buildActionTile(Icons.email, 'Changer l\'email', user.email, () {}),
          _buildActionTile(Icons.lock, 'Changer le mot de passe', '••••••••', () {}),
          _buildActionTile(Icons.notifications, 'Notifications', 'Activées', () {}),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 2)),
            ],
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _buildFieldTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueGrey[400], size: 22),
      title: Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87)),
      dense: true,
    );
  }

  Widget _buildActionTile(IconData icon, String label, String value, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: Colors.blue, size: 22),
      title: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      subtitle: Text(value, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      dense: true,
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          await _authService.logout();
          if (context.mounted) {
            Navigator.of(context).pushReplacementNamed('/login');
          }
        },
        icon: const Icon(Icons.logout, color: Colors.red),
        label: const Text('Déconnexion', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15),
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}


