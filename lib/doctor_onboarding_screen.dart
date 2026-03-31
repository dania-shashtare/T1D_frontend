import 'package:flutter/material.dart';
import 'services/onboarding_api.dart';

class DoctorOnboardingScreen extends StatefulWidget {
  final String userId;

  const DoctorOnboardingScreen({super.key, required this.userId});

  @override
  State<DoctorOnboardingScreen> createState() => _DoctorOnboardingScreenState();
}

class _DoctorOnboardingScreenState extends State<DoctorOnboardingScreen> {
  int currentStep = 0;
  bool isSaving = false;

  // Step 1
  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final workplaceController = TextEditingController();

  String specialty = "Endocrinologist";
  final otherSpecialtyController = TextEditingController();

  // Step 2
  final yearsOfExperienceController = TextEditingController();

  bool ageChildren = false;
  bool ageAdolescents = false;
  bool ageAdults = false;
  bool ageAllAges = false;

  String treatsType1 = "Yes";

  // Step 3
  String professionalProofName = "";
  String cvFileName = "";

  // Step 4
  String patientConnectionMethod = "Invitation Code";

  bool notifyHighGlucose = false;
  bool notifyLowGlucose = false;
  bool notifyMissedLogs = false;
  bool notifyConsultRequests = false;

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    workplaceController.dispose();
    otherSpecialtyController.dispose();
    yearsOfExperienceController.dispose();
    super.dispose();
  }

  int get totalSteps => 4;

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
      await _submitDoctorData();
    }
  }

  void _previousStep() {
    if (currentStep > 0) {
      setState(() => currentStep--);
    }
  }

  bool _validateStep() {
    if (currentStep == 0) {
      if (fullNameController.text.trim().isEmpty ||
          phoneController.text.trim().isEmpty ||
          workplaceController.text.trim().isEmpty) {
        _showSnack("Please complete the basic information");
        return false;
      }

      if (specialty == "Other" &&
          otherSpecialtyController.text.trim().isEmpty) {
        _showSnack("Please enter your specialty");
        return false;
      }
    }

    if (currentStep == 1) {
      if (yearsOfExperienceController.text.trim().isEmpty) {
        _showSnack("Please enter years of experience");
        return false;
      }

      if (!ageChildren && !ageAdolescents && !ageAdults && !ageAllAges) {
        _showSnack("Please select at least one age group");
        return false;
      }
    }

    if (currentStep == 2) {
      if (professionalProofName.isEmpty) {
        _showSnack("Please upload professional proof");
        return false;
      }
    }

    return true;
  }

  Future<void> _submitDoctorData() async {
    try {
      setState(() => isSaving = true);

      await OnboardingApi.saveDoctorProfile(
        userId: widget.userId,
        fullName: fullNameController.text.trim(),
        phone: phoneController.text.trim(),
        workplace: workplaceController.text.trim(),
        specialty: specialty,
        otherSpecialty: otherSpecialtyController.text.trim(),
        yearsOfExperience: int.parse(yearsOfExperienceController.text.trim()),
        ageChildren: ageChildren,
        ageAdolescents: ageAdolescents,
        ageAdults: ageAdults,
        ageAllAges: ageAllAges,
        treatsType1: treatsType1,
        professionalProofName: professionalProofName,
        cvFileName: cvFileName,
        patientConnectionMethod: patientConnectionMethod,
        notifyHighGlucose: notifyHighGlucose,
        notifyLowGlucose: notifyLowGlucose,
        notifyMissedLogs: notifyMissedLogs,
        notifyConsultRequests: notifyConsultRequests,
      );

      _showSnack("Doctor profile saved successfully ✅");
    } catch (e) {
      _showSnack(e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  void _mockPickProfessionalProof() {
    setState(() {
      professionalProofName = "doctor_professional_proof.pdf";
    });
  }

  void _mockPickCv() {
    setState(() {
      cvFileName = "doctor_cv.pdf";
    });
  }

  String _stepTitle() {
    switch (currentStep) {
      case 0:
        return "Basic Professional Information";
      case 1:
        return "Professional Details";
      case 2:
        return "Professional Verification";
      case 3:
        return "App Preferences";
      default:
        return "";
    }
  }

  String _stepImagePath() {
    switch (currentStep) {
      case 0:
        return 'lib/assets/images/doctor1.png';
      case 1:
        return 'lib/assets/images/doctor3.png';
      case 2:
        return 'lib/assets/images/doctor2.png';
      case 3:
        return 'lib/assets/images/doctor4.png';
      default:
        return 'lib/assets/images/doctor1.png';
    }
  }

  Widget _buildCurrentStep() {
    switch (currentStep) {
      case 0:
        return _basicInfoStep();
      case 1:
        return _professionalDetailsStep();
      case 2:
        return _verificationStep();
      case 3:
        return _preferencesStep();
      default:
        return const SizedBox.shrink();
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
                  "Doctor Onboarding",
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
                      constraints: const BoxConstraints(maxWidth: 920),
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
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
                                      Expanded(flex: 3, child: _sidePanel()),
                                      const SizedBox(width: 28),
                                      Expanded(flex: 5, child: _mainPanel()),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      _topPanel(),
                                      const SizedBox(height: 20),
                                      _mainPanel(),
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

  Widget _sidePanel() {
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
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.medical_services_outlined,
                size: 80,
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

  Widget _topPanel() {
    return Container(
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
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.medical_services_outlined,
            size: 70,
            color: Color(0xff90CAF9),
          ),
        ),
      ),
    );
  }

  Widget _mainPanel() {
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
                  onPressed: isSaving ? null : _previousStep,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text("Previous"),
                ),
              ),
            if (currentStep > 0) const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: isSaving ? null : _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff42A5F5),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  isSaving
                      ? "Saving..."
                      : currentStep == totalSteps - 1
                      ? "Finish"
                      : "Next",
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _basicInfoStep() {
    return Column(
      children: [
        _textField(
          controller: fullNameController,
          label: "Full Name",
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 14),
        _textField(
          controller: phoneController,
          label: "Phone Number",
          icon: Icons.phone_outlined,
        ),
        const SizedBox(height: 14),
        _textField(
          controller: workplaceController,
          label: "Workplace / Clinic / Hospital",
          icon: Icons.local_hospital_outlined,
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: specialty,
          decoration: _inputDecoration(
            label: "Specialty",
            icon: Icons.badge_outlined,
          ),
          items: const [
            DropdownMenuItem(
              value: "Endocrinologist",
              child: Text("Endocrinologist"),
            ),
            DropdownMenuItem(
              value: "Pediatric Endocrinologist",
              child: Text("Pediatric Endocrinologist"),
            ),
            DropdownMenuItem(
              value: "Internal Medicine",
              child: Text("Internal Medicine"),
            ),
            DropdownMenuItem(
              value: "General Physician",
              child: Text("General Physician"),
            ),
            DropdownMenuItem(
              value: "Diabetes Specialist",
              child: Text("Diabetes Specialist"),
            ),
            DropdownMenuItem(value: "Other", child: Text("Other")),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() => specialty = value);
          },
        ),
        if (specialty == "Other") ...[
          const SizedBox(height: 14),
          _textField(
            controller: otherSpecialtyController,
            label: "Enter your specialty",
            icon: Icons.edit_outlined,
          ),
        ],
      ],
    );
  }

  Widget _professionalDetailsStep() {
    return Column(
      children: [
        _textField(
          controller: yearsOfExperienceController,
          label: "Years of Experience",
          icon: Icons.work_history_outlined,
        ),
        const SizedBox(height: 18),
        _sectionTitle("Age Groups You Follow"),
        _checkTile(
          title: "Children",
          value: ageChildren,
          onChanged: (v) => setState(() => ageChildren = v),
        ),
        _checkTile(
          title: "Adolescents",
          value: ageAdolescents,
          onChanged: (v) => setState(() => ageAdolescents = v),
        ),
        _checkTile(
          title: "Adults",
          value: ageAdults,
          onChanged: (v) => setState(() => ageAdults = v),
        ),
        _checkTile(
          title: "All Ages",
          value: ageAllAges,
          onChanged: (v) => setState(() => ageAllAges = v),
        ),
        const SizedBox(height: 18),
        DropdownButtonFormField<String>(
          initialValue: treatsType1,
          decoration: _inputDecoration(
            label: "Do you treat Type 1 Diabetes patients?",
            icon: Icons.monitor_heart_outlined,
          ),
          items: const [
            DropdownMenuItem(value: "Yes", child: Text("Yes")),
            DropdownMenuItem(value: "No", child: Text("No")),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() => treatsType1 = value);
          },
        ),
        if (treatsType1 == "No") ...[
          const SizedBox(height: 12),
          _infoBox("This app is intended for Type 1 Diabetes patients."),
        ],
      ],
    );
  }

  Widget _verificationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _uploadCard(
          title: "Upload Professional Proof",
          subtitle: professionalProofName.isEmpty
              ? "Degree, specialty certificate, or professional proof"
              : professionalProofName,
          buttonText: "Upload File",
          onTap: _mockPickProfessionalProof,
        ),
        const SizedBox(height: 14),
        _uploadCard(
          title: "Upload CV (Optional)",
          subtitle: cvFileName.isEmpty ? "You can upload your CV" : cvFileName,
          buttonText: "Upload CV",
          onTap: _mockPickCv,
        ),
        const SizedBox(height: 16),
        _infoBox(
          "Your account will remain under review until verification is completed.",
        ),
      ],
    );
  }

  Widget _preferencesStep() {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          initialValue: patientConnectionMethod,
          decoration: _inputDecoration(
            label: "How should patients connect with you?",
            icon: Icons.link_outlined,
          ),
          items: const [
            DropdownMenuItem(
              value: "Invitation Code",
              child: Text("Invitation Code"),
            ),
            DropdownMenuItem(
              value: "Email Request",
              child: Text("Email Request"),
            ),
            DropdownMenuItem(
              value: "Manual Approval",
              child: Text("Manual Approval"),
            ),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() => patientConnectionMethod = value);
          },
        ),
        const SizedBox(height: 18),
        _sectionTitle("Notification Preferences"),
        _checkTile(
          title: "High glucose alerts",
          value: notifyHighGlucose,
          onChanged: (v) => setState(() => notifyHighGlucose = v),
        ),
        _checkTile(
          title: "Low glucose alerts",
          value: notifyLowGlucose,
          onChanged: (v) => setState(() => notifyLowGlucose = v),
        ),
        _checkTile(
          title: "Missed logging",
          value: notifyMissedLogs,
          onChanged: (v) => setState(() => notifyMissedLogs = v),
        ),
        _checkTile(
          title: "Consultation requests",
          value: notifyConsultRequests,
          onChanged: (v) => setState(() => notifyConsultRequests = v),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xff1565C0),
        ),
      ),
    );
  }

  Widget _checkTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return CheckboxListTile(
      value: value,
      onChanged: (val) => onChanged(val ?? false),
      title: Text(title),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      activeColor: const Color(0xff42A5F5),
    );
  }

  Widget _uploadCard({
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xffF8FCFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffBBDEFB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.upload_file_outlined),
            label: Text(buttonText),
          ),
        ],
      ),
    );
  }

  Widget _infoBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xffEAF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffBBDEFB)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xff1565C0),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: _inputDecoration(label: label, icon: icon),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
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
