import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';

class MedicationTrackerScreen extends StatefulWidget {
  const MedicationTrackerScreen({super.key});

  @override
  State<MedicationTrackerScreen> createState() =>
      _MedicationTrackerScreenState();
}

class _MedicationTrackerScreenState extends State<MedicationTrackerScreen> {
  final _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _medications = [];

  @override
  void initState() {
    super.initState();
    _fetchMedications();
  }

  Future<void> _fetchMedications() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.getMyMedications();
      if (mounted) {
        setState(() {
          _medications = data;
          _isLoading = false;
        });
        
        // Sync local notifications with new data
        NotificationService().syncMedicationReminders();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  void _showAddMedicationSheet() {
    final nameController = TextEditingController();
    final dosageController = TextEditingController();
    String frequency = 'Une fois par jour';
    final times = <TimeOfDay>[const TimeOfDay(hour: 8, minute: 0)];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ajouter un médicament',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom du médicament',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dosageController,
                  decoration: const InputDecoration(
                    labelText: 'Dosage (ex: 500mg)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Fréquence', style: TextStyle(fontWeight: FontWeight.w500)),
                DropdownButton<String>(
                  value: frequency,
                  isExpanded: true,
                  items: [
                    'Une fois par jour',
                    'Deux fois par jour',
                    'Trois fois par jour',
                    'Selon besoin',
                  ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => frequency = val);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Horaires des rappels', style: TextStyle(fontWeight: FontWeight.w500)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          setModalState(() => times.add(time));
                        }
                      },
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  children: times.asMap().entries.map((entry) {
                    final time = entry.value;
                    return Chip(
                      label: Text(time.format(context)),
                      onDeleted: () => setModalState(() => times.removeAt(entry.key)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isEmpty) return;
                      
                      try {
                        await _api.addMedicationSchedule({
                          'medicineName': nameController.text,
                          'dosage': dosageController.text,
                          'frequency': frequency,
                          'reminderTimes': times.map((t) => '${t.hour}:${t.minute.toString().padLeft(2, "0")}').toList(),
                          'isActive': true,
                        });
                        if (context.mounted) Navigator.pop(context);
                        _fetchMedications();
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur: $e')),
                          );
                        }
                      }
                    },
                    child: const Text('Enregistrer'),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Médicaments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddMedicationSheet,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _medications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.medication_liquid,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun médicament enregistré',
                    style: TextStyle(color: Colors.grey[600], fontSize: 18),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _medications.length,
              itemBuilder: (context, index) {
                final med = _medications[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.red.withOpacity(0.1),
                      child: const Icon(Icons.medication, color: Colors.red),
                    ),
                    title: Text(
                      med['medicine_name'] ?? 'Inconnu',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Fréquence: ${med['frequency'] ?? 'Non spécifiée'}\n'
                      'Heures: ${(med['reminder_times'] as List<dynamic>?)?.join(', ') ?? 'Aucune'}',
                    ),
                    isThreeLine: true,
                    trailing: med['is_active'] == true
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.cancel, color: Colors.grey),
                  ),
                );
              },
            ),
    );
  }
}


