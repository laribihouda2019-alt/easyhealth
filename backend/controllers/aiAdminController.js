const db = require('../config/db');

//get Disease Statistics for Admin Dashboard
 
async function getDiseaseStatistics(req, res, next) {
  try {
    const { period, category, diseaseName } = req.query;

    let dateFilter = '';
    if (period === 'week') {
      dateFilter = 'AND observation_date >= CURRENT_DATE - INTERVAL \'7 days\'';
    } else if (period === 'month') {
      dateFilter = 'AND observation_date >= CURRENT_DATE - INTERVAL \'30 days\'';
    } else if (period === 'year') {
      dateFilter = 'AND observation_date >= CURRENT_DATE - INTERVAL \'365 days\'';
    }

    let categoryFilter = '';
    if (category) {
      categoryFilter = `AND disease_category = '${category}'`;
    }

    let diseaseFilter = '';
    if (diseaseName) {
      diseaseFilter = `AND disease_name ILIKE '%${diseaseName}%'`;
    }

    const result = await db.query(
      `SELECT 
         ds.disease_name,
         ds.disease_category,
         ds.observation_date,
         ds.total_cases,
         ds.age_distribution,
         ds.gender_distribution,
         ds.severity_distribution,
         ds.region_distribution,
         ds.trend_analysis,
         ds.created_at,
         ds.updated_at
       FROM disease_statistics ds
       WHERE 1=1 ${dateFilter} ${categoryFilter} ${diseaseFilter}
       ORDER BY ds.observation_date DESC, ds.total_cases DESC
       LIMIT 100`,
      []
    );

    //get histogram data
    const histogramData = await generateHistogramData(result.rows);

    res.json({
      success: true,
      statistics: result.rows,
      histogram: histogramData,
      totalCases: result.rows.reduce((sum, stat) => sum + stat.total_cases, 0)
    });

  } catch (error) {
    console.error('Get disease statistics error:', error);
    next(error);
  }
}

//get Epidemic Alerts
async function getEpidemicAlerts(req, res, next) {
  try {
    const { active, severity } = req.query;

    let query = 'SELECT * FROM epidemic_alerts WHERE 1=1';
    const params = [];

    if (active === 'true') {
      query += ' AND is_active = true';
    } else if (active === 'false') {
      query += ' AND is_active = false';
    }

    if (severity) {
      query += ` AND alert_severity = $${params.length + 1}`;
      params.push(severity);
    }

    query += ' ORDER BY created_at DESC';

    const result = await db.query(query, params);

    res.json({
      success: true,
      alerts: result.rows,
      activeCount: result.rows.filter(alert => alert.is_active).length
    });

  } catch (error) {
    console.error('Get epidemic alerts error:', error);
    next(error);
  }
}

//update Epidemic Alert Status

