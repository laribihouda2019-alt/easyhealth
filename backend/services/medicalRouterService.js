const { GoogleGenerativeAI } = require("@google/generative-ai");
const axios = require("axios");

const medicalDatabase = {
  'Ophtalmologue': [
    'عيني تحرق', 'زغللة', 'ما نشوفش مليح', 'عيني حمراء', 'ضبابة', 'ألم العين', 'ضعف النظر', 'yeux rouges', 'vision floue', 'douleur oculaire'
  ],
  'Cardiologue': [
    'قلبي يخبط', 'ضيق النفس', 'فشلة في الصدر', 'سطر جيهة القلب', 'عييت', 'خفقان', 'ألم الصدر', 'palpitations', 'essoufflement', 'douleur thoracique', 'hypertension'
  ],
  'Dermatologue': [
    'حكة', 'حب في وجهي', 'بقع حمراء', 'قشرة', 'التواليل', 'لاكزيما', 'طفح جلدي', 'حب الشباب', 'démangeaisons', 'acné', 'taches sur la peau', 'éruption cutanée'
  ],
  'Orthopédiste': [
    'سطور في الركبة', 'ظهري مقسوم', 'رجلي توجع', 'كسر', 'مفاصلي يسطروا', 'ألم المفاصل', 'ألم الظهر', 'douleurs articulaires', 'mal de dos', 'fracture', 'rhumatisme'
  ],
  'Gastro-entérologue': [
    'كرشي توجع', 'المعدة تحرق', 'قايا', 'فوميسمو', 'ليكونستيباسيون', 'حموضة', 'إسهال', 'إمساك', 'douleur abdominale', 'brûlures d\'estomac', 'diarrhée', 'ballonnement'
  ],
  'ORL': [
    'وذني توجع', 'نيفي مسدود', 'قرجومتي تحرق', 'ما نسمعش مليح', 'الدوخة', 'التهاب الحلق', 'سيلان الأنف', 'mal d\'oreille', 'mal de gorge', 'nez bouché', 'vertiges'
  ],
  'Dentiste': [
    'ضرستي تسطر', 'لثتي تسيل بالدم', 'ريحة الفم', 'سوسة', 'تسوس', 'ألم الأسنان', 'mal de dents', 'gencives', 'carie', 'abcès'
  ],
  'Endocrinologue': [
    'السكر طالع', 'عطش بزاف', 'نشيان', 'الغدة الدرقية', 'لغود', 'عطش شديد', 'thyroïde', 'diabète', 'perte de poids'
  ],
  'Urologie & Chirurgie Urologique': [
    'سطر في الكلاوي', 'حريق البول', 'بروستات', 'ميكروب في البول', 'وجع الخواصر', 'ألم الكلى', 'التهاب المسالك البولية', 'Douleur rénale', 'infection urinaire', 'prostate', 'calculs rénaux'
  ]
};

const adviceDatabase = {
  'Ophtalmologue': 'Évitez de vous frotter les yeux et consultez rapidement pour un examen de la vue.',
  'Cardiologue': 'Reposez-vous immédiatement. Si la douleur persiste, contactez les urgences.',
  'Dermatologue': 'Évitez d\'appliquer des produits non testés et gardez la zone propre.',
  'Orthopédiste': 'Évitez les efforts physiques intenses. Appliquez de la glace si nécessaire.',
  'Gastro-entérologue': 'Hydratez-vous bien et adoptez un régime léger en attendant la consultation.',
  'ORL': 'Évitez l\'exposition au froid et ne mettez rien dans vos oreilles.',
  'Dentiste': 'Maintenez une bonne hygiène buccale et évitez les aliments trop chauds ou froids.',
  'Endocrinologue': 'Surveillez votre alimentation et notez vos symptômes pour le spécialiste.',
  'Urologie & Chirurgie Urologique': 'Buvez beaucoup d\'eau et consultez pour un test urinaire.'
};

/**
 * Normalizes text for better matching
 */
function normalizeText(text) {
  return text.toLowerCase().trim();
}

/**
 * Local Fallback Logic (Expert System)
 */
function fallbackAnalysis(symptomsDescription) {
  const normalizedSymptoms = normalizeText(symptomsDescription);
  
  let bestMatch = {
    specialty: 'Médecin Généraliste',
    advice: 'Veuillez consulter un médecin généraliste pour un premier diagnostic.',
    matchCount: 0
  };

  for (const [specialty, keywords] of Object.entries(medicalDatabase)) {
    let currentMatchCount = 0;
    for (const keyword of keywords) {
      if (normalizedSymptoms.includes(normalizeText(keyword))) {
        currentMatchCount++;
      }
    }

    if (currentMatchCount > bestMatch.matchCount) {
      bestMatch = {
        specialty,
        advice: adviceDatabase[specialty] || '',
        matchCount: currentMatchCount
      };
    }
  }

  return {
    specialty: bestMatch.specialty,
    advice: bestMatch.advice,
    source: 'AI (Simulation - Quota atteint)'
  };
}

