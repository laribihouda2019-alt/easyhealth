class UserProfile {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String role;
  final bool isApproved;
  final bool needsVerification;
  final String? verificationStatus;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    required this.role,
    required this.isApproved,
    this.needsVerification = false,
    this.verificationStatus,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? 'patient',
      isApproved: json['is_approved'] ?? false,
      needsVerification: json['needsVerification'] ?? false,
      verificationStatus: json['verificationStatus'],
      avatarUrl: json['avatar_url'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'role': role,
      'is_approved': isApproved,
      'needsVerification': needsVerification,
      'verificationStatus': verificationStatus,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? role,
    bool? isApproved,
    bool? needsVerification,
    String? verificationStatus,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isApproved: isApproved ?? this.isApproved,
      needsVerification: needsVerification ?? this.needsVerification,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Getters pour faciliter l'utilisation
  bool get isPatient => role == 'patient';
  bool get isDoctor => role == 'doctor';
  bool get isPharmacy => role == 'pharmacy';
  bool get isLab => role == 'lab';
  bool get isProfessional => !isPatient;

  String get roleDisplayName {
    switch (role) {
      case 'patient':
        return 'Patient';
      case 'doctor':
        return 'Médecin';
      case 'pharmacy':
        return 'Pharmacie';
      case 'lab':
        return 'Laboratoire';
      case 'admin':
        return 'Administrateur';
      default:
        return role;
    }
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, fullName: $fullName, email: $email, role: $role, isApproved: $isApproved)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
