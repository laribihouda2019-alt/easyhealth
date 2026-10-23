import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

// Payment method enum for clarity
enum _PaymentMethod { cod, chargily }

class PharmacyOrderScreen extends StatefulWidget {
  final Map<String, dynamic> pharmacy;

  const PharmacyOrderScreen({super.key, required this.pharmacy});

  @override
  State<PharmacyOrderScreen> createState() => _PharmacyOrderScreenState();
}

class _PharmacyOrderScreenState extends State<PharmacyOrderScreen> {
  final _api = ApiService();
  final _medsController = TextEditingController();
  final _addressController = TextEditingController();
  
  String? _prescriptionPath;
  List<int>? _prescriptionBytes;
  String? _prescriptionFileName;
  bool _isDelivery = true;
  _PaymentMethod _paymentMethod = _PaymentMethod.cod;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _addressController.text = AuthService().currentUser?.address ?? '';
  }

  @override
  void dispose() {
    _medsController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickPrescription() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );

    if (result != null) {
      setState(() {
        _prescriptionFileName = result.files.single.name;
        if (kIsWeb) {
          _prescriptionBytes = result.files.single.bytes;
        } else {
          _prescriptionPath = result.files.single.path;
        }
      });
    }
  }

  Future<void> _submitOrder() async {
    if (_medsController.text.isEmpty && _prescriptionPath == null && _prescriptionBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez ajouter des médicaments ou une ordonnance')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final items = [
        {'name': 'Commande groupée', 'note': _medsController.text}
      ];

      // STEP 1: Always create the order in the DB first.
      // Use 'cod' for Cash on Delivery, 'chargily' only for online payment.
      final String paymentMethodStr = _paymentMethod == _PaymentMethod.chargily ? 'chargily' : 'cod';

      final response = await _api.createMedicationOrder(
        pharmacyId: widget.pharmacy['id'],
        items: items,
        totalAmount: 1000.0, // Placeholder
        deliveryAddress: _isDelivery ? _addressController.text : null,
        prescriptionPath: _prescriptionPath,
        prescriptionBytes: _prescriptionBytes,
        prescriptionFileName: _prescriptionFileName,
        paymentMethod: paymentMethodStr,
      );

      if (!mounted) return;

      // STEP 2: Only call Chargily if the patient explicitly chose online payment.
      if (_paymentMethod == _PaymentMethod.chargily) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commande créée ! Redirection vers le paiement...'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );

        try {
          final orderId = response['data']?['id']?.toString() ?? '';
          final checkout = await _api.createChargilyV2Checkout(
            amount: 1000.0,
            metadata: {'orderId': orderId},
          );

          if (checkout['checkout_url'] != null && mounted) {
            final url = Uri.parse(checkout['checkout_url']);
            if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: SelectableText('Lien de paiement: ${checkout['checkout_url']}'),
                    backgroundColor: Colors.orange,
                    duration: const Duration(seconds: 10),
                  ),
                );
              }
            }
          }
        } catch (paymentError) {
          // Order was created successfully — only payment link failed.
          // Don't block the user; show a warning.
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Commande créée, mais erreur paiement: $paymentError\nContactez la pharmacie.'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 6),
              ),
            );
          }
        }
      } else {
        // Cash on Delivery — order created, no payment needed now.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commande passée avec succès ! Paiement à la livraison.'),
            backgroundColor: Colors.green,
          ),
        );
      }

      if (mounted) Navigator.pop(context);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la commande: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pharmacyName = widget.pharmacy['display_name'] ?? widget.pharmacy['pharmacy_name'] ?? 'Pharmacie';
    final commune = widget.pharmacy['commune']?.toString().isNotEmpty == true ? widget.pharmacy['commune'] : '';
    final wilaya = widget.pharmacy['wilaya']?.toString().isNotEmpty == true ? widget.pharmacy['wilaya'] : '';
    final location = "$commune $wilaya".trim();

    return Scaffold(
      appBar: AppBar(title: const Text('Passer une commande')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Commander chez $pharmacyName',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    location,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // — Medications field —
            const Text('Médicaments ou articles :', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: _medsController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ex: Doliprane 500mg, Pansement...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),

            // — Prescription —
            const Text('Ordonnance (Optionnel) :', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickPrescription,
              icon: const Icon(Icons.upload_file),
              label: Text(_prescriptionFileName ?? 'Télécharger une ordonnance (PDF/Image)'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),

            // — Delivery mode —
            const Text('Mode de réception :', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Livraison'),
                    selected: _isDelivery,
                    onSelected: (val) => setState(() => _isDelivery = true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Retrait'),
                    selected: !_isDelivery,
                    onSelected: (val) => setState(() => _isDelivery = false),
                  ),
                ),
              ],
            ),
            if (_isDelivery) ...[
              const SizedBox(height: 24),
              const Text('Adresse de livraison :', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                controller: _addressController,
                decoration: InputDecoration(
                  hintText: 'Votre adresse complète...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
            const SizedBox(height: 24),

            // — Payment method — NEW SECTION
            const Text('Mode de paiement :', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),

            // Option 1: Cash on Delivery
            _PaymentOptionCard(
              title: 'Paiement à la livraison',
              subtitle: 'Payez en espèces à la réception de votre commande.',
              icon: Icons.money,
              iconColor: Colors.green,
              isSelected: _paymentMethod == _PaymentMethod.cod,
              onTap: () => setState(() => _paymentMethod = _PaymentMethod.cod),
            ),
            const SizedBox(height: 12),

            // Option 2: Online payment via Chargily
            _PaymentOptionCard(
              title: 'Paiement en ligne (Chargily)',
              subtitle: 'Payez maintenant via CIB / BaridiMob.',
              icon: Icons.credit_card,
              iconColor: Colors.indigo,
              isSelected: _paymentMethod == _PaymentMethod.chargily,
              onTap: () => setState(() => _paymentMethod = _PaymentMethod.chargily),
            ),

            const SizedBox(height: 32),

            // — Submit button —
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitOrder,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: _paymentMethod == _PaymentMethod.chargily ? Colors.indigo : Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                : Text(
                    _paymentMethod == _PaymentMethod.chargily
                        ? 'Confirmer et Payer en ligne'
                        : 'Confirmer la commande (Livraison)',
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable payment option card widget
class _PaymentOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? iconColor.withOpacity(0.06) : Colors.grey.shade50,
          border: Border.all(
            color: isSelected ? iconColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? iconColor : Colors.black87)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? iconColor : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}


