import 'package:flutter/material.dart';

import 'services/glucose_api.dart';
import 'services/ai_activity_api.dart';

class ActivityScreen extends StatefulWidget {
  final String userId;

  const ActivityScreen({super.key, required this.userId});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  bool isLoading = true;
  String? errorMessage;

  double? currentGlucose;
  DateTime? readingTime;

  bool isAiLoading = false;
  Map<String, dynamic>? aiPlan;
  String? aiError;

  static const Color _pageBg = Color(0xffEAF6FF);
  static const Color _mainBlue = Color(0xff185FA5);
  static const Color _darkBlue = Color(0xff0C447C);
  static const Color _softBlue = Color(0xffEEF7FF);
  static const Color _softBlue2 = Color(0xffDCEEFF);
  static const Color _green = Color(0xff1D9E75);
  static const Color _orange = Color(0xffEF9F27);
  static const Color _red = Color(0xffE24B4A);

  @override
  void initState() {
    super.initState();
    _loadLatestReading();
  }

  Future<void> _loadLatestReading() async {
    try {
      final data = await GlucoseApi.getReadings(widget.userId);

      final readings = data.map((e) => ActivityReading.fromApiJson(e)).toList();

      readings.sort((a, b) {
        final timeCompare = a.time.compareTo(b.time);
        if (timeCompare != 0) return timeCompare;

        final aCreated = a.createdAt ?? a.time;
        final bCreated = b.createdAt ?? b.time;
        return aCreated.compareTo(bCreated);
      });

      if (!mounted) return;

      if (readings.isEmpty) {
        setState(() {
          currentGlucose = null;
          readingTime = null;
          isLoading = false;
          errorMessage = null;
          aiPlan = null;
          aiError = null;
          isAiLoading = false;
        });
        return;
      }

      final latest = readings.last;

      setState(() {
        currentGlucose = latest.value;
        readingTime = latest.time;
        isLoading = false;
        errorMessage = null;
        aiPlan = null;
        aiError = null;
        isAiLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load glucose reading';
      });
    }
  }

  ActivityDecision _activityDecision() {
    final glucose = currentGlucose;

    if (glucose == null) {
      return ActivityDecision(
        status: 'No reading yet',
        title: 'Add a glucose reading first',
        message:
            'To suggest a safe activity, please add your current glucose reading first.',
        color: _orange,
        icon: Icons.info_outline_rounded,
        allowActivity: false,
        intensity: 'Unknown',
      );
    }

    if (glucose < 70) {
      return ActivityDecision(
        status: 'Low glucose',
        title: 'Do not exercise now',
        message:
            'Your glucose is low. Treat the low first, recheck after 15 minutes, and start activity only when glucose is back in a safer range.',
        color: _red,
        icon: Icons.warning_amber_rounded,
        allowActivity: false,
        intensity: 'Pause',
      );
    }

    if (glucose < 100) {
      return ActivityDecision(
        status: 'Needs caution',
        title: 'Have a small snack first',
        message:
            'Your glucose is close to low. Consider a small carbohydrate snack and recheck before starting. Choose only very light movement.',
        color: _orange,
        icon: Icons.restaurant_rounded,
        allowActivity: true,
        intensity: 'Very light',
      );
    }

    if (glucose <= 180) {
      return ActivityDecision(
        status: 'Good range',
        title: 'Light activity is suitable',
        message:
            'Your glucose is in a good range for light activity. Start gently and keep water nearby.',
        color: _green,
        icon: Icons.directions_walk_rounded,
        allowActivity: true,
        intensity: 'Light',
      );
    }

    if (glucose <= 250) {
      return ActivityDecision(
        status: 'Slightly high',
        title: 'Choose gentle movement',
        message:
            'Your glucose is a bit high. A calm walk or stretching may be suitable if you feel well. Avoid intense activity.',
        color: _orange,
        icon: Icons.self_improvement_rounded,
        allowActivity: true,
        intensity: 'Gentle',
      );
    }

    return ActivityDecision(
      status: 'High glucose',
      title: 'Avoid intense exercise',
      message:
          'Your glucose is high. Check ketones if this applies to your care plan. Avoid intense activity and follow your doctor’s guidance.',
      color: _red,
      icon: Icons.health_and_safety_outlined,
      allowActivity: false,
      intensity: 'Avoid intense',
    );
  }

