import 'dart:convert';
import 'package:http/http.dart' as http;

class OnboardingApi {
  static const String baseUrl = "http://localhost:5000";
  // static const String baseUrl = "http://10.0.2.2:5000";

  static Future<Map<String, dynamic>> savePatientProfile({
    required String userId,
    required String guardianName,
    required String guardianPhone,
    required String guardianRelation,
    required double height,
    required double weight,
    required DateTime diagnosisDate,
    required bool usesRapidInsulin,
    required bool usesBasalInsulin,
    required bool usesMixedInsulin,
    required bool usesPump,
    required bool usesPills,
    required bool usesOtherTreatment,
    required String otherTreatmentName,
    required String managementType,
    double? breakfastDose,
    double? lunchDose,
    double? dinnerDose,
    double? lantusDose,
    required String correctionFactor,
    required String carbRatio,
    required bool hasFoodAllergy,
    required String allergyDetails,
  }) async {
    final url = Uri.parse("$baseUrl/api/patient/save-profile");

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userId": userId,
        "guardianName": guardianName,
        "guardianPhone": guardianPhone,
        "guardianRelation": guardianRelation,
        "height": height,
        "weight": weight,
        "diagnosisDate": diagnosisDate.toIso8601String(),
        "usesRapidInsulin": usesRapidInsulin,
        "usesBasalInsulin": usesBasalInsulin,
        "usesMixedInsulin": usesMixedInsulin,
        "usesPump": usesPump,
        "usesPills": usesPills,
        "usesOtherTreatment": usesOtherTreatment,
        "otherTreatmentName": otherTreatmentName,
        "managementType": managementType,
        "breakfastDose": breakfastDose,
        "lunchDose": lunchDose,
        "dinnerDose": dinnerDose,
        "lantusDose": lantusDose,
        "correctionFactor": correctionFactor,
        "carbRatio": carbRatio,
        "hasFoodAllergy": hasFoodAllergy,
        "allergyDetails": allergyDetails,
      }),
    );

    final data = jsonDecode(res.body);

    if (res.statusCode == 200 || res.statusCode == 201) {
      return data;
    }

    throw Exception(data["message"] ?? "Failed to save patient profile");
  }

  static Future<Map<String, dynamic>?> findPatientByEmail({
    required String email,
    required DateTime birthDate,
  }) async {
    final url = Uri.parse("$baseUrl/api/family/find-patient");

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email.trim().toLowerCase(),
        "birthDate": birthDate.toIso8601String(),
      }),
    );

    final data = jsonDecode(res.body);

    if (res.statusCode == 200) {
      return data["patient"];
    }

    if (res.statusCode == 404) {
      return null;
    }

    throw Exception(data["message"] ?? "Failed to find patient");
  }

  static Future<Map<String, dynamic>> saveParentProfile({
    required String userId,
    required String linkedPatientId,
    required String parentName,
    required String relationship,
    required String phone,
  }) async {
    final url = Uri.parse("$baseUrl/api/family/save-profile");

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userId": userId,
        "linkedPatientId": linkedPatientId,
        "parentName": parentName,
        "relationship": relationship,
        "phone": phone,
      }),
    );

    final data = jsonDecode(res.body);

    if (res.statusCode == 200 || res.statusCode == 201) {
      return data;
    }

    throw Exception(data["message"] ?? "Failed to save parent profile");
  }

  static Future<Map<String, dynamic>> saveDoctorProfile({
    required String userId,
    required String fullName,
    required String phone,
    required String workplace,
    required String specialty,
    required String otherSpecialty,
    required int yearsOfExperience,
    required bool ageChildren,
    required bool ageAdolescents,
    required bool ageAdults,
    required bool ageAllAges,
    required String treatsType1,
    required String professionalProofName,
    required String cvFileName,
    required String patientConnectionMethod,
    required bool notifyHighGlucose,
    required bool notifyLowGlucose,
    required bool notifyMissedLogs,
    required bool notifyConsultRequests,
  }) async {
    final url = Uri.parse("$baseUrl/api/doctor/save-profile");

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userId": userId,
        "fullName": fullName,
        "phone": phone,
        "workplace": workplace,
        "specialty": specialty,
        "otherSpecialty": otherSpecialty,
        "yearsOfExperience": yearsOfExperience,
        "ageChildren": ageChildren,
        "ageAdolescents": ageAdolescents,
        "ageAdults": ageAdults,
        "ageAllAges": ageAllAges,
        "treatsType1": treatsType1,
        "professionalProofName": professionalProofName,
        "cvFileName": cvFileName,
        "patientConnectionMethod": patientConnectionMethod,
        "notifyHighGlucose": notifyHighGlucose,
        "notifyLowGlucose": notifyLowGlucose,
        "notifyMissedLogs": notifyMissedLogs,
        "notifyConsultRequests": notifyConsultRequests,
      }),
    );

    final data = jsonDecode(res.body);

    if (res.statusCode == 200 || res.statusCode == 201) {
      return data;
    }

    throw Exception(data["message"] ?? "Failed to save doctor profile");
  }

  static Future<Map<String, dynamic>> saveNutritionistProfile({
    required String userId,
    required String fullName,
    required String phone,
    required String workplace,
    required String specialty,
    required String otherSpecialty,
    required int yearsOfExperience,
    required bool ageChildren,
    required bool ageAdolescents,
    required bool ageAdults,
    required bool ageAllAges,
    required String hasType1Experience,
    required String planningStyle,
    required String otherPlanningStyle,
    required String professionalProofName,
    required String cvFileName,
    required String patientConnectionMethod,
    required bool notifyAfterMealHighs,
    required bool notifyNutritionRequests,
    required bool notifyMealPlanFollowUp,
    required bool notifyFoodAllergyAlerts,
  }) async {
    final url = Uri.parse("$baseUrl/api/nutritionist/save-profile");

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userId": userId,
        "fullName": fullName,
        "phone": phone,
        "workplace": workplace,
        "specialty": specialty,
        "otherSpecialty": otherSpecialty,
        "yearsOfExperience": yearsOfExperience,
        "ageChildren": ageChildren,
        "ageAdolescents": ageAdolescents,
        "ageAdults": ageAdults,
        "ageAllAges": ageAllAges,
        "hasType1Experience": hasType1Experience,
        "planningStyle": planningStyle,
        "otherPlanningStyle": otherPlanningStyle,
        "professionalProofName": professionalProofName,
        "cvFileName": cvFileName,
        "patientConnectionMethod": patientConnectionMethod,
        "notifyAfterMealHighs": notifyAfterMealHighs,
        "notifyNutritionRequests": notifyNutritionRequests,
        "notifyMealPlanFollowUp": notifyMealPlanFollowUp,
        "notifyFoodAllergyAlerts": notifyFoodAllergyAlerts,
      }),
    );

    final data = jsonDecode(res.body);

    if (res.statusCode == 200 || res.statusCode == 201) {
      return data;
    }

    throw Exception(data["message"] ?? "Failed to save nutritionist profile");
  }
}
