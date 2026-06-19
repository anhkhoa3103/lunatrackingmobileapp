import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/cycle_entry.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});
  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  List<CycleEntry> _entries = [];
  bool _loading = true;

  static const _pink  = Color(0xFFE05D6F);
  static const _teal  = Color(0xFF1D9E75);
  static const _blue  = Color(0xFF5B8CDE);
  static const _amber = Color(0xFFF5A623);
  static const _gray  = Color(0xFFB4B2A9);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final remote = await ApiService.getAllEntries();
      final entries = remote.map((e) => CycleEntry(
        date:     DateTime.parse(e['date']),
        flow:     e['flow'] ?? 'none',
        moods:    List<String>.from(e['moods'] ?? []),
        symptoms: List<String>.from(e['symptoms'] ?? []),
        energy:   e['energy'] ?? '',
        sleep:    e['sleep'] ?? '',
        notes:    e['notes'] ?? '',
      )).toList();
      entries.sort((a, b) => a.date.compareTo(b.date));
      setState(() { _entries = entries; _loading = false; });
    } catch (_) {
      final entries = StorageService.getAllEntries();
      setState(() { _entries = entries; _loading = false; });
    }
  }

  // ── Computed stats ───────────────────────────────────────────

  // Detect cycle starts — days with medium/heavy flow after a gap
  List<DateTime> get _cycleStarts {
    final onCycleDays = _entries
        .where((e) => e.flow == 'medium' || e.flow == 'heavy')
        .map((e) => e.date)
        .toList()
      ..sort();

    if (onCycleDays.isEmpty) return [];

    final starts = <DateTime>[onCycleDays.first];
    for (int i = 1; i < onCycleDays.length; i++) {
      final diff = onCycleDays[i]
          .difference(onCycleDays[i - 1]).inDays;
      // New cycle if gap > 10 days
      if (diff > 10) starts.add(onCycleDays[i]);
    }
    return starts;
  }

  // Cycle lengths from consecutive cycle starts
  List<double> get _cycleLengths {
    final starts = _cycleStarts;
    if (starts.length < 2) return [];
    final lengths = <double>[];
    for (int i = 1; i < starts.length; i++) {
      lengths.add(starts[i].difference(starts[i - 1]).inDays.toDouble());
    }
    return lengths;
  }

  double get _avgCycleLength {
    final lengths = _cycleLengths;
    if (lengths.isEmpty) return 28;
    return lengths.reduce((a, b) => a + b) / lengths.length;
  }

  // Average period duration (consecutive on-cycle days per cycle)
  double get _avgPeriodDays {
    final starts = _cycleStarts;
    if (starts.isEmpty) return 0;
    final onCycleDays = _entries
        .where((e) => e.flow == 'medium' || e.flow == 'heavy')
        .map((e) => e.date)
        .toList()
      ..sort();

    if (onCycleDays.isEmpty) return 0;

    int total = 0, cycles = 0, count = 1;
    for (int i = 1; i < onCycleDays.length; i++) {
      final diff =
          onCycleDays[i].difference(onCycleDays[i - 1]).inDays;
      if (diff == 1) {
        count++;
      } else {
        total += count;
        cycles++;
        count = 1;
      }
    }
    total += count;
    cycles++;
    return total / cycles;
  }

  Map<String, int> get _symptomCounts {
    final map = <String, int>{};
    for (final e in _entries) {
      for (final s in e.symptoms) {
        map[s] = (map[s] ?? 0) + 1;
      }
    }
    final sorted = Map.fromEntries(
        map.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)));
    return sorted;
  }

  Map<String, int> get _moodCounts {
    final map = <String, int>{};
    for (final e in _entries) {
      for (final m in e.moods) {
        map[m] = (map[m] ?? 0) + 1;
      }
    }
    return map;
  }

  // Energy/sleep per week (last 4 weeks)
  List<_WeekStat> get _weekStats {
    final now = DateTime.now();
    final stats = <_WeekStat>[];
    for (int w = 3; w >= 0; w--) {
      final start = now.subtract(Duration(days: (w + 1) * 7));
      final end   = now.subtract(Duration(days: w * 7));
      final week  = _entries.where((e) =>
      e.date.isAfter(start) && e.date.isBefore(end)).toList();

      double avgEnergy = 0, avgSleep = 0;
      if (week.isNotEmpty) {
        avgEnergy = week
            .where((e) => e.energy.isNotEmpty)
            .map((e) => _levelToNum(e.energy))
            .fold(0.0, (a, b) => a + b) /
            week.where((e) => e.energy.isNotEmpty).length
                .clamp(1, 999);
        avgSleep = week
            .where((e) => e.sleep.isNotEmpty)
            .map((e) => _levelToNum(e.sleep))
            .fold(0.0, (a, b) => a + b) /
            week.where((e) => e.sleep.isNotEmpty).length
                .clamp(1, 999);
      }
      stats.add(_WeekStat('Wk ${4 - w}', avgEnergy, avgSleep));
    }
    return stats;
  }

  double _levelToNum(String level) {
    switch (level.toLowerCase()) {
      case 'low':  case 'poor': return 1;
      case 'ok':   case 'medium': return 2;
      case 'good': case 'high':   return 3;
      default: return 0;
    }
  }

  // ── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Insights',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w500)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(
          color: _pink))
          : _entries.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatCards(),
            const SizedBox(height: 24),
            if (_cycleLengths.isNotEmpty) ...[
              _buildCycleChart(),
              const SizedBox(height: 24),
            ],
            if (_symptomCounts.isNotEmpty) ...[
              _buildSymptomBars(),
              const SizedBox(height: 24),
            ],
            if (_moodCounts.isNotEmpty) ...[
              _buildMoodBreakdown(),
              const SizedBox(height: 24),
            ],
            _buildEnergyChart(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── Empty state ──────────────────────────────────────────────
  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.bar_chart, size: 64, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Text('No data yet',
            style: TextStyle(
                fontSize: 16, color: Colors.grey[500])),
        const SizedBox(height: 8),
        Text('Start logging your cycle to see insights',
            style: TextStyle(
                fontSize: 13, color: Colors.grey[400])),
      ],
    ),
  );

  // ── Stat cards ───────────────────────────────────────────────
  Widget _buildStatCards() {
    return Row(children: [
      _statCard('${_avgCycleLength.toStringAsFixed(0)}d',
          'avg cycle', _pink),
      const SizedBox(width: 8),
      _statCard('${_avgPeriodDays.toStringAsFixed(0)}d',
          'avg period', _teal),
      const SizedBox(width: 8),
      _statCard('${_entries.length}', 'logs total', _blue),
    ]);
  }

  Widget _statCard(String value, String label, Color color) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: [
            Text(value,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: color)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11, color: Colors.grey[500])),
          ]),
        ),
      );

  // ── Cycle length chart ───────────────────────────────────────
  Widget _buildCycleChart() {
    final lengths = _cycleLengths;
    final starts  = _cycleStarts;
    const months  = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    final labels  = starts.take(lengths.length)
        .map((d) => '${months[d.month - 1]}')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Cycle length history'),
        const SizedBox(height: 10),
        SizedBox(
          height: 160,
          child: LineChart(LineChartData(
            minY: (lengths.reduce(min) - 4).clamp(18, 40),
            maxY: (lengths.reduce(max) + 4).clamp(22, 45),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 2,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: Colors.grey[200]!, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true, reservedSize: 28,
                  interval: 2,
                  getTitlesWidget: (v, _) => Text(
                      '${v.toInt()}',
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey[400])),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true, reservedSize: 22,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= labels.length)
                      return const SizedBox();
                    return Text(labels[i],
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[400]));
                  },
                ),
              ),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: lengths.asMap().entries
                    .map((e) =>
                    FlSpot(e.key.toDouble(), e.value))
                    .toList(),
                isCurved: true,
                color: _pink,
                barWidth: 2.5,
                dotData: FlDotData(
                  getDotPainter: (_, __, ___, ____) =>
                      FlDotCirclePainter(
                          radius: 4, color: _pink,
                          strokeWidth: 2,
                          strokeColor: Colors.white),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: _pink.withOpacity(0.1),
                ),
              ),
            ],
          )),
        ),
      ],
    );
  }

  // ── Symptom bars ─────────────────────────────────────────────
  Widget _buildSymptomBars() {
    final counts = Map.fromEntries(
        _symptomCounts.entries.take(5));
    final maxVal = counts.values
        .reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Top symptoms'),
        const SizedBox(height: 10),
        ...counts.entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            SizedBox(
              width: 70,
              child: Text(e.key,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey[500])),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Stack(children: [
                  Container(height: 18, color: Colors.grey[100]),
                  FractionallySizedBox(
                    widthFactor: e.value / maxVal,
                    child: Container(
                        height: 18,
                        color: _pink.withOpacity(0.8)),
                  ),
                ]),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 20,
              child: Text('${e.value}',
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey[500])),
            ),
          ]),
        )),
      ],
    );
  }

  // ── Mood breakdown ───────────────────────────────────────────
  Widget _buildMoodBreakdown() {
    final moodColors = {
      'Tired':     _gray,
      'Happy':     _amber,
      'Calm':      _teal,
      'Irritable': _pink,
      'Anxious':   _blue,
      'Sad':       Colors.grey,
    };
    final total = _moodCounts.values
        .fold(0, (a, b) => a + b);
    final sorted = Map.fromEntries(
        _moodCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Mood breakdown'),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8, mainAxisSpacing: 8,
          childAspectRatio: 1.4,
          children: sorted.entries.take(6).map((e) {
            final pct = total == 0
                ? 0 : (e.value / total * 100).round();
            final color = moodColors[e.key] ?? _gray;
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('$pct%',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: color)),
                  const SizedBox(height: 2),
                  Text(e.key,
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500])),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Energy & sleep chart ─────────────────────────────────────
  Widget _buildEnergyChart() {
    final stats = _weekStats;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Energy & sleep (4 weeks)'),
        const SizedBox(height: 6),
        Row(children: [
          _legendDot(_teal), const SizedBox(width: 4),
          Text('Energy',
              style: TextStyle(
                  fontSize: 11, color: Colors.grey[500])),
          const SizedBox(width: 12),
          _legendDot(_blue), const SizedBox(width: 4),
          Text('Sleep',
              style: TextStyle(
                  fontSize: 11, color: Colors.grey[500])),
        ]),
        const SizedBox(height: 10),
        SizedBox(
          height: 140,
          child: BarChart(BarChartData(
            maxY: 4,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 1,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: Colors.grey[200]!, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true, reservedSize: 22,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    return Text(
                        i < stats.length ? stats[i].label : '',
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[400]));
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true, reservedSize: 36,
                  interval: 1,
                  getTitlesWidget: (v, _) {
                    switch (v.toInt()) {
                      case 1: return Text('Low',
                          style: TextStyle(fontSize: 9,
                              color: Colors.grey[400]));
                      case 2: return Text('OK',
                          style: TextStyle(fontSize: 9,
                              color: Colors.grey[400]));
                      case 3: return Text('Good',
                          style: TextStyle(fontSize: 9,
                              color: Colors.grey[400]));
                      default: return const SizedBox();
                    }
                  },
                ),
              ),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
            ),
            barGroups: List.generate(stats.length, (i) =>
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                        toY: stats[i].energy,
                        color: _teal.withOpacity(0.8),
                        width: 12,
                        borderRadius: BorderRadius.circular(4)),
                    BarChartRodData(
                        toY: stats[i].sleep,
                        color: _blue.withOpacity(0.8),
                        width: 12,
                        borderRadius: BorderRadius.circular(4)),
                  ],
                  barsSpace: 4,
                )),
          )),
        ),
      ],
    );
  }

  // ── Helpers ──────────────────────────────────────────────────
  Widget _sectionTitle(String t) => Text(t.toUpperCase(),
      style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w600,
          color: Colors.grey[500], letterSpacing: 0.8));

  Widget _legendDot(Color c) => Container(
      width: 10, height: 10,
      decoration: BoxDecoration(
          color: c, borderRadius: BorderRadius.circular(2)));
}

// ── Week stat model ──────────────────────────────────────────
class _WeekStat {
  final String label;
  final double energy, sleep;
  const _WeekStat(this.label, this.energy, this.sleep);
}

double min(double a, double b) => a < b ? a : b;
double max(double a, double b) => a > b ? a : b;