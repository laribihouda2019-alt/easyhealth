import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../models/appointment_model.dart';

class PaymentScreen extends StatefulWidget {
  final AppointmentModel? appointment;
  final double? amount;
  final String? doctorName;

  const PaymentScreen({
    super.key,
    this.appointment,
    this.amount,
    this.doctorName,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isProcessing = false;
  String _paymentMethod = 'card';

  Future<void> _processPayment() async {
    if (widget.amount == null && widget.appointment == null) return;
    
    setState(() => _isProcessing = true);
    final amountToPay = widget.amount ?? 2500.0;

    try {
      if (_paymentMethod == 'card') {
        
        // 1. Fetch real checkout URL from backend
        final checkoutData = await ApiService().createChargilyV2Checkout(
          amount: amountToPay,
          appointmentId: widget.appointment != null ? int.tryParse(widget.appointment!.id) : null,
        );
        
        final checkoutUrl = checkoutData['checkout_url'];
        if (checkoutUrl == null) throw Exception('Impossible de générer le lien de paiement.');

        final uri = Uri.parse(checkoutUrl);
        
        // 2. Launch using LaunchMode.externalApplication for best compatibility
        final success = await launchUrl(
          uri, 
          mode: LaunchMode.externalApplication,
        );

        if (!success) {
          throw Exception('Impossible d\'ouvrir le navigateur pour le paiement.');
        }
        
      } else {
        // CCP process
        await Future.delayed(const Duration(seconds: 2));
        if (widget.appointment != null) {
          await ApiService().updateAppointmentStatus(
            widget.appointment!.id, 
            AppointmentStatus.confirmed
          );
        }
        if (mounted) _showSuccessAndReturn();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSuccessAndReturn() {
    Navigator.of(context).pushReplacementNamed('/payment-success');
  }

  @override
  Widget build(BuildContext context) {
    final amountToPay = widget.amount ?? 2500.0;
    final doctorName = widget.doctorName ?? widget.appointment?.doctorName ?? "Médecin";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Validation du Paiement'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Résumé de la consultation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Professional Summary Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.medical_services_outlined, color: Colors.blue.shade700),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Professionnel',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            Text(
                              'Dr. $doctorName',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  _buildSummaryRow('Service', 'Consultation Vidéo'),
                  const SizedBox(height: 12),
                  _buildSummaryRow('Date', 'Aujourd\'hui'),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total à payer',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      Text(
                        '${amountToPay.toStringAsFixed(0)} DZD',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            const Text(
              'Méthode de paiement',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _PaymentMethodTile(
                  icon: Icons.credit_card,
                  label: 'Carte CIB',
                  isSelected: _paymentMethod == 'card',
                  onTap: () => setState(() => _paymentMethod = 'card'),
                ),
                const SizedBox(width: 12),
                _PaymentMethodTile(
                  icon: Icons.account_balance_wallet,
                  label: 'CCP',
                  isSelected: _paymentMethod == 'ccp',
                  onTap: () => setState(() => _paymentMethod = 'ccp'),
                ),
              ],
            ),
            const SizedBox(height: 48),
            
            SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Confirmer et Payer',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 8),
                Text(
                  'Paiement 100% sécurisé via Chargily',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
      ],
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodTile({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade50 : Colors.white,
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey.shade300,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.blue.shade700 : Colors.grey),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.blue.shade700 : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



