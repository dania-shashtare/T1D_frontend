import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WaterTrackerPage extends StatefulWidget {
  final String userId;

  const WaterTrackerPage({super.key, required this.userId});

  @override
  State<WaterTrackerPage> createState() => _WaterTrackerPageState();
}

class _WaterTrackerPageState extends State<WaterTrackerPage>
    with SingleTickerProviderStateMixin {
  bool isLoading = true;

  int amountMl = 0;
  int goalMl = 2000;
  int weightKg = 0;
  int percentage = 0;

  DateTime selectedDate = DateTime.now();

  late AnimationController _controller;
  late Animation<double> _bounceAnimation;

  static const String baseUrl = 'http://10.0.2.2:5000/api/water';
  // للويب استخدمي:
  // static const String baseUrl = 'http://localhost:5000/api/water';

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(
      begin: 0,
      end: -10,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    fetchTodayWater();
  }

  String formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> fetchTodayWater() async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/${widget.userId}/today?date=${formatDate(selectedDate)}',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          amountMl = data['amountMl'] ?? 0;
          goalMl = data['goalMl'] ?? 2000;
          weightKg = data['weightKg'] ?? 0;
          percentage = data['percentage'] ?? 0;
          isLoading = false;
        });
      } else {
        setState(() {
          amountMl = 0;
          percentage = 0;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Fetch water error: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> addWater(int ml) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': widget.userId,
          'amountMl': ml,
          'date': formatDate(selectedDate),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          amountMl = data['amountMl'] ?? amountMl;
          goalMl = data['goalMl'] ?? goalMl;
          weightKg = data['weightKg'] ?? weightKg;
          percentage = data['percentage'] ?? percentage;
        });
      }
    } catch (e) {
      debugPrint('Add water error: $e');
    }
  }

  void goPreviousDay() {
    setState(() {
      selectedDate = selectedDate.subtract(const Duration(days: 1));
      isLoading = true;
    });
    fetchTodayWater();
  }

  void goNextDay() {
    setState(() {
      selectedDate = selectedDate.add(const Duration(days: 1));
      isLoading = true;
    });
    fetchTodayWater();
  }

  void showCustomDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Add custom amount'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Example: 300',
              suffixText: 'ml',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = int.tryParse(controller.text);
                if (value != null && value > 0) {
                  addWater(value);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  String getMascotImage() {
    if (percentage < 40) {
      return 'lib/assets/images/water_sad.png';
    } else if (percentage < 80) {
      return 'lib/assets/images/water_normal.png';
    } else {
      return 'lib/assets/images/water_happy.png';
    }
  }

  String getMascotText() {
    if (percentage < 40) {
      return 'I feel tired... need water 💧';
    } else if (percentage < 80) {
      return 'Keep going, almost there 💙';
    } else {
      return 'Great job! I feel energetic ⚡';
    }
  }

  double getMascotOpacity() {
    return 1.0;
  }

  double getMascotScale() {
    if (percentage < 40) return 0.95;
    if (percentage < 80) return 1.0;
    return 1.08;
  }

  Color getMainBlue() {
    if (percentage < 40) return const Color(0xFF8BBDEB);
    if (percentage < 80) return const Color(0xFF3B91D8);
    return const Color(0xFF1976D2);
  }

  @override
  Widget build(BuildContext context) {
    final progress = goalMl == 0 ? 0.0 : (amountMl / goalMl).clamp(0.0, 1.0);
    final remainingMl = (goalMl - amountMl).clamp(0, goalMl);
    final amountL = (amountMl / 1000).toStringAsFixed(1);
    final goalL = (goalMl / 1000).toStringAsFixed(1);
    final remainingL = (remainingMl / 1000).toStringAsFixed(1);

    return Scaffold(
      backgroundColor: const Color(0xFFEAF7FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEAF7FF),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Water Tracker',
          style: TextStyle(
            color: Color(0xFF1E3A5F),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1E3A5F)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: goPreviousDay,
                        icon: const Icon(
                          Icons.chevron_left,
                          color: Color(0xFF1E3A5F),
                          size: 30,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          formatDate(selectedDate),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A5F),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: goNextDay,
                        icon: const Icon(
                          Icons.chevron_right,
                          color: Color(0xFF1E3A5F),
                          size: 30,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        AnimatedBuilder(
                          animation: _bounceAnimation,
                          builder: (context, child) {
                            final move = percentage >= 80
                                ? _bounceAnimation.value
                                : 0.0;

                            return Transform.translate(
                              offset: Offset(0, move),
                              child: AnimatedScale(
                                scale: getMascotScale(),
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOut,
                                child: AnimatedOpacity(
                                  opacity: getMascotOpacity(),
                                  duration: const Duration(milliseconds: 500),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 400),
                                    child: Image.asset(
                                      getMascotImage(),
                                      key: ValueKey(getMascotImage()),
                                      height: 160,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        Text(
                          getMascotText(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: getMainBlue(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 105,
                          height: 105,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 105,
                                height: 105,
                                child: CircularProgressIndicator(
                                  value: progress,
                                  strokeWidth: 11,
                                  backgroundColor: const Color(0xFFD7ECFF),
                                  color: getMainBlue(),
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    amountL,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E3A5F),
                                    ),
                                  ),
                                  const Text(
                                    'liters',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Daily goal',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                '$goalL L',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E3A5F),
                                ),
                              ),
                              Text(
                                'Based on weight $weightKg kg',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 8,
                                  backgroundColor: const Color(0xFFD7ECFF),
                                  color: getMainBlue(),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '$percentage% done — $remainingL L remaining',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Expanded(
                        child: waterButton('+ 150 ml', () => addWater(150)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: waterButton('+ 250 ml', () => addWater(250)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: waterButton('+ Custom', showCustomDialog),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Blood sugar & water',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A5F),
                          ),
                        ),
                        const SizedBox(height: 14),
                        waterInfoMessage(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Summary for ${formatDate(selectedDate)}',
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A5F),
                          ),
                        ),
                        const SizedBox(height: 14),
                        summaryRow('Drunk', '$amountL L'),
                        summaryRow('Daily goal', '$goalL L'),
                        summaryRow('Remaining', '$remainingL L'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget waterButton(String text, VoidCallback onTap) {
    final isCustom = text.contains('Custom');

    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: isCustom ? const Color(0xFF1976D2) : Colors.white,
          foregroundColor: isCustom ? Colors.white : const Color(0xFF1E3A5F),
          side: BorderSide(
            color: isCustom ? const Color(0xFF1976D2) : Colors.grey.shade300,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }

  Widget waterInfoMessage() {
    String message;

    if (percentage < 40) {
      message =
          'Your water intake is low. Drink a glass of water now to help your body stay hydrated.';
    } else if (percentage < 80) {
      message = 'Good progress. Keep drinking small amounts during the day.';
    } else {
      message = 'Excellent! You are close to your daily water goal.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF1976D2)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF1565C0),
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget summaryRow(String title, String value) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1E3A5F),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const Divider(height: 24),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}