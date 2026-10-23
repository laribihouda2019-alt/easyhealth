# EasyHealth AI API

Flask API pour les recommandations IA (médecin, documents, rappels, maladies fréquentes).

## Installation

```bash
cd ai_api
pip install -r requirements.txt
```

## Modèle IA

Placez vos fichiers dans `ai_api/` :
- `doctor_recommendation_model.pkl`
- `tfidf_vectorizer.pkl`

Si absents, exécutez pour créer un modèle de démo :
```bash
python create_dummy_model.py
```

## Lancement

```bash
python app.py
```

API disponible sur `http://localhost:5000`

## Exposer avec ngrok

```bash
ngrok http 5000
```

Mettez à jour l'URL dans `fronten/lib/config/api_config.dart` (aiBaseUrl).

## Routes

| Route | Méthode | Description |
|-------|---------|-------------|
| /predict | POST | Recommandation médecin selon symptômes |
| /admin/check_documents | POST | Vérification documents médecins/pharmacies |
| /medication/reminders | POST | Rappels de médicaments |
| /admin/frequent_diseases | GET/POST | Maladies fréquentes - alertes admin |
