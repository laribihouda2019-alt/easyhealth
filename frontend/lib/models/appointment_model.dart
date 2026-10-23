enum AppointmentStatus { pending, confirmed, completed, cancelled, noShow, accepted, rejected }

extension AppointmentStatusExtension on AppointmentStatus {
  String get value {
    switch (this) {
      case AppointmentStatus.pending:
        return 'pending';
      case AppointmentStatus.confirmed:
        return 'confirmed';
      case AppointmentStatus.completed:
        return 'completed';
      case AppointmentStatus.cancelled:
        return 'cancelled';
      case AppointmentStatus.noShow:
        return 'no_show';
      case AppointmentStatus.accepted:
        return 'accepted';
      case AppointmentStatus.rejected:
        return 'rejected';
    }
  }

  String get displayName {
    switch (this) {
      case AppointmentStatus.pending:
        return 'En attente';
      case AppointmentStatus.confirmed:
        return 'Confirmé';
      case AppointmentStatus.completed:
        return 'Terminé';
      case AppointmentStatus.cancelled:
        return 'Annulé';
      case AppointmentStatus.noShow:
        return 'Absent';
      case AppointmentStatus.accepted:
        return 'Accepté';
      case AppointmentStatus.rejected:
        return 'Refusé';
    }
  }

  static AppointmentStatus fromString(String value) {
    switch (value) {
      case 'confirmed':
        return AppointmentStatus.confirmed;
      case 'completed':
        return AppointmentStatus.completed;
      case 'cancelled':
        return AppointmentStatus.cancelled;
      case 'no_show':
        return AppointmentStatus.noShow;
      case 'accepted':
        return AppointmentStatus.accepted;
      case 'rejected':
        return AppointmentStatus.rejected;
      default:
        return AppointmentStatus.pending;
    }
  }
}

class AppointmentModel {
  final String id;
  final String patientId;
  final String doctorId;
  final String appointmentType;
  final DateTime scheduledAt;
  final int? durationMinutes;
  final AppointmentStatus status;
  final String? location;
  final String? meetingUrl;
  final String? notes;
  final String? patientName;
  final String? doctorName;
  final DateTime createdAt;

  AppointmentModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    this.appointmentType = 'consultation',
    required this.scheduledAt,
    this.durationMinutes,
    this.status = AppointmentStatus.pending,
    this.location,
    this.meetingUrl,
    this.notes,
    this.patientName,
    this.doctorName,
    required this.createdAt,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id']?.toString() ?? '',
      patientId: json['patient_id']?.toString() ?? '',
      doctorId: json['doctor_id']?.toString() ?? '',
      appointmentType: json['appointment_type']?.toString() ?? 'consultation',
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.parse(json['scheduled_at'].toString())
          : DateTime.now(),
      durationMinutes: json['duration_minutes'] is int 
          ? json['duration_minutes'] 
          : int.tryParse(json['duration_minutes']?.toString() ?? ''),
      status: AppointmentStatusExtension.fromString(
        json['status'] ?? 'pending',
      ),
      location: json['location'],
      meetingUrl: json['meeting_url'],
      notes: json['notes'],
      patientName: json['patient_name']?.toString() ?? json['patientName']?.toString(),
      doctorName: json['doctor_name']?.toString() ?? json['doctorName']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patient_id': patientId,
      'doctor_id': doctorId,
      'appointment_type': appointmentType,
      'scheduled_at': scheduledAt.toIso8601String(),
      'duration_minutes': durationMinutes,
      'location': location,
      'meeting_url': meetingUrl,
      'notes': notes,
    };
  }
}


