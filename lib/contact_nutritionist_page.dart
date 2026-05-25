import 'package:flutter/material.dart';
import '../services/nutritionist_appointment_api.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'payment_screen.dart';

class ContactNutritionistPage extends StatefulWidget {
  final String patientId;

  const ContactNutritionistPage({super.key, required this.patientId});

  @override
  State<ContactNutritionistPage> createState() =>
      _ContactNutritionistPageState();
}

class _ContactNutritionistPageState extends State<ContactNutritionistPage> {
  bool isLoading = true;
  bool hasAppointment = false;

  Map<String, dynamic>? appointmentData;
  List<dynamic> nutritionists = [];
  LatLng getClinicLocation(String workplace) {
    final place = workplace.toLowerCase();

    if (place.contains('tulkarm') || place.contains('طولكرم')) {
      return const LatLng(32.3104, 35.0286);
    }

    if (place.contains('hebron') || place.contains('الخليل')) {
      return const LatLng(31.5326, 35.0998);
    }

    if (place.contains('ramallah') || place.contains('رام الله')) {
      return const LatLng(31.9038, 35.2034);
    }

    if (place.contains('jenin') || place.contains('جنين')) {
      return const LatLng(32.4594, 35.3009);
    }

    if (place.contains('rafidia') || place.contains('رفيديا')) {
      return const LatLng(32.2211, 35.2544);
    }

    if (place.contains('nablus') || place.contains('نابلس')) {
      return const LatLng(32.2211, 35.2544);
    }

    return const LatLng(32.2211, 35.2544);
  }

  @override
  void initState() {
    super.initState();
    loadPage();
  }

