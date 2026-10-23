import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/prescription_model.dart';
import '../models/user_model.dart';

class PrescriptionPdfService {
  static Future<Uint8List> generatePrescriptionPdf({
    required PrescriptionModel prescription,
    required UserModel doctor,
  }) async {
    final pdf = pw.Document();

    // Load logo or use default
    pw.ImageProvider? logoImage;
    if (doctor.logoUrl != null && doctor.logoUrl!.isNotEmpty) {
      try {
        logoImage = await networkImage(doctor.logoUrl!);
      } catch (e) {
        // Fallback to default
      }
    }

    // Default professional icon fallback (can use a bundled asset or a material icon font glyph if needed)
    // For simplicity, we'll try to draw a medical cross if logo is missing
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Dr. ${prescription.doctorName ?? doctor.fullName ?? "Médecin"}',
                        style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                      ),
                      pw.Text(
                        prescription.doctorSpecialty ?? doctor.specialty ?? 'Urologue',
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700),
                      ),
                      if (doctor.address != null) pw.Text(doctor.address!, style: pw.TextStyle(fontSize: 11, font: pw.Font.times())),
                      if (doctor.phone != null) pw.Text('Tel: ${doctor.phone!}', style: pw.TextStyle(fontSize: 11, font: pw.Font.times())),
                    ],
                  ),
                  if (logoImage != null)
                    pw.Container(
                      width: 70,
                      height: 70,
                      child: pw.Image(logoImage),
                    )
                  else
                    // Default professional Urologist/Medical icon
                    pw.Container(
                      width: 70,
                      height: 70,
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.blue800,
                        shape: pw.BoxShape.circle,
                      ),
                      child: pw.Center(
                        child: pw.Text('U', style: pw.TextStyle(fontSize: 35, color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
                      ),
                    ),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Divider(thickness: 3, color: PdfColors.blue900),
              pw.SizedBox(height: 20),

              // Patient Info with professional framing
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('ORDONNANCE MÉDICALE', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                        pw.SizedBox(height: 8),
                        pw.Row(
                          children: [
                            pw.Text('Patient: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 15)),
                            pw.Text(prescription.patientName ?? "Patient", style: const pw.TextStyle(fontSize: 15)),
                          ],
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Date: ${prescription.prescriptionDate.day}/${prescription.prescriptionDate.month}/${prescription.prescriptionDate.year}',
                          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text('Réf: ${prescription.verificationCode.split("-").last}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),

              // Medications Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(4),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.teal50),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Médicament', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Dosage', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Durée', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Instructions', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    ],
                  ),
                  ...prescription.medications.map((med) => pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(med.name)),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(med.dosage)),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(med.duration)),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(med.instructions)),
                    ],
                  )).toList(),
                ],
              ),

              if (prescription.notes != null && prescription.notes!.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                pw.Text('Notes / Conseils:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(prescription.notes!),
              ],

              pw.Spacer(),

              // Footer with QR Code
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Cette ordonnance est valide numériquement.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      pw.Text('Code de vérification: ${prescription.verificationCode}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      pw.SizedBox(height: 5),
                      pw.Text('EasyHealth Digital Prescription Service', style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(),
                        data: prescription.verificationCode,
                        width: 60,
                        height: 60,
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text('Vérifier', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}


