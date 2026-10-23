class MedicationItem {
  final String name;
  final String dosage;
  final String duration;
  final String instructions;

  MedicationItem({
    required this.name,
    required this.dosage,
    required this.duration,
    required this.instructions,
  });

  factory MedicationItem.fromJson(Map<String, dynamic> json) {
    return MedicationItem(
      name: json['name'] ?? '',
      dosage: json['dosage'] ?? '',
      duration: json['duration'] ?? '',
      instructions: json['instructions'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dosage': dosage,
      'duration': duration,
      'instructions': instructions,
    };
  }
}

class PrescriptionModel {
  final int id;
  final String doctorId;
  final String patientId;
  final int? appointmentId;
  final List<MedicationItem> medications;
  final DateTime prescriptionDate;
  final String verificationCode;
  final String? notes;
  
  // Dynamic fields from JOIN
  final String? doctorName;
  final String? doctorSpecialty;
  final String? doctorLogo;
  final String? patientName;

  PrescriptionModel({
    required this.id,
    required this.doctorId,
    required this.patientId,
    this.appointmentId,
    required this.medications,
    required this.prescriptionDate,
    required this.verificationCode,
    this.notes,
    this.doctorName,
    this.doctorSpecialty,
    this.doctorLogo,
    this.patientName,
  });

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    var medsList = json['medications'];
    List<MedicationItem> meds = [];
    if (medsList != null) {
      if (medsList is String) {
        // Handle cases where backend might return it as a JSON string
        // but typically pg JSONB is parsed by the driver
      } else if (medsList is List) {
        meds = medsList.map((m) => MedicationItem.fromJson(m)).toList();
      }
    }

    return PrescriptionModel(
      id: json['id'],
      doctorId: json['doctor_id'],
      patientId: json['patient_id'],
      appointmentId: json['appointment_id'],
      medications: meds,
      prescriptionDate: DateTime.parse(json['prescription_date']),
      verificationCode: json['verification_code'],
      notes: json['notes'],
      doctorName: json['doctor_name'],
      doctorSpecialty: json['doctor_specialty'] ?? json['specialty'],
      doctorLogo: json['doctor_logo'] ?? json['logo_url'],
      patientName: json['patient_name'],
    );
  }
}


