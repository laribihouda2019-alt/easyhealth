# Intégration IA - EasyHealth

## Structure

```
ai_api/
├── app.py                    # API Flask
├── requirements.txt
├── create_dummy_model.py     # Crée un modèle si vos .pkl sont absents
├── doctor_recommendation_model.pkl  # Votre modèle (ou généré)
├── tfidf_vectorizer.pkl      # Votre vectorizer (ou généré)
├── run.bat                   # Lance l'API
└── README.md
```

## Routes API

| Route | Méthode | Description |
|-------|---------|-------------|
| `/predict` | POST | Recommandation médecin selon symptômes |
| `/admin/check_documents` | POST | Vérification documents médecins/pharmacies/labs |
| `/medication/reminders` | POST | Rappels de médicaments |
| `/admin/frequent_diseases` | GET | Maladies fréquentes - alertes admin |
| `/health` | GET | Santé de l'API |

## Lancer l'API

```bash
cd ai_api
pip install -r requirements.txt
# Si vos .pkl n'existent pas:
python create_dummy_model.py
# Démarrer:
python app.py
```

L'API écoute sur `http://localhost:5000`.

## Exposer avec ngrok

```bash
ngrok http 5000
```

Copiez l'URL (ex: `https://xxx.ngrok-free.dev`) dans:
`fronten/lib/config/api_config.dart` → `aiBaseUrl`

## Flutter - Utilisation

- **Patient** : Dashboard → "Recommandation IA - Médecin" → saisir symptômes
- **Admin** : Dashboard → "Statistiques IA - Maladies fréquentes"

## Remplacer par votre modèle

Placez vos fichiers dans `ai_api/`:
- `doctor_recommendation_model.pkl`
- `tfidf_vectorizer.pkl`

L'API les charge au démarrage. Sinon, un fallback par mots-clés est utilisé.
