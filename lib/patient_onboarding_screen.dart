import 'package:flutter/material.dart';
import 'services/onboarding_api.dart';

class PatientOnboardingScreen extends StatefulWidget {
  final String userId;
  final String firstName;
  final String lastName;
  final String email;
  final DateTime birthDate;

  const PatientOnboardingScreen({
    super.key,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.birthDate,
  });

  @override
  State<PatientOnboardingScreen> createState() =>
      _PatientOnboardingScreenState();
}

class _PatientOnboardingScreenState extends State<PatientOnboardingScreen> {
  int currentStep = 0;

  // ---------------- Guardian ----------------
  final guardianNameController = TextEditingController();
  final guardianPhoneController = TextEditingController();
  String guardianRelation = "Mother";

  // ---------------- Patient Info ----------------
  final heightController = TextEditingController();
  final weightController = TextEditingController();
  final diagnosisDateController = TextEditingController();

  // ---------------- Treatment ----------------
  bool usesRapidInsulin = false;
  bool usesBasalInsulin = false;
  bool usesMixedInsulin = false;
  bool usesPump = false;
  bool usesPills = false;
  bool usesOtherTreatment = false;

  final otherTreatmentNameController = TextEditingController();

  // ---------------- Management ----------------
  String managementType = "Carb Counting";

  final breakfastDoseController = TextEditingController();
  final lunchDoseController = TextEditingController();
  final dinnerDoseController = TextEditingController();
  final lantusDoseController = TextEditingController();
  final correctionFactorController = TextEditingController();
  final carbRatioController = TextEditingController();

  // ---------------- Allergy ----------------
  bool hasFoodAllergy = false;
  final allergyDetailsController = TextEditingController();

