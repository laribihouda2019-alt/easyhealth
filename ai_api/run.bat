@echo off
cd /d "%~dp0"
if not exist "doctor_recommendation_model.pkl" (
  echo Creating dummy model...
  python create_dummy_model.py
)
echo Starting AI API on port 5000...
python app.py
