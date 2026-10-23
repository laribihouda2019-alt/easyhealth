"""
EasyHealth AI API - Flask Service
Routes: /predict, /admin/check_documents, /medication/reminders, /admin/frequent_diseases
"""
import os
import json
import logging
from pathlib import Path
from datetime import datetime, timedelta
from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app, origins='*', methods=['GET', 'POST', 'OPTIONS'])

BASE_DIR = Path(__file__).resolve().parent
MODEL_PATH = BASE_DIR / 'doctor_recommendation_model.pkl'
VECTORIZER_PATH = BASE_DIR / 'tfidf_vectorizer.pkl'

# Load model and vectorizer at startup
_model = None
_vectorizer = None


def load_ai_model():
    """Load doctor recommendation model and TF-IDF vectorizer."""
    global _model, _vectorizer
    try:
        if MODEL_PATH.exists() and VECTORIZER_PATH.exists():
            import joblib
            _model = joblib.load(MODEL_PATH)
            _vectorizer = joblib.load(VECTORIZER_PATH)
            app.logger.info("AI model and vectorizer loaded successfully")
            return True
        else:
            app.logger.warning(
                f"Model files not found. Expected: {MODEL_PATH}, {VECTORIZER_PATH}. "
                "Using fallback recommendations."
            )
            return False
    except Exception as e:
        app.logger.error(f"Error loading AI model: {e}")
        return False


# Fallback specialty mapping based on symptoms
SYMPTOM_SPECIALTY_MAP = {
    'mal de tête': 'Neurologue',
    'migraine': 'Neurologue',
    'fièvre': 'Médecine générale',
    'toux': 'Pneumologue',
    'douleur thoracique': 'Cardiologue',
    'mal au ventre': 'Gastro-entérologue',
    'douleur abdominale': 'Gastro-entérologue',
    'mal de dos': 'Orthopédiste',
    'douleur articulaire': 'Rhumatologue',
    'eczéma': 'Dermatologue',
    'problème peau': 'Dermatologue',
    'fatigue': 'Médecine générale',
    'insomnie': 'Psychiatre',
    'anxiété': 'Psychiatre',
    'nausée': 'Gastro-entérologue',
    'vertige': 'Neurologue',
    'allergie': 'Allergologue',
    'yeux': 'Ophtalmologue',
    'vision': 'Ophtalmologue',
    'oreille': 'ORL',
    'gorge': 'ORL',
}


def predict_with_model(symptoms_text):
    """Use loaded model to predict doctor specialty."""
    if _model is not None and _vectorizer is not None:
        try:
            X = _vectorizer.transform([symptoms_text])
            specialty = _model.predict(X)[0]
            proba = _model.predict_proba(X)[0]
            confidence = float(max(proba))
            return specialty, confidence
        except Exception as e:
            app.logger.error(f"Model prediction error: {e}")
    return None, 0.0


def fallback_recommend(symptoms_text):
    """Fallback recommendation when model is not loaded."""
    text_lower = symptoms_text.lower()
    for keyword, specialty in SYMPTOM_SPECIALTY_MAP.items():
        if keyword in text_lower:
            return specialty, 0.75
    return "Médecine générale", 0.5


