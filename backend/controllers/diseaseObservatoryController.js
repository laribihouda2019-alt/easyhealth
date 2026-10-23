const diseaseObservatoryService = require('../services/diseaseObservatoryService');
const medicalRouterService = require('../services/medicalRouterService');

async function submitReport(req, res) {
    try {
        const { region, symptomSummary, gender, ageGroup } = req.body;
        const doctorId = req.user?.id; //from authMiddleware
        
        if (!region || !symptomSummary) {
            return res.status(400).json({ success: false, error: 'Region and symptoms are required' });
        } //if il y'a pas region et symptomes set erreur 400

        const report = await diseaseObservatoryService.submitReport({
            region,
            symptomSummary,
            gender,
            ageGroup,
            doctorId
        });

        res.status(201).json({ success: true, data: report });
    } catch (error) {
        console.error('Submit Report Error:', error);
        res.status(500).json({ success: false, error: 'Internal Server Error' });
    }
}

async function getTrends(req, res) {
    try {
        const trends = await diseaseObservatoryService.getAggregatedTrendsByRegion();
        res.status(200).json({ success: true, data: trends });
    } catch (error) {
        console.error('Get Trends Error:', error);
        res.status(500).json({ success: false, error: 'Internal Server Error' });
    }
}  //recupere tendences des maladies par region

async function getSymptomTrends(req, res) {
    try {
        const { symptom, region } = req.query;
        const trends = await diseaseObservatoryService.getSymptomTrends(symptom, region);
        res.status(200).json({ success: true, data: trends });
    } catch (error) {
        console.error('Get Symptom Trends Error:', error);
        res.status(500).json({ success: false, error: 'Internal Server Error' });
    }
}  //les parametre symptomes et regien sont requis dans l'url

async function getDetailedAlerts(req, res) {
    try {
        const alerts = await diseaseObservatoryService.getDetailedAlerts();
        res.status(200).json({ success: true, data: alerts });
    } catch (error) {
        console.error('Get Detailed Alerts Error:', error);
        res.status(500).json({ success: false, error: 'Internal Server Error' });
    }
}

async function getHistory(req, res) {
    try {
        const history = await diseaseObservatoryService.getRecentReports();
        res.status(200).json({ success: true, data: history });
    } catch (error) {
        console.error('Get History Error:', error);
        res.status(500).json({ success: false, error: 'Internal Server Error' });
    }
}

async function incrementReport(req, res) {
    try {
        const { id } = req.params;
        console.log('Incrementing report ID:', id);
        const report = await diseaseObservatoryService.cloneReport(id);
        res.status(201).json({ success: true, data: report });
    } catch (error) {
        console.error('Increment Report Error DETAIL:', error);
        res.status(500).json({ success: false, error: error.message || 'Internal Server Error' });
    }
}

async function getSymptomDistribution(req, res) {
    try {
        const distribution = await diseaseObservatoryService.getSymptomDistribution();
        res.status(200).json({ success: true, data: distribution });
    } catch (error) {
        console.error('Get Symptom Distribution Error:', error);
        res.status(500).json({ success: false, error: 'Internal Server Error' });
    }
} //chart 

async function getAIAdvice(req, res) {
    try {
        const { symptom, region } = req.query;
        if (!symptom || !region) {
            return res.status(400).json({ success: false, error: 'Symptom and region are required' });
        }
        const advice = await medicalRouterService.generatePreventiveAdvice(symptom, region);
        res.status(200).json({ success: true, data: advice });
    } catch (error) {
        console.error('Get AI Advice Error:', error.message);
        const status = error.message.includes('Quota') ? 429 : 500;
        res.status(status).json({ success: false, error: error.message || 'Internal Server Error' });
    }
}  //get ai advice

module.exports = {
    submitReport,
    getTrends,
    getSymptomTrends,
    getDetailedAlerts,
    getHistory,
    incrementReport,
    getSymptomDistribution,
    getAIAdvice
};
