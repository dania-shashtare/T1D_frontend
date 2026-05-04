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
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;

  String? _errorMessage;
  ProfileModel? profile;

  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
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

      final data = await ProfileApi.getProfile(userId);

      setState(() {
        profile = data;
        _weightController.text = data.weight?.toString() ?? '';
        _heightController.text = data.height?.toString() ?? '';
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load profile data';
      });
    }
  }

  Future<void> _saveProfile() async {
    final weight = double.tryParse(_weightController.text.trim());
    final height = double.tryParse(_heightController.text.trim());

    if (weight == null || height == null || weight <= 0 || height <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid weight and height')),
      );
      return;
    }

    try {
      setState(() => _isSaving = true);

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null || userId.isEmpty) {
        throw Exception('No logged-in user found');
      }

      await ProfileApi.updateProfile(
        userId: userId,
        weight: weight,
        height: height,
      );

      await _loadProfile();

      setState(() {
        _isEditing = false;
        _isSaving = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
    }
  }

  double? _calculateBmi() {
    final weight = _isEditing
        ? double.tryParse(_weightController.text.trim())
        : profile?.weight;

    final height = _isEditing
        ? double.tryParse(_heightController.text.trim())
        : profile?.height;

    if (weight == null || height == null) return null;
    final heightM = height / 100;
    if (heightM <= 0) return null;

    return weight / (heightM * heightM);
  }

  String _value(dynamic value, {String suffix = ''}) {
    if (value == null) return 'Not set';
    final text = value.toString();
    if (text.trim().isEmpty) return 'Not set';
    return suffix.isEmpty ? text : '$text $suffix';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FB),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            )
          : Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildUserCard(),
                        const SizedBox(height: 16),
                        _buildPersonalInfoCard(),
                        const SizedBox(height: 16),
                        _buildDiabetesCard(),
                        const SizedBox(height: 16),
                        _buildAllergyCard(),
                        const SizedBox(height: 16),
                        _buildDoctorCard(),
                        const SizedBox(height: 24),
                        _buildLogoutButton(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        bottom: 22,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A73B8), Color(0xFF63B8F2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const Expanded(
            child: Text(
              'Profile',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          GestureDetector(
            onTap: _isSaving
                ? null
                : () async {
                    if (_isEditing) {
                      await _saveProfile();
                    } else {
                      setState(() => _isEditing = true);
                    }
                  },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _isEditing ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _isEditing ? 'Save' : 'Edit',
                      style: TextStyle(
                        color: _isEditing
                            ? const Color(0xFF1A73B8)
                            : Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard() {
    final name = profile?.fullName.isNotEmpty == true
        ? profile!.fullName
        : 'Patient Profile';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          CircleAvatar(
            radius: 42,
            backgroundColor: const Color(0xFFE4F3FF),
            child: Text(
              name[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 34,
                color: Color(0xFF1A73B8),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF123B63),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Type 1 Diabetes Patient',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    final bmi = _calculateBmi();

    return _buildSectionCard(
      title: 'Personal Information',
      icon: Icons.person_outline,
      children: [
        _buildInfoRow(
          Icons.cake_outlined,
          'Age',
          _value(profile?.age, suffix: 'years'),
        ),
        _buildEditableInfoRow(
          Icons.monitor_weight_outlined,
          'Weight',
          _weightController,
          'kg',
        ),
        _buildEditableInfoRow(
          Icons.height_outlined,
          'Height',
          _heightController,
          'cm',
        ),
        _buildInfoRow(
          Icons.favorite_border,
          'BMI',
          bmi == null ? 'Not set' : bmi.toStringAsFixed(1),
        ),
      ],
    );
  }

  Widget _buildDiabetesCard() {
    return _buildSectionCard(
      title: 'Diabetes Information',
      icon: Icons.medical_services_outlined,
      children: [
        _buildInfoRow(
          Icons.restaurant_menu,
          'Carb Ratio',
          _value(profile?.carbRatio),
        ),
        _buildInfoRow(
          Icons.trending_down,
          'Correction Factor',
          _value(profile?.correctionFactor),
        ),
        _buildInfoRow(
          Icons.water_drop_outlined,
          'Lantus Dose',
          _value(profile?.lantusDose, suffix: 'units'),
        ),
      ],
    );
  }

  Widget _buildAllergyCard() {
    final hasAllergy = profile?.hasFoodAllergy == true;
    final allergyText = hasAllergy
        ? _value(profile?.allergyDetails)
        : 'No food allergy';

    return _buildSectionCard(
      title: 'Food Allergy',
      icon: Icons.warning_amber_rounded,
      children: [
        _buildInfoRow(
          hasAllergy ? Icons.error_outline : Icons.check_circle_outline,
          'Allergy',
          allergyText,
        ),
      ],
    );
  }

  Widget _buildDoctorCard() {
    return _buildSectionCard(
      title: 'Doctor',
      icon: Icons.local_hospital_outlined,
      children: [
        _buildInfoRow(Icons.person, 'Doctor Name', _value(profile?.doctorName)),
        _buildInfoRow(
          Icons.badge_outlined,
          'Specialty',
          _value(profile?.doctorSpecialty),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFE4F3FF),
                child: Icon(icon, color: const Color(0xFF1A73B8), size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF123B63),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1EEF8)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1A73B8), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF123B63),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableInfoRow(
    IconData icon,
    String label,
    TextEditingController controller,
    String suffix,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1EEF8)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1A73B8), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
          ),
          _isEditing
              ? SizedBox(
                  width: 90,
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      isDense: true,
                      suffixText: suffix,
                      border: const UnderlineInputBorder(),
                    ),
                  ),
                )
              : Flexible(
                  child: Text(
                    controller.text.trim().isEmpty
                        ? 'Not set'
                        : '${controller.text} $suffix',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF123B63),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.07),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();

          if (!mounted) return;

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const AuthScreen()),
            (route) => false,
          );
        },
        icon: const Icon(Icons.logout),
        label: const Text('Log Out'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE74C4C),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
