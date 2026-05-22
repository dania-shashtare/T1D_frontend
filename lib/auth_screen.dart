import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'services/auth_api.dart';
import 'patient_screen.dart';
import 'forgot_password_screen.dart';
import 'patient_onboarding_screen.dart';
import 'parent_onboarding_screen.dart';
import 'doctor_onboarding_screen.dart';
import 'nutritionist_onboarding_screen.dart';
import 'services/firebase_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'doctor_web_dashboard.dart';
import 'nutritionist_web_dashboard.dart';

class AuthScreen extends StatefulWidget {
  final bool startInSignUp;
  final String? forcedRole;

  const AuthScreen({super.key, this.startInSignUp = false, this.forcedRole});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late bool isSignIn;

  // Shared
  late String selectedRole;
  bool hidePassword = true;
  bool hideConfirmPassword = true;
  bool isLoading = false;
  bool _hasMinLength(String value) => value.length >= 8;
  bool _hasUppercase(String value) => RegExp(r'[A-Z]').hasMatch(value);
  bool _hasLowercase(String value) => RegExp(r'[a-z]').hasMatch(value);
  bool _hasNumber(String value) => RegExp(r'[0-9]').hasMatch(value);
  bool _hasSpecialChar(String value) =>
      RegExp(r'[!@#$%^&*(),.?":{}|<>_\-\\/\[\]=+~`]').hasMatch(value);

  String? signInGeneralError;
  String? signUpEmailError;
  String? signUpPasswordError;
  String? confirmPasswordError;

