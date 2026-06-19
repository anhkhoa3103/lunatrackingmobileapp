  import 'package:flutter/material.dart';
  import 'dart:math';
  import '../models/cycle_entry.dart';
  import '../services/api_service.dart';
  import '../services/storage_service.dart';
  import 'log_screen.dart';
  import 'calendar_screen.dart';
  import 'insights_screen.dart';
  import 'profile_screen.dart';
  import 'login_screen.dart';

  class HomeScreen extends StatefulWidget {
    const HomeScreen({super.key});
    @override
    State<HomeScreen> createState() => _HomeScreenState();
  }

  class _HomeScreenState extends State<HomeScreen> {
    int _selectedTab = 0;
    int _currentDay  = 1;
    int _cycleLength = 28;
    DateTime _cycleStart = DateTime.now();
    Map<String, CycleEntry> _logs = {};
    bool _loading = true;
    String _userName  = '';
    String _userEmail = '';

    final List<CyclePhase> phases = [
      CyclePhase('Menstrual',  1,  5,  Color(0xFFE05D6F), 'Rest, stay warm, track your flow.'),
      CyclePhase('Follicular', 6,  13, Color(0xFFF5A623), 'Energy rising. Great time for new things.'),
      CyclePhase('Ovulation',  14, 16, Color(0xFF1D9E75), 'Peak fertility. High energy & confidence.'),
      CyclePhase('Luteal',     17, 28, Color(0xFF5B8CDE), 'Wind-down phase. Rest and reduce stress.'),
    ];

    @override
    void initState() {
      super.initState();
      _loadCycleData();
    }

    Future<void> _loadCycleData() async {
      setState(() => _loading = true);
      try {
        final remote = await ApiService.getAllEntries();
        final map = <String, CycleEntry>{};
        DateTime? lastCycleStart;

        // Sort by date
        final entries = remote
            .map((e) => MapEntry(DateTime.parse(e['date']), e))
            .toList()
          ..sort((a, b) => a.key.compareTo(b.key));

        for (final e in entries) {
          final key   = _dateKey(e.key);
          final flow  = e.value['flow'] ?? 'none';
          map[key] = CycleEntry(
            date:     e.key,
            flow:     flow,
            moods:    List<String>.from(e.value['moods'] ?? []),
            symptoms: List<String>.from(e.value['symptoms'] ?? []),
            energy:   e.value['energy'] ?? '',
            sleep:    e.value['sleep'] ?? '',
            notes:    e.value['notes'] ?? '',
          );
          // Track most recent on-cycle start
          if (flow == 'medium' || flow == 'heavy') {
            lastCycleStart = e.key;
          }
        }

        setState(() {
          _logs       = map;
          _cycleStart = lastCycleStart ?? DateTime.now();
          _currentDay = DateTime.now()
              .difference(_cycleStart).inDays + 1;
          _currentDay = _currentDay.clamp(1, _cycleLength);
          _loading    = false;
        });

        _userName  = await ApiService.getUserName();
        _userEmail = await ApiService.getUserEmail();
      } catch (_) {
        // Fallback to local
        final entries = StorageService.getAllEntries();
        DateTime? lastCycleStart;
        for (final e in entries) {
          if (e.flow == 'medium' || e.flow == 'heavy') {
            lastCycleStart = e.date;
          }
        }
        setState(() {
          _cycleStart = lastCycleStart ?? DateTime.now();
          _currentDay = DateTime.now()
              .difference(_cycleStart).inDays + 1;
          _currentDay = _currentDay.clamp(1, _cycleLength);
          _loading    = false;
        });
      }
    }

    CyclePhase get _currentPhase => phases.firstWhere(
            (p) => _currentDay >= p.startDay && _currentDay <= p.endDay,
        orElse: () => phases.last);

    // ── Compute the actual date for a given cycle day ────────────
    DateTime _dateForDay(int day) =>
        _cycleStart.add(Duration(days: day - 1));

    String _dateKey(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-'
            '${d.day.toString().padLeft(2, '0')}';

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: Colors.white,
        drawer: _buildDrawer(),
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(
                    color: Color(0xFFE05D6F)))
                    : SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      _buildCycleRing(),
                      const SizedBox(height: 20),
                      _buildLegend(),
                      const SizedBox(height: 20),
                      _buildTodayCard(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              _buildBottomNav(),
            ],
          ),
        ),
      );
    }

    Widget _buildDrawer() {
      final initials = _userName.isEmpty ? '?'
          : _userName.trim().split(' ').length >= 2
          ? '${_userName.trim().split(' ')[0][0]}'
          '${_userName.trim().split(' ')[1][0]}'.toUpperCase()
          : _userName[0].toUpperCase();

      return Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              color: const Color(0xFFE05D6F),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 20, right: 20, bottom: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.25),
                    ),
                    child: Center(
                      child: Text(initials,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(_userName,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(_userEmail,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.75))),
                ],
              ),
            ),

            // Menu items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _drawerItem(Icons.circle_outlined,
                      'Cycle', onTap: () {
                        Navigator.pop(context);
                      }),
                  _drawerItem(Icons.calendar_today_outlined,
                      'Calendar', onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(
                            builder: (_) => const CalendarScreen()))
                            .then((_) => _loadCycleData());
                      }),
                  _drawerItem(Icons.bar_chart,
                      'Insights', onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(
                            builder: (_) => const InsightsScreen()));
                      }),
                  const Divider(height: 1),
                  _drawerItem(Icons.person_outline,
                      'View profile', onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(
                            builder: (_) => const ProfileScreen()))
                            .then((_) => _loadCycleData());
                      }),
                  _drawerItem(Icons.notifications_outlined,
                      'Notifications', onTap: () {
                        Navigator.pop(context);
                      }),
                  const Divider(height: 1),
                  _drawerItem(Icons.logout,
                      'Log out',
                      color: const Color(0xFFE24B4A),
                      onTap: _confirmLogout),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget _drawerItem(IconData icon, String label,
        {VoidCallback? onTap, Color? color}) {
      final c = color ?? Colors.grey[700]!;
      return ListTile(
        leading: Icon(icon, size: 20, color: c),
        title: Text(label,
            style: TextStyle(fontSize: 13, color: c)),
        onTap: onTap,
        dense: true,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 20),
      );
    }

    void _confirmLogout() {
      Navigator.pop(context); // close drawer first
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Text('Log out',
              style: TextStyle(fontSize: 16)),
          content: const Text(
              'Are you sure you want to log out?',
              style: TextStyle(fontSize: 14)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: TextStyle(color: Colors.grey[600])),
            ),
            TextButton(
              onPressed: () async {
                await ApiService.logout();
                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const LoginScreen()),
                      (_) => false,
                );
              },
              child: const Text('Log out',
                  style: TextStyle(color: Color(0xFFE24B4A))),
            ),
          ],
        ),
      );
    }

    // ── Top bar ──────────────────────────────────────────────────
    Widget _buildTopBar() {
      return Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 12),
        child: Row(
          children: [
            // Hamburger menu
            Builder(
              builder: (scaffoldContext) => GestureDetector(
                onTap: () => Scaffold.of(scaffoldContext).openDrawer(),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: const Icon(Icons.menu, size: 18),
                ),
              ),
            ),
            const Spacer(),
            Text('Luna Track',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800])),
            const Spacer(),
            // Refresh
            GestureDetector(
              onTap: _loadCycleData,
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: const Icon(Icons.refresh, size: 18),
              ),
            ),
          ],
        ),
      );
    }

    // ── Cycle ring ───────────────────────────────────────────────
    Widget _buildCycleRing() {
      return GestureDetector(
        onPanUpdate: (details) {
          final RenderBox box =
          context.findRenderObject() as RenderBox;
          // Center of the ring on screen
          final center = Offset(
              box.size.width / 2,
              box.size.height / 2 - 60);
          final local =
          box.globalToLocal(details.globalPosition);
          final angle =
          atan2(local.dy - center.dy, local.dx - center.dx);
          double degrees = (angle * 180 / pi) + 90;
          if (degrees < 0) degrees += 360;
          final day =
          ((degrees / 360) * _cycleLength).round().clamp(1, _cycleLength);
          setState(() => _currentDay = day);
        },
        child: SizedBox(
          width: 280, height: 280,
          child: CustomPaint(
            painter: CycleRingPainter(
              phases:      phases,
              currentDay:  _currentDay,
              cycleLength: _cycleLength,
            ),
            child: Center(child: _buildCenterInfo()),
          ),
        ),
      );
    }

    // ── Center info inside ring ──────────────────────────────────
    Widget _buildCenterInfo() {
      final phase       = _currentPhase;
      final date        = _dateForDay(_currentDay);
      final isToday     = _isSameDay(date, DateTime.now());
      final log         = _logs[_dateKey(date)];
      final daysLeft    = _cycleLength - _currentDay;

      // Format date
      const months = ['Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
      final dateLabel = isToday
          ? 'Today'
          : '${date.day} ${months[date.month - 1]}';

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Phase badge
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 3),
            decoration: BoxDecoration(
              color: phase.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(phase.name,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: phase.color)),
          ),
          const SizedBox(height: 6),

          // Date — big and prominent
          Text(dateLabel,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: isToday
                      ? const Color(0xFFE05D6F)
                      : Colors.grey[800])),

          const SizedBox(height: 2),

          // Day x of y
          Text('Day $_currentDay of $_cycleLength',
              style: TextStyle(
                  fontSize: 12, color: Colors.grey[500])),

          const SizedBox(height: 4),

          // Days left or next period
          Text(
            daysLeft == 0
                ? 'Last day of cycle'
                : isToday
                ? '$daysLeft days left'
                : '',
            style: TextStyle(
                fontSize: 11, color: Colors.grey[400]),
          ),

          // Show if logged
          if (log != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle,
                      size: 10, color: const Color(0xFF1D9E75)),
                  const SizedBox(width: 3),
                  Text('Logged',
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey[500])),
                ],
              ),
            ),
          ],
        ],
      );
    }

    // ── Legend ───────────────────────────────────────────────────
    Widget _buildLegend() {
      return Wrap(
        spacing: 16, runSpacing: 8,
        alignment: WrapAlignment.center,
        children: phases.map((p) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                    color: p.color, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text(p.name,
                style: TextStyle(
                    fontSize: 12, color: Colors.grey[600])),
          ],
        )).toList(),
      );
    }

    // ── Today card ───────────────────────────────────────────────
    Widget _buildTodayCard() {
      final todayKey = _dateKey(DateTime.now());
      final todayLog = _logs[todayKey];

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LogScreen(
                date:        DateTime.now(),
                existingLog: todayLog,
              ),
            ),
          ).then((_) => _loadCycleData()),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0EC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: const BoxDecoration(
                      color: Color(0xFFF5A623),
                      shape: BoxShape.circle),
                  child: const Icon(
                      Icons.sentiment_satisfied_alt,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          todayLog != null
                              ? 'Today\'s log ✓'
                              : 'How do you feel today?',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500)),
                      if (todayLog != null)
                        Text(
                            'Flow: ${todayLog.flow}  •  '
                                'Energy: ${todayLog.energy}',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500])),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      );
    }

    // ── Bottom nav ───────────────────────────────────────────────
    Widget _buildBottomNav() {
      final tabs = [
        {'icon': Icons.circle_outlined,        'label': 'Cycle'},
        {'icon': Icons.calendar_today_outlined, 'label': 'Calendar'},
        {'icon': Icons.add_circle,             'label': 'Log'},
        {'icon': Icons.bar_chart,              'label': 'Insights'},
        {'icon': Icons.chat_bubble_outline,    'label': 'AI chat'},
      ];
      return Container(
        decoration: BoxDecoration(
          border: Border(
              top: BorderSide(color: Colors.grey[200]!, width: 0.5)),
        ),
        child: Row(
          children: List.generate(tabs.length, (i) {
            final active = i == _selectedTab;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  if (i == 1) {
                    Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const CalendarScreen()))
                        .then((_) => _loadCycleData());
                  } else if (i == 2) {
                    Navigator.push(context, MaterialPageRoute(
                        builder: (_) => LogScreen(
                          date: DateTime.now(),
                          existingLog: _logs[_dateKey(DateTime.now())],
                        ))).then((_) => _loadCycleData());
                  } else if (i == 3) {
                    Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const InsightsScreen()));
                  } else {
                    setState(() => _selectedTab = i);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  color: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tabs[i]['icon'] as IconData,
                        size: i == 2 ? 28 : 22,
                        color: active
                            ? const Color(0xFFE05D6F)
                            : i == 2
                            ? const Color(0xFFE05D6F)
                            : Colors.grey[400],
                      ),
                      const SizedBox(height: 2),
                      Text(tabs[i]['label'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            color: active
                                ? const Color(0xFFE05D6F)
                                : Colors.grey[400],
                            fontWeight: active
                                ? FontWeight.w600
                                : FontWeight.normal,
                          )),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      );
    }

    bool _isSameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;
  }


  // ── Data model ───────────────────────────────────────────────
  class CyclePhase {
    final String name;
    final int startDay, endDay;
    final Color color;
    final String description;
    CyclePhase(this.name, this.startDay, this.endDay,
        this.color, this.description);
  }


  // ── Ring painter ─────────────────────────────────────────────
  class CycleRingPainter extends CustomPainter {
    final List<CyclePhase> phases;
    final int currentDay;
    final int cycleLength;

    CycleRingPainter({
      required this.phases,
      required this.currentDay,
      required this.cycleLength,
    });

    @override
    void paint(Canvas canvas, Size size) {
      final cx = size.width / 2;
      final cy = size.height / 2;
      final radius = size.width / 2 - 20;
      const strokeWidth = 16.0;
      const dotRadius   = 11.0;

      // Track background
      canvas.drawCircle(
          Offset(cx, cy), radius,
          Paint()
            ..color = Colors.grey[200]!
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.round);

      // Phase arcs
      for (final phase in phases) {
        final startAngle = _dayToAngle(phase.startDay);
        final endAngle   = _dayToAngle(phase.endDay + 1);
        canvas.drawArc(
          Rect.fromCircle(
              center: Offset(cx, cy), radius: radius),
          startAngle, endAngle - startAngle, false,
          Paint()
            ..color = phase.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.round,
        );
      }

      // Dot
      final dotAngle = _dayToAngle(currentDay);
      final dotX = cx + radius * cos(dotAngle);
      final dotY = cy + radius * sin(dotAngle);

      // Glow
      canvas.drawCircle(Offset(dotX, dotY), dotRadius + 4,
          Paint()..color = Colors.white.withOpacity(0.6));
      // White circle
      canvas.drawCircle(Offset(dotX, dotY), dotRadius,
          Paint()..color = Colors.white);
      // Border
      canvas.drawCircle(Offset(dotX, dotY), dotRadius,
          Paint()
            ..color = Colors.black26
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);

      // Color center
      final phase = phases.firstWhere(
              (p) => currentDay >= p.startDay &&
              currentDay <= p.endDay,
          orElse: () => phases.last);
      canvas.drawCircle(
          Offset(dotX, dotY), 4,
          Paint()..color = phase.color);
    }

    double _dayToAngle(int day) =>
        ((day - 1) / cycleLength) * 2 * pi - pi / 2;

    @override
    bool shouldRepaint(CycleRingPainter old) =>
        old.currentDay != currentDay;
  }