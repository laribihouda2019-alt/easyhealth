import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/api_service.dart';

class CcpPaymentScreen extends StatefulWidget {
  final int appointmentId;
  final double amount;

  const CcpPaymentScreen({
    super.key,
    required this.appointmentId,
    required this.amount,
  });

  @override
  State<CcpPaymentScreen> createState() => _CcpPaymentScreenState();
}

class _CcpPaymentScreenState extends State<CcpPaymentScreen> {
  final _api = ApiService();
  final _accountNameController = TextEditingController();
  final _ccpNumberController = TextEditingController();
  File? _proofFile;
  bool _isSubmitting = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'pdf', 'png'],
    );

    if (result != null) {
      setState(() {
        _proofFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _submitPayment() async {
    if (_accountNameController.text.isEmpty ||
        _ccpNumberController.text.isEmpty ||
        _proofFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs et ajouter une preuve')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _api.uploadCcpProof(
        appointmentId: widget.appointmentId,
        accountName: _accountNameController.text,
        ccpNumber: _ccpNumberController.text,
        proofFile: _proofFile!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preuve envoyée avec succès. En attente de vérification.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paiement par CCP')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Text(
                    'Informations de virement CCP',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text('Numéro CCP: 0023456789 12'),
                  const Text('Nom: EasyHealth SARL'),
                  const SizedBox(height: 8),
                  const Text(
                    'Veuillez effectuer le virement et télécharger le reçu ci-dessous.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Montant à payer: ${widget.amount} DZD',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _accountNameController,
              decoration: const InputDecoration(
                labelText: 'Nom du titulaire du compte',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ccpNumberController,
              decoration: const InputDecoration(
                labelText: 'Numéro de votre CCP',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Preuve de paiement (Photo ou PDF)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickFile,
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade50,
                ),
                child: _proofFile == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_upload, size: 40, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Cliquez pour choisir un fichier'),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.file_present, size: 40, color: Colors.blue),
                          const SizedBox(height: 8),
                          Text(_proofFile!.path.split('/').last),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitPayment,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Confirmer le paiement'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


