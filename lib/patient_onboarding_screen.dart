import 'package:flutter/material.dart';
import 'services/onboarding_api.dart';
import 'patient_screen.dart';

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
  final guardianNameController = TextEditingController();
  final guardianPhoneController = TextEditingController();
  String guardianRelation = "Mother";

  final heightController = TextEditingController();
  final weightController = TextEditingController();
  final diagnosisDateController = TextEditingController();

  bool usesRapidInsulin = false;
  bool usesBasalInsulin = false;
  bool usesMixedInsulin = false;
  bool usesPump = false;
  bool usesPills = false;
  bool usesOtherTreatment = false;

  final otherTreatmentNameController = TextEditingController();

  String? managementType;

  final breakfastDoseController = TextEditingController();
  final lunchDoseController = TextEditingController();
  final dinnerDoseController = TextEditingController();
  final lantusDoseController = TextEditingController();
  final lantusTimeController = TextEditingController();
  final correctionFactorController = TextEditingController();
  final carbRatioController = TextEditingController();

  bool hasFoodAllergy = false;
  final allergyDetailsController = TextEditingController();

  bool isSubmitting = false;

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
    lantusTimeController.dispose();
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

  Future<void> _pickDiagnosisDate() async {
    final now = DateTime.now();

    DateTime initialDate = now;
    if (diagnosisDateController.text.trim().isNotEmpty) {
      try {
        initialDate = DateTime.parse(diagnosisDateController.text.trim());
      } catch (_) {}
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: now,
    );

    if (picked != null) {
      final formatted =
          "${picked.year.toString().padLeft(4, '0')}-"
          "${picked.month.toString().padLeft(2, '0')}-"
          "${picked.day.toString().padLeft(2, '0')}";

      setState(() {
        diagnosisDateController.text = formatted;
      });
    }
  }

  bool _validateForm() {
    if (isChild) {
      if (guardianNameController.text.trim().isEmpty ||
          guardianPhoneController.text.trim().isEmpty) {
        _showSnack("Please fill guardian information");
        return false;
      }
    }

    if (heightController.text.trim().isEmpty ||
        weightController.text.trim().isEmpty ||
        diagnosisDateController.text.trim().isEmpty) {
      _showSnack("Please complete patient information");
      return false;
    }

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

    if (managementType == null || managementType!.trim().isEmpty) {
      _showSnack("Please choose how you manage diabetes");
      return false;
    }

    if (managementType == "Fixed Doses") {
      if (breakfastDoseController.text.trim().isEmpty ||
          lunchDoseController.text.trim().isEmpty ||
          dinnerDoseController.text.trim().isEmpty ||
          lantusDoseController.text.trim().isEmpty ||
          lantusTimeController.text.trim().isEmpty ||
          correctionFactorController.text.trim().isEmpty) {
        _showSnack("Please complete the fixed dose details");
        return false;
      }
    }

    if (managementType == "Carb Counting") {
      if (carbRatioController.text.trim().isEmpty ||
          lantusDoseController.text.trim().isEmpty ||
          lantusTimeController.text.trim().isEmpty ||
          correctionFactorController.text.trim().isEmpty) {
        _showSnack("Please complete the carb counting details");
        return false;
      }
    }

    if (hasFoodAllergy && allergyDetailsController.text.trim().isEmpty) {
      _showSnack("Please enter allergy details");
      return false;
    }

    return true;
  }

  Future<void> _submitData() async {
    if (!_validateForm()) return;

    setState(() => isSubmitting = true);

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
        managementType: managementType ?? "",
        breakfastDose: breakfastDose,
        lunchDose: lunchDose,
        dinnerDose: dinnerDose,
        lantusDose: lantusDose,
        lantusTime: lantusTimeController.text.trim(),
        correctionFactor: correctionFactorController.text.trim(),
        carbRatio: carbRatioController.text.trim(),
        hasFoodAllergy: hasFoodAllergy,
        allergyDetails: allergyDetailsController.text.trim(),
      );

      _showSnack("Patient profile saved successfully ✅");

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => PatientHomeScreen(userId: widget.userId),
        ),
        (route) => false,
      );
    } catch (e) {
      _showSnack(e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
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
                      constraints: const BoxConstraints(maxWidth: 980),
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
                        child: _mainFormPanel(),
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

  Widget _mainFormPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Complete Your Information",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color(0xff1565C0),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isChild
              ? "Child profile with guardian details"
              : "Patient profile form",
          style: const TextStyle(fontSize: 15, color: Colors.black54),
        ),
        const SizedBox(height: 24),

        if (isChild) ...[
          _sectionBlock(
            title: "Guardian Information",
            imagePath: 'lib/assets/images/step_guardian.png',
            child: _guardianSection(),
          ),
          const SizedBox(height: 24),
        ],

        _sectionBlock(
          title: "Patient Information",
          imagePath: 'lib/assets/images/step_patient.png',
          child: _patientInfoSection(),
        ),
        const SizedBox(height: 24),

        _sectionBlock(
          title: "Treatment & Medications",
          imagePath: 'lib/assets/images/step_insulin.png',
          child: _treatmentSection(),
        ),
        const SizedBox(height: 24),

        _sectionBlock(
          title: "Diabetes Management",
          imagePath: 'lib/assets/images/step_management.png',
          child: _managementTypeSection(),
        ),
        const SizedBox(height: 24),

        if (managementType != null && managementType != "I Don't Know") ...[
          _simpleSectionBlock(
            title: "Management Details",
            child: _managementDetailsSection(),
          ),
          const SizedBox(height: 24),
        ],

        _sectionBlock(
          title: "Food Allergy",
          imagePath: 'lib/assets/images/step_allergy.png',
          child: _allergySection(),
        ),
        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isSubmitting ? null : _submitData,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff42A5F5),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    "Submit",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _sectionBlock({
    required String title,
    required String imagePath,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xffF9FCFF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xffD7EBFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 640;

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xffF3FAFF),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(
                        child: Image.asset(
                          imagePath,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.image_outlined,
                            size: 54,
                            color: Color(0xff90CAF9),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff1565C0),
                        ),
                      ),
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xffF3FAFF),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: Image.asset(
                        imagePath,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.image_outlined,
                          size: 54,
                          color: Color(0xff90CAF9),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff1565C0),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _simpleSectionBlock({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xffF9FCFF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xffD7EBFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xff1565C0),
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _guardianSection() {
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

  Widget _patientInfoSection() {
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
        TextField(
          controller: diagnosisDateController,
          readOnly: true,
          onTap: _pickDiagnosisDate,
          decoration:
              _inputDecoration(
                label: "Diagnosis Date",
                icon: Icons.calendar_month_outlined,
                hint: "Select diagnosis date",
              ).copyWith(
                suffixIcon: IconButton(
                  onPressed: _pickDiagnosisDate,
                  icon: const Icon(Icons.calendar_month_outlined),
                ),
              ),
        ),
      ],
    );
  }

  Widget _treatmentSection() {
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

  Widget _managementTypeSection() {
    return DropdownButtonFormField<String>(
      value: managementType,
      decoration: _inputDecoration(
        label: "How do you manage diabetes?",
        icon: Icons.settings_accessibility_outlined,
      ),
      hint: const Text("Select one option"),
      items: const [
        DropdownMenuItem<String>(
          value: "Carb Counting",
          child: Text("Carb Counting"),
        ),
        DropdownMenuItem<String>(
          value: "Fixed Doses",
          child: Text("Fixed Doses"),
        ),
        DropdownMenuItem<String>(
          value: "I Don't Know",
          child: Text("I Don't Know"),
        ),
      ],
      onChanged: (value) {
        setState(() {
          managementType = value;
        });
      },
    );
  }

  Widget _managementDetailsSection() {
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
            controller: lantusTimeController,
            label: "Lantus / Basal Time (e.g. 9:00 PM)",
            icon: Icons.access_time,
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
            controller: lantusTimeController,
            label: "Lantus / Basal Time (e.g. 9:00 PM)",
            icon: Icons.access_time,
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

    return const SizedBox.shrink();
  }

  Widget _allergySection() {
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
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth < 500 ? 130.0 : 148.0;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: cardWidth,
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
