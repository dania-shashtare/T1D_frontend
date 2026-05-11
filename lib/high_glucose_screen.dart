import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'dart:async';
import 'notification_service.dart';
import 'services/firebase_notification_service.dart';

class HighGlucoseScreen extends StatefulWidget {
  final double glucoseValue;
  final String userId;
  final double? correctionFactor;
  final double targetGlucose;

  const HighGlucoseScreen({
    super.key,
    required this.glucoseValue,
    required this.userId,
    required this.correctionFactor,
    this.targetGlucose = 120,
  });

  @override
  State<HighGlucoseScreen> createState() => _HighGlucoseScreenState();
}

class _HighGlucoseScreenState extends State<HighGlucoseScreen>
    with SingleTickerProviderStateMixin {
  bool reminderEnabled = true;
  late final AnimationController _mascotController;

  static const Color _headerOrange = Color(0xFFF28C28);
  static const Color _pageBlue = Color(0xFFEAF6FF);
  static const Color _darkBlue = Color(0xFF1D5FAE);
  static const Color _cardBg = Colors.white;
  static const Color _borderColor = Color(0xFFFFD5A8);
  static const Color _textDark = Color(0xFF5A3A16);
  static const Color _textSubtle = Color(0xFF7A6B5A);

  @override
  void initState() {
    super.initState();
    _mascotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _mascotController.dispose();
    super.dispose();
  }

  double? get _suggestedDose {
    final factor = widget.correctionFactor;

    if (factor == null || factor <= 0) return null;

    final diff = widget.glucoseValue - widget.targetGlucose;
    if (diff <= 0) return 0;

    final rawDose = diff / factor;

    final roundedDose = rawDose.roundToDouble();

    if (roundedDose < 0) return 0;
    return roundedDose;
  }

  String get _doseText {
    final dose = _suggestedDose;
    if (dose == null) return '--';

    if (dose == dose.roundToDouble()) {
      return '${dose.toInt()} units';
    }

    return '${dose.toStringAsFixed(1)} units';
  }

  bool get _hasCorrectionFactor {
    final factor = widget.correctionFactor;
    return factor != null && factor > 0;
  }

  Future<void> _confirmCorrection() async {
    if (!mounted) return;

    if (reminderEnabled) {
      Timer(const Duration(hours: 2), () async {
        try {
          await NotificationService.showHighGlucoseNotification();

          await FirebaseNotificationService.saveNotificationToFirestore(
            userId: widget.userId,
            title: 'High glucose follow-up',
            body: '2 hours passed. Please recheck your glucose.',
            type: 'high_glucose_followup',
          );
        } catch (e) {
          debugPrint('High glucose notification failed: $e');
        }
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          reminderEnabled
              ? 'Saved. Recheck reminder is set for 2 hours.'
              : 'Saved. Correction confirmed.',
        ),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBlue,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 700;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(isMobile),
                  const SizedBox(height: 18),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16 : 26,
                    ),
                    child: _buildInfoCard(),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16 : 26,
                    ),
                    child: _buildDoseCard(),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16 : 26,
                    ),
                    child: _buildReminderCard(isMobile),
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16 : 26,
                    ),
                    child: _buildConfirmButton(),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 20 : 30,
                    ),
                    child: const Text(
                      'If your glucose stays high, follow your care plan or contact your healthcare team.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _textSubtle,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 18 : 26,
        18,
        isMobile ? 18 : 26,
        24,
      ),
      decoration: const BoxDecoration(
        color: _headerOrange,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: isMobile ? _buildMobileHeader() : _buildWideHeader(),
    );
  }

  Widget _buildMobileHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.maybePop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 17,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'HIGH GLUCOSE ALERT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Center(child: _buildMascot(145)),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              widget.glucoseValue.toStringAsFixed(0),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 58,
                fontWeight: FontWeight.w300,
                height: 0.9,
              ),
            ),
            const SizedBox(width: 10),
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                'mg/dL',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildStatusPill(),
      ],
    );
  }

  Widget _buildWideHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 17,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'HIGH GLUCOSE ALERT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    widget.glucoseValue.toStringAsFixed(0),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 70,
                      fontWeight: FontWeight.w300,
                      height: 0.9,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'mg/dL',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildStatusPill(),
            ],
          ),
        ),
        const SizedBox(width: 20),
        _buildMascot(180),
      ],
    );
  }

  Widget _buildMascot(double size) {
    return AnimatedBuilder(
      animation: _mascotController,
      builder: (context, child) {
        final dy = math.sin(_mascotController.value * 2 * math.pi) * 3;
        final angle = math.sin(_mascotController.value * 2 * math.pi) * 0.008;

        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.rotate(angle: angle, child: child),
        );
      },
      child: SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          'lib/assets/images/mascot_high.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildStatusPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.white, size: 16),
          SizedBox(width: 6),
          Text(
            'High • correction needed',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _borderColor),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What to do',
            style: TextStyle(
              color: _textDark,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Your glucose is high. Take a correction dose if your care plan says so. Drink water and recheck your glucose in 2 hours.',
            style: TextStyle(color: _textDark, fontSize: 15, height: 1.55),
          ),
        ],
      ),
    );
  }

  Widget _buildDoseCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Correction Dose',
            style: TextStyle(
              color: _textDark,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          _valueRow(
            label: 'Current glucose',
            value: '${widget.glucoseValue.toStringAsFixed(0)} mg/dL',
          ),
          const SizedBox(height: 10),
          _valueRow(
            label: 'Target glucose',
            value: '${widget.targetGlucose.toStringAsFixed(0)} mg/dL',
          ),
          const SizedBox(height: 10),
          _valueRow(
            label: 'Correction factor',
            value: widget.correctionFactor == null
                ? '--'
                : '${widget.correctionFactor!.toStringAsFixed(0)} mg/dL per unit',
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4E8),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFF6D0A5)),
            ),
            child: _hasCorrectionFactor
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Suggested correction dose',
                        style: TextStyle(
                          fontSize: 13,
                          color: _textSubtle,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _doseText,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: _headerOrange,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Formula: (Current glucose - Target glucose) / Correction factor',
                        style: TextStyle(fontSize: 12, color: _textSubtle),
                      ),
                    ],
                  )
                : const Text(
                    'No correction factor found. Please follow your doctor’s plan.',
                    style: TextStyle(
                      fontSize: 14,
                      color: _textDark,
                      height: 1.5,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(bool isMobile) {
    final switchWidget = Switch(
      value: reminderEnabled,
      activeColor: Colors.white,
      activeTrackColor: const Color(0xFFFFC07A),
      inactiveThumbColor: Colors.white,
      inactiveTrackColor: Colors.white24,
      onChanged: (v) => setState(() => reminderEnabled = v),
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _headerOrange,
        borderRadius: BorderRadius.circular(24),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.alarm_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const Spacer(),
                    switchWidget,
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Reminder after 2 hours',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Turn this on to get a reminder to recheck your glucose.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.alarm_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reminder after 2 hours',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Turn this on to get a reminder to recheck your glucose.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                switchWidget,
              ],
            ),
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      height: 60,
      child: ElevatedButton(
        onPressed: _confirmCorrection,
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        child: const Text(
          'I Took the Correction Dose',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _valueRow({required String label, required String value}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: _textSubtle,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: _textDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