/**
 * Primary Layer: Gemini AI - Universal Medical Assistant
 * Capable of: Conversational triage, Numerical analysis (Lab results), Medication info.
 */
async function analyzeSymptomsWithGemini(symptomsDescription) {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) throw new Error("GEMINI_API_KEY is not defined");

  const genAI = new GoogleGenerativeAI(apiKey);
  
  // Cleaned model list based on confirmed availability and higher free-tier quotas
  const modelsToTry = [
    "gemini-flash-lite-latest", 
    "gemini-flash-latest",
    "gemini-2.5-flash",
    "gemini-3-flash-preview"
  ]; 
  
  let lastError;

  for (const modelName of modelsToTry) {
    try {
      
      const model = genAI.getGenerativeModel({ 
        model: modelName,
        generationConfig: { responseMimeType: "application/json" }
      });

      const systemPrompt = `
        Tu es l'Expert Médical Virtuel d'EasyHealth. Réponds comme un médecin empathique.
        
        RÈGLES:
        1. Mix Français/Arabe Algérien (Derja).
        2. Analyse Glycémie (0.7-1.1 g/L normal) et Tension (12/8 normal).
        3. Infos médicaments + disclaimer obligatoire: "**La posologie doit être confirmée par un médecin.**"
        4. Identification de spécialité: ${Object.keys(medicalDatabase).join(", ")}.

        FORMAT: Markdown (Titres gras, listes).
        JSON Output: {"specialty": "...", "advice": "..."}
      `;

      const result = await model.generateContent([systemPrompt, `Patient: "${symptomsDescription}"`]);
      const response = await result.response;
      const text = response.text();
      const jsonStr = text.replace(/```json|```/g, "").trim();
      const parsed = JSON.parse(jsonStr);

      return {
        specialty: parsed.specialty || 'Médecin Généraliste',
        advice: parsed.advice || 'Veuillez consulter un médecin.',
        source: `AI (Gemini ${modelName})`
      };
    } catch (e) {
      lastError = e;
      
      // Special handling for quota to avoid long useless loops
      if (e.message.includes("429") || e.message.includes("Quota exceeded")) {
        
        continue; 
      }
      if (e.message.includes("404")) continue;
      break; 
    }
  }
  
  throw lastError;
}

/**
 * Main Routing Logic with Timeout and Fallback
 */
async function routeSymptoms(symptomsDescription) {
  try {
    // Create a promise that rejects after 25 seconds
    const timeoutPromise = new Promise((_, reject) =>
      setTimeout(() => reject(new Error('Timeout AI')), 25000)
    );

    // Race Gemini against the timeout
    const recommendation = await Promise.race([
      analyzeSymptomsWithGemini(symptomsDescription),
      timeoutPromise
    ]);

    return recommendation;
  } catch (error) {
    console.error('Gemini failed or timed out, falling back to expert system:', error.message);
    // Call the local expert system fallback
    return fallbackAnalysis(symptomsDescription);
  }
}

const preventiveDatabase = {
  'Grippe': 'InchaAllah tghaslo idikom b l ma o sabon, lbso bavette, o echrbo hwayj skhounin (ataye, tchina). Évitez les lieux bondés.',
  'Gastro': 'Echrbou el ma b l 3kel (SRO), o kolou l roz o tchina. Ghaslo idikom mlih qbel el makla.',
  'Bronchiolite': 'Ghaslo nif el bebé b l ma el melh (Physiol), o khlo el hwa yfout f el dar. Évitez de fumer à côté du bébé.',
  'Allergie': 'Eb3dou 3la el ghbar o el nawer. Ghaslo wjahkom mlih ki dkholo l l dar.',
  'Diarhée': 'Hydratation mliha, o kolou hwayj nasfine. Si ça persiste 2 jours, il faut voir un médecin.'
};

//Generate Preventive Advice using Gemini

async function generatePreventiveAdvice(symptom, region) {
  const apiKey = process.env.GEMINI_API_KEY;
  const prompt = `L'utilisateur est à ${region} où le symptôme "${symptom}" se propage actuellement. 
  Donne une liste brève et professionnelle de mesures préventives (3-5 points).
  Mélange le Français et l'Arabe Algérien (Derja) pour que ça soit proche des gens.
  Format: Markdown avec des titres en gras.`;

  try {
    if (!apiKey) throw new Error("No API Key");

    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({ model: "gemini-flash-lite-latest" });
    
    //Race Gemini against a 25-second timeout to avoid holding connections open
    const timeoutPromise = new Promise((_, reject) =>
      setTimeout(() => reject(new Error('Timeout_Gemini_AI')), 25000)
    );

    const result = await Promise.race([
      model.generateContent(prompt),
      timeoutPromise
    ]);
    
    const text = (await result.response).text();

    return { advice: text, source: 'Gemini AI' };
  } catch (error) {
    console.error('Gemini Advice Error:', error.message);
    throw new Error('Le service de conseil IA est temporairement indisponible (Temps d\'attente dépassé ou Quota atteint). Veuillez réessayer plus tard.');
  }
}

module.exports = {
  routeSymptoms,
  fallbackAnalysis,
  generatePreventiveAdvice
};

