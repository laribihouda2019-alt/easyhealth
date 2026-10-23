import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class SlotBookingSheet extends StatefulWidget {
  final String doctorId;
  final String doctorName;

  const SlotBookingSheet({super.key, required this.doctorId, required this.doctorName});

  @override
  State<SlotBookingSheet> createState() => _SlotBookingSheetState();
}

class _SlotBookingSheetState extends State<SlotBookingSheet> {
  final _api = ApiService();
  DateTime _selectedDate = DateTime.now();
  List<dynamic> _availableSlots = [];
  bool _isLoadingSlots = true;
  int? _selectedSlotId;
  bool _isBooking = false;

  @override
  void initState() {
    super.initState();
    _fetchSlots();
  }

  Future<void> _fetchSlots() async {
    setState(() => _isLoadingSlots = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final response = await _api.getAvailableSlots(widget.doctorId, date: dateStr);
      setState(() {
        _availableSlots = response['availableSlots'] ?? [];
        _isLoadingSlots = false;
        _selectedSlotId = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSlots = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Réserver avec Dr. ${widget.doctorName.replaceFirst('Dr. ', '')}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Date selection
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 30)),
              );
              if (date != null) {
                setState(() => _selectedDate = date);
                _fetchSlots();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 20, color: Colors.blue),
                  const SizedBox(width: 12),
                  Text(
                    DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_selectedDate),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Choisissez un créneau horaire :',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoadingSlots
                ? const Center(child: CircularProgressIndicator())
                : _availableSlots.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy, size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 8),
                            const Text('Aucun créneau disponible pour cette date.'),
                          ],
                        ),
                      )
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 2.2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _availableSlots.length,
                        itemBuilder: (context, index) {
                          final slot = _availableSlots[index];
                          final slotId = slot['id'];
                          final start = DateTime.parse(slot['start_time']).toLocal();
                          final timeStr = DateFormat('HH:mm').format(start);
                          final isSelected = _selectedSlotId == slotId;

                          return InkWell(
                            onTap: () => setState(() => _selectedSlotId = slotId),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.blue : Colors.white,
                                border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                timeStr,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black87,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: (_selectedSlotId == null || _isBooking) ? null : _handleBooking,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isBooking
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Confirmer la réservation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _handleBooking() async {
    setState(() => _isBooking = true);
    try {
      await _api.createRealAppointment({
        'doctorId': widget.doctorId,
        'slotId': _selectedSlotId,
        'appointmentType': 'consultation',
        'notes': 'Réservation via créneau horaire spécifique',
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rendez-vous réservé avec succès !'),
            backgroundColor: Colors.green,
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
      if (mounted) setState(() => _isBooking = false);
    }
  }
}


