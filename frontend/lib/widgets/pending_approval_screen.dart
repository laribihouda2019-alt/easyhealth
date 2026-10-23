import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class PendingApprovalScreen extends StatelessWidget {
  final String roleDisplayName;
  final bool isRefreshing;
  final VoidCallback onRefresh;

  const PendingApprovalScreen({
    super.key,
    required this.roleDisplayName,
    required this.isRefreshing,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isRefreshing)
                const CircularProgressIndicator()
              else
                Icon(Icons.hourglass_empty, size: 80, color: Colors.orange[300]),
              const SizedBox(height: 24),
              const Text(
                'Compte en attente de validation',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Votre compte $roleDisplayName est en cours de vérification par notre équipe. Vous recevrez une notification dès que votre compte sera activé.',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: isRefreshing ? null : onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Vérifier le statut'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () async {
                  await AuthService().logout();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacementNamed('/login');
                  }
                },
                child: const Text('Se déconnecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


