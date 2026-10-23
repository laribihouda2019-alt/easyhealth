const profileModel = require('../models/profileModel');

async function getProfile(id) {
  return profileModel.getProfileById(id);
}

async function updateProfile(id, data) {
  return profileModel.updateProfile(id, data);
}

async function getProfilesByRole(role) {
  return profileModel.getProfilesByRole(role);
}

async function searchProfiles(query, commune) {
  return profileModel.searchProfiles(query, commune);
}

async function updateApprovalStatus(id, isApproved) {
  return profileModel.updateApprovalStatus(id, isApproved);
}

async function getProfileStats(id, role) {
  return profileModel.getProfileStats(id, role);
}

module.exports = {
  getProfile,
  updateProfile,
  getProfilesByRole,
  searchProfiles,
  updateApprovalStatus,
  getProfileStats,
};

