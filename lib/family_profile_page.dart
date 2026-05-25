import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/family_api.dart';
import 'auth_screen.dart';

class FamilyProfilePage extends StatefulWidget {
  final String familyUserId;

  const FamilyProfilePage({super.key, required this.familyUserId});

  @override
  State<FamilyProfilePage> createState() => _FamilyProfilePageState();
}

class _FamilyProfilePageState extends State<FamilyProfilePage> {
  bool isLoading = true;
  bool isSaving = false;

  String parentName = '';
  String relationship = '';
  String phone = '';
  String patientName = '';
  String patientEmail = '';

  final TextEditingController parentNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  String selectedRelationship = 'Mother';

  static const Color _mainBlue = Color(0xff185FA5);
  static const Color _textBlue = Color(0xff0C447C);
  static const Color _softBlue = Color(0xffEAF6FF);

  @override
  void initState() {
    super.initState();
    _loadFamilyProfile();
  }

  @override
  void dispose() {
    parentNameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadFamilyProfile() async {
    try {
      final data = await FamilyApi.getFamilyProfile(widget.familyUserId);

      final parentProfile = data['parentProfile'];
      final linkedPatient = parentProfile['linkedPatientId'];

      setState(() {
        parentName = parentProfile['parentName']?.toString() ?? '';
        relationship = parentProfile['relationship']?.toString() ?? '';
        phone = parentProfile['phone']?.toString() ?? '';

        parentNameController.text = parentName;
        phoneController.text = phone;
        selectedRelationship = relationship.trim().isEmpty
            ? 'Mother'
            : relationship;

        if (linkedPatient is Map) {
          patientName =
              '${linkedPatient['firstName'] ?? ''} ${linkedPatient['lastName'] ?? ''}'
                  .trim();
          patientEmail = linkedPatient['email']?.toString() ?? '';
        }

        isLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to load family profile: $e');

      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load family profile: $e')),
      );
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('userId');
    await prefs.remove('role');
    await prefs.remove('savedUserId');
    await prefs.remove('savedRole');

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  void _showEditFamilyDialog() {
    parentNameController.text = parentName;
    phoneController.text = phone;
    selectedRelationship = relationship.trim().isEmpty
        ? 'Mother'
        : relationship;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: const Text(
                'Edit Family Information',
                style: TextStyle(color: _textBlue, fontWeight: FontWeight.w700),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: parentNameController,
                      decoration: _dialogInputDecoration(
                        label: 'Full Name',
                        icon: Icons.person_outline,
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: selectedRelationship,
                      isExpanded: true,
                      decoration: _dialogInputDecoration(
                        label: 'Relationship',
                        icon: Icons.family_restroom,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Mother',
                          child: Text('Mother'),
                        ),
                        DropdownMenuItem(
                          value: 'Father',
                          child: Text('Father'),
                        ),
                        DropdownMenuItem(
                          value: 'Sibling',
                          child: Text('Sibling'),
                        ),
                        DropdownMenuItem(
                          value: 'Relative',
                          child: Text('Relative'),
                        ),
                        DropdownMenuItem(
                          value: 'Caregiver',
                          child: Text('Caregiver'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;

                        setDialogState(() {
                          selectedRelationship = value;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: _dialogInputDecoration(
                        label: 'Phone',
                        icon: Icons.phone_outlined,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () {
                          Navigator.pop(context);
                        },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final name = parentNameController.text.trim();
                          final phoneText = phoneController.text.trim();

                          if (name.isEmpty || phoneText.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please fill all fields'),
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isSaving = true);

                          try {
                            await FamilyApi.updateFamilyProfile(
                              userId: widget.familyUserId,
                              parentName: name,
                              relationship: selectedRelationship,
                              phone: phoneText,
                            );

                            if (!mounted) return;

                            setState(() {
                              parentName = name;
                              relationship = selectedRelationship;
                              phone = phoneText;
                            });

                            Navigator.pop(context);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Profile updated successfully'),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.toString().replaceAll('Exception: ', ''),
                                ),
                              ),
                            );
                          } finally {
                            setDialogState(() => isSaving = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _mainBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(isSaving ? 'Saving...' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  InputDecoration _dialogInputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _mainBlue),
      filled: true,
      fillColor: const Color(0xffF8FCFF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xffBBDEFB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xffBBDEFB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _mainBlue, width: 1.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _softBlue,
      appBar: AppBar(
        title: const Text('Family Profile'),
        backgroundColor: _mainBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: isLoading ? null : _showEditFamilyDialog,
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadFamilyProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _mainCard(),
                    const SizedBox(height: 14),
                    _infoCard(
                      title: 'Family Information',
                      children: [
                        _row('Name', parentName),
                        _row('Relationship', relationship),
                        _row('Phone', phone),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _infoCard(
                      title: 'Linked Patient',
                      children: [
                        _row(
                          'Patient',
                          patientName.isEmpty ? 'Patient' : patientName,
                        ),
                        _row('Email', patientEmail),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _mainCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _mainBlue,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _mainBlue.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.family_restroom_rounded,
              color: _mainBlue,
              size: 38,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            parentName.isEmpty ? 'Family Member' : parentName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            relationship.isEmpty ? '-' : relationship,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withOpacity(0.04), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _textBlue,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xff6D8AA5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? '-' : value,
              style: const TextStyle(
                color: _textBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
