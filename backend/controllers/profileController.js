const profileService = require('../services/profileService');

async function getMe(req, res, next) {
  try {
    const profile = await profileService.getProfile(req.user.id);
    res.json(profile);
  } catch (err) {
    next(err);
  }
}

async function getProfileById(req, res, next) {
  try {
    const { userId } = req.params;
    const profile = await profileService.getProfile(userId);
    res.json(profile);
  } catch (err) {
    next(err);
  }
}

async function updateProfile(req, res, next) {
  try {
    const { full_name, email, phone, avatar_url, metadata, wilaya, commune, consultation_fee, specialty, logo_url } = req.body;
    const updatedProfile = await profileService.updateProfile(req.user.id, {
      full_name,
      email,
      phone,
      avatar_url,
      metadata,
      wilaya,
      commune,
      consultation_fee,
      specialty,
      logo_url
    });
    res.json(updatedProfile);
  } catch (err) {
    next(err);
  }
}

async function getProfilesByRole(req, res, next) {
  try {
    const { role } = req.params;
    const profiles = await profileService.getProfilesByRole(role);
    res.json(profiles);
  } catch (err) {
    next(err);
  }
}

async function searchProfiles(req, res, next) {
  try {
    const { query, commune } = req.query;
    const profiles = await profileService.searchProfiles(query, commune);
    res.json(profiles);
  } catch (err) {
    next(err);
  }
}

async function approveProfile(req, res, next) {
  try {
    const { userId } = req.params;
    const { is_approved } = req.body;
    const updatedProfile = await profileService.updateApprovalStatus(userId, is_approved);
    res.json(updatedProfile);
  } catch (err) {
    next(err);
  }
}

async function getProfileStats(req, res, next) {
  try {
    const { id, role } = req.user;
    const stats = await profileService.getProfileStats(id, role);
    res.json(stats);
  } catch (err) {
    next(err);
  }
}

module.exports = {
  getMe,
  getProfileById,
  updateProfile,
  getProfilesByRole,
  searchProfiles,
  approveProfile,
  getProfileStats,
};

