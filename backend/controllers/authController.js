const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const db = require('../config/db');
const { ROLES } = require('../config/constants');
const emailService = require('../services/emailService');

function isValidRole(role) {
  return Object.values(ROLES).includes(role);
}

function generateUUID() {
  return crypto.randomUUID();
}

//registration using existing profiles table with role-specific columns
 //uses id (UUID) as primary key, not user_id
async function registerUser(req, res, next) {
  try {
    const { userId, fullName, email, password, phone, role = ROLES.PATIENT, wilaya, commune } = req.body || {};

    if (!email) {
      return res.status(400).json({ error: 'email is required' });
    }

    if (!fullName) {
      return res.status(400).json({ error: 'fullName is required' });
    }

    if (!password) {
      return res.status(400).json({ error: 'password is required' });
    }

    if (!isValidRole(role)) {
      return res.status(400).json({
        error: 'Invalid role. Must be one of: patient, doctor, pharmacy, lab'
      });
    }

    //check if user already exists by email
    const existingResult = await db.query(
      'SELECT * FROM public.profiles WHERE email = $1 LIMIT 1',
      [email]
    );

    if (existingResult.rows.length > 0) {
      return res.status(400).json({
        success: false,
        alreadyExists: true,
        message: 'Cet email est déjà utilisé. Veuillez vous connecter ou utiliser un autre email.',
        profile: existingResult.rows[0],
      });
    }

    //generate a proper UUID for the profile
    const profileId = generateUUID();

    //set approval status based on role
    //patient are auto-approved,professionals need verification
    const isApproved = role === ROLES.PATIENT;

    const hashedPassword = await bcrypt.hash(password, 10);

    //prepare role-specific columns
    let roleSpecificColumns = ', wilaya, commune, password';
    let roleSpecificValues = `, $7, $8, $9`;
    let values = [profileId, fullName, email, phone, role, isApproved, wilaya, commune, hashedPassword];
    let paramIndex = 10; //starting from $10

    switch (role) {
      case ROLES.PATIENT:
        //add patient-specific columns if provided
        if (req.body.dateOfBirth) {
          roleSpecificColumns += ', date_of_birth';
          roleSpecificValues += `, $${paramIndex++}`;
          values.push(req.body.dateOfBirth);
        }
        if (req.body.bloodType) {
          roleSpecificColumns += ', blood_type';
          roleSpecificValues += `, $${paramIndex++}`;
          values.push(req.body.bloodType);
        }
        if (req.body.allergies) {
          roleSpecificColumns += ', allergies';
          roleSpecificValues += `, $${paramIndex++}`;
          values.push(req.body.allergies);
        }
        if (req.body.emergencyContact) {
          roleSpecificColumns += ', emergency_contact';
          roleSpecificValues += `, $${paramIndex++}`;
          values.push(req.body.emergencyContact);
        }
        if (req.body.emergencyPhone) {
          roleSpecificColumns += ', emergency_phone';
          roleSpecificValues += `, $${paramIndex++}`;
          values.push(req.body.emergencyPhone);
        }
        break;

      case ROLES.DOCTOR:
        //add doctor-specific columns
        if (req.body.specialization) {
          roleSpecificColumns += ', specialization';
          roleSpecificValues += `, $${paramIndex++}`;
          values.push(req.body.specialization);
        }
        if (req.body.licenseNumber) {
          roleSpecificColumns += ', license_number';
          roleSpecificValues += `, $${paramIndex++}`;
          values.push(req.body.licenseNumber);
        }
        if (req.body.experienceYears) {
          roleSpecificColumns += ', experience_years';
          roleSpecificValues += `, $${paramIndex++}`;
          values.push(req.body.experienceYears);
        }
        if (req.body.consultationFee) {
          roleSpecificColumns += ', consultation_fee';
          roleSpecificValues += `, $${paramIndex++}`;
          values.push(req.body.consultationFee);
        }
        if (req.body.availableDays) {
          roleSpecificColumns += ', available_days';
          roleSpecificValues += `, $${paramIndex++}`;
          values.push(JSON.stringify(req.body.availableDays));
        }
        if (req.body.availableHours) {
          roleSpecificColumns += ', available_hours';
          roleSpecificValues += `, $${paramIndex++}`;
          values.push(JSON.stringify(req.body.availableHours));
        }
        if (req.body.hospitalClinic) {
          roleSpecificColumns += ', hospital_clinic';
          roleSpecificValues += `, $${paramIndex++}`;
          values.push(req.body.hospitalClinic);
        }
        if (req.body.education) {
          roleSpecificColumns += ', education';
          roleSpecificValues += `, $${paramIndex++}`;
          values.push(req.body.education);
        }
        if (req.body.certifications) {
          roleSpecificColumns += ', certifications';
          roleSpecificValues += `, $${paramIndex++}`;
          values.push(req.body.certifications);
        }
        break;

      case ROLES.PHARMACY:
        //add pharmacy-specific columns
        if (req.body.pharmacyName) {
          roleSpecificColumns += ', pharmacy_name';
          roleSpecificValues += `, $${paramIndex++}`;
          values.push(req.body.pharmacyName);
        }
        if (req.body.address) {
          roleSpecificColumns += ', address';
          roleSpecificValues += `, $${paramIndex++}`;
          values.push(req.body.address);
        }
        if (req.body.openingHours) {
          roleSpecificColumns += ', opening_hours';
          roleSpecificValues += `, $${paramIndex++}`;
          values.push(req.body.openingHours);
        }
        if (req.body.servicesOffered) {
          roleSpecificColumns += ', services_offered';
          roleSpecificValues += `, $${paramIndex++}`;
          values.push(JSON.stringify(req.body.servicesOffered));
        }
        if (req.body.deliveryAvailable !== undefined) {
          roleSpecificColumns += ', delivery_available';
          roleSpecificValues += `, $${paramIndex++}`;
          values.push(req.body.deliveryAvailable);
        }
        if (req.body.emergencyServices !== undefined) {
          roleSpecificColumns += ', emergency_services';
          roleSpecificValues += `, $${paramIndex++}`;
          values.push(req.body.emergencyServices);
        }
        break;

      case ROLES.LAB:
        //add laboratory-specific columns
        if (req.body.labName) {
          roleSpecificColumns += ', lab_name';
          roleSpecificValues += `, $${paramIndex++}`;
          values.push(req.body.labName);
        }
        if (req.body.address) {
          roleSpecificColumns += ', address';
          roleSpecificValues += `, $${paramIndex++}`;
          values.push(req.body.address);
        }
        if (req.body.licenseNumber) {
          roleSpecificColumns += ', license_number';
          roleSpecificValues += `, $${paramIndex++}`;
          values.push(req.body.licenseNumber);
        }
        if (req.body.accreditation) {
          roleSpecificColumns += ', accreditation';
          roleSpecificValues += `, $${paramIndex++}`;
          values.push(req.body.accreditation);
        }
        if (req.body.testsAvailable) {
          roleSpecificColumns += ', tests_available';
          roleSpecificValues += `, $${paramIndex++}`;
          values.push(JSON.stringify(req.body.testsAvailable));
        }
        if (req.body.equipment) {
          roleSpecificColumns += ', equipment';
          roleSpecificValues += `, $${paramIndex++}`;
          values.push(req.body.equipment);
        }
        if (req.body.sampleCollection !== undefined) {
          roleSpecificColumns += ', sample_collection';
          roleSpecificValues += `, $${paramIndex++}`;
          values.push(req.body.sampleCollection);
        }
        if (req.body.homeService !== undefined) {
          roleSpecificColumns += ', home_service';
          roleSpecificValues += `, $${paramIndex++}`;
          values.push(req.body.homeService);
        }
        if (req.body.emergencyServices !== undefined) {
          roleSpecificColumns += ', emergency_services';
          roleSpecificValues += `, $${paramIndex++}`;
          values.push(req.body.emergencyServices);
        }
        break;
    }

    //create user in profiles table with role-specific columns
    const insertQuery = `
      INSERT INTO public.profiles (id, full_name, email, phone, role, is_approved${roleSpecificColumns})
      VALUES ($1, $2, $3, $4, $5, $6${roleSpecificValues})
      RETURNING *
    `;

    const insertResult = await db.query(insertQuery, values);
    const newUser = insertResult.rows[0];

    //return consistent response format
    const responseProfile = {
      id: newUser.id,
      userId: newUser.id, //use id as userId for frontend compatibility
      fullName: newUser.full_name,
      full_name: newUser.full_name, //added for snake_case compatibility
      email: newUser.email,
      phone: newUser.phone,
      role: newUser.role,
      is_approved: newUser.is_approved,
      wilaya: newUser.wilaya,
      commune: newUser.commune,
      createdAt: newUser.created_at
    };

    //add role-specific information to response
    switch (role) {
      case ROLES.PATIENT:
        responseProfile.dateOfBirth = newUser.date_of_birth;
        responseProfile.bloodType = newUser.blood_type;
        responseProfile.allergies = newUser.allergies;
        responseProfile.emergencyContact = newUser.emergency_contact;
        responseProfile.emergencyPhone = newUser.emergency_phone;
        break;
      case ROLES.DOCTOR:
        responseProfile.specialization = newUser.specialization;
        responseProfile.licenseNumber = newUser.license_number;
        responseProfile.experienceYears = newUser.experience_years;
        responseProfile.consultationFee = newUser.consultation_fee;
        responseProfile.availableDays = newUser.available_days;
        responseProfile.availableHours = newUser.available_hours;
        responseProfile.hospitalClinic = newUser.hospital_clinic;
        responseProfile.education = newUser.education;
        responseProfile.certifications = newUser.certifications;
        break;
      case ROLES.PHARMACY:
        responseProfile.pharmacyName = newUser.pharmacy_name;
        responseProfile.address = newUser.address;
        responseProfile.openingHours = newUser.opening_hours;
        responseProfile.servicesOffered = newUser.services_offered;
        responseProfile.deliveryAvailable = newUser.delivery_available;
        responseProfile.emergencyServices = newUser.emergency_services;
        break;
      case ROLES.LAB:
        responseProfile.labName = newUser.lab_name;
        responseProfile.address = newUser.address;
        responseProfile.licenseNumber = newUser.license_number;
        responseProfile.accreditation = newUser.accreditation;
        responseProfile.testsAvailable = newUser.tests_available;
        responseProfile.equipment = newUser.equipment;
        responseProfile.sampleCollection = newUser.sample_collection;
        responseProfile.homeService = newUser.home_service;
        responseProfile.emergencyServices = newUser.emergency_services;
        break;
    }

    res.status(201).json({
      success: true,
      message: 'Registration successful',
      profile: responseProfile,
      token: jwt.sign(
        { userId: newUser.id, email: newUser.email, role: newUser.role },
        process.env.JWT_SECRET || 'easyhealth_jwt_secret_key',
        { expiresIn: '24h' }
      ),
    });

  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({
      success: false,
      error: 'Registration failed',
      details: error.message
    });
  }
}

