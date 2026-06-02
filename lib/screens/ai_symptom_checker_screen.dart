import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AiSymptomCheckerScreen extends StatefulWidget {
  const AiSymptomCheckerScreen({super.key});

  @override
  State<AiSymptomCheckerScreen> createState() => _AiSymptomCheckerScreenState();
}

class _AiSymptomCheckerScreenState extends State<AiSymptomCheckerScreen> {
  static const Color mainColor = Color(0xFF00DDB3);
  static const Color lightColor = Color(0xFFE8FFF8);

  final TextEditingController symptomsController = TextEditingController();

  bool isLoading = false;
  bool hasResult = false;

  String department = "";
  String urgency = "";
  String reason = "";
  String suggestion = "";
  String suggestedDoctor = "";
  String matchedKeywords = "";

  @override
  void dispose() {
    symptomsController.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> analyzeSymptoms() async {
    final symptoms = symptomsController.text.trim();

    if (symptoms.length < 3) {
      showMessage("Please describe your symptoms first");
      return;
    }

    setState(() {
      isLoading = true;
      hasResult = false;
    });

    try {
      final rulesSnapshot =
          await FirebaseFirestore.instance.collection("symptom_rules").get();

      if (rulesSnapshot.docs.isEmpty) {
        setState(() {
          isLoading = false;
          hasResult = false;
        });

        showMessage("No AI rules found. Admin must add symptom rules first.");
        return;
      }

      final bestRule = findBestRule(symptoms, rulesSnapshot.docs);

      if (bestRule == null) {
        final doctor = await findDoctorFromFirestore("General Medicine");

        setState(() {
          department = "General Medicine";
          urgency = "Low";
          reason =
              "No exact symptom rule matched. General Medicine is suggested for initial consultation.";
          suggestion = "Book a general consultation if symptoms continue.";
          suggestedDoctor = doctor;
          matchedKeywords = "No exact keyword match";
          hasResult = true;
          isLoading = false;
        });

        return;
      }

      final ruleData = bestRule.data();

      final selectedDepartment =
          ruleData["department"]?.toString() ?? "General Medicine";

      final doctor = await findDoctorFromFirestore(selectedDepartment);

      setState(() {
        department = selectedDepartment;
        urgency = ruleData["urgency"]?.toString() ?? "Medium";
        reason = ruleData["reason"]?.toString() ??
            "Based on your symptoms, $selectedDepartment is suitable for consultation.";
        suggestion = ruleData["suggestion"]?.toString() ??
            "Please consult a doctor for proper medical advice.";
        suggestedDoctor = doctor;
        matchedKeywords = getMatchedKeywords(symptoms, ruleData);
        hasResult = true;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Analyze symptoms error: $e");

      setState(() {
        isLoading = false;
      });

      showMessage("Could not analyze symptoms");
    }
  }

  QueryDocumentSnapshot<Map<String, dynamic>>? findBestRule(
    String symptoms,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> rules,
  ) {
    final symptomsText = symptoms.toLowerCase();

    QueryDocumentSnapshot<Map<String, dynamic>>? bestRule;
    int bestScore = 0;

    for (final rule in rules) {
      final data = rule.data();

      if (data["active"] == false) {
        continue;
      }

      final keywordsRaw = data["keywords"];

      if (keywordsRaw is! List) {
        continue;
      }

      int matchedKeywordCount = 0;

      for (final keyword in keywordsRaw) {
        final word = keyword.toString().toLowerCase().trim();

        if (word.isNotEmpty && symptomsText.contains(word)) {
          matchedKeywordCount++;
        }
      }

      final priority = data["priority"] is int ? data["priority"] as int : 0;
      final finalScore = matchedKeywordCount * 10 + priority;

      if (matchedKeywordCount > 0 && finalScore > bestScore) {
        bestScore = finalScore;
        bestRule = rule;
      }
    }

    return bestRule;
  }

  String getMatchedKeywords(String symptoms, Map<String, dynamic> ruleData) {
    final symptomsText = symptoms.toLowerCase();
    final keywordsRaw = ruleData["keywords"];

    if (keywordsRaw is! List) {
      return "Not found";
    }

    final matched = <String>[];

    for (final keyword in keywordsRaw) {
      final word = keyword.toString().toLowerCase().trim();

      if (word.isNotEmpty && symptomsText.contains(word)) {
        matched.add(keyword.toString());
      }
    }

    if (matched.isEmpty) {
      return "Not found";
    }

    return matched.join(", ");
  }

  Future<String> findDoctorFromFirestore(String dept) async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection("doctors").get();

      String bestDoctor = "No matching doctor available";
      double bestRating = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final approved = data["approved"] == true ||
            data["isApproved"] == true ||
            data["status"]?.toString().toLowerCase() == "approved";

        if (!approved) {
          continue;
        }

        final doctorName = data["name"]?.toString() ??
            data["fullName"]?.toString() ??
            data["doctorName"]?.toString() ??
            "Doctor";

        final specialty = data["specialty"]?.toString().toLowerCase() ??
            data["department"]?.toString().toLowerCase() ??
            "";

        final ratingValue =
            double.tryParse(data["rating"]?.toString() ?? "0") ?? 0;

        if (specialty.contains(dept.toLowerCase())) {
          if (ratingValue >= bestRating) {
            bestRating = ratingValue;
            bestDoctor = doctorName;
          }
        }
      }

      return bestDoctor;
    } catch (e) {
      debugPrint("Doctor search error: $e");
      return "Could not load doctor";
    }
  }

