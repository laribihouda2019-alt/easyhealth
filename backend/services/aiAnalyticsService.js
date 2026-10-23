const axios = require('axios');
const ENV = require('../config/env');

const AI_API_URL = process.env.AI_API_URL || 'http://localhost:5000';

async function getDiseaseStatistics(filters = {}) {
  try {
    const days = filters.days || 30;
    const response = await axios.get(`${AI_API_URL}/admin/frequent_diseases?days=${days}`);

    return {
      topConditions: response.data.diseases || [],
      trends: [],
      alerts: response.data.alerts || [],
      filters,
    };
  } catch (error) {
    console.error('Error fetching disease statistics from AI API:', error.message);
    return {
      topConditions: [],
      trends: [],
      alerts: [],
      filters,
    };
  }
}

async function getSmartAlertCandidates() {
  try {
    const response = await axios.get(`${AI_API_URL}/admin/frequent_diseases?days=7`);
    return response.data.alerts || [];
  } catch (error) {
    console.error('Error fetching smart alerts from AI API:', error.message);
    return [];
  }
}

module.exports = {
  getDiseaseStatistics,
  getSmartAlertCandidates,
};