//login using existing profiles table
 
async function loginUser(req, res, next) {
  try {
    const { email, password } = req.body || {};

    if (!email) {
      return res.status(400).json({ error: 'email is required' });
    }

    if (!password) {
      return res.status(400).json({ error: 'password is required' });
    }

    //find user by email in profiles table
    const result = await db.query(
      'SELECT * FROM public.profiles WHERE email = $1 LIMIT 1',
      [email]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({
        success: false,
        error: 'Invalid credentials'
      });
    }

    const user = result.rows[0];

    //verify password using bcryptjs
    const isMatch = await bcrypt.compare(password, user.password || '');
    if (!isMatch) {
      return res.status(401).json({
        success: false,
        error: 'Invalid credentials'
      });
    }

    //build response with role-specific information
    const responseProfile = {
      id: user.id,
      userId: user.id, //use id as userId for frontend compatibility
      fullName: user.full_name,
      full_name: user.full_name, //added for snake_case compatibility
      email: user.email,
      phone: user.phone,
      role: user.role,
      is_approved: user.is_approved,
      wilaya: user.wilaya,
      commune: user.commune,
      createdAt: user.created_at
    };

    //add role-specific information
    switch (user.role) {
      case ROLES.PATIENT:
        responseProfile.dateOfBirth = user.date_of_birth;
        responseProfile.bloodType = user.blood_type;
        responseProfile.allergies = user.allergies;
        responseProfile.emergencyContact = user.emergency_contact;
        responseProfile.emergencyPhone = user.emergency_phone;
        break;
      case ROLES.DOCTOR:
        responseProfile.specialization = user.specialization;
        responseProfile.licenseNumber = user.license_number;
        responseProfile.experienceYears = user.experience_years;
        responseProfile.consultationFee = user.consultation_fee;
        responseProfile.availableDays = user.available_days;
        responseProfile.availableHours = user.available_hours;
        responseProfile.hospital_clinic = user.hospital_clinic;
        responseProfile.education = user.education;
        responseProfile.certifications = user.certifications;
        break;
      case ROLES.PHARMACY:
        responseProfile.pharmacyName = user.pharmacy_name;
        responseProfile.address = user.address;
        responseProfile.openingHours = user.opening_hours;
        responseProfile.servicesOffered = user.services_offered;
        responseProfile.deliveryAvailable = user.delivery_available;
        responseProfile.emergencyServices = user.emergency_services;
        break;
      case ROLES.LAB:
        responseProfile.labName = user.lab_name;
        responseProfile.address = user.address;
        responseProfile.licenseNumber = user.license_number;
        responseProfile.accreditation = user.accreditation;
        responseProfile.testsAvailable = user.tests_available;
        responseProfile.equipment = user.equipment;
        responseProfile.sampleCollection = user.sample_collection;
        responseProfile.homeService = user.home_service;
        responseProfile.emergencyServices = user.emergency_services;
        break;
    }

    res.status(200).json({
      success: true,
      message: 'Login successful',
      user: responseProfile,
      token: jwt.sign(
        { userId: user.id, email: user.email, role: user.role },
        process.env.JWT_SECRET || 'easyhealth_jwt_secret_key',
        { expiresIn: '24h' }
      ),
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      error: 'Login failed',
      details: error.message
    });
  }
}