  List<ActivityOption> _suggestedActivities() {
    final glucose = currentGlucose;

    if (glucose == null) {
      return [];
    }

    if (glucose < 70) {
      return [
        ActivityOption(
          title: 'Rest and recheck',
          duration: '15 min',
          intensity: 'Safety first',
          icon: Icons.timer_rounded,
          description:
              'Treat the low glucose, rest, and recheck before any movement.',
          color: _red,
        ),
      ];
    }

    if (glucose < 100) {
      return [
        ActivityOption(
          title: 'Slow indoor walk',
          duration: '5–10 min',
          intensity: 'Very light',
          icon: Icons.directions_walk_rounded,
          description:
              'Only after a small snack if needed. Keep it slow and stop if symptoms appear.',
          color: _orange,
        ),
        ActivityOption(
          title: 'Gentle stretching',
          duration: '5–8 min',
          intensity: 'Very light',
          icon: Icons.self_improvement_rounded,
          description:
              'Simple neck, shoulder, and leg stretches without effort.',
          color: _orange,
        ),
      ];
    }

    if (glucose <= 180) {
      return [
        ActivityOption(
          title: 'Easy walking',
          duration: '15–25 min',
          intensity: 'Light',
          icon: Icons.directions_walk_rounded,
          description:
              'A comfortable walk that keeps breathing normal and relaxed.',
          color: _green,
        ),
        ActivityOption(
          title: 'Light stretching',
          duration: '10 min',
          intensity: 'Light',
          icon: Icons.self_improvement_rounded,
          description:
              'Gentle full-body stretching to improve flexibility and reduce stiffness.',
          color: _green,
        ),
        ActivityOption(
          title: 'Simple home movement',
          duration: '10–15 min',
          intensity: 'Light',
          icon: Icons.home_rounded,
          description:
              'Slow step-touch, arm circles, and gentle seated movements.',
          color: _green,
        ),
      ];
    }

    if (glucose <= 250) {
      return [
        ActivityOption(
          title: 'Calm walk',
          duration: '10–15 min',
          intensity: 'Gentle',
          icon: Icons.directions_walk_rounded,
          description: 'Keep it calm. Avoid running or intense workouts.',
          color: _orange,
        ),
        ActivityOption(
          title: 'Breathing + stretching',
          duration: '8–10 min',
          intensity: 'Gentle',
          icon: Icons.air_rounded,
          description:
              'Relaxed breathing with gentle stretching. Stop if you feel unwell.',
          color: _orange,
        ),
      ];
    }

    return [
      ActivityOption(
        title: 'Rest and monitor',
        duration: 'Now',
        intensity: 'No intense activity',
        icon: Icons.monitor_heart_outlined,
        description:
            'Avoid intense exercise. Follow your care plan and contact a professional if needed.',
        color: _red,
      ),
    ];
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '--';

    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  String _glucoseText() {
    if (currentGlucose == null) return '--';
    return currentGlucose!.toStringAsFixed(0);
  }

  Color _glucoseColor() {
    final value = currentGlucose;

    if (value == null) return _orange;
    if (value < 70 || value > 250) return _red;
    if (value > 180 || value < 100) return _orange;
    return _green;
  }

  Map<String, dynamic> _activityPayloadForAi() {
    final decision = _activityDecision();
    final activities = _suggestedActivities();

    return {
      'currentGlucose': currentGlucose?.round(),
      'readingTime': readingTime?.toIso8601String(),
      'status': decision.status,
      'recommendedIntensity': decision.intensity,
      'allowActivity': decision.allowActivity,
      'suggestedActivities': activities
          .map(
            (a) => {
              'title': a.title,
              'duration': a.duration,
              'intensity': a.intensity,
              'description': a.description,
            },
          )
          .toList(),
      'safetyInstruction':
          'Do not prescribe insulin doses or treatment changes. Give safe light activity suggestions only.',
    };
  }

  Future<void> _generateAiActivityPlan() async {
    if (isAiLoading) return;

    setState(() {
      isAiLoading = true;
      aiError = null;
      aiPlan = null;
    });

    try {
      final result = await AiActivityApi.analyzeActivity(
        activity: _activityPayloadForAi(),
      );

      if (!mounted) return;

      setState(() {
        aiPlan = result;
        isAiLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        aiError = e.toString().replaceAll('Exception: ', '');
        isAiLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final decision = _activityDecision();
    final activities = _suggestedActivities();

    return Scaffold(
      backgroundColor: _pageBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadLatestReading,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  isWide ? 28 : 16,
                  14,
                  isWide ? 28 : 16,
                  24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isWide ? 1180 : 620),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 14),
                        if (isLoading)
                          const Padding(
                            padding: EdgeInsets.only(top: 120),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (errorMessage != null)
                          _emptyCard(errorMessage!)
                        else if (isWide)
                          _buildWideLayout(decision, activities)
                        else
                          _buildMobileLayout(decision, activities),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(
    ActivityDecision decision,
    List<ActivityOption> activities,
  ) {
    return Column(
      children: [
        _buildGlucoseCard(decision),
        const SizedBox(height: 12),
        _buildSafetyCard(decision),
        const SizedBox(height: 12),
        _buildActivitiesCard(activities),
        const SizedBox(height: 12),
        _buildAiActivityCard(),
      ],
    );
  }

  Widget _buildWideLayout(
    ActivityDecision decision,
    List<ActivityOption> activities,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Column(
            children: [
              _buildGlucoseCard(decision),
              const SizedBox(height: 12),
              _buildSafetyCard(decision),
              const SizedBox(height: 12),
              _buildAiActivityCard(),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          flex: 6,
          child: Column(children: [_buildActivitiesCard(activities)]),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        _circleButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.pop(context),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Activity',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: _darkBlue,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Smart light exercise suggestions',
                style: TextStyle(fontSize: 13, color: Color(0xff378ADD)),
              ),
            ],
          ),
        ),
        _circleButton(icon: Icons.refresh_rounded, onTap: _loadLatestReading),
      ],
    );
  }

  Widget _circleButton({required IconData icon, VoidCallback? onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black.withOpacity(0.05), width: 0.5),
        ),
        child: Icon(icon, size: 18, color: const Color(0xff378ADD)),
      ),
    );
  }

  Widget _buildGlucoseCard(ActivityDecision decision) {
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
      child: Row(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.13),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(decision.icon, color: Colors.white, size: 34),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CURRENT GLUCOSE',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.end,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      _glucoseText(),
                      style: TextStyle(
                        color: _glucoseColor(),
                        fontSize: 38,
                        height: 1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 5),
                      child: Text(
                        'mg/dL',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${decision.status} · Last reading ${_formatTime(readingTime)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyCard(ActivityDecision decision) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: decision.color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: decision.color.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: decision.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(decision.icon, color: decision.color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  decision.title,
                  style: TextStyle(
                    color: decision.color,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  decision.message,
                  style: const TextStyle(
                    color: Color(0xff5F7F99),
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Recommended intensity: ${decision.intensity}',
                    style: TextStyle(
                      color: decision.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesCard(List<ActivityOption> activities) {
    return _whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.directions_run_rounded,
            title: 'Suggested Activities',
            subtitle: 'Light exercises based on current glucose',
          ),
          const SizedBox(height: 14),
          if (activities.isEmpty)
            const Text(
              'Add a glucose reading to get smart activity suggestions.',
              style: TextStyle(color: Color(0xff5F7F99), fontSize: 12.5),
            )
          else
            ...activities.map(
              (activity) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _activityTile(activity),
              ),
            ),
        ],
      ),
    );
  }

  Widget _activityTile(ActivityOption activity) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _softBlue,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffD8EBFF)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: activity.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(activity.icon, color: activity.color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(
                    color: _darkBlue,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  activity.description,
                  style: const TextStyle(
                    color: Color(0xff5F7F99),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _miniBadge(activity.duration, Icons.timer_outlined),
                    _miniBadge(activity.intensity, Icons.speed_rounded),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniBadge(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: _mainBlue),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: _mainBlue,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiActivityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withOpacity(0.05), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.auto_awesome_rounded,
            title: 'AI Activity Coach',
            subtitle: 'Safe personalized explanation',
          ),
          const SizedBox(height: 14),
          if (aiPlan == null && aiError == null && !isAiLoading) ...[
            const Text(
              'Generate a safe AI explanation for your activity plan. It will not suggest insulin doses or treatment changes.',
              style: TextStyle(
                color: Color(0xff5F7F99),
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: currentGlucose == null
                    ? null
                    : _generateAiActivityPlan,
                icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                label: const Text('Generate AI Activity Plan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _mainBlue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
          if (isAiLoading) ...[
            const SizedBox(height: 12),
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'Building a safe activity plan...',
                style: TextStyle(color: Color(0xff7A9AB5), fontSize: 12),
              ),
            ),
          ],
          if (aiError != null) ...[
            Text(
              aiError!,
              style: const TextStyle(color: Colors.red, fontSize: 12.5),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: _generateAiActivityPlan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _mainBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Try Again'),
              ),
            ),
          ],
          if (aiPlan != null) ...[
            _aiRiskBadge(aiPlan!['riskLevel']?.toString() ?? 'medium'),
            const SizedBox(height: 12),
            _aiTextBlock(
              title: 'Summary',
              text: aiPlan!['summary']?.toString() ?? '--',
            ),
            _aiListBlock(title: 'Plan', items: aiPlan!['plan']),
            _aiListBlock(
              title: 'Safe Activities',
              items: aiPlan!['safeActivities'],
            ),
            _aiListBlock(title: 'Avoid', items: aiPlan!['avoid']),
            _aiListBlock(
              title: 'Questions for Doctor',
              items: aiPlan!['doctorQuestions'],
            ),
            const SizedBox(height: 8),
            Text(
              aiPlan!['warning']?.toString() ??
                  'AI activity plan is not medical advice.',
              style: const TextStyle(
                color: Color(0xff7A9AB5),
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _aiRiskBadge(String riskLevel) {
    Color color;

    if (riskLevel.toLowerCase() == 'low') {
      color = _green;
    } else if (riskLevel.toLowerCase() == 'high') {
      color = _red;
    } else {
      color = _orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Risk level: ${riskLevel.toUpperCase()}',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _aiTextBlock({required String title, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _darkBlue,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xff5F7F99),
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _aiListBlock({required String title, required dynamic items}) {
    final list = items is List ? items : [];

    if (list.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _darkBlue,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          ...list.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(
                      color: _mainBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item.toString(),
                      style: const TextStyle(
                        color: Color(0xff5F7F99),
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _whiteCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withOpacity(0.05), width: 0.5),
      ),
      child: child,
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _softBlue2,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: _mainBlue, size: 22),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _darkBlue,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xff7A9AB5),
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _emptyCard(String message) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 80),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const Icon(Icons.directions_run_rounded, color: _mainBlue, size: 48),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _darkBlue,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class ActivityReading {
  final String? id;
  final double value;
  final DateTime time;
  final DateTime? createdAt;

  ActivityReading({
    this.id,
    required this.value,
    required this.time,
    this.createdAt,
  });

  factory ActivityReading.fromApiJson(Map<String, dynamic> json) {
    return ActivityReading(
      id: json['_id']?.toString(),
      value: (json['value'] as num).toDouble(),
      time: DateTime.parse(json['readingTime']),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}

class ActivityDecision {
  final String status;
  final String title;
  final String message;
  final Color color;
  final IconData icon;
  final bool allowActivity;
  final String intensity;

  ActivityDecision({
    required this.status,
    required this.title,
    required this.message,
    required this.color,
    required this.icon,
    required this.allowActivity,
    required this.intensity,
  });
}

class ActivityOption {
  final String title;
  final String duration;
  final String intensity;
  final IconData icon;
  final String description;
  final Color color;

  ActivityOption({
    required this.title,
    required this.duration,
    required this.intensity,
    required this.icon,
    required this.description,
    required this.color,
  });
}
