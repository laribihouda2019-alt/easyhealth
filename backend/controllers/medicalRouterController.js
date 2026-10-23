const medicalRouterService = require('../services/medicalRouterService');

//handle symptom recommendation request Uses Gemini AI with Local Fallback
 
async function recommendSpecialty(req, res, next) {
  try {
    const { symptomsDescription } = req.body;

    if (!symptomsDescription) {
      return res.status(400).json({ 
        success: false, 
        error: 'Symptom description is required' 
      });
    }

    //call the service which handles Gemini + Fallback logic
    const recommendation = await medicalRouterService.routeSymptoms(symptomsDescription);

    res.status(200).json({
      success: true,
      specialty: recommendation.specialty,
      advice: recommendation.advice,
      source: recommendation.source,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Critical Medical Router Error:', error.message);
    const status = error.message.includes('Quota') || error.message.includes('surcharge') ? 429 : 500;
    res.status(status).json({
      success: false,
      error: error.message || 'Le service IA est indisponible'
    });
  }
}

module.exports = {
  recommendSpecialty
};