//get user profile from profiles table
 
async function getMyProfile(req, res, next) {
  try {
    const userId = req.user?.id; // This should be the UUID id

    if (!userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    //get user from profiles table using id
    const result = await db.query(
      'SELECT * FROM public.profiles WHERE id = $1 LIMIT 1',
      [userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    const user = result.rows[0];

    //build response with role-specific information
    const responseProfile = {
      id: user.id,
      userId: user.id, // Use id as userId for frontend compatibility
      fullName: user.full_name,
      full_name: user.full_name, // Added for snake_case compatibility
      email: user.email,
      phone: user.phone,
      role: user.role,
      is_approved: user.is_approved,
      wilaya: user.wilaya,
      commune: user.commune,
      createdAt: user.created_at
    };

    //add role-specific information
    switch (user.role) {
      case ROLES.PATIENT:
        responseProfile.dateOfBirth = user.date_of_birth;
        responseProfile.bloodType = user.blood_type;
        responseProfile.allergies = user.allergies;
        responseProfile.emergencyContact = user.emergency_contact;
        responseProfile.emergencyPhone = user.emergency_phone;
        break;
      case ROLES.DOCTOR:
        responseProfile.specialization = user.specialization;
        responseProfile.licenseNumber = user.license_number;
        responseProfile.experienceYears = user.experience_years;
        responseProfile.consultationFee = user.consultation_fee;
        responseProfile.availableDays = user.available_days;
        responseProfile.availableHours = user.available_hours;
        responseProfile.hospital_clinic = user.hospital_clinic;
        responseProfile.education = user.education;
        responseProfile.certifications = user.certifications;
        break;
      case ROLES.PHARMACY:
        responseProfile.pharmacyName = user.pharmacy_name;
        responseProfile.address = user.address;
        responseProfile.openingHours = user.opening_hours;
        responseProfile.servicesOffered = user.services_offered;
        responseProfile.deliveryAvailable = user.delivery_available;
        responseProfile.emergencyServices = user.emergency_services;
        break;
      case ROLES.LAB:
        responseProfile.labName = user.lab_name;
        responseProfile.address = user.address;
        responseProfile.licenseNumber = user.license_number;
        responseProfile.accreditation = user.accreditation;
        responseProfile.testsAvailable = user.tests_available;
        responseProfile.equipment = user.equipment;
        responseProfile.sampleCollection = user.sample_collection;
        responseProfile.homeService = user.home_service;
        responseProfile.emergencyServices = user.emergency_services;
        break;
    }

    res.status(200).json(responseProfile);

  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({
      error: 'Failed to get profile',
      details: error.message
    });
  }
}

//get profiles by role - queries profiles table directly for complete field access
 
async function getProfilesByRole(req, res, next) {
  try {
    const { role } = req.params;

    if (!isValidRole(role)) {
      return res.status(400).json({ error: 'Invalid role' });
    }

    //use SELECT * so the query works even if role-specific columns haven't been migrated yet
    const result = await db.query(
      `SELECT * FROM public.profiles WHERE role = $1 ORDER BY created_at DESC`,
      [role]
    );

    //normalize: add a display_name field so frontend always has one reliable key
    const rows = result.rows.map(p => ({
      ...p,
      display_name:
        (role === 'pharmacy' ? (p.pharmacy_name || p.full_name) : null) ||
        (role === 'lab' ? (p.lab_name || p.full_name) : null) ||
        p.full_name ||
        'Inconnu',
    }));

    res.status(200).json(rows);

  } catch (error) {
    console.error('Get profiles by role error:', error);
    res.status(500).json({
      error: 'Failed to get profiles by role',
      details: error.message
    });
  }
}

async function forgotPassword(req, res, next) {
  try {
    const { email } = req.body || {};

    if (!email) {
      return res.status(400).json({ error: 'email is required' });
    }

    //find user by email
    const result = await db.query(
      'SELECT * FROM public.profiles WHERE email = $1 LIMIT 1',
      [email]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Aucun compte n\'est associé à cette adresse e-mail.'
      });
    }

    const user = result.rows[0];

    //generate secure token
    const token = crypto.randomBytes(32).toString('hex');

    //set expiry: 1 hour from now
    const expires = new Date();
    expires.setHours(expires.getHours() + 1);

    //save token and expiry to profiles table
    await db.query(
      'UPDATE public.profiles SET reset_token = $1, reset_token_expires = $2 WHERE email = $3',
      [token, expires, email]
    );

    //send reset link email
    const frontendUrl = process.env.FRONTEND_URL || 'https://yourapp.com';
    const resetLink = `${frontendUrl}/reset-password?token=${token}`;

    await emailService.sendResetPasswordEmail(email, resetLink);

    res.status(200).json({
      success: true,
      message: 'E-mail de réinitialisation envoyé avec succès.'
    });
  } catch (error) {
    console.error('Forgot password error:', error);
    res.status(500).json({
      success: false,
      error: 'Échec de l\'envoi de l\'e-mail de réinitialisation.',
      details: error.message
    });
  }
}

async function resetPassword(req, res, next) {
  try {
    const { token, newPassword } = req.body || {};

    if (!token) {
      return res.status(400).json({ error: 'token is required' });
    }

    if (!newPassword) {
      return res.status(400).json({ error: 'newPassword is required' });
    }

    //find user where reset_token = token
    const result = await db.query(
      'SELECT * FROM public.profiles WHERE reset_token = $1 LIMIT 1',
      [token]
    );

    if (result.rows.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'Jeton de réinitialisation invalide.'
      });
    }

    const user = result.rows[0];

    //check token is not expired
    if (new Date() > new Date(user.reset_token_expires)) {
      return res.status(400).json({
        success: false,
        error: 'Le jeton de réinitialisation a expiré.'
      });
    }

    //hash new password with bcryptjs
    const hashedPassword = await bcrypt.hash(newPassword, 10);

    //update password and clear reset fields
    await db.query(
      'UPDATE public.profiles SET password = $1, reset_token = NULL, reset_token_expires = NULL WHERE id = $2',
      [hashedPassword, user.id]
    );

    res.status(200).json({
      success: true,
      message: 'Votre mot de passe a été réinitialisé avec succès.'
    });
  } catch (error) {
    console.error('Reset password error:', error);
    res.status(500).json({
      success: false,
      error: 'Échec de la réinitialisation du mot de passe.',
      details: error.message
    });
  }
}

async function logout(req, res, next) {
  try {
    res.status(200).json({ success: true, message: 'Logged out successfully' });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  registerUser,
  loginUser,
  getMyProfile,
  getProfilesByRole,
  forgotPassword,
  resetPassword,
  logout,
};