  bool _isStrongPassword(String value) {
    return _hasMinLength(value) &&
        _hasUppercase(value) &&
        _hasLowercase(value) &&
        _hasNumber(value) &&
        _hasSpecialChar(value);
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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
  void initState() {
    super.initState();
    isSignIn = !widget.startInSignUp;
    selectedRole = widget.forcedRole ?? "patient";
  }

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

  Future<void> _pickDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2010),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      helpText: 'Select Date of Birth',
    );

    if (picked != null) {
      final formatted =
          "${picked.year.toString().padLeft(4, '0')}-"
          "${picked.month.toString().padLeft(2, '0')}-"
          "${picked.day.toString().padLeft(2, '0')}";

      setState(() {
        dateOfBirth.text = formatted;
      });
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

    setState(() {
      signUpEmailError = null;
      signUpPasswordError = null;
      confirmPasswordError = null;
    });

    if (f.isEmpty ||
        l.isEmpty ||
        e.isEmpty ||
        p.isEmpty ||
        c.isEmpty ||
        dobText.isEmpty) {
      _snack("Please fill all fields");
      return;
    }

    bool hasError = false;

    if (!_isStrongPassword(p)) {
      signUpPasswordError = "Password is not strong enough";
      hasError = true;
    }

    if (p != c) {
      confirmPasswordError = "Passwords do not match";
      hasError = true;
    }

    if (dob == null) {
      _snack("Please select a valid date of birth");
      return;
    }

    if (hasError) {
      setState(() {});
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

      _snack("Account created ✅");

      firstName.clear();
      lastName.clear();
      signUpEmail.clear();
      signUpPassword.clear();
      confirmPassword.clear();
      dateOfBirth.clear();

      setState(() {
        isSignIn = true;
      });
    } catch (e) {
      final errorMessage = e.toString().replaceAll("Exception: ", "");

      setState(() {
        if (errorMessage.toLowerCase().contains("email already exists")) {
          signUpEmailError = "Email already exists";
        } else {
          _snack(errorMessage);
        }
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _handleLogin() async {
    final email = signInEmail.text.trim();
    final password = signInPassword.text;

    setState(() {
      signInGeneralError = null;
    });

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        signInGeneralError = "Please enter your email and password";
      });
      return;
    }

    try {
      final loginData = await AuthApi.login(email: email, password: password);

      final user = loginData['user'];
      final userId = user['_id'].toString();
      final role = user['role'].toString();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', userId);
      await prefs.setString('role', role);

      try {
        await FirebaseNotificationService.saveUserToken(userId);
      } catch (e) {
        debugPrint('saveUserToken failed: $e');
      }

      if (!mounted) return;

      if (role == 'patient') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PatientHomeScreen(userId: userId),
          ),
        );
      } else if (role == 'doctor') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DoctorWebDashboard(doctorId: userId),
          ),
        );
      } else if (role == 'nutritionist') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => NutritionistWebDashboard(userId: userId),
          ),
        );
      } else {
        _snack("This role home page is not linked yet");
      }
    } catch (e) {
      debugPrint('LOGIN REAL ERROR: $e');

      setState(() {
        signInGeneralError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        _snack("Google sign-in cancelled");
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      final User? user = userCredential.user;

      if (user == null || user.email == null) {
        _snack("Google sign-in failed");
        return;
      }

      final email = user.email!;
      final displayName = user.displayName ?? '';
      final nameParts = displayName.trim().split(' ');
      final googleFirstName = nameParts.isNotEmpty ? nameParts.first : '';
      final googleLastName = nameParts.length > 1
          ? nameParts.sublist(1).join(' ')
          : '';

      final result = await AuthApi.checkGoogleUser(email);

      if (result['exists'] == true && result['user'] != null) {
        final userData = result['user'];

        final userId = userData['_id'].toString();
        final role = (userData['role'] ?? 'patient').toString();

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', userId);
        await prefs.setString('role', role);

        try {
          await FirebaseNotificationService.saveUserToken(userId);
        } catch (e) {
          debugPrint('saveUserToken failed: $e');
        }

        if (!mounted) return;

        _snack("Welcome back ${user.displayName ?? ''}");

        if (role == 'patient') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PatientHomeScreen(userId: userId),
            ),
          );
        } else {
          _snack("This role home page is not linked yet");
        }
      } else {
        firstName.text = googleFirstName;
        lastName.text = googleLastName;
        signUpEmail.text = email;

        setState(() {
          isSignIn = false;
        });

        _snack("Complete your account");
      }
    } catch (e) {
      _snack("Google sign-in failed: $e");
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

  Widget _signInForm() {
    return Column(
      key: const ValueKey("signin"),
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Login to your account",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xff1565C0),
            ),
          ),
        ),

        const SizedBox(height: 20),
        _textField(
          controller: signInEmail,
          label: "Email",
          icon: Icons.email_outlined,
          onChanged: (_) {
            if (signInGeneralError != null) {
              setState(() => signInGeneralError = null);
            }
          },
        ),
        const SizedBox(height: 14),
        _passwordField(
          controller: signInPassword,
          label: "Password",
          hide: hidePassword,
          onToggle: () => setState(() => hidePassword = !hidePassword),
          onChanged: (_) {
            if (signInGeneralError != null) {
              setState(() => signInGeneralError = null);
            }
          },
        ),
        if (signInGeneralError != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              signInGeneralError!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],

        const SizedBox(height: 20),
        _primaryButton(text: "Login", onPressed: _handleLogin),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ForgotPasswordScreen(),
              ),
            );
          },
          child: const Text(
            "Forgot password?",
            style: TextStyle(
              color: Color(0xff1565C0),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 10),
        _dividerWithText("Or continue with"),
        const SizedBox(height: 16),
        _socialButton(
          text: "Continue with Google",
          leading: Image.asset(
            'lib/assets/icons/google_logo.png',
            height: 28,
            width: 28,
          ),
          onPressed: _handleGoogleSignIn,
        ),

        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Don’t have an account? ",
              style: TextStyle(color: Colors.black54, fontSize: 15),
            ),
            GestureDetector(
              onTap: () => setState(() => isSignIn = false),
              child: const Text(
                "Sign Up",
                style: TextStyle(
                  color: Color(0xff1565C0),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _signUpForm() {
    return Column(
      key: const ValueKey("signup"),
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Create your account",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xff1565C0),
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
          errorText: signUpEmailError,
          onChanged: (_) {
            if (signUpEmailError != null) {
              setState(() => signUpEmailError = null);
            }
          },
        ),
        const SizedBox(height: 14),
        _passwordField(
          controller: signUpPassword,
          label: "Password",
          hide: hidePassword,
          onToggle: () => setState(() => hidePassword = !hidePassword),
          errorText: signUpPasswordError,
          onChanged: (_) => setState(() {
            signUpPasswordError = null;
          }),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _passwordRequirement(
                "At least 8 characters",
                _hasMinLength(signUpPassword.text),
              ),
              _passwordRequirement(
                "At least one uppercase letter",
                _hasUppercase(signUpPassword.text),
              ),
              _passwordRequirement(
                "At least one lowercase letter",
                _hasLowercase(signUpPassword.text),
              ),
              _passwordRequirement(
                "At least one number",
                _hasNumber(signUpPassword.text),
              ),
              _passwordRequirement(
                "At least one special character",
                _hasSpecialChar(signUpPassword.text),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _passwordField(
          controller: confirmPassword,
          label: "Confirm password",
          hide: hideConfirmPassword,
          onToggle: () =>
              setState(() => hideConfirmPassword = !hideConfirmPassword),
          errorText: confirmPasswordError,
          onChanged: (_) {
            if (confirmPasswordError != null) {
              setState(() => confirmPasswordError = null);
            }
          },
        ),
        const SizedBox(height: 14),
        TextField(
          controller: dateOfBirth,
          readOnly: true,
          onTap: _pickDateOfBirth,
          decoration:
              _inputDecoration(
                label: "Date of Birth",
                icon: Icons.cake_outlined,
                hint: "Select your birth date",
              ).copyWith(
                suffixIcon: IconButton(
                  onPressed: _pickDateOfBirth,
                  icon: const Icon(Icons.calendar_month_outlined),
                ),
              ),
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
      ],
      onChanged: widget.forcedRole != null
          ? null
          : (value) {
              if (value == null) return;
              setState(() => selectedRole = value);
            },
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    String? errorText,
    ValueChanged<String>? onChanged,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      decoration: _inputDecoration(
        label: label,
        icon: icon,
        hint: hint,
        errorText: errorText,
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool hide,
    required VoidCallback onToggle,
    ValueChanged<String>? onChanged,
    String? errorText,
  }) {
    return TextField(
      controller: controller,
      obscureText: hide,
      onChanged: onChanged,
      decoration:
          _inputDecoration(
            label: label,
            icon: Icons.lock_outline,
            errorText: errorText,
          ).copyWith(
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

  Widget _dividerWithText(String text) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xffC7DEF5), thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xffC7DEF5), thickness: 1)),
      ],
    );
  }

  Widget _socialButton({
    required String text,
    required Widget leading,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xffBBDEFB), width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            leading,
            const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xff374151),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
    String? errorText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: errorText,
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 1.4),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 1.6),
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

  Widget _passwordRequirement(String text, bool isValid) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: isValid ? Colors.green : Colors.black38,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isValid ? Colors.green : Colors.black54,
              fontWeight: isValid ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
