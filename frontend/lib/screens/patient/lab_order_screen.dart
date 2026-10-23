import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class LabOrderScreen extends StatefulWidget {
  final Map<String, dynamic> lab;

  const LabOrderScreen({super.key, required this.lab});

  @override
  State<LabOrderScreen> createState() => _LabOrderScreenState();
}

class _LabOrderScreenState extends State<LabOrderScreen> {
  final _api = ApiService();
  final _searchController = TextEditingController();
  
  List<dynamic> _availableServices = [];
  final Set<int> _selectedServiceIds = {};
  DateTime? _selectedDate;
  String? _selectedTime;
  bool _isServicesLoading = true;
  bool _isSubmitting = false;

  final List<String> _timeSlots = [
    '08:30', '09:00', '09:30', '10:00', '10:30', '11:00',
    '14:00', '14:30', '15:00', '15:30', '16:00', '16:30'
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now().add(const Duration(days: 1));
    _fetchLabServices();
  }

  Future<void> _fetchLabServices() async {
    try {
      final services = await _api.getLabServices(widget.lab['id']);
      setState(() {
        _availableServices = services;
        _isServicesLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isServicesLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors du chargement des services.')),
        );
      }
    }
  }

  List<dynamic> get _filteredTests {
    if (_searchController.text.isEmpty) return _availableServices;
    return _availableServices
        .where((s) => s['test_name'].toString().toLowerCase().contains(_searchController.text.toLowerCase()))
        .toList();
  }

  double get _totalPrice {
    double total = 0;
    for (var serviceId in _selectedServiceIds) {
      final service = _availableServices.firstWhere((s) => s['id'] == serviceId, orElse: () => null);
      if (service != null && service['price'] != null) {
        total += double.tryParse(service['price'].toString()) ?? 0.0;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final labName = widget.lab['display_name'] ?? widget.lab['lab_name'] ?? 'Laboratoire';
    final location = "${widget.lab['commune'] ?? ''} ${widget.lab['wilaya'] ?? ''}".trim();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('RDV $labName', style: const TextStyle(fontSize: 16)),
            if (location.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.location_on, size: 10, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    location,
                    style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.normal),
                  ),
                ],
              ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un examen (ex: PCR, Sang...)',
                      prefixIcon: const Icon(Icons.search, color: Colors.teal),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Date Picker
                  Text('Choisir une date', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 14,
                      itemBuilder: (context, index) {
                        final date = DateTime.now().add(Duration(days: index + 1));
                        final isSelected = _selectedDate?.day == date.day && 
                                         _selectedDate?.month == date.month;
                        
                        return GestureDetector(
                          onTap: () => setState(() => _selectedDate = date),
                          child: Container(
                            width: 65,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.teal : Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: isSelected ? Colors.teal : Colors.grey[300]!),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  DateFormat('E', 'fr_FR').format(date).toUpperCase(),
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  date.day.toString(),
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.black,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Time Slots
                  Text('Horaire', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _timeSlots.map((time) {
                      final isSelected = _selectedTime == time;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedTime = time),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.teal.withOpacity(0.1) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isSelected ? Colors.teal : Colors.grey[300]!),
                          ),
                          child: Text(
                            time,
                            style: TextStyle(
                              color: isSelected ? Colors.teal : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Tests List
                  Text('Sélectionner les examens', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (_isServicesLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_filteredTests.isEmpty)
                    _buildEmptyState()
                  else
                    ..._filteredTests.map((service) => _buildTestTile(service)),
                  
                  const SizedBox(height: 120), // Space for bottom card
                ],
              ),
            ),
          ),
          
          // Selection Summary and Action
          if (_selectedServiceIds.isNotEmpty) _buildSummaryCard(),
        ],
      ),
    );
  }

  Widget _buildTestTile(dynamic service) {
    final serviceId = service['id'] as int;
    final isSelected = _selectedServiceIds.contains(serviceId);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? Colors.teal : Colors.transparent),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2)),
        ],
      ),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (bool? value) {
          setState(() {
            if (value == true) {
              _selectedServiceIds.add(serviceId);
            } else {
              _selectedServiceIds.remove(serviceId);
            }
          });
        },
        activeColor: Colors.teal,
        title: Text(service['test_name'], style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text('Prix: ${service['price']} DZD', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        secondary: Icon(Icons.science_outlined, color: isSelected ? Colors.teal : Colors.grey),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.search_off_outlined, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('Aucun examen disponible', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${_selectedServiceIds.length} examens sélectionnés', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Total à régler', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                ),
                Text('${_totalPrice.toStringAsFixed(0)} DZD', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: (_isSubmitting || _selectedTime == null) ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  elevation: 5,
                  shadowColor: Colors.teal.withOpacity(0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: _isSubmitting 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Confirmer le rendez-vous', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitRequest() async {
    setState(() => _isSubmitting = true);

    try {
      final timeParts = _selectedTime!.split(':');
      final scheduledAt = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );

      final response = await _api.createLabRequest(
        labId: widget.lab['id'],
        serviceIds: _selectedServiceIds.toList(),
        scheduledAt: scheduledAt,
        paymentMethod: 'chargily',
      );

      final totalFromBackend = double.tryParse(response['data']['amount'].toString()) ?? _totalPrice;

      if (mounted) {
        await _api.createChargilyV2Checkout(
          amount: totalFromBackend,
          metadata: {'requestId': response['data']['id']},
        );
        
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demande de rendez-vous envoyée avec succès !'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString();
        if (e is DioException && e.response != null && e.response!.data != null) {
          final data = e.response!.data;
          errorMsg = data['error'] ?? data['message'] ?? e.toString();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $errorMsg'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}


