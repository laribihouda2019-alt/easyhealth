import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../models/prescription_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/prescription_pdf_service.dart';

class PrescriptionViewScreen extends StatelessWidget {
  final PrescriptionModel prescription;
  final UserModel? doctor; // Pass if available, else fetch/use currentUser if applicable

  const PrescriptionViewScreen({
    super.key,
    required this.prescription,
    this.doctor,
  });

  @override
  Widget build(BuildContext context) {
    // If doctor not passed, and we are doctor, use currentUser.
    // If we are patient, we should have the doctor info in the JOIN result in prescription model.
    final currentUser = AuthService().currentUser;
    final displayDoctor = doctor ?? (prescription.doctorId == currentUser?.id ? currentUser : null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aperçu de l\'ordonnance'),
      ),
      body: PdfPreview(
        build: (format) => PrescriptionPdfService.generatePrescriptionPdf(
          prescription: prescription,
          doctor: displayDoctor ?? UserModel(
            id: prescription.doctorId,
            fullName: prescription.doctorName ?? 'Médecin',
            email: '',
            role: UserRole.doctor,
            specialty: prescription.doctorSpecialty,
            logoUrl: prescription.doctorLogo,
          ),
        ),
        canDebug: false,
        actions: [
          PdfPreviewAction(
            icon: const Icon(Icons.share),
            onPressed: (context, build, format) async {
              final bytes = await build(format);
              await Printing.sharePdf(bytes: bytes, filename: 'ordonnance_${prescription.verificationCode}.pdf');
            },
          ),
        ],
      ),
    );
  }
}


