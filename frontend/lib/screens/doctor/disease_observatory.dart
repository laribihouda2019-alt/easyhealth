import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../widgets/symptom_distribution_chart.dart';

class DiseaseObservatoryScreen extends StatefulWidget {
  const DiseaseObservatoryScreen({super.key});

  @override
  State<DiseaseObservatoryScreen> createState() =>
      _DiseaseObservatoryScreenState();
}

class _DiseaseObservatoryScreenState extends State<DiseaseObservatoryScreen> {
  final _symptomsController = TextEditingController();
  final _api = ApiService();
  bool _isLoading = false;
  bool _isLoadingDistribution = true;
  bool _isLoadingHistory = true;
  List<dynamic> _distribution = [];
  List<dynamic> _history = [];

  String? _selectedRegion;
  String? _selectedGender;
  String? _selectedAgeGroup;

  final List<String> _regions = ['Oran', 'Bir El Djir', 'Es Senia', 'Gdyel', 'Sidi Chami'];
  final List<String> _genders = ['Homme', 'Femme', 'Autre'];
  final List<String> _ageGroups = ['Enfant', 'Adolescent', 'Adulte', 'Senior'];

  @override
  void initState() {
    super.initState();
    _refreshData(); // Automatic data loading on initialization
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    await Future.wait([
      _fetchHistory(),
      _fetchDistribution(),
    ]);
  }

  Future<void> _fetchHistory() async {
    if (mounted) setState(() => _isLoadingHistory = true);
    try {
      final response = await _api.get('/disease-observatory/history');
      if (mounted && response != null && response['success'] == true) {
        setState(() {
          _history = response['data'] ?? [];
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _fetchDistribution() async {
    if (mounted) setState(() => _isLoadingDistribution = true);
    try {
      final response = await _api.get('/disease-observatory/symptom-distribution');
      if (mounted && response != null && response['success'] == true) {
        setState(() {
          _distribution = response['data'] ?? [];
          _isLoadingDistribution = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingDistribution = false);
    }
  }

  Future<void> _submitData() async {
    if (_selectedRegion == null || _selectedGender == null || _selectedAgeGroup == null || _symptomsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _api.post('/disease-observatory/report', {
        'region': _selectedRegion,
        'gender': _selectedGender,
        'ageGroup': _selectedAgeGroup,
        'symptomSummary': _symptomsController.text.trim(),
      });

      if (mounted) {
        setState(() {
          _isLoading = false;
          _symptomsController.clear();
        });
        _refreshData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rapport envoyé avec succès'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _incrementReport(dynamic id) async {
    if (id == null) return;
    try {
      // Robust increment: Ensure we capture the numeric ID correctly
      final response = await _api.post('/disease-observatory/increment/$id', {});
      if (response['success'] == true) {
        _refreshData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compteur incrémenté (+1)'), backgroundColor: Colors.blue),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'ajout rapide: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Observatoire & Analytics'),
        actions: [
          IconButton(onPressed: _refreshData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. PERSISTENT CHARTS (First thing the doctor sees)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: _isLoadingDistribution
                      ? const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
                      : SymptomDistributionChart(data: _distribution),
                ),
              ),
              const SizedBox(height: 24),

              // 2. NEW DECLARATION FORM
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Nouvelle Déclaration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Divider(height: 32),
                      DropdownButtonFormField<String>(
                        value: _selectedRegion,
                        decoration: const InputDecoration(labelText: 'Région / Commune'),
                        items: _regions.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                        onChanged: (val) => setState(() => _selectedRegion = val),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedGender,
                              decoration: const InputDecoration(labelText: 'Sexe'),
                              items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                              onChanged: (val) => setState(() => _selectedGender = val),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedAgeGroup,
                              decoration: const InputDecoration(labelText: 'Tranche d\'âge'),
                              items: _ageGroups.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                              onChanged: (val) => setState(() => _selectedAgeGroup = val),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _symptomsController,
                        decoration: const InputDecoration(labelText: 'Pathologie observée', hintText: 'Ex: Grippe, Bronchiolite...'),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _isLoading ? null : _submitData,
                        icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.add),
                        label: const Text('Enregistrer le cas'),
                        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 3. RECENT REPORTS (History)
              const Text('Historique Récent', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (_isLoadingHistory)
                const Center(child: CircularProgressIndicator())
              else if (_history.isEmpty)
                const Card(child: Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Aucune donnée signalée pour le moment', style: TextStyle(color: Colors.grey)))))
              else
                ..._history.map((h) => Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal.shade50,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(Icons.medical_information, color: Colors.teal.shade700, size: 20),
                              if (int.parse(h['case_count'].toString()) > 1)
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                    constraints: BoxConstraints(minWidth: 14, minHeight: 14),
                                    child: Text(
                                      '${h['case_count']}',
                                      style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(h['symptom_summary'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            if (int.parse(h['case_count'].toString()) > 1) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.teal.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'x${h['case_count']}',
                                  style: TextStyle(color: Colors.teal.shade700, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text('${h['region']} • ${h['age_group']} • ${DateFormat('dd/MM HH:mm').format(DateTime.parse(h['created_at']))}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Colors.teal),
                          tooltip: 'Ajouter à nouveau',
                          onPressed: () => _incrementReport(h['id']),
                        ),
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }
}