# ============== ROUTES ==============

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint."""
    return jsonify({
        'status': 'ok',
        'model_loaded': _model is not None,
        'timestamp': datetime.utcnow().isoformat(),
    })


@app.route('/predict', methods=['POST'])
def predict():
    """
    POST /predict
    Body: { "symptoms": "mal de tête, fièvre, fatigue" }
    Returns: { "recommended_specialty": "...", "confidence": 0.9, "doctors": [...] }
    """
    try:
        data = request.get_json() or {}
        symptoms = data.get('symptoms', '').strip()
        if not symptoms:
            return jsonify({'error': 'symptoms is required'}), 400

        specialty, confidence = predict_with_model(symptoms)
        if specialty is None:
            specialty, confidence = fallback_recommend(symptoms)

        return jsonify({
            'recommended_specialty': str(specialty),
            'confidence': round(confidence, 2),
            'symptoms_received': symptoms,
            'message': f'Recommandation: consulter un {specialty}',
        })
    except Exception as e:
        app.logger.exception(e)
        return jsonify({'error': str(e)}), 500


@app.route('/admin/check_documents', methods=['POST'])
def check_documents():
    """
    POST /admin/check_documents
    Body: { "document_url": "...", "role_requested": "doctor", "document_type": "diploma" }
    Returns: { "suggested_status": "approved"|"rejected"|"needs_review", "confidence": 0.85, "notes": "..." }
    """
    try:
        data = request.get_json() or {}
        document_url = data.get('document_url', '')
        role_requested = data.get('role_requested', 'doctor')
        document_type = data.get('document_type', 'certificate')

        # Simulated AI analysis - in production, use OCR + ML
        # For real implementation: download document, run OCR, validate fields
        suggested_status = 'needs_review'
        confidence = 0.7
        notes = f"Document {document_type} pour rôle {role_requested}. Analyse automatique en attente d'approbation manuelle."

        if document_url and any(x in document_url.lower() for x in ['.pdf', '.png', '.jpg']):
            suggested_status = 'needs_review'
            confidence = 0.75
            notes = "Document téléchargé. Vérification manuelle recommandée par l'admin."

        return jsonify({
            'suggested_status': suggested_status,
            'confidence': confidence,
            'notes': notes,
            'role_requested': role_requested,
            'document_type': document_type,
        })
    except Exception as e:
        app.logger.exception(e)
        return jsonify({'error': str(e)}), 500


@app.route('/medication/reminders', methods=['POST'])
def medication_reminders():
    """
    POST /medication/reminders
    Body: { "user_id": "uuid", "minutes_before": 15 }
    Triggers AI to send notifications for upcoming medication doses.
    Returns: { "reminders_sent": 3, "next_reminders": [...] }
    """
    try:
        data = request.get_json() or {}
        user_id = data.get('user_id', '')
        minutes_before = int(data.get('minutes_before', 15))

        # Simulated: in production, query medication_schedule + reminder_times
        # and send push/email notifications
        reminders_sent = 0
        next_reminders = []

        return jsonify({
            'reminders_sent': reminders_sent,
            'next_reminders': next_reminders,
            'message': 'Rappels de médicaments traités.',
        })
    except Exception as e:
        app.logger.exception(e)
        return jsonify({'error': str(e)}), 500


@app.route('/admin/frequent_diseases', methods=['GET', 'POST'])
def frequent_diseases():
    """
    GET /admin/frequent_diseases?days=30
    Returns: { "diseases": [{"condition": "...", "count": 10}], "alerts": [...] }
    """
    try:
        if request.method == 'POST':
            data = request.get_json() or {}
            days = int(data.get('days', 30))
        else:
            days = int(request.args.get('days', 30))

        # Query real database for diseases
        diseases = []
        alerts = []
        try:
            import psycopg2
            from psycopg2.extras import RealDictCursor
            from urllib.parse import urlparse
            
            # Use environment variable or fallback to default EasyHealth local DB
            db_url = os.environ.get('DATABASE_URL', 'postgresql://postgres:postgres@localhost:5432/postgres')
            
            conn = psycopg2.connect(db_url)
            cur = conn.cursor(cursor_factory=RealDictCursor)
            
            # Safe interval injection for PostgreSQL
            cur.execute(f"""
                SELECT primary_condition as condition, COUNT(*) as count 
                FROM anonymized_diagnoses 
                WHERE created_at >= NOW() - INTERVAL '{days} days'
                GROUP BY primary_condition 
                ORDER BY count DESC 
                LIMIT 10
            """)
            
            db_rows = cur.fetchall()
            cur.close()
            conn.close()
            
            for row in db_rows:
                diseases.append({'condition': row['condition'], 'count': row['count']})
                
                # Epidemic alert logic (if any disease has >= 5 cases in the period)
                if row['count'] >= 5:
                    alerts.append({
                        'type': 'epidemic_alert',
                        'message': f"Alerte Épidémie : {row['condition']} détectée {row['count']} fois sur {days} jours.",
                        'severity': 'high'
                    })
                    
        except ImportError:
            app.logger.warning("psycopg2 not installed. Using fallback data.")
        except Exception as db_err:
            app.logger.error(f"Database error while fetching anonymized_diagnoses: {db_err}")

        # If DB is empty or failed, use some fallback data to ensure UI doesn't break
        if not diseases:
            diseases = [
                {'condition': 'Grippe', 'count': 0},
                {'condition': 'COVID-19', 'count': 0},
            ]

        return jsonify({
            'diseases': diseases,
            'alerts': alerts,
            'period_days': days,
        })
    except Exception as e:
        app.logger.exception(e)
        return jsonify({'error': str(e)}), 500


# ============== STARTUP ==============

if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO)
    load_ai_model()
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)
