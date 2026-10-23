import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/prescription_model.dart';
import '../../models/user_model.dart';
import '../shared/prescription_view_screen.dart';
import '../../services/auth_service.dart';

class PrescriptionFormScreen extends StatefulWidget {
  final String? patientId;
  final String? patientName;
  final int? appointmentId;

  const PrescriptionFormScreen({
    super.key,
    this.patientId,
    this.patientName,
    this.appointmentId,
  });

  @override
  State<PrescriptionFormScreen> createState() => _PrescriptionFormScreenState();
}

class _PrescriptionFormScreenState extends State<PrescriptionFormScreen> {
  final _api = ApiService();
  final _notesController = TextEditingController();
  final List<MedicationEntry> _medications = [MedicationEntry()];
  
  String? _selectedPatientId;
  String? _selectedPatientName;
  List<dynamic> _patients = [];
  bool _isLoadingPatients = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedPatientId = widget.patientId;
    _selectedPatientName = widget.patientName;
    if (_selectedPatientId == null) {
      _fetchPatients();
    }
  }

  Future<void> _fetchPatients() async {
    setState(() => _isLoadingPatients = true);
    try {
      final data = await _api.getProfilesByRole('patient');
      if (mounted) {
        setState(() {
          _patients = data;
          _isLoadingPatients = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingPatients = false);
    }
  }

  void _addMedication() {
    setState(() {
      _medications.add(MedicationEntry());
    });
  }

  void _removeMedication(int index) {
    if (_medications.length > 1) {
      setState(() {
        _medications.removeAt(index);
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un patient')),
      );
      return;
    }

    // Validate meds
    bool isValid = true;
    for (var med in _medications) {
      if (med.nameController.text.isEmpty) {
        isValid = false;
        break;
      }
    }

    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir au moins le nom de chaque médicament')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final List<Map<String, dynamic>> medsJson = _medications.map((m) => {
        'name': m.nameController.text,
        'dosage': m.dosageController.text,
        'duration': m.durationController.text,
        'instructions': m.instructionsController.text,
      }).toList();

      final response = await _api.createPrescription(
        patientId: _selectedPatientId!,
        appointmentId: widget.appointmentId,
        medications: medsJson,
        notes: _notesController.text,
      );

      if (mounted) {
        final newPrescription = PrescriptionModel.fromJson(response['data']);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PrescriptionViewScreen(prescription: newPrescription),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle Ordonnance'),
        actions: [
          if (!_isSubmitting)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _submit,
            ),
        ],
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDoctorInfoSection(),
                  const SizedBox(height: 16),
                  _buildPatientSelectionSection(),
                  const SizedBox(height: 24),
                  const Text('Médicaments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _medications.length,
                    itemBuilder: (context, index) {
                      return _buildMedicationCard(index);
                    },
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton.icon(
                      onPressed: _addMedication,
                      icon: const Icon(Icons.add),
                      label: const Text('Ajouter un médicament'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Notes / Conseils', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Conseils supplémentaires...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: Colors.teal,
          ),
          child: const Text('Générer l\'ordonnance'),
        ),
      ),
    );
  }

  Widget _buildDoctorInfoSection() {
    final doctor = AuthService().currentUser;
    return Card(
      elevation: 0,
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: const Icon(Icons.medical_services, color: Colors.blue),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Médecin Prescripteur:', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
                Text(
                  _getDoctorDisplayName(doctor),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                Text(
                  doctor?.specialty ?? 'Urologue',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientSelectionSection() {
    if (_selectedPatientId != null && _selectedPatientName != null) {
      return Card(
        color: Colors.teal.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.person, color: Colors.teal),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Patient sélectionné:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(
                      _selectedPatientName!, 
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)
                    ),
                  ],
                ),
              ),
              if (widget.patientId == null) // Only allow change if not fixed by constructor
                TextButton(
                  onPressed: () => setState(() {
                    _selectedPatientId = null;
                    _selectedPatientName = null;
                  }),
                  child: const Text('Changer'),
                ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choisir un patient', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (_isLoadingPatients)
              const Center(child: CircularProgressIndicator())
            else
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Sélectionner le patient',
                  prefixIcon: Icon(Icons.search),
                ),
                items: _patients.map((p) => DropdownMenuItem<String>(
                  value: p['id'].toString(),
                  child: Text(p['full_name'] ?? 'Inconnu'),
                )).toList(),
                onChanged: (val) {
                  final p = _patients.firstWhere((element) => element['id'].toString() == val);
                  setState(() {
                    _selectedPatientId = val;
                    _selectedPatientName = p['full_name'];
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationCard(int index) {
    final entry = _medications[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.teal.shade100,
                  child: Text('${index + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: entry.nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom du médicament',
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _removeMedication(index),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: entry.dosageController,
                    decoration: const InputDecoration(
                      labelText: 'Dosage (ex: 1 mat/soir)',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: entry.durationController,
                    decoration: const InputDecoration(
                      labelText: 'Durée (ex: 7 jours)',
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: entry.instructionsController,
              decoration: const InputDecoration(
                labelText: 'Instructions (ex: Avant repas)',
                isDense: true,
              ),
            ),
          ],
        ),
      ),
    );
  } // Closing _buildMedicationCard

  String _getDoctorDisplayName(UserModel? doctor) {
    if (doctor == null) return "Dr. Inconnu";
    if (doctor.fullName != null && doctor.fullName!.trim().isNotEmpty) {
      return "Dr. ${doctor.fullName}";
    }
    // Fallback to part of email if fullName is missing
    final nameFromEmail = doctor.email.split('@')[0];
    return "Dr. $nameFromEmail";
  }
} // Closing _PrescriptionFormScreenState

class MedicationEntry {
  final nameController = TextEditingController();
  final dosageController = TextEditingController();
  final durationController = TextEditingController();
  final instructionsController = TextEditingController();
}


