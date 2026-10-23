import 'package:flutter/material.dart';
import '../screens/patient/doctor_list_screen.dart';

class RecommendationIAMedecin extends StatelessWidget {
  final String specialty;
  final String advice;
  final String source;

  const RecommendationIAMedecin({
    super.key,
    required this.specialty,
    required this.advice,
    required this.source,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return RepaintBoundary(
      child: Card(
        elevation: 8,
        shadowColor: theme.colorScheme.primary.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primaryContainer.withOpacity(0.3),
                theme.colorScheme.surface,
              ],
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.psychology, color: theme.colorScheme.primary, size: 28),
                      const SizedBox(width: 10),
                      Text(
                        'Recommandation',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: source == 'AI' ? Colors.purple.shade50 : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: source == 'AI' ? Colors.purple.shade200 : Colors.blue.shade200,
                      ),
                    ),
                    child: Text(
                      source,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: source == 'AI' ? Colors.purple.shade700 : Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Text(
                'Spécialité recommandée :',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
              Text(
                specialty,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.colorScheme.secondaryContainer.withOpacity(0.5),
                  ),
                ),
                child: Text(
                  advice,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DoctorListScreen(specialty: specialty),
                      ),
                    );
                  },
                  icon: const Icon(Icons.search),
                  label: const Text('Trouver un médecin'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