  Future<void> loadPage() async {
    setState(() => isLoading = true);

    try {
      final active = await NutritionistAppointmentApi.getActiveAppointment(
        widget.patientId,
      );

      if (active['hasAppointment'] == true) {
        setState(() {
          hasAppointment = true;
          appointmentData = active;
          isLoading = false;
        });
      } else {
        final list = await NutritionistAppointmentApi.getNutritionists();

        setState(() {
          hasAppointment = false;
          nutritionists = list;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Color cardColor(int index) {
    final colors = [
      const Color(0xffDCEBFF),
      const Color(0xffCFF6EA),
      const Color(0xffE9E3FF),
    ];

    return colors[index % colors.length];
  }

  Color mainColor(int index) {
    final colors = [
      const Color(0xff1677E8),
      const Color(0xff008B68),
      const Color(0xff5B45B8),
    ];

    return colors[index % colors.length];
  }

  String getInitials(String name) {
    final parts = name.trim().split(' ').where((e) => e.isNotEmpty).toList();

    if (parts.isEmpty) return 'N';
    if (parts.length == 1) return parts.first[0].toUpperCase();

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  double getRating(dynamic item, int index) {
    if (item['rating'] != null) {
      return double.tryParse(item['rating'].toString()) ?? 4.0;
    }

    return index == 1 ? 5.0 : 4.0;
  }

  Future<void> openMeetingLink(String link) async {
    final cleanLink = link.trim();

    if (cleanLink.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meeting link is not available')),
      );
      return;
    }

    final uri = Uri.parse(cleanLink);

    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );

    if (!opened) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(cleanLink)));
    }
  }

  Future<void> openClinicMap(String workplace) async {
    final cleanPlace = workplace.trim();

    if (cleanPlace.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clinic location is not available')),
      );
      return;
    }

    final encodedPlace = Uri.encodeComponent(cleanPlace);

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$encodedPlace',
    );

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!opened) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open map')));
    }
  }

  Future<void> cancelAppointment(String appointmentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text(
          'Are you sure you want to cancel this appointment?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await NutritionistAppointmentApi.cancelAppointment(appointmentId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment cancelled successfully')),
      );

      loadPage();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> showEditAppointmentDialog(
    Map<String, dynamic> appointment,
  ) async {
    String selectedVisitType = appointment['visitType'] ?? 'online';
    String? selectedDay = appointment['day'];
    String? selectedTime = appointment['time'];

    List<dynamic> editAvailability = [];
    List<String> editDays = [];
    List<String> editSlots = [];

    Future<void> loadEditAvailability(
      void Function(void Function()) setDialogState,
    ) async {
      final data = await NutritionistAppointmentApi.getAvailability(
        nutritionistId: appointment['nutritionistId'] is Map
            ? appointment['nutritionistId']['_id']
            : appointment['nutritionistId'].toString(),
        visitType: selectedVisitType,
      );

      editAvailability = data;
      editDays = data.map((e) => e['day'].toString()).toList();

      if (selectedDay != null && !editDays.contains(selectedDay)) {
        editDays.insert(0, selectedDay!);
      }

      final dayData = editAvailability.firstWhere(
        (item) => item['day'] == selectedDay,
        orElse: () => null,
      );

      editSlots = List<String>.from(dayData?['slots'] ?? []);

      if (selectedTime != null && !editSlots.contains(selectedTime)) {
        editSlots.insert(0, selectedTime!);
      }

      setDialogState(() {});
    }

    await showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            if (editAvailability.isEmpty) {
              Future.microtask(() => loadEditAvailability(setDialogState));
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: const Text('Edit Appointment'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedVisitType,
                      decoration: const InputDecoration(
                        labelText: 'Visit Type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'online',
                          child: Text('Online'),
                        ),
                        DropdownMenuItem(
                          value: 'clinic',
                          child: Text('Clinic'),
                        ),
                      ],
                      onChanged: (value) async {
                        selectedVisitType = value ?? 'online';
                        selectedDay = null;
                        selectedTime = null;
                        editAvailability = [];
                        editDays = [];
                        editSlots = [];

                        setDialogState(() {});
                        await loadEditAvailability(setDialogState);
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: selectedDay,
                      decoration: const InputDecoration(
                        labelText: 'Day',
                        border: OutlineInputBorder(),
                      ),
                      items: editDays.map((day) {
                        return DropdownMenuItem<String>(
                          value: day,
                          child: Text(day),
                        );
                      }).toList(),
                      onChanged: (value) {
                        selectedDay = value;
                        selectedTime = null;

                        final dayData = editAvailability.firstWhere(
                          (item) => item['day'] == selectedDay,
                          orElse: () => null,
                        );

                        editSlots = List<String>.from(dayData?['slots'] ?? []);
                        setDialogState(() {});
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: selectedTime,
                      decoration: const InputDecoration(
                        labelText: 'Time',
                        border: OutlineInputBorder(),
                      ),
                      items: editSlots.map((time) {
                        return DropdownMenuItem<String>(
                          value: time,
                          child: Text(time),
                        );
                      }).toList(),
                      onChanged: (value) {
                        selectedTime = value;
                        setDialogState(() {});
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff1769B5),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (selectedDay == null || selectedTime == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please choose day and time'),
                        ),
                      );
                      return;
                    }

                    try {
                      await NutritionistAppointmentApi.updateAppointment(
                        appointmentId: appointment['_id'],
                        visitType: selectedVisitType,
                        day: selectedDay!,
                        time: selectedTime!,
                      );

                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Appointment updated successfully'),
                        ),
                      );

                      loadPage();
                    } catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffEAF6FF),
      appBar: AppBar(
        title: const Text('Contact Nutritionist'),
        backgroundColor: const Color(0xff5DB9F5),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasAppointment
          ? buildCurrentAppointment()
          : buildNutritionistsList(),
    );
  }

  Widget clinicMapCard(String workplace) {
    final location = getClinicLocation(workplace);

    return Container(
      height: 210,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      clipBehavior: Clip.antiAlias,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(target: location, zoom: 15),
        markers: {
          Marker(
            markerId: const MarkerId('clinic_location'),
            position: location,
            infoWindow: InfoWindow(
              title: 'Clinic Location',
              snippet: workplace,
            ),
          ),
        },
        zoomControlsEnabled: false,
        myLocationButtonEnabled: false,
        mapToolbarEnabled: true,
      ),
    );
  }

  Widget buildCurrentAppointment() {
    final appointment = appointmentData?['appointment'];
    final profile = appointmentData?['nutritionistProfile'];

    final name = profile?['fullName'] ?? 'Nutritionist';
    final specialty = profile?['specialty'] ?? '';
    final visitType = appointment?['visitType'] ?? '';
    final day = appointment?['day'] ?? '';
    final time = appointment?['time'] ?? '';
    final workplace = profile?['workplace'] ?? 'Clinic';
    final meetingLink = appointment?['meetingLink'] ?? '';

    final isOnline = visitType.toString().toLowerCase() == 'online';
    final paymentStatus = appointment?['paymentStatus'] ?? 'not_required';
    final isPaid = paymentStatus == 'paid';
    final isPendingPayment = paymentStatus == 'pending';
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.black.withOpacity(0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.10),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 30, 22, 28),
                decoration: const BoxDecoration(
                  color: Color(0xffE3F2FF),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: const Color(0xff1769B5),
                      child: Text(
                        getInitials(name),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        color: Color(0xff083763),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$specialty Specialist',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xff1769B5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: isOnline
                            ? const Color(0xff1769B5)
                            : const Color(0xff3E7B14),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        isOnline ? 'Online Visit' : 'In-Clinic Visit',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
                child: Column(
                  children: [
                    appointmentDetailsRow(
                      Icons.calendar_today_outlined,
                      'Day',
                      day,
                    ),
                    const SizedBox(height: 18),
                    appointmentDetailsRow(Icons.access_time, 'Time', time),
                    const SizedBox(height: 18),
                    if (isOnline)
                      appointmentDetailsRow(
                        Icons.link,
                        'Session link',
                        meetingLink.isEmpty ? 'Not created yet' : meetingLink,
                      )
                    else
                      Column(
                        children: [
                          appointmentDetailsRow(
                            Icons.business,
                            'Workplace',
                            workplace,
                          ),
                          const SizedBox(height: 18),
                          clinicMapCard(workplace),
                        ],
                      ),

                    const SizedBox(height: 26),

                    if (isOnline)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          children: [
                            Icon(
                              isPaid
                                  ? Icons.check_circle
                                  : Icons.access_time_filled,
                              color: isPaid ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isPaid ? 'Payment Paid' : 'Payment Pending',
                              style: TextStyle(
                                color: isPaid ? Colors.green : Colors.orange,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (isOnline && isPendingPayment)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff1769B5),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          onPressed: () async {
                            final paid = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PaymentScreen(
                                  appointmentId: appointment['_id'],
                                  appointmentType: 'nutritionist',
                                  amount: appointment['paymentAmount'] ?? 10,
                                ),
                              ),
                            );

                            if (paid == true) {
                              loadPage();
                            }
                          },
                          icon: const Icon(Icons.payment),
                          label: const Text(
                            'Pay Now',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                    if (isOnline && isPaid)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff1769B5),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          onPressed: () {
                            print('MEETING LINK = $meetingLink');
                            openMeetingLink(meetingLink);
                          },
                          icon: const Icon(Icons.video_call),
                          label: const Text(
                            'Join Meeting',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                    if (isOnline) const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 54,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xff1769B5),
                                side: const BorderSide(
                                  color: Color(0xff1769B5),
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              onPressed: () {
                                showEditAppointmentDialog(appointment);
                              },
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text(
                                'Edit',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 54,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xffE53935),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              onPressed: () {
                                cancelAppointment(appointment['_id']);
                              },
                              icon: const Icon(Icons.delete_outline),
                              label: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget appointmentDetailsRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xffD8E9FA),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: const Color(0xff1769B5), size: 26),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.black54, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: title == 'Session link' ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xff202020),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildNutritionistsList() {
    if (nutritionists.isEmpty) {
      return const Center(child: Text('No nutritionists available now'));
    }

    return RefreshIndicator(
      onRefresh: loadPage,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
        itemCount: nutritionists.length,
        itemBuilder: (context, index) {
          final item = nutritionists[index];
          final name = item['fullName'] ?? 'Nutritionist';
          final specialty = item['specialty'] ?? '';
          final rating = getRating(item, index);

          return InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BookNutritionistPage(
                    patientId: widget.patientId,
                    nutritionist: item,
                    profileColor: cardColor(index),
                    mainColor: mainColor(index),
                  ),
                ),
              );

              if (result == true) {
                loadPage();
              }
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 18),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.black.withOpacity(0.04)),
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: cardColor(index),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            getInitials(name),
                            style: TextStyle(
                              color: mainColor(index),
                              fontSize: 25,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Container(
                          width: 15,
                          height: 15,
                          decoration: BoxDecoration(
                            color: const Color(0xff2ECC71),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.health_and_safety_outlined,
                              size: 14,
                              color: mainColor(index),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                specialty,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: mainColor(index),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ...List.generate(5, (starIndex) {
                              return Icon(
                                starIndex < rating.round()
                                    ? Icons.star
                                    : Icons.star_border,
                                color: const Color(0xffFFC107),
                                size: 16,
                              );
                            }),
                            const SizedBox(width: 6),
                            Text(
                              '(${rating.toStringAsFixed(1)})',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: mainColor(index), size: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class BookNutritionistPage extends StatefulWidget {
  final String patientId;
  final Map<String, dynamic> nutritionist;
  final Color profileColor;
  final Color mainColor;

  const BookNutritionistPage({
    super.key,
    required this.patientId,
    required this.nutritionist,
    required this.profileColor,
    required this.mainColor,
  });

  @override
  State<BookNutritionistPage> createState() => _BookNutritionistPageState();
}

class _BookNutritionistPageState extends State<BookNutritionistPage> {
  String selectedVisitType = 'online';
  String? selectedDay;
  String? selectedTime;

  bool isLoading = false;
  bool isBooking = false;

  List<dynamic> availability = [];
  List<String> slots = [];

  @override
  void initState() {
    super.initState();
    loadAvailability();
  }

  String get nutritionistUserId {
    final user = widget.nutritionist['userId'];

    if (user is Map<String, dynamic>) {
      return user['_id'];
    }

    return user.toString();
  }

  String getInitials(String name) {
    final parts = name.trim().split(' ').where((e) => e.isNotEmpty).toList();

    if (parts.isEmpty) return 'N';
    if (parts.length == 1) return parts.first[0].toUpperCase();

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Future<void> loadAvailability() async {
    setState(() {
      isLoading = true;
      selectedDay = null;
      selectedTime = null;
      slots = [];
    });

    try {
      final data = await NutritionistAppointmentApi.getAvailability(
        nutritionistId: nutritionistUserId,
        visitType: selectedVisitType,
      );

      setState(() {
        availability = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void selectDay(String day) {
    final dayData = availability.firstWhere(
      (item) => item['day'] == day,
      orElse: () => null,
    );

    setState(() {
      selectedDay = day;
      selectedTime = null;
      slots = List<String>.from(dayData['slots'] ?? []);
    });
  }

  Future<void> confirmBooking() async {
    if (selectedDay == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose day and time')),
      );
      return;
    }

    setState(() => isBooking = true);

    try {
      final result = await NutritionistAppointmentApi.bookAppointment(
        patientId: widget.patientId,
        nutritionistId: nutritionistUserId,
        visitType: selectedVisitType,
        day: selectedDay!,
        time: selectedTime!,
      );

      setState(() => isBooking = false);

      final appointment = result['appointment'];

      if (appointment['visitType'] == 'online' &&
          appointment['paymentStatus'] == 'pending') {
        final paid = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentScreen(
              appointmentId: appointment['_id'],
              appointmentType: 'nutritionist',
              amount: appointment['paymentAmount'] ?? 10,
            ),
          ),
        );

        if (paid == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment completed and appointment booked'),
            ),
          );

          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Appointment created, payment is still pending'),
            ),
          );

          Navigator.pop(context, true);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment booked successfully')),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => isBooking = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final nutritionist = widget.nutritionist;
    final name = nutritionist['fullName'] ?? 'Nutritionist';
    final specialty = nutritionist['specialty'] ?? '';
    final years = nutritionist['yearsOfExperience'] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xffEAF6FF),
      appBar: AppBar(
        title: const Text('Book Appointment'),
        backgroundColor: const Color(0xff5DB9F5),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.black.withOpacity(0.04)),
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        color: widget.profileColor,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Center(
                        child: Text(
                          getInitials(name),
                          style: TextStyle(
                            color: widget.mainColor,
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 3,
                      bottom: 3,
                      child: Container(
                        width: 17,
                        height: 17,
                        decoration: BoxDecoration(
                          color: const Color(0xff2ECC71),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xff222222),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  specialty,
                  style: TextStyle(
                    color: widget.mainColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$years years experience',
                  style: const TextStyle(
                    color: Color(0xff2494D8),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Choose visit type',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: Color(0xff222222),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              visitTypeButton('online', 'Online', Icons.video_call),
              const SizedBox(width: 14),
              visitTypeButton('clinic', 'Clinic', Icons.local_hospital),
            ],
          ),
          const SizedBox(height: 28),
          const Text(
            'Available days',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: Color(0xff222222),
            ),
          ),
          const SizedBox(height: 14),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (availability.isEmpty)
            emptyBox('No available days')
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: availability.map((item) {
                final day = item['day'].toString();
                final selected = selectedDay == day;

                return GestureDetector(
                  onTap: () => selectDay(day),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xff5DB9F5) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected
                            ? const Color(0xff5DB9F5)
                            : Colors.grey.shade300,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      day,
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 28),
          const Text(
            'Available times',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: Color(0xff222222),
            ),
          ),
          const SizedBox(height: 14),
          if (selectedDay == null)
            emptyBox('Choose a day first')
          else if (slots.isEmpty)
            emptyBox('No times available')
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: slots.map((time) {
                final selected = selectedTime == time;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedTime = time;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xff2494D8) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected
                            ? const Color(0xff2494D8)
                            : Colors.grey.shade300,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      time,
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 34),
          SizedBox(
            height: 60,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff2494D8),
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: Colors.blue.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: isBooking ? null : confirmBooking,
              child: isBooking
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Confirm Booking',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget emptyBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black54,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget visitTypeButton(String value, String text, IconData icon) {
    final selected = selectedVisitType == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedVisitType = value;
          });

          loadAvailability();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 100,
          decoration: BoxDecoration(
            color: selected ? const Color(0xff5DB9F5) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? const Color(0xff5DB9F5) : Colors.grey.shade300,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(selected ? 0.18 : 0.08),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 28,
                color: selected ? Colors.white : const Color(0xff2494D8),
              ),
              const SizedBox(height: 8),
              Text(
                text,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
