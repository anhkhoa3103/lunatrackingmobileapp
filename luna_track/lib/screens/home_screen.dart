  import 'package:flutter/material.dart';
  import 'package:flutter/services.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import 'dart:math';
  import '../l10n.dart';
  import '../models/cycle_entry.dart';
  import '../services/api_service.dart';
  import '../utils/app_colors.dart';
  import '../utils/app_theme.dart';
  import '../services/storage_service.dart';
  import '../widgets/log_bottom_sheet.dart';
  import '../widgets/skeleton_loaders.dart';
  import 'calendar_screen.dart';
  import 'chat_screen.dart';
  import 'insights_screen.dart';
  import 'profile_screen.dart';
  import 'login_screen.dart';

  class HomeScreen extends StatefulWidget {
    const HomeScreen({super.key});
    @override
    State<HomeScreen> createState() => _HomeScreenState();
  }

  class _HomeScreenState extends State<HomeScreen>
      with TickerProviderStateMixin {
    int _selectedTab = 0;
    int _currentDay  = 1;
    int _animatedDay = 1;        // animated display day
    int _cycleLength = 28;
    late AnimationController _ringAnimController;
    late Animation<int> _ringAnimation;
    late AnimationController _glowController;      // breathing glow
    late Animation<double> _glowAnimation;
    late AnimationController _cardSlideController; // today card entry
    late Animation<Offset> _cardSlideAnim;
    late Animation<double> _cardFadeAnim;
    DateTime _cycleStart = DateTime.now();
    Map<String, CycleEntry> _logs = {};
    bool _loading = true;
    String _userName  = '';
    String _userEmail = '';
    DateTime? _periodConfirmedDate;
    String? _bannerDismissedDate;

    final List<CyclePhase> phases = [
      CyclePhase('Menstrual',  1,  5,  Color(0xFFE05D6F), 'Rest, stay warm, track your flow.'),
      CyclePhase('Follicular', 6,  13, Color(0xFFF5A623), 'Energy rising. Great time for new things.'),
      CyclePhase('Ovulation',  14, 16, Color(0xFF1D9E75), 'Peak fertility. High energy & confidence.'),
      CyclePhase('Luteal',     17, 28, Color(0xFF5B8CDE), 'Wind-down phase. Rest and reduce stress.'),
    ];

    @override
    void initState() {
      super.initState();
      _ringAnimController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
      );

      // Breathing glow — continuous loop
      _glowController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2000),
      )..repeat(reverse: true);  // pulse in/out forever

      _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _glowController,
          curve: Curves.easeInOut,
        ),
      );

      // Today card slide-in
      _cardSlideController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
      _cardSlideAnim = Tween<Offset>(
        begin: const Offset(0, 0.3),  // start below
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _cardSlideController,
        curve: Curves.easeOutCubic,
      ));
      _cardFadeAnim = Tween<double>(begin: 0, end: 1)
          .animate(CurvedAnimation(
            parent: _cardSlideController,
            curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
          ));

      _loadCycleData();
    }

    @override
    void dispose() {
      _ringAnimController.dispose();
      _glowController.dispose();
      _cardSlideController.dispose();
      super.dispose();
    }

    Future<void> _loadCycleData() async {
      setState(() => _loading = true);
      final prefs = await SharedPreferences.getInstance();
      final confirmedStr = prefs.getString('period_confirmed_date');
      if (confirmedStr != null) {
        _periodConfirmedDate = DateTime.tryParse(confirmedStr);
      }
      _bannerDismissedDate = prefs.getString('period_banner_dismissed');
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

        // After loading remote entries, read cycle settings from prefs
        final savedCycleLength = prefs.getInt('cycle_length') ?? 28;

        setState(() {
          _logs        = map;
          _cycleStart  = lastCycleStart ?? DateTime.now();
          _cycleLength = savedCycleLength; // ← use saved setting
          _currentDay  = DateTime.now()
              .difference(_cycleStart).inDays + 1;
          _currentDay  = _currentDay.clamp(1, _cycleLength);
          _loading     = false;
        });
        _startRingAnimation();
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) _cardSlideController.forward(from: 0);
        });

        _userName  = await ApiService.getUserName();
        _userEmail = await ApiService.getUserEmail();
      } catch (_) {
        // Fallback to local Hive + SharedPreferences
        final entries = StorageService.getAllEntries();
        DateTime? lastCycleStart;

        // Try SharedPreferences first (set during onboarding)
        final lastPeriodStr = prefs.getString('last_period_start');
        if (lastPeriodStr != null) {
          lastCycleStart = DateTime.tryParse(lastPeriodStr);
        }

        // Then check Hive entries
        for (final e in entries) {
          if (e.flow == 'medium' || e.flow == 'heavy') {
            lastCycleStart = e.date;
          }
        }

        final cycleLengthPref = prefs.getInt('cycle_length') ?? 28;

        setState(() {
          _cycleStart  = lastCycleStart ?? DateTime.now();
          _cycleLength = cycleLengthPref;
          _currentDay  = DateTime.now()
              .difference(_cycleStart).inDays + 1;
          _currentDay  = _currentDay.clamp(1, _cycleLength);
          _loading     = false;
        });
        _startRingAnimation();
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) _cardSlideController.forward(from: 0);
        });
      }
    }

    void _startRingAnimation() {
      _ringAnimation = IntTween(begin: 1, end: _currentDay)
          .animate(CurvedAnimation(
            parent: _ringAnimController,
            curve: Curves.easeOutCubic,
          ))
        ..addListener(() {
          setState(() {
            _animatedDay = _ringAnimation.value;
          });
        });

      _ringAnimController.forward(from: 0).whenComplete(() {
        // Briefly scale the dot up then back — subtle pulse
        setState(() {
          _animatedDay = _currentDay; // ensure exact day
        });
      });
    }

    bool get _showPeriodBanner {
      // Calculate predicted next period
      final nextPeriod = _cycleStart.add(Duration(days: _cycleLength));
      final today = DateTime.now();
      final daysDiff = today.difference(nextPeriod).inDays;

      // Only show if today is within 0–2 days after predicted date
      if (daysDiff < 0 || daysDiff > 2) return false;

      // Don't show if already confirmed this cycle
      // (confirmed date is within current cycle)
      if (_periodConfirmedDate != null) {
        final confirmedDiff =
            _cycleStart.difference(_periodConfirmedDate!).inDays;
        if (confirmedDiff < 0) return false; // confirmed after current cycle start
      }

      // Don't show if dismissed today
      if (_bannerDismissedDate != null) {
        final todayStr = today.toIso8601String().split('T')[0];
        if (_bannerDismissedDate == todayStr) return false;
      }

      return true;
    }

    // ── Compute the actual date for a given cycle day ────────────
    DateTime _dateForDay(int day) =>
        _cycleStart.add(Duration(days: day - 1));

    String _dateKey(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-'
            '${d.day.toString().padLeft(2, '0')}';

    @override
    Widget build(BuildContext context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final gradientColors = AppColors.getPhaseGradient(
          _currentPhase.name, isDark);

      return Scaffold(
        backgroundColor: Colors.transparent,
        drawer: _buildDrawer(),
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: gradientColors,
              stops: const [0.0, 1.0],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildTopBar(),
                    if (_showPeriodBanner) _buildPeriodConfirmationBanner(),
                    Expanded(
                      child: _loading
                          ? const HomeScreenSkeleton()
                          : RefreshIndicator(
                        onRefresh: _loadCycleData,
                        color: const Color(0xFFE05D6F),
                        backgroundColor: Colors.white,
                        strokeWidth: 2.5,
                        child: SingleChildScrollView(
                          // must be scrollable even when content fits
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            children: [
                              const SizedBox(height: 8),
                              _buildGreetingCard(),
                              const SizedBox(height: 16),
                              _buildCycleRing(),
                              const SizedBox(height: 16),
                              _buildLegend(),
                              const SizedBox(height: 16),
                              _buildPhaseCard(),
                              const SizedBox(height: 12),
                              _buildQuickStats(),
                              const SizedBox(height: 16),
                              _buildTodayCard(),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                    _buildBottomNav(),
                  ],
                ),
                // Gradient fade above the bottom nav
                Positioned(
                  bottom: 60, left: 0, right: 0, height: 40,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            gradientColors.last.withOpacity(0),
                            gradientColors.last.withOpacity(0.8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
        backgroundColor: AppColors.background(context),
        elevation: 16,
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFE05D6F),
                boxShadow: AppColors.subtleShadow,
              ),
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
                      AppLocalizations.of(context)!.cycle, onTap: () {
                        Navigator.pop(context);
                      }),
                  _drawerItem(Icons.calendar_today_outlined,
                      AppLocalizations.of(context)!.calendar, onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(
                            builder: (_) => const CalendarScreen()))
                            .then((_) => _loadCycleData());
                      }),
                  _drawerItem(Icons.bar_chart,
                      AppLocalizations.of(context)!.insights, onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(
                            builder: (_) => const InsightsScreen()));
                      }),
                  const Divider(height: 1),
                  _drawerItem(Icons.person_outline,
                      AppLocalizations.of(context)!.viewProfile, onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(
                            builder: (_) => const ProfileScreen()))
                            .then((_) => _loadCycleData());
                      }),
                  _drawerItem(Icons.notifications_outlined,
                      AppLocalizations.of(context)!.notifications, onTap: () {
                        Navigator.pop(context);
                      }),
                  const Divider(height: 1),
                  _drawerItem(Icons.logout,
                      AppLocalizations.of(context)!.logout,
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
      final c = color ?? AppColors.textSecondary(context);
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
          title: Text(AppLocalizations.of(context)!.logout,
              style: const TextStyle(fontSize: 16)),
          content: Text(
              AppLocalizations.of(context)!.logoutConfirm,
              style: const TextStyle(fontSize: 14)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancelBtn,
                  style: TextStyle(
                      color: AppColors.textSecondary(context))),
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
              child: Text(AppLocalizations.of(context)!.logout,
                  style: const TextStyle(color: Color(0xFFE24B4A))),
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
                    border: Border.all(
                        color: AppColors.cardBorder(context)),
                  ),
                  child: const Icon(Icons.menu, size: 18),
                ),
              ),
            ),
            const Spacer(),
            Text(AppLocalizations.of(context)!.appName,
                style: AppTheme.headlineLarge.copyWith(
                    color: AppColors.textPrimary(context))),
            const Spacer(),
            // Refresh
            GestureDetector(
              onTap: _loadCycleData,
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.cardBorder(context)),
                ),
                child: const Icon(Icons.refresh, size: 18),
              ),
            ),
          ],
        ),
      );
    }

    // ── Greeting card ────────────────────────────────────────────
    Widget _buildGreetingCard() {
      final hour = DateTime.now().hour;
      final greeting = hour < 12
          ? 'Chào buổi sáng'
          : hour < 17
              ? 'Chào buổi chiều'
              : 'Chào buổi tối';

      final name = _userName.isNotEmpty
          ? _userName.split(' ').last  // first name only
          : '';

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting${name.isNotEmpty ? ', $name' : ''} 👋',
                    style: AppTheme.headlineMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ngày $_currentDay của chu kỳ',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            // Avatar circle
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE05D6F).withOpacity(0.15),
              ),
              child: Center(
                child: Text(
                  _userName.isNotEmpty
                      ? _userName[0].toUpperCase()
                      : '🌙',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE05D6F),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ── Period confirmation banner ───────────────────────────────
    Widget _buildPeriodConfirmationBanner() {
      final nextPeriod = _cycleStart.add(Duration(days: _cycleLength));
      const months = ['Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
      final dateLabel = '${nextPeriod.day} '
          '${months[nextPeriod.month - 1]} ${nextPeriod.year}';

      return Container(
        margin: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFBEAF0),
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppColors.getShadow(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.water_drop,
                    size: 20, color: Color(0xFFE05D6F)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context)!
                              .periodBannerTitle,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text(AppLocalizations.of(context)!
                              .periodBannerSubtitle(dateLabel),
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary(context))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _confirmPeriodStarted,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE05D6F),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(AppLocalizations.of(context)!.yesStarted,
                        style: const TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _dismissBannerForToday,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE05D6F),
                      side: const BorderSide(
                          color: Color(0xFFE05D6F)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(AppLocalizations.of(context)!.notYet,
                        style: const TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    Future<void> _confirmPeriodStarted() async {
      HapticFeedback.heavyImpact(); // ← strong for important action
      // 1. Save today as new cycle start
      final today = DateTime.now();
      final entry = {
        'date': today.toIso8601String().split('T')[0],
        'flow': 'medium',      // default to medium flow
        'moods': [],
        'symptoms': [],
        'energy': '',
        'sleep': '',
        'notes': '',
      };
      await ApiService.saveEntry(entry);

      // 2. Save confirmation to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('period_confirmed_date',
          today.toIso8601String().split('T')[0]);

      // 3. Reload cycle data to update ring
      await _loadCycleData();

      // 4. Show success snackbar
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!.periodConfirmed),
        backgroundColor: const Color(0xFF1D9E75),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ));
    }

    Future<void> _dismissBannerForToday() async {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];
      await prefs.setString('period_banner_dismissed', today);
      setState(() {}); // hide banner
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
          final newDay =
          ((degrees / 360) * _cycleLength).round().clamp(1, _cycleLength);
          if (newDay != _currentDay) {
            HapticFeedback.selectionClick(); // ← only when day changes
          }
          setState(() {
            _currentDay  = newDay;
            _animatedDay = newDay;   // keep in sync when dragging
          });
        },
        child: SizedBox(
          width: 280, height: 280,
          child: AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, _) {
              return CustomPaint(
                painter: CycleRingPainter(
                  phases:            phases,
                  currentDay:        _animatedDay,
                  cycleLength:       _cycleLength,
                  animationProgress: _ringAnimController.value,
                  glowIntensity:     _glowAnimation.value,
                  isDark:            AppColors.isDark(context),
                ),
                child: Center(child: _buildCenterInfo()),
              );
            },
          ),
        ),
      );
    }

    // ── Center info inside ring ──────────────────────────────────
    Widget _buildCenterInfo() {
      final displayDay  = _animatedDay;
      final phase       = phases.firstWhere(
              (p) => displayDay >= p.startDay && displayDay <= p.endDay,
          orElse: () => phases.last);
      final date        = _dateForDay(displayDay);
      final isToday     = _isSameDay(date, DateTime.now()) &&
          displayDay == _currentDay;
      final log         = _logs[_dateKey(date)];
      final daysLeft    = _cycleLength - displayDay;

      // Format date
      const months = ['Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
      final dateLabel = isToday
          ? AppLocalizations.of(context)!.today
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
                style: AppTheme.labelLarge.copyWith(
                    color: phase.color)),
          ),
          const SizedBox(height: 6),

          // Date — big and prominent
          Text(dateLabel,
              style: AppTheme.displayMedium.copyWith(
                  color: isToday
                      ? const Color(0xFFE05D6F)
                      : AppColors.textPrimary(context))),

          const SizedBox(height: 2),

          // Day x of y
          Text(AppLocalizations.of(context)!
                  .dayOf(displayDay, _cycleLength),
              style: AppTheme.bodySmall.copyWith(
                  color: AppColors.textSecondary(context))),

          const SizedBox(height: 4),

          // Days left or next period
          Text(
            daysLeft == 0
                ? AppLocalizations.of(context)!.lastDayOfCycle
                : isToday
                ? AppLocalizations.of(context)!.daysLeft(daysLeft)
                : '',
            style: TextStyle(
                fontSize: 11, color: AppColors.textHint(context)),
          ),

          // Show if logged
          if (log != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle,
                      size: 10, color: const Color(0xFF1D9E75)),
                  const SizedBox(width: 3),
                  Text(AppLocalizations.of(context)!.logged,
                      style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary(context))),
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
                    fontSize: 12,
                    color: AppColors.textSecondary(context))),
          ],
        )).toList(),
      );
    }

    // ── Phase description card ───────────────────────────────────
    CyclePhase get _currentPhase => phases.firstWhere(
            (p) => _currentDay >= p.startDay && _currentDay <= p.endDay,
        orElse: () => phases.last);

    // Phase descriptions in Vietnamese
    static const Map<String, Map<String, dynamic>> _phaseInfo = {
      'Menstrual': {
        'icon': '🩸',
        'title': 'Kỳ Kinh Nguyệt',
        'desc': 'Hãy nghỉ ngơi, giữ ấm cơ thể và uống nhiều nước. '
            'Đây là thời điểm cơ thể cần được chăm sóc đặc biệt.',
        'tip': '💡 Tip: Trà gừng giúp giảm đau bụng kinh hiệu quả.',
        'gradient': [Color(0xFFFFECEF), Color(0xFFFFF0F0)],
        'accent': Color(0xFFE05D6F),
      },
      'Follicular': {
        'icon': '🌸',
        'title': 'Giai Đoạn Nang Trứng',
        'desc': 'Năng lượng đang tăng lên! Đây là thời điểm tốt để '
            'bắt đầu dự án mới và hoạt động thể chất.',
        'tip': '💡 Tip: Tăng cường protein và rau xanh trong bữa ăn.',
        'gradient': [Color(0xFFFFF8EC), Color(0xFFFFF3E0)],
        'accent': Color(0xFFF5A623),
      },
      'Ovulation': {
        'icon': '✨',
        'title': 'Giai Đoạn Rụng Trứng',
        'desc': 'Đỉnh cao năng lượng và sự tự tin! Cửa sổ thụ thai '
            'đang mở. Bạn đang ở trạng thái tốt nhất.',
        'tip': '💡 Tip: Thời điểm tốt để tập thể dục cường độ cao.',
        'gradient': [Color(0xFFECFFF6), Color(0xFFE1F5EE)],
        'accent': Color(0xFF1D9E75),
      },
      'Luteal': {
        'icon': '🌙',
        'title': 'Giai Đoạn Hoàng Thể',
        'desc': 'Cơ thể đang chuẩn bị cho chu kỳ tiếp theo. '
            'Hãy nghỉ ngơi nhiều hơn và giảm căng thẳng.',
        'tip': '💡 Tip: Ăn sô cô la đen giúp cải thiện tâm trạng.',
        'gradient': [Color(0xFFEEF4FF), Color(0xFFE6F1FB)],
        'accent': Color(0xFF5B8CDE),
      },
    };

    Widget _buildPhaseCard() {
      final phase = _currentPhase;
      final info = _phaseInfo[phase.name] ??
          _phaseInfo['Luteal']!;
      final gradientColors =
          info['gradient'] as List<Color>;
      final accent = info['accent'] as Color;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppColors.getShadow(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(info['icon'] as String,
                      style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(info['title'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: accent,
                      )),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Ngày $_currentDay',
                      style: TextStyle(
                          fontSize: 11,
                          color: accent,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(info['desc'] as String,
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      height: 1.5)),
              const SizedBox(height: 8),
              Text(info['tip'] as String,
                  style: TextStyle(
                      fontSize: 11,
                      color: accent.withOpacity(0.8),
                      fontStyle: FontStyle.italic)),
            ],
          ),
        ),
      );
    }

    // ── Quick stats row ──────────────────────────────────────────
    Widget _buildQuickStats() {
      final daysLeft = _cycleLength - _currentDay;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            _statItem(
              icon: '📅',
              value: 'Ngày $_currentDay',
              label: 'Chu kỳ hiện tại',
              color: const Color(0xFFE05D6F),
            ),
            _statDivider(),
            _statItem(
              icon: '⏳',
              value: '$daysLeft ngày',
              label: 'Còn lại',
              color: const Color(0xFF5B8CDE),
            ),
            _statDivider(),
            _statItem(
              icon: '🔄',
              value: '$_cycleLength ngày',
              label: 'Độ dài chu kỳ',
              color: const Color(0xFF1D9E75),
            ),
          ],
        ),
      );
    }

    Widget _statItem({
      required String icon,
      required String value,
      required String label,
      required Color color,
    }) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppColors.subtleShadow,
          ),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 4),
              Text(value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  )),
              const SizedBox(height: 2),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary(context),
                  )),
            ],
          ),
        ),
      );
    }

    Widget _statDivider() => const SizedBox(width: 8);

    // ── Today card ───────────────────────────────────────────────
    Widget _buildTodayCard() {
      final todayKey = _dateKey(DateTime.now());
      final todayLog = _logs[todayKey];

      return SlideTransition(
        position: _cardSlideAnim,
        child: FadeTransition(
          opacity: _cardFadeAnim,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: () => LogBottomSheet.show(
                context,
                date:        DateTime.now(),
                existingLog: todayLog,
                onSaved:     _loadCycleData,
              ),
              child: todayLog == null
                  ? _buildShimmerTodayCard()          // shimmer if not logged
                  : _buildLoggedTodayCard(todayLog),  // normal if logged
            ),
          ),
        ),
      );
    }

    // Shimmer version (when not logged)
    Widget _buildShimmerTodayCard() {
      return _ShimmerCard(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.isDark(context)
                ? AppColors.surface(context)
                : const Color(0xFFFFF0EC),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFFE05D6F).withOpacity(0.1),
                  blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: const BoxDecoration(
                    color: Color(0xFFF5A623), shape: BoxShape.circle),
                child: const Icon(Icons.sentiment_satisfied_alt,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Hôm nay bạn cảm thấy thế nào?',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text('Chạm để ghi chép nhật ký',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary(context))),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: AppColors.textHint(context)),
            ],
          ),
        ),
      );
    }

    // Normal card (when logged)
    Widget _buildLoggedTodayCard(CycleEntry log) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.isDark(context)
              ? AppColors.surface(context)
              : const Color(0xFFECFFF6),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF1D9E75).withOpacity(0.12),
                blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: const BoxDecoration(
                  color: Color(0xFF1D9E75), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_outline,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nhật ký hôm nay ✓',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Wrap(spacing: 6, children: [
                    if (log.flow.isNotEmpty && log.flow != 'none')
                      _miniChip('💧 ${log.flow}',
                          const Color(0xFFE05D6F)),
                    if (log.energy.isNotEmpty)
                      _miniChip('⚡ ${log.energy}',
                          const Color(0xFF1D9E75)),
                    if (log.moods.isNotEmpty)
                      _miniChip('😊 ${log.moods.first}',
                          const Color(0xFFF5A623)),
                  ]),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: AppColors.textHint(context)),
          ],
        ),
      );
    }

    Widget _miniChip(String label, Color color) => Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500)),
    );

    // ── Bottom nav ───────────────────────────────────────────────
    Widget _buildBottomNav() {
      final tabs = [
        {'icon': Icons.circle_outlined,
         'label': AppLocalizations.of(context)!.cycle},
        {'icon': Icons.calendar_today_outlined,
         'label': AppLocalizations.of(context)!.calendar},
        {'icon': Icons.add_circle,
         'label': AppLocalizations.of(context)!.log},
        {'icon': Icons.bar_chart,
         'label': AppLocalizations.of(context)!.insights},
        {'icon': Icons.chat_bubble_outline,
         'label': AppLocalizations.of(context)!.aiChat},
      ];
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
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
                    LogBottomSheet.show(
                      context,
                      date: DateTime.now(),
                      existingLog: _logs[_dateKey(DateTime.now())],
                      onSaved: _loadCycleData,
                    );
                  } else if (i == 3) {
                    Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const InsightsScreen()));
                  } else if (i == 4) {
                    Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const ChatScreen()));
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
                            : AppColors.textHint(context),
                      ),
                      const SizedBox(height: 2),
                      Text(tabs[i]['label'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            color: active
                                ? const Color(0xFFE05D6F)
                                : AppColors.textHint(context),
                            fontWeight: active
                                ? FontWeight.w600
                                : FontWeight.normal,
                          )),
                      if (active)
                        Container(
                          width: 4, height: 4,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            color: _currentPhase.color,
                            shape: BoxShape.circle,
                          ),
                        ),
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
    final double animationProgress; // 0.0 → 1.0
    final double glowIntensity;     // 0.0 → 1.0 breathing glow
    final bool isDark;

    CycleRingPainter({
      required this.phases,
      required this.currentDay,
      required this.cycleLength,
      this.animationProgress = 1.0,
      this.glowIntensity = 0.5,
      this.isDark = false,
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
            ..color = isDark
                ? const Color(0xFF3A3A3A)
                : Colors.grey[200]!
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.round);

      // Phase arcs — grow with the animation
      final sweepLimit = animationProgress >= 1.0
          ? _dayToAngle(cycleLength + 1)
          : _dayToAngle((cycleLength * animationProgress)
              .round().clamp(1, cycleLength));
      for (final phase in phases) {
        final startAngle = _dayToAngle(phase.startDay);
        final endAngle   = _dayToAngle(phase.endDay + 1);
        if (startAngle > sweepLimit) continue; // not reached yet
        final clippedEnd =
            endAngle > sweepLimit ? sweepLimit : endAngle;
        canvas.drawArc(
          Rect.fromCircle(
              center: Offset(cx, cy), radius: radius),
          startAngle, clippedEnd - startAngle, false,
          Paint()
            ..color = phase.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.round,
        );
      }

      // Dot position
      final dotAngle = _dayToAngle(currentDay);
      final dotX = cx + radius * cos(dotAngle);
      final dotY = cy + radius * sin(dotAngle);

      // ── GLOW LAYERS (paint before dot) ──────────────────────────
      final phase = phases.firstWhere(
              (p) => currentDay >= p.startDay &&
              currentDay <= p.endDay,
          orElse: () => phases.last);

      // Outer glow — large, very transparent
      final outerGlowRadius = dotRadius + 8 + (glowIntensity * 10);
      canvas.drawCircle(
        Offset(dotX, dotY),
        outerGlowRadius,
        Paint()
          ..color = phase.color.withOpacity(0.08 + glowIntensity * 0.12)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );

      // Middle glow
      final midGlowRadius = dotRadius + 4 + (glowIntensity * 5);
      canvas.drawCircle(
        Offset(dotX, dotY),
        midGlowRadius,
        Paint()
          ..color = phase.color.withOpacity(0.15 + glowIntensity * 0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

      // Inner glow — tight around dot
      canvas.drawCircle(
        Offset(dotX, dotY),
        dotRadius + 3 + (glowIntensity * 2),
        Paint()
          ..color = phase.color.withOpacity(0.3 + glowIntensity * 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );

      // ── DOT (paint after glow) ───────────────────────────────────
      // White circle
      canvas.drawCircle(
        Offset(dotX, dotY), dotRadius,
        Paint()..color = isDark ? const Color(0xFF2A2A2A) : Colors.white,
      );
      // Border
      canvas.drawCircle(
        Offset(dotX, dotY), dotRadius,
        Paint()
          ..color = phase.color.withOpacity(0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      // Color center
      canvas.drawCircle(
        Offset(dotX, dotY), 5,
        Paint()..color = phase.color,
      );

      // ── PULSE RING (animates with breathing) ─────────────────────
      if (glowIntensity > 0.3) {
        canvas.drawCircle(
          Offset(dotX, dotY),
          dotRadius + 6 + (glowIntensity * 8),
          Paint()
            ..color = phase.color.withOpacity(
                (1 - glowIntensity) * 0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }

    double _dayToAngle(int day) =>
        ((day - 1) / cycleLength) * 2 * pi - pi / 2;

    @override
    bool shouldRepaint(CycleRingPainter old) =>
        old.currentDay != currentDay ||
            old.animationProgress != animationProgress ||
            old.glowIntensity != glowIntensity ||
            old.isDark != isDark;
  }


  // ── Shimmer sweep wrapper for the today card ─────────────────
  class _ShimmerCard extends StatefulWidget {
    final Widget child;
    const _ShimmerCard({required this.child});

    @override
    State<_ShimmerCard> createState() => _ShimmerCardState();
  }

  class _ShimmerCardState extends State<_ShimmerCard>
      with SingleTickerProviderStateMixin {

    late AnimationController _ctrl;
    late Animation<double> _anim;

    @override
    void initState() {
      super.initState();
      _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1800),
      )..repeat();
      _anim = Tween<double>(begin: -1.5, end: 2.5).animate(_ctrl);
    }

    @override
    void dispose() {
      _ctrl.dispose();
      super.dispose();
    }

    @override
    Widget build(BuildContext context) {
      return AnimatedBuilder(
        animation: _anim,
        builder: (_, child) => ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.transparent,
              Colors.white.withOpacity(0.35),
              Colors.transparent,
            ],
            stops: [
              (_anim.value - 0.5).clamp(0.0, 1.0),
              _anim.value.clamp(0.0, 1.0),
              (_anim.value + 0.5).clamp(0.0, 1.0),
            ],
          ).createShader(bounds),
          child: child,
        ),
        child: widget.child,
      );
    }
  }
