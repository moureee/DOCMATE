const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const OpenAI = require("openai");

admin.initializeApp();

const openaiApiKey = defineSecret("OPENAI_API_KEY");

exports.aiSymptomCheck = onCall(
  {
    secrets: [openaiApiKey],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Please login first.");
    }

    const symptoms = request.data.symptoms || "";
    const bmi = request.data.bmi || "Not provided";

    if (symptoms.toString().trim().length < 3) {
      throw new HttpsError(
        "invalid-argument",
        "Please enter symptoms properly."
      );
    }

    const doctorsSnapshot = await admin.firestore().collection("doctors").get();

    const doctors = [];

    doctorsSnapshot.forEach((doc) => {
      const data = doc.data();

      const approved =
        data.approved === true ||
        data.isApproved === true ||
        data.status === "approved";

      if (approved) {
        doctors.push({
          name: data.name || data.fullName || data.doctorName || "Doctor",
          specialty: data.specialty || data.department || "General",
          rating: data.rating || 4.5,
          available: data.available || data.availability || "Availability not set",
        });
      }
    });

    const doctorsText = doctors
      .map((doctor) => {
        return `Doctor: ${doctor.name}, Specialty: ${doctor.specialty}, Rating: ${doctor.rating}, Availability: ${doctor.available}`;
      })
      .join("\n");

    const client = new OpenAI({
      apiKey: openaiApiKey.value(),
    });

    const prompt = `
You are an AI healthcare assistant for a university demo app called DocMate.

Important rules:
- Do not give a final medical diagnosis.
- Suggest a suitable department.
- Suggest a doctor only from the available doctor list.
- If no suitable doctor exists, say "Not available".
- Give simple health suggestions.
- If symptoms sound urgent, recommend emergency support.
- Return ONLY valid JSON. No markdown.

Patient symptoms:
${symptoms}

Patient BMI:
${bmi}

Available doctors:
${doctorsText || "No approved doctors available"}

Return JSON only in this format:
{
  "department": "department name",
  "suggestedDoctor": "doctor name or Not available",
  "urgency": "Low / Medium / High / Emergency",
  "reason": "short reason",
  "healthSuggestion": "short suggestion",
  "warning": "This is not a medical diagnosis. Please consult a doctor."
}
`;

    const response = await client.responses.create({
      model: "gpt-4o-mini",
      input: prompt,
    });

    const aiText = response.output_text;

    try {
      const result = JSON.parse(aiText);

      return {
        success: true,
        result: result,
      };
    } catch (error) {
      return {
        success: true,
        result: {
          department: "General Medicine",
          suggestedDoctor: "Not available",
          urgency: "Medium",
          reason: "AI response format issue.",
          healthSuggestion: aiText,
          warning: "This is not a medical diagnosis. Please consult a doctor.",
        },
      };
    }
  }
);