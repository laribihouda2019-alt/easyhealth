"""
Create dummy doctor_recommendation_model.pkl and tfidf_vectorizer.pkl if not present.
Run: python create_dummy_model.py
"""
from pathlib import Path

try:
    from sklearn.ensemble import RandomForestClassifier
    from sklearn.feature_extraction.text import TfidfVectorizer
    import joblib
except ImportError:
    print("Install: pip install scikit-learn joblib")
    exit(1)

BASE = Path(__file__).resolve().parent
MODEL_PATH = BASE / "doctor_recommendation_model.pkl"
VEC_PATH = BASE / "tfidf_vectorizer.pkl"

# Simple training data: symptoms -> specialty
SAMPLES = [
    ("mal de tête migraine vertige", "Neurologue"),
    ("fièvre toux fatigue", "Médecine générale"),
    ("douleur thoracique coeur", "Cardiologue"),
    ("mal au ventre nausée", "Gastro-entérologue"),
    ("mal de dos douleur articulaire", "Orthopédiste"),
    ("eczéma problème peau", "Dermatologue"),
    ("insomnie anxiété stress", "Psychiatre"),
    ("yeux vision", "Ophtalmologue"),
    ("oreille gorge", "ORL"),
    ("allergie respiration", "Allergologue"),
]

X_text = [s[0] for s in SAMPLES]
y = [s[1] for s in SAMPLES]

vec = TfidfVectorizer()
X = vec.fit_transform(X_text)
clf = RandomForestClassifier(n_estimators=10)
clf.fit(X, y)

joblib.dump(clf, MODEL_PATH)
joblib.dump(vec, VEC_PATH)
print(f"Created {MODEL_PATH} and {VEC_PATH}")
