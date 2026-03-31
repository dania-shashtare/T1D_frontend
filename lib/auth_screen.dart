import 'package:flutter/material.dart';
import 'services/auth_api.dart';
import 'patient_onboarding_screen.dart';
import 'parent_onboarding_screen.dart';
import 'doctor_onboarding_screen.dart';
import 'nutritionist_onboarding_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isSignIn = true;

  // Shared
  String selectedRole = "patient";
  bool hidePassword = true;
  bool hideConfirmPassword = true;
  bool isLoading = false;

  // Sign in
  final signInEmail = TextEditingController();
  final signInPassword = TextEditingController();

  // Sign up
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final signUpEmail = TextEditingController();
  final signUpPassword = TextEditingController();
  final confirmPassword = TextEditingController();
  final dateOfBirth = TextEditingController();

  @override
  void dispose() {
    signInEmail.dispose();
    signInPassword.dispose();
    firstName.dispose();
    lastName.dispose();
    signUpEmail.dispose();
    signUpPassword.dispose();
    confirmPassword.dispose();
    dateOfBirth.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  DateTime? _parseDob(String input) {
    try {
      return DateTime.parse(input.trim());
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleSignup() async {
    if (isLoading) return;

    final f = firstName.text.trim();
    final l = lastName.text.trim();
    final e = signUpEmail.text.trim();
    final p = signUpPassword.text;
    final c = confirmPassword.text;
    final dobText = dateOfBirth.text.trim();
    final dob = _parseDob(dobText);

    if (f.isEmpty ||
        l.isEmpty ||
        e.isEmpty ||
        p.isEmpty ||
        c.isEmpty ||
        dobText.isEmpty) {
      _snack("Please fill all fields");
      return;
    }

    if (p != c) {
      _snack("Passwords do not match");
      return;
    }

    if (dob == null) {
      _snack("Date of Birth must be YYYY-MM-DD");
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await AuthApi.signup(
        firstName: f,
        lastName: l,
        email: e,
        password: p,
        role: selectedRole,
        birthDate: dob,
      );

      final user = response["user"];
      final userId = user["_id"];

      if (!mounted) return;

      if (selectedRole == "patient") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PatientOnboardingScreen(
              userId: userId,
              firstName: f,
              lastName: l,
              email: e,
              birthDate: dob,
            ),
          ),
        );
      } else if (selectedRole == "family") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ParentOnboardingScreen(userId: userId),
          ),
        );
      } else if (selectedRole == "doctor") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DoctorOnboardingScreen(userId: userId),
          ),
        );
      } else if (selectedRole == "nutritionist") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => NutritionistOnboardingScreen(userId: userId),
          ),
        );
      } else {
        _snack("This role is not linked yet");
      }
    } catch (e) {
      _snack(e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 900;

            return Center(
              child: Container(
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
                child: isDesktop
                    ? Row(
                        children: [
                          Expanded(flex: 4, child: _characterPanel()),
                          Expanded(flex: 5, child: _authPanel()),
                        ],
                      )
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            SizedBox(height: 320, child: _characterPanel()),
                            _authPanel(),
                          ],
                        ),
                      ),
              ),
            );
          },
        ),
      ),
    );
  }
  // ================= LEFT / RIGHT PANEL =================

  Widget _characterPanel() {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Image.asset(
                'lib/assets/images/sugerhappy.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isSignIn ? "Welcome Back" : "Create New Account",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Color(0xff1565C0),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isSignIn
                  ? "Sign in and continue your journey with us"
                  : "Join us and start your health journey today",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, color: Colors.black54),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _authPanel() {
    return Container(
      color: Colors.transparent,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _tabs(),
                  const SizedBox(height: 24),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: isSignIn ? _signInForm() : _signUpForm(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================= TABS =================

  Widget _tabs() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xffD9EEFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _tabButton(
              title: "Sign In",
              selected: isSignIn,
              onTap: () => setState(() => isSignIn = true),
            ),
          ),
          Expanded(
            child: _tabButton(
              title: "Sign Up",
              selected: !isSignIn,
              onTap: () => setState(() => isSignIn = false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xff42A5F5) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xff1565C0),
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  // ================= SIGN IN =================

  Widget _signInForm() {
    return Column(
      key: const ValueKey("signin"),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Login to your account",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 255, 255, 255),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _textField(
          controller: signInEmail,
          label: "Email",
          icon: Icons.email_outlined,
        ),
        const SizedBox(height: 14),
        _passwordField(
          controller: signInPassword,
          label: "Password",
          hide: hidePassword,
          onToggle: () => setState(() => hidePassword = !hidePassword),
        ),
        const SizedBox(height: 14),
        roleDropdown(),
        const SizedBox(height: 20),
        _primaryButton(
          text: "Login",
          onPressed: () {
            _snack("Login API not added yet");
          },
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {},
          child: const Text(
            "Forgot password?",
            style: TextStyle(color: Color(0xff1565C0)),
          ),
        ),
      ],
    );
  }

  // ================= SIGN UP =================

  Widget _signUpForm() {
    return Column(
      key: const ValueKey("signup"),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Create your account",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 255, 255, 255),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _textField(
                controller: firstName,
                label: "First name",
                icon: Icons.person_outline,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _textField(
                controller: lastName,
                label: "Last name",
                icon: Icons.person_outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _textField(
          controller: signUpEmail,
          label: "Email",
          icon: Icons.email_outlined,
        ),
        const SizedBox(height: 14),
        _passwordField(
          controller: signUpPassword,
          label: "Password",
          hide: hidePassword,
          onToggle: () => setState(() => hidePassword = !hidePassword),
        ),
        const SizedBox(height: 14),
        _passwordField(
          controller: confirmPassword,
          label: "Confirm password",
          hide: hideConfirmPassword,
          onToggle: () =>
              setState(() => hideConfirmPassword = !hideConfirmPassword),
        ),
        const SizedBox(height: 14),
        _textField(
          controller: dateOfBirth,
          label: "Date of Birth (YYYY-MM-DD)",
          icon: Icons.cake_outlined,
          hint: "Example: 2008-05-12",
        ),
        const SizedBox(height: 14),
        roleDropdown(),
        const SizedBox(height: 20),
        _primaryButton(
          text: isLoading ? "Creating..." : "Create Account",
          onPressed: isLoading ? () {} : _handleSignup,
        ),
      ],
    );
  }

  // ================= ROLE DROPDOWN =================

  Widget roleDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedRole,
      isExpanded: true,
      decoration: _inputDecoration(label: "Role", icon: Icons.badge_outlined),
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      items: const [
        DropdownMenuItem(value: "patient", child: Text("👤 Patient")),
        DropdownMenuItem(value: "doctor", child: Text("👨‍⚕️ Doctor")),
        DropdownMenuItem(value: "nutritionist", child: Text("🥗 Nutritionist")),
        DropdownMenuItem(value: "family", child: Text("👨‍👩‍👧 Family")),
        // DropdownMenuItem(value: "psychologist", child: Text("🧠 Psychologist")),
      ],
      onChanged: (value) {
        if (value == null) return;
        setState(() => selectedRole = value);
      },
    );
  }

  // ================= HELPERS =================

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

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool hide,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: hide,
      decoration: _inputDecoration(label: label, icon: Icons.lock_outline)
          .copyWith(
            suffixIcon: IconButton(
              onPressed: onToggle,
              icon: Icon(
                hide
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
          ),
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

  Widget _primaryButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff42A5F5),
          foregroundColor: Colors.white,

          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
