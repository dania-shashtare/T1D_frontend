import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/profile_model.dart';
import '../services/profile_api.dart';
import 'auth_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isEditing = false;
  bool _isLoading = true;
  String? _errorMessage;

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _doctorController = TextEditingController();
  final _specialtyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null || userId.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No logged-in user found';
        });
        return;
      }

      final ProfileModel profile = await ProfileApi.getProfile(userId);

      _nameController.text = profile.fullName;
      _ageController.text = profile.age?.toString() ?? '';
      _weightController.text = profile.weight?.toString() ?? '';
      _heightController.text = profile.height?.toString() ?? '';
      _doctorController.text = profile.doctorName;
      _specialtyController.text = profile.doctorSpecialty;

      setState(() {
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      print('Profile load error: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load profile data: $e';
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _doctorController.dispose();
    _specialtyController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          : Column(
              children: [
                _buildHeader(),
                _buildAvatar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 16, bottom: 40),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPersonalInfoCard(),
                          const SizedBox(height: 16),
                          _buildSectionLabel('Doctor'),
                          const SizedBox(height: 8),
                          _buildDoctorCard(),
                          const SizedBox(height: 24),
                          _buildLogoutButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: const Color(0xFF1A4A8A),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 20,
        left: 16,
        right: 16,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Profile',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: _toggleEdit,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              decoration: BoxDecoration(
                color: _isEditing ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(_isEditing ? 1.0 : 0.5),
                ),
              ),
              child: Text(
                _isEditing ? 'Save' : 'Edit',
                style: TextStyle(
                  color: _isEditing ? const Color(0xFF1A4A8A) : Colors.white,
                  fontSize: 13,
                  fontWeight: _isEditing ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      color: const Color(0xFF1A4A8A),
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 20),
      child: Center(
        child: Text(
          _nameController.text.isNotEmpty ? _nameController.text : 'Profile',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    return _buildCard(
      label: 'Personal Information',
      children: [
        _buildField(
          icon: Icons.person_outline,
          iconBg: const Color(0xFFE6F1FB),
          iconColor: const Color(0xFF185FA5),
          label: 'Full Name',
          controller: _nameController,
          keyboardType: TextInputType.name,
        ),
        _buildField(
          icon: Icons.calendar_today_outlined,
          iconBg: const Color(0xFFFAEEDA),
          iconColor: const Color(0xFFBA7517),
          label: 'Age',
          controller: _ageController,
          suffix: 'years',
          keyboardType: TextInputType.number,
        ),
        _buildField(
          icon: Icons.monitor_weight_outlined,
          iconBg: const Color(0xFFEAF3DE),
          iconColor: const Color(0xFF1D9E75),
          label: 'Weight',
          controller: _weightController,
          suffix: 'kg',
          keyboardType: TextInputType.number,
        ),
        _buildField(
          icon: Icons.straighten_outlined,
          iconBg: const Color(0xFFEEEDFE),
          iconColor: const Color(0xFF534AB7),
          label: 'Height',
          controller: _heightController,
          suffix: 'cm',
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildCard({required String label, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.08), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
                letterSpacing: 0.6,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required TextEditingController controller,
    String? suffix,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      children: [
        const Divider(height: 0.5, thickness: 0.5),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 70,
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
              Expanded(
                child: _isEditing
                    ? TextField(
                        controller: controller,
                        keyboardType: keyboardType,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.only(bottom: 2),
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Color(0xFF1A4A8A),
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Color(0xFF1A4A8A),
                              width: 1.5,
                            ),
                          ),
                        ),
                      )
                    : Text(
                        controller.text.isEmpty
                            ? '-'
                            : suffix != null
                            ? '${controller.text} $suffix'
                            : controller.text,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: Colors.grey,
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _buildDoctorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.08), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF3DE),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _doctorInitials(),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF3B6D11),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _isEditing
                ? Column(
                    children: [
                      TextField(
                        controller: _doctorController,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.only(bottom: 2),
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Color(0xFF1A4A8A),
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Color(0xFF1A4A8A),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _specialtyController,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.only(bottom: 2),
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.grey,
                              width: 0.5,
                            ),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Color(0xFF1A4A8A),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _doctorController.text.isNotEmpty
                            ? _doctorController.text
                            : '-',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _specialtyController.text.isNotEmpty
                            ? _specialtyController.text
                            : '-',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  String _doctorInitials() {
    final text = _doctorController.text.trim();
    if (text.isEmpty) return '--';

    final parts = text.split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Widget _buildLogoutButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: () {
            Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AuthScreen()),
          (route) => false,
        );
        },
        icon: const Icon(Icons.logout, color: Color(0xFFA32D2D), size: 18),
        label: const Text(
          'Log Out',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFFA32D2D),
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          backgroundColor: const Color(0xFFFCEBEB),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xFFF09595), width: 0.5),
          ),
        ),
      ),
    );
  }
}
