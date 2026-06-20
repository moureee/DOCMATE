import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';

import 'package:docmate/core/theme/app_theme.dart';

class AiSymptomCheckerScreen extends StatefulWidget {
  const AiSymptomCheckerScreen({super.key});

  @override
  State<AiSymptomCheckerScreen> createState() => _AiSymptomCheckerScreenState();
}

class _AiSymptomCheckerScreenState extends State<AiSymptomCheckerScreen> {
  final TextEditingController symptomController = TextEditingController();
  bool isLoading = false;
  String? aiResult;
  String? errorMessage;

  @override
  void dispose() {
    symptomController.dispose();
    super.dispose();
  }

  Future<void> generateGuidance() async {
    final symptoms = symptomController.text.trim();

    if (symptoms.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please describe the symptoms in a little more detail.'),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
      aiResult = null;
      errorMessage = null;
    });

    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-3.5-flash',
      );

      final prompt = '''
You are DocMate AI Health Guidance for a university healthcare appointment app.

A patient wrote these symptoms:
"""
$symptoms
"""

Respond in simple language using exactly these sections:
1. Possible Department:
2. Urgency Level: Routine / Moderate / Emergency
3. Suggested Next Step:
4. Questions to Ask the Patient:
5. Safety Note:

Rules:
- Do not claim to diagnose disease.
- Do not prescribe medicine or dosage.
- For severe symptoms such as chest pain, breathing difficulty, fainting, severe bleeding, stroke-like signs, or suicidal/self-harm risk, mark Emergency and advise immediate local emergency support or nearest hospital.
- Keep the answer under 180 words.
- Make the Safety Note say this is AI guidance only and not a medical diagnosis.
''';

      final response = await model.generateContent([
        Content.text(prompt),
      ]);

      final text = response.text?.trim();

      setState(() {
        aiResult = text == null || text.isEmpty
            ? 'No AI response was returned. Please try again.'
            : text;
      });
    } catch (error) {
      setState(() {
        errorMessage = 'AI Health Guidance could not connect right now. '
            'Check Firebase AI Logic setup, internet connection, and model access. '
            'Details: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void clearAll() {
    setState(() {
      symptomController.clear();
      aiResult = null;
      errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Health Guidance'),
        actions: [
          IconButton(
            tooltip: 'Clear',
            onPressed: clearAll,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          buildIntroCard(),
          const SizedBox(height: 18),
          const Text(
            'Describe Symptoms',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: symptomController,
            minLines: 5,
            maxLines: 8,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              hintText:
                  'Example: fever, cough, headache for 2 days, feeling weak...',
              alignLabelWithHint: true,
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 90),
                child: Icon(Icons.health_and_safety_outlined),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : generateGuidance,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(
                isLoading ? 'Getting AI Guidance...' : 'Get AI Guidance',
              ),
            ),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 18),
            buildMessageCard(
              icon: Icons.error_outline,
              title: 'Connection Issue',
              message: errorMessage!,
              danger: true,
            ),
          ],
          if (aiResult != null) ...[
            const SizedBox(height: 18),
            buildMessageCard(
              icon: Icons.smart_toy_outlined,
              title: 'Gemini AI Guidance',
              message: aiResult!,
            ),
          ],
          const SizedBox(height: 18),
          buildSafetyCard(),
        ],
      ),
    );
  }

  Widget buildIntroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome, size: 42),
          SizedBox(height: 10),
          Text(
            'Real AI Health Guidance',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Powered by Firebase AI Logic and Gemini. It suggests a suitable '
            'department, urgency level, and next step from typed symptoms.',
          ),
        ],
      ),
    );
  }

  Widget buildMessageCard({
    required IconData icon,
    required String title,
    required String message,
    bool danger = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: danger ? AppColors.danger : AppColors.primary,
          width: 1.3,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: danger ? AppColors.danger : AppColors.primaryDark,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SelectableText(
            message,
            style: const TextStyle(height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget buildSafetyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFC857)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Color(0xFF8A5A00)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'AI Health Guidance is educational support only. It is not a '
              'medical diagnosis. For urgent or severe symptoms, contact local '
              'emergency support or visit the nearest hospital immediately.',
              style: TextStyle(
                color: Color(0xFF5C3A00),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
