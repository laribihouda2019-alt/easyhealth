enum UserRole { patient, doctor, pharmacy, lab, admin, socialSecurity, medicalController }

extension UserRoleExtension on UserRole {
  String get value {
    switch (this) {
      case UserRole.patient:
        return 'patient';
      case UserRole.doctor:
        return 'doctor';
      case UserRole.pharmacy:
        return 'pharmacy';
      case UserRole.lab:
        return 'lab';
      case UserRole.admin:
        return 'admin';
      case UserRole.socialSecurity:
        return 'social_security';
      case UserRole.medicalController:
        return 'medical_controller';
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.patient:
        return 'Patient';
      case UserRole.doctor:
        return 'Médecin';
      case UserRole.pharmacy:
        return 'Pharmacie';
      case UserRole.lab:
        return 'Laboratoire';
      case UserRole.admin:
        return 'Administrateur';
      case UserRole.socialSecurity:
        return 'Sécurité Sociale';
      case UserRole.medicalController:
        return 'Contrôleur Médical';
    }
  }

  static UserRole fromString(String value) {
    switch (value) {
      case 'doctor':
        return UserRole.doctor;
      case 'pharmacy':
        return UserRole.pharmacy;
      case 'lab':
        return UserRole.lab;
      case 'admin':
        return UserRole.admin;
      case 'social_security':
        return UserRole.socialSecurity;
      case 'medical_controller':
        return UserRole.medicalController;
      default:
        return UserRole.patient;
    }
  }
}

class UserModel {
  final String id;
  final String? fullName;
  final String email;
  final String? phone;
  final UserRole role;
  final bool isApproved;
  final String? address;
  final String? wilaya;
  final String? commune;
  final String? avatarUrl;
  final String? logoUrl;
  final String? specialty;
  final double? consultationFee;
  final String? licenseNumber;
  final String? experienceYears;
  final dynamic availableDays;
  final dynamic availableHours;
  final String? hospitalClinic;
  final String? education;
  final String? certifications;
  final String? dateOfBirth;
  final String? bloodType;
  final String? emergencyContact;
  final String? emergencyPhone;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    this.fullName,
    required this.email,
    this.phone,
    required this.role,
    this.isApproved = false,
    this.address,
    this.wilaya,
    this.commune,
    this.avatarUrl,
    this.logoUrl,
    this.specialty,
    this.consultationFee,
    this.licenseNumber,
    this.experienceYears,
    this.availableDays,
    this.availableHours,
    this.hospitalClinic,
    this.education,
    this.certifications,
    this.dateOfBirth,
    this.bloodType,
    this.emergencyContact,
    this.emergencyPhone,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      fullName: json['full_name'] ?? json['fullName'],
      email: json['email'] ?? '',
      phone: json['phone'],
      role: UserRoleExtension.fromString(json['role'] ?? 'patient'),
      isApproved: json['is_approved'] ?? false,
      address: json['address'],
      wilaya: json['wilaya'],
      commune: json['commune'],
      avatarUrl: json['avatar_url'],
      logoUrl: json['logo_url'],
      specialty: json['specialty'] ?? json['specialization'],
      consultationFee: json['consultation_fee'] != null 
          ? (json['consultation_fee'] is int ? (json['consultation_fee'] as int).toDouble() : json['consultation_fee'] is String ? double.tryParse(json['consultation_fee']) : json['consultation_fee'] as double)
          : null,
      licenseNumber: json['license_number'],
      experienceYears: json['experience_years']?.toString(),
      availableDays: json['available_days'],
      availableHours: json['available_hours'],
      hospitalClinic: json['hospital_clinic'] ?? json['hospital_name'],
      education: json['education'],
      certifications: json['certifications'],
      dateOfBirth: json['date_of_birth'] ?? json['dateOfBirth'],
      bloodType: json['blood_type'] ?? json['bloodType'],
      emergencyContact: json['emergency_contact'] ?? json['emergencyContact'],
      emergencyPhone: json['emergency_phone'] ?? json['emergencyPhone'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'role': role.value,
      'is_approved': isApproved,
      'address': address,
      'wilaya': wilaya,
      'commune': commune,
      'avatar_url': avatarUrl,
      'logo_url': logoUrl,
      'specialty': specialty,
      'consultation_fee': consultationFee,
      'license_number': licenseNumber,
      'experience_years': experienceYears,
      'available_days': availableDays,
      'available_hours': availableHours,
      'hospital_clinic': hospitalClinic,
      'education': education,
      'certifications': certifications,
      'date_of_birth': dateOfBirth,
      'blood_type': bloodType,
      'emergency_contact': emergencyContact,
      'emergency_phone': emergencyPhone,
    };
  }
}


