const db = require('../config/db');

/**
 * Submit an anonymous health report
 */
async function submitReport({ region, symptomSummary, gender, ageGroup, doctorId }) {
    const { rows } = await db.query(
        `INSERT INTO public.health_reports (region, symptom_summary, gender, age_group, doctor_id)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING *`,
        [region, symptomSummary, gender, ageGroup, doctorId]
    );
    return rows[0];
}

/**
 * Get aggregated trends by region for the last 7 days
 * Currently returns basic counts. Gemini summarization planned for tomorrow.
 */
async function getAggregatedTrendsByRegion() {
    const { rows } = await db.query(
        `SELECT 
            region, 
            COUNT(*) as report_count,
            STRING_AGG(symptom_summary, ' | ') as all_symptoms
         FROM public.health_reports 
         WHERE created_at > NOW() - INTERVAL '7 days'
         GROUP BY region
         ORDER BY report_count DESC
         LIMIT 5`
    );

    // Simple manual summary for today
    return rows.map(row => ({
        region: row.region,
        count: row.report_count,
        summary: `Tendance: ${row.report_count} cas signalés. Symptômes fréquents: ${row.all_symptoms.split(' | ').slice(0, 3).join(', ')}...`
    }));
}

/**
 * Get monthly trend for all prevalent symptoms in a region (or globally)
 */
async function getSymptomTrends(symptom = '', region = '') {
    let query = `
        SELECT 
            TO_CHAR(created_at, 'YYYY-MM') as month,
            COUNT(*) as case_count
        FROM public.health_reports
        WHERE 1=1
    `;
    const params = [];

    if (symptom) {
        params.push(`%${symptom}%`);
        query += ` AND symptom_summary ILIKE $${params.length}`;
    }
    if (region) {
        params.push(`%${region}%`);
        query += ` AND region ILIKE $${params.length}`;
    }

    query += ` GROUP BY month ORDER BY month ASC`;

    const { rows } = await db.query(query, params);
    return rows;
}

/**
 * Get grouped recent reports (History with counters)
 */
async function getRecentReports(limit = 15) {
    const { rows } = await db.query(
        `SELECT 
            MAX(id) as id, 
            region, 
            symptom_summary, 
            gender, 
            age_group, 
            MAX(created_at) as created_at,
            COUNT(*) as case_count
         FROM public.health_reports 
         WHERE created_at > NOW() - INTERVAL '48 hours'
         GROUP BY region, symptom_summary, gender, age_group
         ORDER BY created_at DESC 
         LIMIT $1`,
        [limit]
    );
    return rows;
}

/**
 * Quick increment: Create a new report based on an existing one
 */
async function cloneReport(reportId) {
    if (!reportId) throw new Error('ID du rapport manquant');

    const { rows: existing } = await db.query(
        `SELECT region, symptom_summary, gender, age_group FROM public.health_reports WHERE id = $1`,
        [parseInt(reportId)]
    );
    
    if (existing.length === 0) throw new Error('Rapport non trouvé');
    
    const { region, symptom_summary, gender, age_group } = existing[0];
    
    // Ensure critical fields are present
    if (!region || !symptom_summary) throw new Error('Données du rapport incomplètes');

    return submitReport({
        region,
        symptomSummary: symptom_summary,
        gender,
        ageGroup: age_group
    });
}

/**
 * Get detailed regional alerts with percentage breakdown for AI
 */
async function getDetailedAlerts() {
    const { rows } = await db.query(
        `WITH RegionTotals AS (
            SELECT region, COUNT(*) as total_cases
            FROM public.health_reports
            WHERE created_at > NOW() - INTERVAL '14 days'
            GROUP BY region
        )
        SELECT 
            hr.region,
            hr.symptom_summary as dominant_symptom,
            COUNT(*) as symptom_count,
            rt.total_cases,
            ROUND((COUNT(*)::numeric / rt.total_cases) * 100) as percentage
        FROM public.health_reports hr
        JOIN RegionTotals rt ON hr.region = rt.region
        WHERE hr.created_at > NOW() - INTERVAL '14 days'
        GROUP BY hr.region, hr.symptom_summary, rt.total_cases
        HAVING COUNT(*) > 0
        ORDER BY rt.total_cases DESC, percentage DESC`
    );
    return rows;
}

/**
 * Get distribution of symptoms (Top 5)
 */
async function getSymptomDistribution() {
    const { rows } = await db.query(
        `SELECT 
            symptom_summary as symptom,
            COUNT(*) as count
         FROM public.health_reports
         WHERE created_at > NOW() - INTERVAL '30 days'
         GROUP BY symptom
         ORDER BY count DESC
         LIMIT 5`
    );
    return rows;
}

module.exports = {
    submitReport,
    getAggregatedTrendsByRegion,
    getSymptomTrends,
    getDetailedAlerts,
    getRecentReports,
    cloneReport,
    getSymptomDistribution
};

