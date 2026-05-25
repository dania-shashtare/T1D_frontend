import 'package:flutter/material.dart';
import 'services/onboarding_api.dart';
import 'family_home_screen.dart';
import 'auth_screen.dart';

class ParentOnboardingScreen extends StatefulWidget {
  final String userId;

  const ParentOnboardingScreen({super.key, required this.userId});

  @override
  State<ParentOnboardingScreen> createState() => _ParentOnboardingScreenState();
}

class _ParentOnboardingScreenState extends State<ParentOnboardingScreen> {
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

  Future<void> _pickPatientBirthDate() async {
    final now = DateTime.now();

    DateTime initialDate = DateTime(2010);
    if (patientBirthDateController.text.trim().isNotEmpty) {
      try {
        initialDate = DateTime.parse(patientBirthDateController.text.trim());
      } catch (_) {}
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: now,
      helpText: 'Select Patient Date of Birth',
    );

    if (picked != null) {
      final formatted =
          "${picked.year.toString().padLeft(4, '0')}-"
          "${picked.month.toString().padLeft(2, '0')}-"
          "${picked.day.toString().padLeft(2, '0')}";

      setState(() {
        patientBirthDateController.text = formatted;
      });
    }
  }

  void _goToPatientSignUp() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) =>
            const AuthScreen(startInSignUp: true, forcedRole: 'patient'),
      ),
      (route) => false,
    );
  }

  void _goToPatientLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) =>
            const AuthScreen(startInSignUp: false, forcedRole: 'patient'),
      ),
      (route) => false,
    );
  }

  void _goToFamilyHome(String patientId) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) =>
            FamilyHomeScreen(familyUserId: widget.userId, patientId: patientId),
      ),
      (route) => false,
    );
  }

  Future<bool> _checkPatientOnly() async {
    final email = patientEmailController.text.trim();
    final birthText = patientBirthDateController.text.trim();

    if (email.isEmpty || birthText.isEmpty) {
      _showSnack("Please enter patient email and date of birth");
      return false;
    }

    DateTime? birthDate;
    try {
      birthDate = DateTime.parse(birthText);
    } catch (_) {
      _showSnack("Birth date must be valid");
      return false;
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
        return false;
      }

      if (!patientExists) {
        _showPatientNotFoundDialog();
        return false;
      }

      linkedPatientId = patient["_id"];
      return true;
    } catch (e) {
      _showSnack(e.toString().replaceAll("Exception: ", ""));
      return false;
    } finally {
      if (mounted) {
        setState(() => isCheckingPatient = false);
      }
    }
  }

  Future<void> _submitAll() async {
    if (parentNameController.text.trim().isEmpty ||
        parentPhoneController.text.trim().isEmpty) {
      _showSnack("Please complete parent information");
      return;
    }

    if (!_isValidFullName(parentNameController.text)) {
      _showSnack("Please enter the parent's full name as 4 names or more");
      return;
    }

    final ok = await _checkPatientOnly();
    if (!ok) return;

    if (linkedPatientId == null) {
      _showSnack("Linked patient not found");
      return;
    }

    try {
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

      _goToFamilyHome(linkedPatientId!);
    } catch (e) {
      _showSnack(e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) {
        setState(() => isSavingParent = false);
      }
    }
  }

  void _showSmallChildExistingAccountDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Use Patient Account"),
        content: const Text(
          "Because your child is 12 years old or younger, please continue using the patient account login.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _goToPatientLogin();
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
          "Because your child is 12 years old or younger, you need to create a patient account first.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _goToPatientSignUp();
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
              _goToPatientSignUp();
            },
            child: const Text("Go to Patient Sign Up"),
          ),
        ],
      ),
    );
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
                      constraints: const BoxConstraints(maxWidth: 980),
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
                        child: _mainFormPanel(isBusy),
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

  Widget _mainFormPanel(bool isBusy) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Complete Family Information",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color(0xff1565C0),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Verify the patient first, then complete parent information.",
          style: TextStyle(fontSize: 15, color: Colors.black54),
        ),
        const SizedBox(height: 24),

        _sectionBlock(
          title: "Patient Verification",
          imagePath: 'lib/assets/images/step_guardian.png',
          child: _patientVerificationSection(),
        ),
        const SizedBox(height: 24),

        _sectionBlock(
          title: "Parent Information",
          imagePath: 'lib/assets/images/step_guardian.png',
          child: _parentInfoSection(),
        ),
        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isBusy ? null : _submitAll,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff42A5F5),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              isCheckingPatient
                  ? "Checking..."
                  : isSavingParent
                  ? "Saving..."
                  : "Submit",
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
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

  Widget _patientVerificationSection() {
    return Column(
      children: [
        _textField(
          controller: patientEmailController,
          label: "Patient Email",
          icon: Icons.email_outlined,
        ),
        const SizedBox(height: 14),
        TextField(
          controller: patientBirthDateController,
          readOnly: true,
          onTap: _pickPatientBirthDate,
          decoration:
              _inputDecoration(
                label: "Patient Date of Birth",
                icon: Icons.cake_outlined,
                hint: "Select patient date of birth",
              ).copyWith(
                suffixIcon: IconButton(
                  onPressed: _pickPatientBirthDate,
                  icon: const Icon(Icons.calendar_month_outlined),
                ),
              ),
        ),
      ],
    );
  }

  Widget _parentInfoSection() {
    return Column(
      children: [
        TextField(
          controller: parentNameController,
          decoration: _inputDecoration(
            label: "Parent Full Name",
            icon: Icons.person_outline,
            hint: "Enter full name (4 names or more)",
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