  bool get isChild {
    final age = _calculateAge(widget.birthDate);
    return age <= 12;
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  int get totalSteps => isChild ? 6 : 5;

  @override
  void dispose() {
    guardianNameController.dispose();
    guardianPhoneController.dispose();

    heightController.dispose();
    weightController.dispose();
    diagnosisDateController.dispose();

    otherTreatmentNameController.dispose();

    breakfastDoseController.dispose();
    lunchDoseController.dispose();
    dinnerDoseController.dispose();
    lantusDoseController.dispose();
    correctionFactorController.dispose();
    carbRatioController.dispose();

    allergyDetailsController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _nextStep() async {
    if (!_validateStep()) return;

    if (currentStep < totalSteps - 1) {
      setState(() => currentStep++);
    } else {
      await _submitData();
    }
  }

  void _previousStep() {
    if (currentStep > 0) {
      setState(() => currentStep--);
    }
  }

  bool _validateStep() {
    if (isChild && currentStep == 0) {
      if (guardianNameController.text.trim().isEmpty ||
          guardianPhoneController.text.trim().isEmpty) {
        _showSnack("Please fill guardian information");
        return false;
      }
    }

    final patientInfoStep = isChild ? 1 : 0;
    if (currentStep == patientInfoStep) {
      if (heightController.text.trim().isEmpty ||
          weightController.text.trim().isEmpty ||
          diagnosisDateController.text.trim().isEmpty) {
        _showSnack("Please complete patient information");
        return false;
      }
    }

    final treatmentStep = isChild ? 2 : 1;
    if (currentStep == treatmentStep) {
      if (!usesRapidInsulin &&
          !usesBasalInsulin &&
          !usesMixedInsulin &&
          !usesPump &&
          !usesPills &&
          !usesOtherTreatment) {
        _showSnack("Please select at least one treatment type");
        return false;
      }

      if (usesOtherTreatment &&
          otherTreatmentNameController.text.trim().isEmpty) {
        _showSnack("Please enter the other treatment name");
        return false;
      }
    }

    final managementDetailsStep = isChild ? 4 : 3;
    if (currentStep == managementDetailsStep) {
      if (managementType == "Fixed Doses") {
        if (breakfastDoseController.text.trim().isEmpty ||
            lunchDoseController.text.trim().isEmpty ||
            dinnerDoseController.text.trim().isEmpty ||
            lantusDoseController.text.trim().isEmpty ||
            correctionFactorController.text.trim().isEmpty) {
          _showSnack("Please complete the fixed dose details");
          return false;
        }
      }

      if (managementType == "Carb Counting") {
        if (carbRatioController.text.trim().isEmpty ||
            lantusDoseController.text.trim().isEmpty ||
            correctionFactorController.text.trim().isEmpty) {
          _showSnack("Please complete the carb counting details");
          return false;
        }
      }
    }

    final allergyStep = totalSteps - 1;
    if (currentStep == allergyStep && hasFoodAllergy) {
      if (allergyDetailsController.text.trim().isEmpty) {
        _showSnack("Please enter allergy details");
        return false;
      }
    }

    return true;
  }

  Future<void> _submitData() async {
    try {
      final diagnosisDate = DateTime.parse(diagnosisDateController.text.trim());

      double? breakfastDose;
      double? lunchDose;
      double? dinnerDose;
      double? lantusDose;

      if (breakfastDoseController.text.trim().isNotEmpty) {
        breakfastDose = double.tryParse(breakfastDoseController.text.trim());
      }

      if (lunchDoseController.text.trim().isNotEmpty) {
        lunchDose = double.tryParse(lunchDoseController.text.trim());
      }

      if (dinnerDoseController.text.trim().isNotEmpty) {
        dinnerDose = double.tryParse(dinnerDoseController.text.trim());
      }

      if (lantusDoseController.text.trim().isNotEmpty) {
        lantusDose = double.tryParse(lantusDoseController.text.trim());
      }

      await OnboardingApi.savePatientProfile(
        userId: widget.userId,
        guardianName: isChild ? guardianNameController.text.trim() : "",
        guardianPhone: isChild ? guardianPhoneController.text.trim() : "",
        guardianRelation: isChild ? guardianRelation : "",
        height: double.parse(heightController.text.trim()),
        weight: double.parse(weightController.text.trim()),
        diagnosisDate: diagnosisDate,
        usesRapidInsulin: usesRapidInsulin,
        usesBasalInsulin: usesBasalInsulin,
        usesMixedInsulin: usesMixedInsulin,
        usesPump: usesPump,
        usesPills: usesPills,
        usesOtherTreatment: usesOtherTreatment,
        otherTreatmentName: otherTreatmentNameController.text.trim(),
        managementType: managementType,
        breakfastDose: breakfastDose,
        lunchDose: lunchDose,
        dinnerDose: dinnerDose,
        lantusDose: lantusDose,
        correctionFactor: correctionFactorController.text.trim(),
        carbRatio: carbRatioController.text.trim(),
        hasFoodAllergy: hasFoodAllergy,
        allergyDetails: allergyDetailsController.text.trim(),
      );

      _showSnack("Patient profile saved successfully ✅");

      if (!mounted) return;

      // لاحقًا وديه على الهوم
      // Navigator.pushReplacement(...);
    } catch (e) {
      _showSnack(e.toString().replaceAll("Exception: ", ""));
    }
  }

  Widget _buildCurrentStep() {
    if (isChild) {
      switch (currentStep) {
        case 0:
          return _guardianStep();
        case 1:
          return _patientInfoStep();
        case 2:
          return _treatmentStep();
        case 3:
          return _managementTypeStep();
        case 4:
          return _managementDetailsStep();
        case 5:
          return _allergyStep();
        default:
          return const SizedBox.shrink();
      }
    } else {
      switch (currentStep) {
        case 0:
          return _patientInfoStep();
        case 1:
          return _treatmentStep();
        case 2:
          return _managementTypeStep();
        case 3:
          return _managementDetailsStep();
        case 4:
          return _allergyStep();
        default:
          return const SizedBox.shrink();
      }
    }
  }

  String _stepTitle() {
    if (isChild) {
      switch (currentStep) {
        case 0:
          return "Guardian Information";
        case 1:
          return "Patient Information";
        case 2:
          return "Treatment & Medications";
        case 3:
          return "Diabetes Management";
        case 4:
          return "Management Details";
        case 5:
          return "Food Allergy";
        default:
          return "";
      }
    } else {
      switch (currentStep) {
        case 0:
          return "Patient Information";
        case 1:
          return "Treatment & Medications";
        case 2:
          return "Diabetes Management";
        case 3:
          return "Management Details";
        case 4:
          return "Food Allergy";
        default:
          return "";
      }
    }
  }

  String _stepImagePath() {
    if (isChild) {
      switch (currentStep) {
        case 0:
          return 'lib/assets/images/step_guardian.png';
        case 1:
          return 'lib/assets/images/step_patient.png';
        case 2:
          return 'lib/assets/images/step_insulin.png';
        case 3:
          return 'lib/assets/images/step_management.png';
        case 4:
          return 'lib/assets/images/step_management.png';
        case 5:
          return 'lib/assets/images/step_allergy.png';
        default:
          return 'lib/assets/images/step_patient.png';
      }
    } else {
      switch (currentStep) {
        case 0:
          return 'lib/assets/images/step_patient.png';
        case 1:
          return 'lib/assets/images/step_insulin.png';
        case 2:
          return 'lib/assets/images/step_management.png';
        case 3:
          return 'lib/assets/images/step_management.png';
        case 4:
          return 'lib/assets/images/step_allergy.png';
        default:
          return 'lib/assets/images/step_patient.png';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xffD2EAFE),
              Color(0xffBFE0FB),
              Color(0xffA9D3F6),
              Color(0xff93C5EF),
              Color(0xff7FB8E8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 18,
                ),
                child: const Text(
                  "Patient Onboarding",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff1565C0),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.96),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x18000000),
                              blurRadius: 22,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth >= 760;

                            return isWide
                                ? Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: _sideCharacterPanel(),
                                      ),
                                      const SizedBox(width: 28),
                                      Expanded(
                                        flex: 5,
                                        child: _mainFormPanel(),
                                      ),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      _topCharacterPanel(),
                                      const SizedBox(height: 20),
                                      _mainFormPanel(),
                                    ],
                                  );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sideCharacterPanel() {
    return Column(
      children: [
        Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xffF3FAFF),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Center(
            child: Image.asset(
              _stepImagePath(),
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.image_outlined,
                size: 90,
                color: Color(0xff90CAF9),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _stepTitle(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xff1565C0),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Step ${currentStep + 1} of $totalSteps",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _topCharacterPanel() {
    return Column(
      children: [
        Container(
          height: 140,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xffF3FAFF),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Center(
            child: Image.asset(
              _stepImagePath(),
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.image_outlined,
                size: 70,
                color: Color(0xff90CAF9),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _mainFormPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _stepTitle(),
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color(0xff1565C0),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Step ${currentStep + 1} of $totalSteps",
          style: const TextStyle(fontSize: 15, color: Colors.black54),
        ),
        const SizedBox(height: 24),
        _buildCurrentStep(),
        const SizedBox(height: 28),
        Row(
          children: [
            if (currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousStep,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    side: const BorderSide(color: Color(0xff8E8E8E)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text("Previous", style: TextStyle(fontSize: 17)),
                ),
              ),
            if (currentStep > 0) const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff42A5F5),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  currentStep == totalSteps - 1 ? "Finish" : "Next",
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _guardianStep() {
    return Column(
      children: [
        _textField(
          controller: guardianNameController,
          label: "Guardian Name",
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          value: guardianRelation,
          decoration: _inputDecoration(
            label: "Relation",
            icon: Icons.family_restroom,
          ),
          items: const [
            DropdownMenuItem(value: "Mother", child: Text("Mother")),
            DropdownMenuItem(value: "Father", child: Text("Father")),
            DropdownMenuItem(value: "Sibling", child: Text("Sibling")),
            DropdownMenuItem(value: "Relative", child: Text("Relative")),
            DropdownMenuItem(value: "Caregiver", child: Text("Caregiver")),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() => guardianRelation = value);
          },
        ),
        const SizedBox(height: 14),
        _textField(
          controller: guardianPhoneController,
          label: "Guardian Phone Number",
          icon: Icons.phone_outlined,
        ),
      ],
    );
  }

  Widget _patientInfoStep() {
    return Column(
      children: [
        _textField(
          controller: heightController,
          label: "Height (cm)",
          icon: Icons.height,
        ),
        const SizedBox(height: 14),
        _textField(
          controller: weightController,
          label: "Weight (kg)",
          icon: Icons.monitor_weight_outlined,
        ),
        const SizedBox(height: 14),
        _textField(
          controller: diagnosisDateController,
          label: "Diagnosis Date (YYYY-MM-DD)",
          icon: Icons.calendar_month_outlined,
          hint: "Example: 2022-01-01",
        ),
      ],
    );
  }

  Widget _treatmentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "What types of treatment do you use?",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "You can select more than one option",
          style: TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _multiTreatmentOptionCard(
              title: "Rapid",
              imagePath: "lib/assets/images/rapid_icon.png",
              selected: usesRapidInsulin,
              onTap: () => setState(() => usesRapidInsulin = !usesRapidInsulin),
            ),
            _multiTreatmentOptionCard(
              title: "Basal",
              imagePath: "lib/assets/images/basal_icon.png",
              selected: usesBasalInsulin,
              onTap: () => setState(() => usesBasalInsulin = !usesBasalInsulin),
            ),
            _multiTreatmentOptionCard(
              title: "Mixed",
              imagePath: "lib/assets/images/mixed_icon.png",
              selected: usesMixedInsulin,
              onTap: () => setState(() => usesMixedInsulin = !usesMixedInsulin),
            ),
            _multiTreatmentOptionCard(
              title: "Pump",
              imagePath: "lib/assets/images/pump_icon.png",
              selected: usesPump,
              onTap: () => setState(() => usesPump = !usesPump),
            ),
            _multiTreatmentOptionCard(
              title: "Pills",
              imagePath: "lib/assets/images/pills_icon.png",
              selected: usesPills,
              onTap: () => setState(() => usesPills = !usesPills),
            ),
            _multiTreatmentOptionCard(
              title: "Other",
              imagePath: "lib/assets/images/other_icon.png",
              selected: usesOtherTreatment,
              onTap: () =>
                  setState(() => usesOtherTreatment = !usesOtherTreatment),
            ),
          ],
        ),
        if (usesOtherTreatment) ...[
          const SizedBox(height: 16),
          _textField(
            controller: otherTreatmentNameController,
            label: "Other treatment name",
            icon: Icons.edit_outlined,
            hint: "Enter the treatment name",
          ),
        ],
      ],
    );
  }

  Widget _managementTypeStep() {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: managementType,
          decoration: _inputDecoration(
            label: "How do you manage diabetes?",
            icon: Icons.settings_accessibility_outlined,
          ),
          items: const [
            DropdownMenuItem(
              value: "Carb Counting",
              child: Text("Carb Counting"),
            ),
            DropdownMenuItem(value: "Fixed Doses", child: Text("Fixed Doses")),
            DropdownMenuItem(
              value: "I Don't Know",
              child: Text("I Don't Know"),
            ),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() => managementType = value);
          },
        ),
      ],
    );
  }

  Widget _managementDetailsStep() {
    if (managementType == "Fixed Doses") {
      return Column(
        children: [
          _textField(
            controller: breakfastDoseController,
            label: "Breakfast Dose",
            icon: Icons.breakfast_dining_outlined,
          ),
          const SizedBox(height: 14),
          _textField(
            controller: lunchDoseController,
            label: "Lunch Dose",
            icon: Icons.lunch_dining_outlined,
          ),
          const SizedBox(height: 14),
          _textField(
            controller: dinnerDoseController,
            label: "Dinner Dose",
            icon: Icons.dinner_dining_outlined,
          ),
          const SizedBox(height: 14),
          _textField(
            controller: lantusDoseController,
            label: "Lantus / Basal Dose",
            icon: Icons.medication_outlined,
          ),
          const SizedBox(height: 14),
          _textField(
            controller: correctionFactorController,
            label: "Correction Factor (e.g. 1 unit لكل 50)",
            icon: Icons.calculate_outlined,
          ),
        ],
      );
    }

    if (managementType == "Carb Counting") {
      return Column(
        children: [
          _textField(
            controller: carbRatioController,
            label: "Carb Ratio (e.g. 1 unit لكل 10g carbs)",
            icon: Icons.calculate_outlined,
          ),
          const SizedBox(height: 14),
          _textField(
            controller: lantusDoseController,
            label: "Lantus / Basal Dose",
            icon: Icons.medication_outlined,
          ),
          const SizedBox(height: 14),
          _textField(
            controller: correctionFactorController,
            label: "Correction Factor (e.g. 1 unit لكل 50)",
            icon: Icons.monitor_heart_outlined,
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xffF8FCFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffBBDEFB)),
      ),
      child: const Text(
        "No additional details are required for this option.",
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _allergyStep() {
    return Column(
      children: [
        SwitchListTile(
          value: hasFoodAllergy,
          onChanged: (value) {
            setState(() => hasFoodAllergy = value);
          },
          title: const Text("Do you have food allergies?"),
          activeColor: const Color(0xff42A5F5),
        ),
        if (hasFoodAllergy) ...[
          const SizedBox(height: 12),
          _textField(
            controller: allergyDetailsController,
            label: "Allergy Details",
            icon: Icons.warning_amber_outlined,
            hint: "Example: gluten, nuts, milk",
          ),
        ],
      ],
    );
  }

  Widget _multiTreatmentOptionCard({
    required String title,
    required String imagePath,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 148,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xffE3F2FD) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? const Color(0xff42A5F5) : const Color(0xffBBDEFB),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 64,
              width: 64,
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  selected ? Icons.check_circle : Icons.medication_outlined,
                  size: 32,
                  color: selected
                      ? const Color(0xff42A5F5)
                      : const Color(0xff90CAF9),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            if (selected) ...[
              const SizedBox(height: 6),
              const Icon(
                Icons.check_circle,
                size: 18,
                color: Color(0xff42A5F5),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return TextField(
      controller: controller,
      decoration: _inputDecoration(label: label, icon: icon, hint: hint),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xff1565C0)),
      filled: true,
      fillColor: const Color(0xffF8FCFF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xffBBDEFB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xffBBDEFB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xff42A5F5), width: 1.6),
      ),
    );
  }
}
