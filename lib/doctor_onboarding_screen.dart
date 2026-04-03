import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
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
  bool isUploadingProof = false;
  bool isUploadingCv = false;

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

  String professionalProofUrl = "";
  String cvFileUrl = "";

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    workplaceController.dispose();
    otherSpecialtyController.dispose();
    yearsOfExperienceController.dispose();
    super.dispose();
  }

  int get totalSteps => 3;

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  List<String> _extractNameParts(String value) {
    return value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();
  }

  bool _isValidFullName(String value) {
    final parts = _extractNameParts(value);
    return parts.length >= 4;
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

      if (!_isValidFullName(fullNameController.text)) {
        _showSnack("Please enter your full name as 4 names or more");
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

      if (int.tryParse(yearsOfExperienceController.text.trim()) == null) {
        _showSnack("Years of experience must be a valid number");
        return false;
      }

      if (!ageChildren && !ageAdolescents && !ageAdults && !ageAllAges) {
        _showSnack("Please select at least one age group");
        return false;
      }
    }

    if (currentStep == 2) {
      if (professionalProofName.isEmpty || professionalProofUrl.isEmpty) {
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
        professionalProofUrl: professionalProofUrl,
        cvFileName: cvFileName,
        cvFileUrl: cvFileUrl,
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

  Future<void> _pickAndUploadProfessionalProof() async {
    try {
      setState(() => isUploadingProof = true);

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: false,
        withData: kIsWeb,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result == null || result.files.isEmpty) return;

      final picked = result.files.single;

      final uploadResult = await OnboardingApi.uploadDoctorFile(
        userId: widget.userId,
        pickedFile: picked,
        fileFieldName: "professionalProof",
      );

      setState(() {
        professionalProofName = uploadResult["fileName"] ?? picked.name;
        professionalProofUrl = uploadResult["fileUrl"] ?? "";
      });

      _showSnack("Professional proof uploaded successfully");
    } catch (e) {
      _showSnack(e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) {
        setState(() => isUploadingProof = false);
      }
    }
  }

  Future<void> _pickAndUploadCv() async {
    try {
      setState(() => isUploadingCv = true);

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: false,
        withData: kIsWeb,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result == null || result.files.isEmpty) return;

      final picked = result.files.single;

      final uploadResult = await OnboardingApi.uploadDoctorFile(
        userId: widget.userId,
        pickedFile: picked,
        fileFieldName: "cvFile",
      );

      setState(() {
        cvFileName = uploadResult["fileName"] ?? picked.name;
        cvFileUrl = uploadResult["fileUrl"] ?? "";
      });

      _showSnack("CV uploaded successfully");
    } catch (e) {
      _showSnack(e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) {
        setState(() => isUploadingCv = false);
      }
    }
  }

  String _stepTitle() {
    switch (currentStep) {
      case 0:
        return "Basic Professional Information";
      case 1:
        return "Professional Details";
      case 2:
        return "Professional Verification";
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
        TextField(
          controller: fullNameController,
          decoration: _inputDecoration(
            label: "Full Name",
            icon: Icons.person_outline,
            hint: "Enter your full name (4 names or more)",
          ),
        ),
        const SizedBox(height: 8),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "The full name must contain at least 4 names",
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
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
          buttonText: isUploadingProof ? "Uploading..." : "Upload File",
          onTap: isUploadingProof ? null : _pickAndUploadProfessionalProof,
        ),
        const SizedBox(height: 14),
        _uploadCard(
          title: "Upload CV (Optional)",
          subtitle: cvFileName.isEmpty ? "You can upload your CV" : cvFileName,
          buttonText: isUploadingCv ? "Uploading..." : "Upload CV",
          onTap: isUploadingCv ? null : _pickAndUploadCv,
        ),
        const SizedBox(height: 16),
        _infoBox(
          "The selected file will be uploaded from your laptop and saved in the database.",
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
    required VoidCallback? onTap,
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
