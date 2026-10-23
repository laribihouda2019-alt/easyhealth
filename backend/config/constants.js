const ROLES = {
  PATIENT: 'patient',
  DOCTOR: 'doctor',
  PHARMACY: 'pharmacy',
  LAB: 'lab',
  ADMIN: 'admin',
  SOCIAL_SECURITY: 'social_security',
  MEDICAL_CONTROLLER: 'medical_controller',
};

const ROLES_REQUIRING_APPROVAL = [ROLES.DOCTOR, ROLES.PHARMACY, ROLES.LAB, ROLES.MEDICAL_CONTROLLER];

const PAYMENT_STATUS = {
  PENDING: 'pending',
  PAID: 'paid',
  FAILED: 'failed',
  REFUNDED: 'refunded',
};

module.exports = {
  ROLES,
  ROLES_REQUIRING_APPROVAL,
  PAYMENT_STATUS,
};

