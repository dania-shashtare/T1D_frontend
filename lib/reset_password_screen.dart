import 'package:flutter/material.dart';
import 'auth_screen.dart';
import 'services/auth_api.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String code;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.code,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool hideNewPassword = true;
  bool hideConfirmPassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _resetPassword() async {
    final newPassword = newPasswordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      _snack("Please fill all fields");
      return;
    }

    if (newPassword != confirmPassword) {
      _snack("Passwords do not match");
      return;
    }

    setState(() => isLoading = true);

    try {
      await AuthApi.resetPassword(
        email: widget.email,
        code: widget.code,
        newPassword: newPassword,
      );

      if (!mounted) return;

      _snack("Password reset successful");

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const AuthScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      _snack(e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xff1565C0)),
      suffixIcon: suffixIcon,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffEEF7FF),
      appBar: AppBar(
        title: const Text("Reset Password"),
        backgroundColor: const Color(0xff42A5F5),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.password_outlined,
                    size: 64,
                    color: Color(0xff42A5F5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Create New Password",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff1565C0),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Enter your new password below.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: newPasswordController,
                    obscureText: hideNewPassword,
                    decoration: _inputDecoration(
                      label: "New Password",
                      icon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            hideNewPassword = !hideNewPassword;
                          });
                        },
                        icon: Icon(
                          hideNewPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: hideConfirmPassword,
                    decoration: _inputDecoration(
                      label: "Confirm Password",
                      icon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            hideConfirmPassword = !hideConfirmPassword;
                          });
                        },
                        icon: Icon(
                          hideConfirmPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _primaryButton(
                    text: isLoading ? "Saving..." : "Reset Password",
                    onPressed: isLoading ? () {} : _resetPassword,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}