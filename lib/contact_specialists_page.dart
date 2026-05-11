import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'chat_page.dart';

class ContactSpecialistsPage extends StatefulWidget {
  final String role; // doctor أو nutritionist
  final String currentUserId; // patient userId

  const ContactSpecialistsPage({
    super.key,
    required this.role,
    required this.currentUserId,
  });

  @override
  State<ContactSpecialistsPage> createState() => _ContactSpecialistsPageState();
}

class _ContactSpecialistsPageState extends State<ContactSpecialistsPage> {
  bool isLoading = true;
  List specialists = [];

  static const String baseUrl = 'http://10.0.2.2:5000/api';

  @override
  void initState() {
    super.initState();
    fetchSpecialists();
  }

  Future<void> fetchSpecialists() async {
    try {
      final String endpoint = widget.role == 'doctor'
          ? '$baseUrl/doctor-appointments/doctors'
          : '$baseUrl/nutritionist-appointments/nutritionists';

      final response = await http.get(Uri.parse(endpoint));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          specialists = data;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load ${widget.role}s'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  String getTitle() {
    return widget.role == 'doctor' ? 'Choose Doctor' : 'Choose Nutritionist';
  }

  String getName(Map item) {
    final String fullName = item['fullName']?.toString() ?? '';

    if (fullName.isNotEmpty) {
      return fullName;
    }

    final dynamic userId = item['userId'];

    if (userId is Map) {
      final String firstName = userId['firstName']?.toString() ?? '';
      final String lastName = userId['lastName']?.toString() ?? '';

      final String name = '$firstName $lastName'.trim();

      if (name.isNotEmpty) {
        return name;
      }

      final String email = userId['email']?.toString() ?? '';
      if (email.isNotEmpty) {
        return email;
      }
    }

    return 'No name';
  }

  String getReceiverUserId(Map item) {
    final dynamic userId = item['userId'];

    if (userId == null) return '';

    if (userId is String) {
      return userId;
    }

    if (userId is Map && userId['_id'] != null) {
      return userId['_id'].toString();
    }

    return '';
  }

  String getSubtitle(Map item) {
    final String workplace = item['workplace']?.toString() ?? '';
    final String specialty = item['specialty']?.toString() ?? '';
    final String phone = item['phone']?.toString() ?? '';

    if (specialty.isNotEmpty && workplace.isNotEmpty) {
      return '$specialty\n$workplace';
    }

    if (specialty.isNotEmpty) return specialty;
    if (workplace.isNotEmpty) return workplace;
    if (phone.isNotEmpty) return phone;

    return 'No details';
  }

  String getInitials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.isEmpty) return '?';

    if (parts.length == 1) {
      final word = parts.first;
      return word.length >= 2
          ? word.substring(0, 2).toUpperCase()
          : word.substring(0, 1).toUpperCase();
    }

    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Color getAvatarBackgroundColor(String name) {
    final colors = [
      const Color(0xFFDCE8F8),
      const Color(0xFFD9F0E8),
      const Color(0xFFE8E0F8),
      const Color(0xFFFCE6D6),
      const Color(0xFFF9E0E8),
      const Color(0xFFE2F1FB),
    ];

    return colors[name.hashCode.abs() % colors.length];
  }

  Color getAvatarTextColor(String name) {
    final colors = [
      const Color(0xFF2C72D6),
      const Color(0xFF178E6B),
      const Color(0xFF6A5ACD),
      const Color(0xFFD07A2D),
      const Color(0xFFC14E7A),
      const Color(0xFF2678A8),
    ];

    return colors[name.hashCode.abs() % colors.length];
  }

  Widget buildProfileAvatar(String name) {
    final bgColor = getAvatarBackgroundColor(name);
    final textColor = getAvatarTextColor(name);
    final initials = getInitials(name);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(18),
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: TextStyle(
              color: textColor,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Positioned(
          right: -1,
          bottom: -1,
          child: Container(
            width: 14,
            height: 14,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(
                color: Color(0xFF2ECC71),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FBFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6FBFF),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: Color(0xFF0B4F8A),
        ),
        title: Text(
          getTitle(),
          style: const TextStyle(
            color: Color(0xFF0B4F8A),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : specialists.isEmpty
              ? Center(
                  child: Text(
                    widget.role == 'doctor'
                        ? 'No doctors found'
                        : 'No nutritionists found',
                    style: const TextStyle(
                      color: Color(0xFF0B4F8A),
                      fontSize: 16,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: specialists.length,
                  itemBuilder: (context, index) {
                    final Map item = specialists[index];

                    final String name = getName(item);
                    final String receiverUserId = getReceiverUserId(item);
                    final String subtitle = getSubtitle(item);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF6FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFD3ECFF),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(14),
                        leading: buildProfileAvatar(name),
                        title: Text(
                          name,
                          style: const TextStyle(
                            color: Color(0xFF0B4F8A),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.blueGrey.shade600,
                              height: 1.3,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chat_bubble_outline,
                          color: Color(0xFF1976C9),
                        ),
                        onTap: () {
                          if (receiverUserId.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('This account has no userId'),
                              ),
                            );
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatPage(
                                currentUserId: widget.currentUserId,
                                receiverId: receiverUserId,
                                receiverName: name,
                                receiverRole: widget.role,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}