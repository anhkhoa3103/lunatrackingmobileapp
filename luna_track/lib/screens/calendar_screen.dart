import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n.dart';
import '../models/cycle_entry.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../utils/app_colors.dart';
import '../widgets/empty_state.dart';
import '../widgets/log_bottom_sheet.dart';
import '../widgets/skeleton_loaders.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  Map<String, CycleEntry> _logs = {};
  Set<String> _onCycleDays = {};
  bool _loading = true;

  static const _pink    = Color(0xFFE05D6F);
  static const _teal    = Color(0xFF1D9E75);
  static const _blue    = Color(0xFF5B8CDE);
  static const _amber   = Color(0xFFF5A623);

  late PageController _pageController;
  int _pageIndex = 0; // current page

  @override
  void initState() {
    super.initState();
    // Calculate initial page based on current month
    final now = DateTime.now();
    _pageIndex = (now.year - 2020) * 12 + now.month - 1;
    _pageController = PageController(initialPage: _pageIndex);
    _selectedDate = DateTime.now();
    _loadData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final remote = await ApiService.getAllEntries();
      final map = <String, CycleEntry>{};
      final cycleDays = <String>{};

      for (final e in remote) {
        final date = DateTime.parse(e['date']);
        final key  = _dateKey(date);
        final entry = CycleEntry(
          date:     date,
          flow:     e['flow'] ?? 'none',
          moods:    List<String>.from(e['moods'] ?? []),
          symptoms: List<String>.from(e['symptoms'] ?? []),
          energy:   e['energy'] ?? '',
          sleep:    e['sleep'] ?? '',
          notes:    e['notes'] ?? '',
        );
        map[key] = entry;

        // Only mark as on-cycle if flow is medium or heavy
        if (entry.flow == 'medium' || entry.flow == 'heavy') {
          cycleDays.add(key);
        }
      }

      setState(() {
        _logs        = map;
        _onCycleDays = cycleDays;
        _loading     = false;
      });
    } catch (_) {
      // Fallback to local Hive
      final entries = StorageService.getAllEntries();
      final map = <String, CycleEntry>{};
      final cycleDays = <String>{};

      for (final e in entries) {
        final key = _dateKey(e.date);
        map[key] = e;
        if (e.flow == 'medium' || e.flow == 'heavy') {
          cycleDays.add(key);
        }
      }

      setState(() {
        _logs        = map;
        _onCycleDays = cycleDays;
        _loading     = false;
      });
    }
  }

  // ── Toggle on-cycle for a day ────────────────────────────────
  void _toggleCycle(DateTime date) {
    HapticFeedback.mediumImpact(); // ← stronger for toggle
    final key = _dateKey(date);
    setState(() {
      if (_onCycleDays.contains(key)) {
        _onCycleDays.remove(key);
        // Update log flow to none
        if (_logs.containsKey(key)) {
          _logs[key]!.flow = 'none';
        }
      } else {
        _onCycleDays.add(key);
        // If no log exists, create a minimal one with medium flow
        if (!_logs.containsKey(key)) {
          _logs[key] = CycleEntry(
            date: date, flow: 'medium',
            moods: [], symptoms: [],
            energy: '', sleep: '', notes: '',
          );
        } else {
          _logs[key]!.flow = 'medium';
        }
      }
    });
    // Save to API in background
    _saveOnCycleToApi(date);
  }

  Future<void> _saveOnCycleToApi(DateTime date) async {
    final key  = _dateKey(date);
    final log  = _logs[key];
    if (log == null) return;
    await ApiService.saveEntry({
      'date':     date.toIso8601String().split('T')[0],
      'flow':     log.flow,
      'moods':    log.moods,
      'symptoms': log.symptoms,
      'energy':   log.energy,
      'sleep':    log.sleep,
      'notes':    log.notes,
    });
  }

  // ── Open log sheet for selected date ─────────────────────────
  void _openLog(DateTime date) {
    final key         = _dateKey(date);
    final existingLog = _logs[key];
    LogBottomSheet.show(
      context,
      date:        date,
      existingLog: existingLog,
      onSaved:     _loadData,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        elevation: 0,
        title: Text(AppLocalizations.of(context)!.calendar,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _loading
          ? const CalendarScreenSkeleton()
          : Column(
        children: [
          _buildMonthNav(),
          Expanded(
            child: Column(
              children: [
                _buildDowRow(),
                // Swipeable calendar
                SizedBox(
                  height: 300,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (page) {
                      HapticFeedback.lightImpact(); // ← haptic on swipe
                      final year = 2020 + page ~/ 12;
                      final month = page % 12 + 1;
                      setState(() {
                        _pageIndex = page;
                        _focusedMonth = DateTime(year, month);
                      });
                    },
                    itemBuilder: (context, page) {
                      final year = 2020 + page ~/ 12;
                      final month = page % 12 + 1;
                      return _buildCalendarGridForMonth(
                          DateTime(year, month));
                    },
                  ),
                ),
                _buildLegend(),
                const Divider(height: 1),
                Expanded(child: _buildDetailPanel()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Month navigation ─────────────────────────────────────────
  Widget _buildMonthNav() {
    const months = ['January','February','March','April','May','June',
      'July','August','September','October','November','December'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE05D6F).withOpacity(0.05),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFE05D6F).withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _navBtn(Icons.chevron_left, () {
            HapticFeedback.lightImpact();
            _pageController.previousPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }),
          Expanded(
            child: Text(
              '${months[_focusedMonth.month - 1]} ${_focusedMonth.year}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
          _navBtn(Icons.chevron_right, () {
            HapticFeedback.lightImpact();
            _pageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }),
        ],
      ),
    );
  }

  Widget _navBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.cardBorder(context)),
      ),
      child: Icon(icon, size: 18,
          color: AppColors.textSecondary(context)),
    ),
  );

  // ── Day of week row ──────────────────────────────────────────
  Widget _buildDowRow() {
    const days = ['Su','Mo','Tu','We','Th','Fr','Sa'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: days.map((d) => Expanded(
          child: Center(
            child: Text(d,
                style: TextStyle(fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textHint(context))),
          ),
        )).toList(),
      ),
    );
  }

  // ── Calendar grid ────────────────────────────────────────────
  Widget _buildCalendarGridForMonth(DateTime focusedMonth) {
    final firstDay =
    DateTime(focusedMonth.year, focusedMonth.month, 1);
    final daysInMonth =
        DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7;
    final prevDays =
        DateTime(focusedMonth.year, focusedMonth.month, 0).day;
    final today = DateTime.now();

    List<Widget> cells = [];

    // Prev month filler
    for (int i = 0; i < startWeekday; i++) {
      cells.add(_dayCell(
          day: prevDays - startWeekday + 1 + i,
          isCurrentMonth: false));
    }

    // Current month
    for (int d = 1; d <= daysInMonth; d++) {
      final date =
      DateTime(focusedMonth.year, focusedMonth.month, d);
      final key        = _dateKey(date);
      final isToday    = _sameDay(date, today);
      final isSelected = _sameDay(date, _selectedDate);
      final isOnCycle  = _onCycleDays.contains(key);
      final log        = _logs[key];

      // Phase from cycle logic
      String phase = '';
      if (!isOnCycle) {
        phase = _phaseForDate(date);
      }

      cells.add(_dayCell(
        day: d,
        isCurrentMonth: true,
        isToday: isToday,
        isSelected: isSelected,
        isOnCycle: isOnCycle,
        phase: phase,
        hasLog: log != null,
        onTap: () {
          HapticFeedback.selectionClick(); // ← light for selection
          setState(() => _selectedDate = date);
        },
      ));
    }

    // Next month filler
    for (int d = 1; d <= (42 - cells.length); d++) {
      cells.add(_dayCell(day: d, isCurrentMonth: false));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: cells,
      ),
    );
  }

  Widget _dayCell({
    required int day,
    required bool isCurrentMonth,
    bool isToday = false,
    bool isSelected = false,
    bool isOnCycle = false,
    String phase = '',
    bool hasLog = false,
    VoidCallback? onTap,
  }) {
    // Background color
    Color? bgColor;
    Color textColor = isCurrentMonth
        ? AppColors.textPrimary(context)
        : AppColors.textHint(context);

    if (isOnCycle) {
      bgColor   = _pink;            // RED = actual on cycle
      textColor = Colors.white;
    } else if (phase == 'period-predicted') {
      bgColor   = const Color(0xFFFBEAF0);   // light pink = predicted
      textColor = const Color(0xFF993556);
    } else if (phase == 'follicular') {
      bgColor   = const Color(0xFFFFF3E0);
      textColor = const Color(0xFF854F0B);
    } else if (phase == 'ovulation') {
      bgColor   = const Color(0xFFE1F5EE);
      textColor = const Color(0xFF0F6E56);
    } else if (phase == 'fertile') {
      bgColor   = const Color(0xFFE6F1FB);
      textColor = const Color(0xFF185FA5);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: _pink, width: 2)
              : isToday && !isOnCycle
              ? Border.all(color: _pink, width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$day',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isOnCycle || phase.isNotEmpty
                      ? FontWeight.w600 : FontWeight.normal,
                  color: isToday && !isOnCycle ? _pink : textColor,
                )),
            // Small dot if logged but not on-cycle
            if (hasLog && !isOnCycle)
              Container(
                width: 4, height: 4,
                decoration: BoxDecoration(
                  color: textColor.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Legend ───────────────────────────────────────────────────
  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 12, runSpacing: 6,
        alignment: WrapAlignment.center,
        children: [
          _legendItem(_pink, _pink,
              AppLocalizations.of(context)!.onCycle),
          _legendItem(const Color(0xFFFBEAF0), const Color(0xFFF4C0D1), 'Predicted period'),
          _legendItem(const Color(0xFFFFF3E0), const Color(0xFFEF9F27), 'Follicular'),
          _legendItem(const Color(0xFFE6F1FB), const Color(0xFFB5D4F4), 'Fertile window'),
          _legendItem(const Color(0xFFE1F5EE), const Color(0xFF9FE1CB), 'Ovulation'),
        ],
      ),
    );
  }

  Widget _legendItem(Color bg, Color border, String label) =>
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 11, height: 11,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: border),
              boxShadow: AppColors.subtleShadow,
            ),
          ),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary(context))),
        ],
      );

  // ── Detail panel ─────────────────────────────────────────────
  Widget _buildDetailPanel() {
    final key  = _dateKey(_selectedDate);
    final log  = _logs[key];
    final isOnCycle = _onCycleDays.contains(key);
    final months = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    final dateStr =
        '${_selectedDate.day} ${months[_selectedDate.month - 1]} ${_selectedDate.year}';

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFFE05D6F),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(14),
        child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppColors.getShadow(context),
        ),
        child: Column(
          children: [
            // Header with date + on-cycle toggle
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Text(dateStr,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                  const Spacer(),
                  Text(AppLocalizations.of(context)!.onCycle,
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary(context))),
                  const SizedBox(width: 8),
                  // Toggle switch
                  GestureDetector(
                    onTap: () => _toggleCycle(_selectedDate),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40, height: 22,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(11),
                        color: isOnCycle
                            ? _pink : AppColors.cardBorder(context),
                      ),
                      child: AnimatedAlign(
                        duration: const Duration(milliseconds: 200),
                        alignment: isOnCycle
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.all(3),
                          width: 16, height: 16,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Log details
            if (log != null) ...[
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _detailRow(Icons.water_drop_outlined,
                        AppLocalizations.of(context)!.flow,
                        log.flow, _pink),
                    if (log.moods.isNotEmpty)
                      _detailChipRow(
                          Icons.sentiment_satisfied_alt_outlined,
                          AppLocalizations.of(context)!.mood,
                          log.moods, _amber),
                    if (log.symptoms.isNotEmpty)
                      _detailChipRow(
                          Icons.monitor_heart_outlined,
                          AppLocalizations.of(context)!.symptoms,
                          log.symptoms, _pink),
                    if (log.energy.isNotEmpty)
                      _detailRow(Icons.bolt_outlined,
                          AppLocalizations.of(context)!.energy,
                          log.energy, _teal),
                    if (log.sleep.isNotEmpty)
                      _detailRow(Icons.bedtime_outlined,
                          AppLocalizations.of(context)!.sleep,
                          log.sleep, _blue),
                    if (log.notes.isNotEmpty)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.notes_outlined,
                              size: 16,
                              color: AppColors.textHint(context)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(log.notes,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary(context))),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ] else ...[
              EmptyState(
                type: EmptyStateType.noCalendarLog,
                onAction: () => _openLog(_selectedDate),
                actionLabel: 'Thêm nhật ký',
              ),
            ],

            // Edit / Add log button
            GestureDetector(
              onTap: () => _openLog(_selectedDate),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: const BoxDecoration(
                  color: _pink,
                  borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.edit_outlined,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(log != null
                            ? AppLocalizations.of(context)!.editLog
                            : AppLocalizations.of(context)!.addLog,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label,
      String value, Color color) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Icon(icon, size: 16, color: AppColors.textHint(context)),
          const SizedBox(width: 8),
          Text('$label: ',
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary(context))),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(value,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: color)),
          ),
        ]),
      );

  Widget _detailChipRow(IconData icon, String label,
      List<String> values, Color color) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16,
                color: AppColors.textHint(context)),
            const SizedBox(width: 8),
            Text('$label: ',
                style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary(context))),
            Expanded(
              child: Wrap(
                spacing: 4, runSpacing: 4,
                children: values.map((v) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(v,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: color)),
                )).toList(),
              ),
            ),
          ],
        ),
      );

  // ── Helpers ──────────────────────────────────────────────────
  // Returns: 'period-actual', 'period-predicted',
