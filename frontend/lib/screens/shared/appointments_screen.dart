import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/appointment_model.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../patient/payment_screen.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final List<AppointmentModel> _appointments = [];
  bool _isLoading = true;
  Timer? _pollTimer;
  final StreamController<List<AppointmentModel>> _streamController = 
      StreamController<List<AppointmentModel>>.broadcast();

  @override
  void initState() {
    super.initState();
    _loadAppointments();
    _startPolling();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _loadAppointments(isPoll: true);
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _streamController.close();
    super.dispose();
  }

  Future<void> _loadAppointments({bool isPoll = false}) async {
    if (!isPoll) setState(() => _isLoading = true);
    try {
      final user = AuthService().currentUser;
      Map<String, dynamic> response;
      
      if (user?.role == UserRole.doctor) {
        response = await ApiService().getDoctorAppointments();
      } else {
        response = await ApiService().getMyAppointments();
      }
      
      final List<dynamic> data = response['data'] ?? response['appointments'] ?? [];
      final List<AppointmentModel> loadedAppointments = data.map((json) => AppointmentModel.fromJson(json)).toList();
      
      if (mounted) {
        setState(() {
          _appointments.clear();
          _appointments.addAll(loadedAppointments);
          _isLoading = false;
        });
        _streamController.add(loadedAppointments);
      }
    } catch (e) {
      if (!isPoll && mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e')),
        );
      }
    }
  }

  Future<void> _updateStatus(String appointmentId, AppointmentStatus status) async {
    try {
      // Optimistic UI update: find and update the appointment in the list immediately
      final index = _appointments.indexWhere((a) => a.id == appointmentId);
      if (index != -1) {
        setState(() {
          // Note: AppointmentModel is immutable, so we'd need a copyWith or just reload
          // For now, reloading is safer but I'll trigger the stream manual refresh
        });
      }

      await ApiService().updateAppointmentStatus(appointmentId, status);
      await _loadAppointments(); // Refresh from server
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Statut mis à jour : ${status.displayName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rendez-vous'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadAppointments(),
          ),
        ],
      ),
      body: StreamBuilder<List<AppointmentModel>>(
        stream: _streamController.stream,
        initialData: _appointments,
        builder: (context, snapshot) {
          if (_isLoading && (_appointments.isEmpty)) {
            return const Center(child: CircularProgressIndicator());
          }

          final appointments = snapshot.data ?? [];

          if (appointments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun rendez-vous',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final apt = appointments[index];
              return _AppointmentCard(
                appointment: apt,
                onUpdateStatus: (status) => _updateStatus(apt.id, status),
              );
            },
          );
        },
      ),
      floatingActionButton: AuthService().currentUser?.role == UserRole.patient
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await _showBookingDialog(context);
                if (result == true) _loadAppointments();
              },
              icon: const Icon(Icons.add),
              label: const Text('Nouveau'),
            )
          : null,
    );
  }

  Future<bool?> _showBookingDialog(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _BookAppointmentSheet(),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final Function(AppointmentStatus)? onUpdateStatus;

  const _AppointmentCard({
    required this.appointment,
    this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final bool isDoctor = user?.role == UserRole.doctor;
    final timeFormat = DateFormat('HH:mm');
    final DateTime localTime = appointment.scheduledAt.toLocal();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('d').format(localTime),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      Text(
                        DateFormat('MMM').format(localTime),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Text(
                          isDoctor 
                            ? "Patient: ${appointment.patientName ?? 'Anonyme'}" 
                            : "Dr. ${appointment.doctorName ?? 'Inconnu'}",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),

                      const SizedBox(height: 4),
                      Text(
                        appointment.notes ?? 'Consultation',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeFormat.format(localTime),
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              appointment.location ?? 'Non spécifié',
                              style: TextStyle(color: Colors.grey[600]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: appointment.status),
              ],
            ),
            if (isDoctor && appointment.status == AppointmentStatus.pending) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => onUpdateStatus?.call(AppointmentStatus.rejected),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Refuser'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () => onUpdateStatus?.call(AppointmentStatus.accepted),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Accepter'),
                    style: FilledButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ],
              ),
            ],
            if (!isDoctor && appointment.status == AppointmentStatus.accepted) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton.icon(
                    onPressed: () async {
                      // Navigate using route name and arguments to match main.dart
                      final result = await Navigator.of(context).pushNamed(
                        '/payment',
                        arguments: appointment,
                      );
                      if (result == true) {
                        onUpdateStatus?.call(AppointmentStatus.confirmed);
                      }
                    },
                    icon: const Icon(Icons.payment, size: 18),
                    label: const Text('Payer maintenant'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      elevation: 2,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final AppointmentStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case AppointmentStatus.accepted:
      case AppointmentStatus.confirmed:
        color = Colors.green;
        break;
      case AppointmentStatus.pending:
        color = Colors.orange;
        break;
      case AppointmentStatus.rejected:
      case AppointmentStatus.cancelled:
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _BookAppointmentSheet extends StatefulWidget {
  const _BookAppointmentSheet();

  @override
  State<_BookAppointmentSheet> createState() => _BookAppointmentSheetState();
}

class _BookAppointmentSheetState extends State<_BookAppointmentSheet> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  String? _selectedDoctorId;
  List<dynamic> _doctors = [];
  bool _isLoadingDoctors = true;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    try {
      final docs = await ApiService().getProfilesByRole('doctor');
      if (mounted) {
        setState(() {
          _doctors = docs;
          if (_doctors.isNotEmpty) {
            _selectedDoctorId = _doctors.first['id'];
          }
          _isLoadingDoctors = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingDoctors = false);
    }
  }

  Future<void> _bookAppointment() async {
    if (_selectedDoctorId == null) return;

    final scheduledAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    try {
      final doctorName = _doctors.firstWhere(
        (doc) => doc['id'] == _selectedDoctorId,
        orElse: () => {'full_name': 'Médecin'}
      )['full_name'];
      
      await ApiService().createRealAppointment({
        'doctorId': _selectedDoctorId,
        'doctorName': doctorName,
        'patientName': AuthService().currentUser?.fullName ?? 'Anonyme',
        'scheduledAt': scheduledAt.toIso8601String(),
        'appointmentType': 'consultation',
        'durationMinutes': 30,
        'notes': 'Consultation via application',
      });

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Nouveau rendez-vous',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            if (_isLoadingDoctors)
              const Center(child: CircularProgressIndicator())
            else
              DropdownButtonFormField<String>(
                value: _selectedDoctorId,
                decoration: InputDecoration(
                  labelText: 'Médecin',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _doctors.map((doc) {
                  return DropdownMenuItem<String>(
                    value: doc['id'],
                    child: Text(doc['full_name'] ?? 'Médecin'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedDoctorId = value);
                },
              ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Date'),
              subtitle: Text(
                DateFormat('EEEE d MMMM yyyy').format(_selectedDate),
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                );
                if (date != null) setState(() => _selectedDate = date);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time),
              title: const Text('Heure'),
              subtitle: Text(_selectedTime.format(context)),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime,
                );
                if (time != null) setState(() => _selectedTime = time);
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _bookAppointment,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Confirmer le rendez-vous'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


