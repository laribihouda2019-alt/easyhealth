import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../services/api_service.dart';
import '../../models/prescription_model.dart';
import 'package:intl/intl.dart';

class PrescriptionVerificationScreen extends StatefulWidget {
  const PrescriptionVerificationScreen({super.key});

  @override
  State<PrescriptionVerificationScreen> createState() => _PrescriptionVerificationScreenState();
}

class _PrescriptionVerificationScreenState extends State<PrescriptionVerificationScreen> {
  final ApiService _api = ApiService();
  final MobileScannerController _controller = MobileScannerController();
  bool _isScanned = false;
  bool _isLoading = false;
  PrescriptionModel? _verifiedPrescription;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _verifyCode(String code) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _api.verifyPrescription(code);
      if (mounted) {
        setState(() {
          _verifiedPrescription = PrescriptionModel.fromJson(response['data']);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Code invalide ou ordonnance introuvable.";
          _isLoading = false;
          _isScanned = false; // Allow re-scanning on error
        });
      }
    }
  }

  Future<void> _pickAndVerifyFile({bool isPdf = false}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: isPdf ? FileType.custom : FileType.image,
        allowedExtensions: isPdf ? ['pdf'] : null,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      if (mounted) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      final file = result.files.first;

      if (isPdf) {
        // For PDF, we'll try to extract the code or ask for manual entry
        // Since pure dart PDF QR extraction is complex, we'll prompt for the code
        // and use the PDF as a visual validation if needed.
        _showManualCodeEntry(
          title: "Vérification PDF",
          message: "Veuillez saisir le code de vérification figurant sur le PDF."
        );
      } else {
        // For Images on Web, MobileScanner analyzeImage doesn't work.
        // If we're on web, we'll prompt for manual entry or use a decoder.
        if (kIsWeb) {
           _showManualCodeEntry(
             title: "Analyse d'image (Web)",
             message: "Détection automatique limitée sur le Web. Veuillez saisir le code manuellement."
           );
        } else {
          // Mobile native support
          final capture = await _controller.analyzeImage(file.path!);
          if (capture == null || capture.barcodes.isEmpty) {
            _showManualCodeEntry(
              title: "QR non détecté",
              message: "Aucun QR code n'a été trouvé. Veuillez saisir le code manuellement."
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Erreur lors de la sélection du fichier: $e";
          _isLoading = false;
        });
      }
    }
  }

  void _showManualCodeEntry({String title = "Entrée manuelle", String message = ""}) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.isNotEmpty) ...[
              Text(message, style: const TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: "Code de vérification",
                hintText: "ex: ORD-123456789-123",
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () {
              final code = controller.text.trim();
              Navigator.pop(context);
              if (code.isNotEmpty) {
                _verifyCode(code);
              }
            },
            child: const Text("Vérifier"),
          ),
        ],
      ),
    ).then((_) {
      if (mounted && _isLoading && _verifiedPrescription == null) {
        setState(() => _isLoading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vérification d\'Ordonnance'),
        backgroundColor: Colors.orange[800],
        foregroundColor: Colors.white,
      ),
      body: _verifiedPrescription != null 
          ? _buildResultView() 
          : _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _buildScannerView(),
    );
  }

  Widget _buildScannerView() {
    return Stack(
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: (capture) {
            if (_isScanned) return;
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              final String? code = barcode.rawValue;
              if (code != null) {
                setState(() => _isScanned = true);
                _verifyCode(code);
                break;
              }
            }
          },
        ),
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.orange, width: 4),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        if (_error != null)
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
              child: Text(_error!, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
            ),
          ),
        const Positioned(
          bottom: 150,
          left: 0,
          right: 0,
          child: Text(
            'Scannez le QR code de l\'ordonnance patient',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Positioned(
          bottom: 40,
          left: 20,
          right: 20,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildActionBtn(
                      icon: Icons.image,
                      label: 'Image / Galerie',
                      onTap: () => _pickAndVerifyFile(isPdf: false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionBtn(
                      icon: Icons.picture_as_pdf,
                      label: 'Fichier PDF',
                      onTap: () => _pickAndVerifyFile(isPdf: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => _showManualCodeEntry(),
                icon: const Icon(Icons.keyboard, color: Colors.white70),
                label: const Text('Saisie manuelle du code', style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionBtn({required IconData icon, required String label, required VoidCallback onTap}) {
    return FilledButton.icon(
      onPressed: _isLoading ? null : onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.2),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: const BorderSide(color: Colors.white30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildResultView() {
    final p = _verifiedPrescription!;
    final dateStr = DateFormat('dd MMMM yyyy', 'fr_FR').format(p.prescriptionDate);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              border: Border.all(color: Colors.green),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified, color: Colors.green, size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('AUTHENTICITÉ GARANTIE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      Text('Code: ${p.verificationCode}', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   _buildInfoRow('Médecin:', 'Dr. ${p.doctorName}', Icons.person),
                   _buildInfoRow('Spécialité:', p.doctorSpecialty ?? 'Urologue', Icons.badge),
                   const Divider(),
                   _buildInfoRow('Patient:', p.patientName ?? 'Inconnu', Icons.person_outline),
                   _buildInfoRow('Date:', dateStr, Icons.calendar_today),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Médicaments prescrits:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: p.medications.length,
            itemBuilder: (context, index) {
              final med = p.medications[index];
              return Card(
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: Colors.orange[100], child: Text('${index + 1}')),
                  title: Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${med.dosage} - ${med.duration}\n${med.instructions}'),
                ),
              );
            },
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                setState(() {
                  _verifiedPrescription = null;
                  _isScanned = false;
                });
              },
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scanner une autre ordonnance'),
              style: FilledButton.styleFrom(backgroundColor: Colors.orange[800]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
        ],
      ),
    );
  }
}


