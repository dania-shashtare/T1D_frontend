import 'package:flutter/material.dart';
import 'services/onboarding_api.dart';

class ParentOnboardingScreen extends StatefulWidget {
  final String userId;

  const ParentOnboardingScreen({super.key, required this.userId});

  @override
  State<ParentOnboardingScreen> createState() => _ParentOnboardingScreenState();
}

class _ParentOnboardingScreenState extends State<ParentOnboardingScreen> {
  int currentStep = 0;
  bool isCheckingPatient = false;
  bool isSavingParent = false;

  final patientEmailController = TextEditingController();
  final patientBirthDateController = TextEditingController();

  final parentNameController = TextEditingController();
  final parentPhoneController = TextEditingController();
  String relationship = "Mother";

  String? linkedPatientId;

  @override
  void dispose() {
    patientEmailController.dispose();
    patientBirthDateController.dispose();
    parentNameController.dispose();
    parentPhoneController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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

  Future<void> _nextStep() async {
    if (currentStep == 0) {
      await _checkPatientAndContinue();
      return;
    }

    if (currentStep == 1) {
      if (parentNameController.text.trim().isEmpty ||
          parentPhoneController.text.trim().isEmpty) {
        _showSnack("Please complete parent information");
        return;
      }

      await _submitParentData();
    }
  }

  void _previousStep() {
    if (currentStep > 0) {
      setState(() => currentStep--);
    }
  }

  Future<void> _checkPatientAndContinue() async {
    final email = patientEmailController.text.trim();
    final birthText = patientBirthDateController.text.trim();

    if (email.isEmpty || birthText.isEmpty) {
      _showSnack("Please enter patient email and date of birth");
      return;
    }

    DateTime? birthDate;
    try {
      birthDate = DateTime.parse(birthText);
    } catch (_) {
      _showSnack("Birth date must be YYYY-MM-DD");
      return;
    }

    final age = _calculateAge(birthDate);

    setState(() => isCheckingPatient = true);

    try {
      final patient = await OnboardingApi.findPatientByEmail(
        email: email,
        birthDate: birthDate,
      );

      final bool patientExists = patient != null;

      if (age <= 12) {
        if (patientExists) {
          _showSmallChildExistingAccountDialog();
        } else {
          _showSmallChildCreateAccountDialog();
        }
        return;
      }

      if (!patientExists) {
        _showPatientNotFoundDialog();
        return;
      }

      linkedPatientId = patient["_id"];
      setState(() => currentStep = 1);
    } catch (e) {
      _showSnack(e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) {
        setState(() => isCheckingPatient = false);
      }
    }
  }

  void _showSmallChildExistingAccountDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Use Patient Account"),
        content: const Text(
          "Because your child is 12 years old or younger, you should continue using the patient account. Please log in using the patient account email and password.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Go to Patient Login"),
          ),
        ],
      ),
    );
  }

  void _showSmallChildCreateAccountDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Create Patient Account"),
        content: const Text(
          "Because your child is 12 years old or younger, you need to create a patient account for your child first.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Go to Patient Sign Up"),
          ),
        ],
      ),
    );
  }

  void _showPatientNotFoundDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Patient Not Found"),
        content: const Text(
          "Patient account was not found. Please create the patient account first, then come back to create the family account.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Go to Patient Sign Up"),
          ),
        ],
      ),
    );
  }

  Future<void> _submitParentData() async {
    try {
      if (linkedPatientId == null) {
        _showSnack("Linked patient not found");
        return;
      }

      setState(() => isSavingParent = true);

      await OnboardingApi.saveParentProfile(
        userId: widget.userId,
        linkedPatientId: linkedPatientId!,
        parentName: parentNameController.text.trim(),
        relationship: relationship,
        phone: parentPhoneController.text.trim(),
      );

      _showSnack("Parent profile saved successfully ✅");

      if (!mounted) return;

      // لاحقًا:
      // Navigator.pushReplacement(...);
    } catch (e) {
      _showSnack(e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) {
        setState(() => isSavingParent = false);
      }
    }
  }

  String _stepTitle() {
    switch (currentStep) {
      case 0:
        return "Patient Verification";
      case 1:
        return "Parent Information";
      default:
        return "";
    }
  }

  String _stepImagePath() {
    switch (currentStep) {
      case 0:
        return 'lib/assets/images/step_guardian.png';
      case 1:
        return 'lib/assets/images/step_guardian.png';
      default:
        return 'lib/assets/images/step_guardian.png';
    }
  }

  Widget _buildCurrentStep() {
    switch (currentStep) {
      case 0:
        return _patientVerificationStep();
      case 1:
        return _parentInfoStep();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isBusy = isCheckingPatient || isSavingParent;

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
                  "Family Onboarding",
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
                          color: Colors.white.withValues(alpha: 0.96),
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
                                        child: _mainFormPanel(isBusy),
                                      ),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      _topCharacterPanel(),
                                      const SizedBox(height: 20),
                                      _mainFormPanel(isBusy),
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
              errorBuilder: (context, error, stackTrace) => const Icon(
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
          "Step ${currentStep + 1} of 2",
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

  Widget _mainFormPanel(bool isBusy) {
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
          "Step ${currentStep + 1} of 2",
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
                  onPressed: isBusy ? null : _previousStep,
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
                onPressed: isBusy ? null : _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff42A5F5),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  isCheckingPatient
                      ? "Checking..."
                      : isSavingParent
                      ? "Saving..."
                      : currentStep == 1
                      ? "Finish"
                      : "Next",
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

  Widget _patientVerificationStep() {
    return Column(
      children: [
        _textField(
          controller: patientEmailController,
          label: "Patient Email",
          icon: Icons.email_outlined,
        ),
        const SizedBox(height: 14),
        _textField(
          controller: patientBirthDateController,
          label: "Patient Date of Birth (YYYY-MM-DD)",
          icon: Icons.cake_outlined,
          hint: "Example: 2010-05-12",
        ),
      ],
    );
  }

  Widget _parentInfoStep() {
    return Column(
      children: [
        _textField(
          controller: parentNameController,
          label: "Parent Name",
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          value: relationship,
          decoration: _inputDecoration(
            label: "Relationship",
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
            setState(() => relationship = value);
          },
        ),
        const SizedBox(height: 14),
        _textField(
          controller: parentPhoneController,
          label: "Phone Number",
          icon: Icons.phone_outlined,
        ),
      ],
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
