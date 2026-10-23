import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';

class AvailabilityManagementScreen extends StatefulWidget {
  const AvailabilityManagementScreen({super.key});

  @override
  State<AvailabilityManagementScreen> createState() => _AvailabilityManagementScreenState();
}

class _AvailabilityManagementScreenState extends State<AvailabilityManagementScreen> {
  final ApiService _apiService = ApiService();
  DateTime _selectedDate = DateTime.now();
  final List<Map<String, TimeOfDay>> _timeSlots = [];
  List<dynamic> _existingSlots = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchExistingSlots();
  }

  Future<void> _fetchExistingSlots() async {
    setState(() => _isLoading = true);
    try {
      final slots = await _apiService.getAvailabilitySlots();
      setState(() {
        _existingSlots = slots;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des créneaux: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.teal,
              onPrimary: Colors.white,
              onSurface: Colors.teal.shade900,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _addTimeSlot() async {
    final TimeOfDay? startTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      helpText: 'Heure de début',
    );
    if (startTime == null) return;

    if (!mounted) return;

    final TimeOfDay? endTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: startTime.hour, minute: startTime.minute + 30),
      helpText: 'Heure de fin',
    );
    if (endTime == null) return;

    setState(() {
      _timeSlots.add({'start': startTime, 'end': endTime});
      _timeSlots.sort((a, b) {
        if (a['start']!.hour != b['start']!.hour) {
          return a['start']!.hour.compareTo(b['start']!.hour);
        }
        return a['start']!.minute.compareTo(b['start']!.minute);
      });
    });
  }

  Future<void> _saveSlots() async {
    if (_timeSlots.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final List<Map<String, dynamic>> slotsToSave = _timeSlots.map((slot) {
        final start = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          slot['start']!.hour,
          slot['start']!.minute,
        );
        final end = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          slot['end']!.hour,
          slot['end']!.minute,
        );
        return {
          'start_time': start.toUtc().toIso8601String(),
          'end_time': end.toUtc().toIso8601String(),
        };
      }).toList();

      await _apiService.addAvailabilitySlots(slotsToSave);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Disponibilité enregistrée avec succès'), backgroundColor: Colors.green),
        );
        setState(() {
          _timeSlots.clear();
        });
        _fetchExistingSlots();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteSlot(int id) async {
    try {
      await _apiService.deleteAvailabilitySlot(id);
      _fetchExistingSlots();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion de Disponibilité'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Ajouter des disponibilités'),
                const SizedBox(height: 12),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        ListTile(
                          title: const Text('Date sélectionnée'),
                          subtitle: Text(DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_selectedDate)),
                          trailing: const Icon(Icons.calendar_today, color: Colors.teal),
                          onTap: _selectDate,
                        ),
                        const Divider(),
                        if (_timeSlots.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Text('Aucun créneau ajouté', style: TextStyle(color: Colors.grey)),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _timeSlots.length,
                            itemBuilder: (context, index) {
                              final slot = _timeSlots[index];
                              return ListTile(
                                leading: const Icon(Icons.access_time, color: Colors.blue),
                                title: Text('${slot['start']!.format(context)} - ${slot['end']!.format(context)}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                  onPressed: () => setState(() => _timeSlots.removeAt(index)),
                                ),
                              );
                            },
                          ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _addTimeSlot,
                              icon: const Icon(Icons.add),
                              label: const Text('Ajouter un créneau'),
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.teal),
                            ),
                            if (_timeSlots.isNotEmpty)
                              FilledButton.icon(
                                onPressed: _saveSlots,
                                icon: const Icon(Icons.save),
                                label: const Text('Enregistrer'),
                                style: FilledButton.styleFrom(backgroundColor: Colors.teal),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _buildSectionTitle('Disponibilités à venir'),
                const SizedBox(height: 12),
                if (_existingSlots.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Vous n\'avez pas encore défini de disponibilités futures.'),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _existingSlots.length,
                    itemBuilder: (context, index) {
                      final slot = _existingSlots[index];
                      final start = DateTime.parse(slot['start_time']).toLocal();
                      final end = DateTime.parse(slot['end_time']).toLocal();
                      final isBooked = slot['status'] == 'booked';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isBooked ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isBooked ? Icons.event_available : Icons.event_note,
                              color: isBooked ? Colors.orange : Colors.green,
                            ),
                          ),
                          title: Text(DateFormat('d MMMM yyyy', 'fr_FR').format(start)),
                          subtitle: Text('${DateFormat('HH:mm').format(start)} - ${DateFormat('HH:mm').format(end)}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isBooked ? Colors.orange : Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isBooked ? 'Réservé' : 'Libre',
                                  style: const TextStyle(color: Colors.white, fontSize: 10),
                                ),
                              ),
                              if (!isBooked)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () => _deleteSlot(slot['id']),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.teal,
      ),
    );
  }
}