async function updateEpidemicAlert(req, res, next) {
  try {
    const { alertId } = req.params;
    const { isActive, notes } = req.body;

    const result = await db.query(
      `UPDATE epidemic_alerts 
       SET is_active = $1, resolved_at = CASE WHEN $1 = false THEN NOW() ELSE resolved_at END
       WHERE id = $2
       RETURNING *`,
      [isActive, alertId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Alert not found' });
    }

    res.json({
      success: true,
      alert: result.rows[0],
      message: `Alert ${isActive ? 'réactivée' : 'résolue'} avec succès`
    });

  } catch (error) {
    console.error('Update epidemic alert error:', error);
    next(error);
  }
}

//generate Disease Trend Analysis
 
async function generateDiseaseTrends(req, res, next) {
  try {
    const { diseaseName, period } = req.query;

    if (!diseaseName) {
      return res.status(400).json({ error: 'Disease name is required' });
    }

    let days = 30;
    if (period === 'week') days = 7;
    else if (period === 'month') days = 30;
    else if (period === 'year') days = 365;

    const result = await db.query(
      `SELECT 
         observation_date,
         total_cases,
         age_distribution,
         gender_distribution,
         severity_distribution
       FROM disease_statistics 
       WHERE disease_name = $1 AND observation_date >= CURRENT_DATE - INTERVAL '${days} days'
       ORDER BY observation_date ASC`,
      [diseaseName]
    );

    //generate trend analysis
    const trendAnalysis = await performTrendAnalysis(result.rows, diseaseName);

    res.json({
      success: true,
      diseaseName,
      period,
      data: result.rows,
      trends: trendAnalysis
    });

  } catch (error) {
    console.error('Generate disease trends error:', error);
    next(error);
  }
}

//get Regional Disease Distribution
 
async function getRegionalDistribution(req, res, next) {
  try {
    const { diseaseName, period } = req.query;

    let dateFilter = '';
    if (period === 'week') {
      dateFilter = 'AND observation_date >= CURRENT_DATE - INTERVAL \'7 days\'';
    } else if (period === 'month') {
      dateFilter = 'AND observation_date >= CURRENT_DATE - INTERVAL \'30 days\'';
    }

    let whereClause = 'WHERE 1=1';
    if (diseaseName) {
      whereClause += ` AND disease_name = '${diseaseName}'`;
    }

    const result = await db.query(
      `SELECT 
         ds.disease_name,
         ds.region_distribution,
         ds.total_cases,
         ds.observation_date
       FROM disease_statistics ds
       ${whereClause} ${dateFilter}
       ORDER BY ds.observation_date DESC`,
      []
    );

    //aggregate regional data
    const regionalData = aggregateRegionalData(result.rows);

    res.json({
      success: true,
      regionalData,
      totalRegions: Object.keys(regionalData).length
    });

  } catch (error) {
    console.error('Get regional distribution error:', error);
    next(error);
  }
}

//get AI Health Insights
 
async function getHealthInsights(req, res, next) {
  try {
    const { period } = req.query;

    let days = 30;
    if (period === 'week') days = 7;
    else if (period === 'month') days = 30;
    else if (period === 'year') days = 365;

    //get top diseases
    const topDiseases = await db.query(
      `SELECT 
         disease_name,
         SUM(total_cases) as total_cases,
         disease_category
       FROM disease_statistics 
       WHERE observation_date >= CURRENT_DATE - INTERVAL '${days} days'
       GROUP BY disease_name, disease_category
       ORDER BY total_cases DESC
       LIMIT 10`,
      []
    );

    //get disease categories distribution
    const categoryDistribution = await db.query(
      `SELECT 
         disease_category,
         SUM(total_cases) as total_cases,
         COUNT(DISTINCT disease_name) as disease_count
       FROM disease_statistics 
       WHERE observation_date >= CURRENT_DATE - INTERVAL '${days} days'
       GROUP BY disease_category
       ORDER BY total_cases DESC`,
      []
    );

    //get active epidemic alerts
    const activeAlerts = await db.query(
      'SELECT * FROM epidemic_alerts WHERE is_active = true ORDER BY created_at DESC',
      []
    );

    //generate insights
    const insights = await generateHealthInsights(topDiseases.rows, categoryDistribution.rows, activeAlerts.rows);

    res.json({
      success: true,
      insights,
      topDiseases: topDiseases.rows,
      categoryDistribution: categoryDistribution.rows,
      activeAlerts: activeAlerts.rows,
      period
    });

  } catch (error) {
    console.error('Get health insights error:', error);
    next(error);
  }
}

//perform Mass Disease Analysis

async function performMassAnalysis(req, res, next) {
  try {
    const { analysisType } = req.query; // 'weekly', 'monthly', 'custom'

    //get all recent disease observations
    const observations = await db.query(
      `SELECT 
         do.*,
         p.full_name as doctor_name
       FROM disease_observations do
       JOIN profiles p ON do.doctor_id = p.id
       WHERE do.observation_date >= CURRENT_DATE - INTERVAL '30 days'
       ORDER BY do.observation_date DESC`,
      []
    );

    //perform AI analysis
    const analysisResults = await performAIMassAnalysis(observations.rows);

    //update disease statistics
    await updateDiseaseStatistics(analysisResults);

    //check for new epidemic alerts
    await checkForNewEpidemics(analysisResults);

    res.json({
      success: true,
      analysis: analysisResults,
      observationsProcessed: observations.rows.length,
      message: 'Analyse de masse complétée avec succès'
    });

  } catch (error) {
    console.error('Perform mass analysis error:', error);
    next(error);
  }
}

//get Disease Prediction

async function getDiseasePrediction(req, res, next) {
  try {
    const { diseaseName } = req.query;

    if (!diseaseName) {
      return res.status(400).json({ error: 'Disease name is required' });
    }

    //get historical data
    const historicalData = await db.query(
      `SELECT 
         observation_date,
         total_cases,
         age_distribution,
         gender_distribution
       FROM disease_statistics 
       WHERE disease_name = $1 AND observation_date >= CURRENT_DATE - INTERVAL '90 days'
       ORDER BY observation_date ASC`,
      [diseaseName]
    );

    //generate prediction
    const prediction = await generateDiseasePrediction(historicalData.rows, diseaseName);

    res.json({
      success: true,
      diseaseName,
      prediction,
      historicalData: historicalData.rows
    });

  } catch (error) {
    console.error('Get disease prediction error:', error);
    next(error);
  }
}

//helper Functions
async function generateHistogramData(statistics) {
  const histogram = {};
  
  statistics.forEach(stat => {
    const date = stat.observation_date;
    if (!histogram[date]) {
      histogram[date] = 0;
    }
    histogram[date] += stat.total_cases;
  });

  //convert to array format for charts
  return Object.keys(histogram)
    .sort()
    .map(date => ({
      date,
      cases: histogram[date]
    }));
}

async function performTrendAnalysis(data, diseaseName) {
  if (data.length < 2) {
    return { trend: 'insufficient_data', confidence: 0 };
  }

  const recent = data.slice(-7); // Last 7 days
  const previous = data.slice(-14, -7); // Previous 7 days

  const recentTotal = recent.reduce((sum, day) => sum + day.total_cases, 0);
  const previousTotal = previous.reduce((sum, day) => sum + day.total_cases, 0);

  const change = previousTotal > 0 ? ((recentTotal - previousTotal) / previousTotal) * 100 : 0;

  let trend = 'stable';
  let confidence = 0;

  if (change > 20) {
    trend = 'increasing';
    confidence = Math.min(95, 70 + change);
  } else if (change < -20) {
    trend = 'decreasing';
    confidence = Math.min(95, 70 + Math.abs(change));
  } else {
    trend = 'stable';
    confidence = 60;
  }

  return {
    trend,
    confidence,
    change: change.toFixed(2),
    recentTotal,
    previousTotal,
    recommendation: getTrendRecommendation(trend, change)
  };
}

function getTrendRecommendation(trend, change) {
  if (trend === 'increasing' && change > 50) {
    return 'Surveillance renforcée recommandée. Préparer les services de santé.';
  } else if (trend === 'increasing') {
    return 'Augmentation détectée. Continuer la surveillance.';
  } else if (trend === 'decreasing') {
    return 'Baisse des cas. Maintenir les mesures préventives.';
  } else {
    return 'Situation stable. Surveillance normale.';
  }
}

function aggregateRegionalData(data) {
  const regionalData = {};

  data.forEach(item => {
    if (item.region_distribution) {
      const regions = typeof item.region_distribution === 'string' 
        ? JSON.parse(item.region_distribution) 
        : item.region_distribution;

      Object.entries(regions).forEach(([region, count]) => {
        if (!regionalData[region]) {
          regionalData[region] = 0;
        }
        regionalData[region] += count;
      });
    }
  });

  return regionalData;
}

async function generateHealthInsights(topDiseases, categoryDistribution, activeAlerts) {
  const insights = [];

  //insight 1: Top disease
  if (topDiseases.length > 0) {
    insights.push({
      type: 'top_disease',
      title: 'Maladie la plus fréquente',
      content: `${topDiseases[0].disease_name} avec ${topDiseases[0].total_cases} cas`,
      severity: topDiseases[0].total_cases > 100 ? 'high' : 'medium'
    });
  }

  //insight 2: Most affected category
  if (categoryDistribution.length > 0) {
    insights.push({
      type: 'category_trend',
      title: 'Catégorie la plus affectée',
      content: `${categoryDistribution[0].disease_category} avec ${categoryDistribution[0].total_cases} cas`,
      severity: categoryDistribution[0].total_cases > 200 ? 'high' : 'medium'
    });
  }

  //insight 3: Active alerts
  if (activeAlerts.length > 0) {
    insights.push({
      type: 'epidemic_alert',
      title: 'Alertes épidémiques actives',
      content: `${activeAlerts.length} alerte(s) épidémique(s) en cours`,
      severity: activeAlerts.some(alert => alert.alert_severity === 'critical') ? 'critical' : 'high'
    });
  }

  //insight 4: Overall trend
  const totalCases = topDiseases.reduce((sum, disease) => sum + disease.total_cases, 0);
  insights.push({
    type: 'overall_trend',
    title: 'Tendance globale',
    content: `Total de ${totalCases} cas sur la période`,
    severity: totalCases > 500 ? 'high' : totalCases > 200 ? 'medium' : 'low'
  });

  return insights;
}

async function performAIMassAnalysis(observations) {
  //simulate AI mass analysis
  const diseaseCounts = {};
  const categoryCounts = {};
  const severityCounts = {};

  observations.forEach(obs => {
    if (!diseaseCounts[obs.disease_name]) {
      diseaseCounts[obs.disease_name] = 0;
    }
    diseaseCounts[obs.disease_name]++;

    if (!categoryCounts[obs.disease_category]) {
      categoryCounts[obs.disease_category] = 0;
    }
    categoryCounts[obs.disease_category]++;

    if (obs.severity_level) {
      if (!severityCounts[obs.severity_level]) {
        severityCounts[obs.severity_level] = 0;
      }
      severityCounts[obs.severity_level]++;
    }
  });

  return {
    diseaseCounts,
    categoryCounts,
    severityCounts,
    totalObservations: observations.length,
    analysisDate: new Date().toISOString()
  };
}

async function updateDiseaseStatistics(analysisResults) {
  //update statistics based on analysis
  for (const [diseaseName, count] of Object.entries(analysisResults.diseaseCounts)) {
    await db.query(
      `INSERT INTO disease_statistics (disease_name, disease_category, total_cases)
       VALUES ($1, $2, $3)
       ON CONFLICT (disease_name, observation_date)
       DO UPDATE SET total_cases = disease_statistics.total_cases + $3`,
      [diseaseName, 'other', count]
    );
  }
}

async function checkForNewEpidemics(analysisResults) {
  //check for unusual patterns that might indicate epidemics
  for (const [diseaseName, count] of Object.entries(analysisResults.diseaseCounts)) {
    if (count > 10) { // Threshold for epidemic detection
      await createEpidemicAlert(diseaseName, 'unknown', count * 20); // 20% increase estimate
    }
  }
}

async function generateDiseasePrediction(historicalData, diseaseName) {
  if (historicalData.length < 7) {
    return { 
      prediction: 'insufficient_data',
      confidence: 0,
      message: 'Pas assez de données historiques pour prédire'
    };
  }

  //simple linear regression prediction
  const recentData = historicalData.slice(-7);
  const averageCases = recentData.reduce((sum, day) => sum + day.total_cases, 0) / recentData.length;
  
  //calculate trend
  let trend = 0;
  for (let i = 1; i < recentData.length; i++) {
    trend += recentData[i].total_cases - recentData[i-1].total_cases;
  }
  trend /= (recentData.length - 1);

  const predictedCases = Math.max(0, averageCases + trend);
  const confidence = Math.min(95, 50 + (historicalData.length / 30) * 45);

  return {
    prediction: predictedCases.toFixed(1),
    confidence: confidence.toFixed(1),
    trend: trend > 0 ? 'increasing' : trend < 0 ? 'decreasing' : 'stable',
    message: `Prédiction de ${predictedCases.toFixed(1)} cas pour demain`,
    recommendations: getPredictionRecommendations(trend, predictedCases)
  };
}

function getPredictionRecommendations(trend, predictedCases) {
  const recommendations = [];

  if (trend > 5) {
    recommendations.push('Préparer une augmentation des ressources');
  } else if (trend < -5) {
    recommendations.push('Maintenir les mesures préventives');
  }

  if (predictedCases > 50) {
    recommendations.push('Surveillance renforcée recommandée');
  }

  if (recommendations.length === 0) {
    recommendations.push('Surveillance normale');
  }

  return recommendations;
}

module.exports = {
  getDiseaseStatistics,
  getEpidemicAlerts,
  updateEpidemicAlert,
  generateDiseaseTrends,
  getRegionalDistribution,
  getHealthInsights,
  performMassAnalysis,
  getDiseasePrediction
};