  Color urgencyColor() {
    final value = urgency.toLowerCase();

    if (value == "emergency") return Colors.red;
    if (value == "high") return Colors.deepOrange;
    if (value == "medium") return Colors.orange;

    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: mainColor,
        title: const Text("AI Symptom Checker"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildIntroCard(),
            const SizedBox(height: 18),
            buildInputCard(),
            const SizedBox(height: 18),
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              ),
            if (hasResult) buildResultCard(),
            const SizedBox(height: 18),
            buildRuleInfoCard(),
          ],
        ),
      ),
    );
  }

  Widget buildIntroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: mainColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.psychology, size: 42),
          SizedBox(height: 10),
          Text(
            "Smart Symptom Analysis",
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "DocMate uses Firebase symptom rules to suggest department, urgency, and doctor.",
            style: TextStyle(height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget buildInputCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          TextField(
            controller: symptomsController,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: "Describe your symptoms",
              hintText: "Example: fever, cough, headache...",
              filled: true,
              fillColor: lightColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : analyzeSymptoms,
              icon: const Icon(Icons.search),
              label: Text(isLoading ? "Analyzing..." : "Analyze Symptoms"),
              style: ElevatedButton.styleFrom(
                backgroundColor: mainColor,
                foregroundColor: Colors.black,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildResultCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: mainColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "AI Result",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          buildResultRow("Suggested Department", department),
          buildResultRow("Suggested Doctor", suggestedDoctor),
          buildUrgencyRow(),
          buildResultRow("Matched Keywords", matchedKeywords),
          buildResultRow("Reason", reason),
          buildResultRow("Health Suggestion", suggestion),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              "Warning: This is not a medical diagnosis. Please consult a doctor for proper treatment.",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildRuleInfoCard() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream:
          FirebaseFirestore.instance.collection("symptom_rules").snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: lightColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: mainColor.withOpacity(0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "AI Rule Engine",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Firestore rule documents: $count",
                style: const TextStyle(color: Colors.black87),
              ),
              const SizedBox(height: 8),
              const Text(
                "AI rules are controlled by admin. No demo rules are created from the patient side.",
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildResultRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildUrgencyRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Text(
            "Urgency: ",
            style: TextStyle(
              color: Colors.black54,
              fontSize: 13,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: urgencyColor().withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              urgency,
              style: TextStyle(
                color: urgencyColor(),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