//          'ovulation', 'fertile', or ''
  // ── Find the most recent cycle start from on-cycle days ──────
  DateTime? get _lastCycleStart {
    if (_onCycleDays.isEmpty) return null;

    final sorted = _onCycleDays.toList()..sort();

    // Group consecutive days — a new cycle starts after a gap > 10 days
    DateTime? cycleStart;
    DateTime? prev;

    for (final key in sorted) {
      final date = DateTime.parse(key);
      if (prev == null || date.difference(prev).inDays > 10) {
        // New cycle group
        cycleStart = date;
      }
      prev = date;
    }

    return cycleStart; // returns the START of the most recent group
  }

// ── Phase prediction based only on last cycle start ──────────
  String _phaseForDate(DateTime date) {
    final cycleStart = _lastCycleStart;
    if (cycleStart == null) return '';

    // Don't predict for days before cycle start
    if (date.isBefore(cycleStart)) return '';

    // Don't show prediction for actual on-cycle days
    if (_onCycleDays.contains(_dateKey(date))) return '';

    // Days since cycle start (1-indexed)
    final diff = date.difference(cycleStart).inDays;
    final day  = diff + 1;

    // Current cycle phases (days 1–28)
    if (day >= 1  && day <= 28) {
      if (day >= 6  && day <= 13) return 'follicular';
      if (day >= 14 && day <= 16) return 'ovulation';
      if (day >= 11 && day <= 17) return 'fertile';
      return '';
    }

    // Next predicted cycle (day 29+)
    final nextCycleDay = day - 28;
    if (nextCycleDay >= 1  && nextCycleDay <= 5)  return 'period-predicted';
    if (nextCycleDay >= 11 && nextCycleDay <= 17) return 'fertile';
    if (nextCycleDay >= 14 && nextCycleDay <= 16) return 'ovulation';

    return '';
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';
}