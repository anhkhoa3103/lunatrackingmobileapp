import 'package:flutter/material.dart';
import '../models/cycle_entry.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class LogScreen extends StatefulWidget {
  final DateTime? date;           // ← which day to log
  final CycleEntry? existingLog;  // ← prefill if editing

  const LogScreen({super.key, this.date, this.existingLog});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {

  String? selectedFlow;
  final Set<String> selectedMoods    = {};
  final Set<String> selectedSymptoms = {};
  String? selectedEnergy;
  String? selectedSleep;
  final TextEditingController noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existingLog != null) {
      final log = widget.existingLog!;
      selectedFlow = log.flow;
      selectedMoods.addAll(log.moods);
      selectedSymptoms.addAll(log.symptoms);
      selectedEnergy = log.energy;
      selectedSleep = log.sleep;
      noteCtrl.text = log.notes;
    }
  }
  // ── Data ────────────────────────────────────────────────────
  final flowOptions = [
    _Option('None',   '#B4B2A9', Icons.remove),
    _Option('Light',  '#F4C0D1', Icons.water_drop_outlined),
    _Option('Medium', '#E05D6F', Icons.water_drop),
    _Option('Heavy',  '#993556', Icons.opacity),
  ];

  final moodOptions = [
    _Option('Happy',     '#F5A623', Icons.sentiment_very_satisfied_outlined),
    _Option('Calm',      '#1D9E75', Icons.spa_outlined),
    _Option('Anxious',   '#5B8CDE', Icons.psychology_outlined),
    _Option('Sad',       '#888780', Icons.sentiment_dissatisfied_outlined),
    _Option('Irritable', '#E05D6F', Icons.local_fire_department_outlined),
    _Option('Tired',     '#B4B2A9', Icons.bedtime_outlined),
  ];

  final symptomOptions = [
    _Option('Cramps',    '#E05D6F', Icons.waves),
    _Option('Headache',  '#E05D6F', Icons.sick_outlined),
    _Option('Bloating',  '#E05D6F', Icons.circle_outlined),
    _Option('Back pain', '#E05D6F', Icons.accessibility_outlined),
    _Option('Nausea',    '#E05D6F', Icons.air_outlined),
    _Option('Fatigue',   '#E05D6F', Icons.battery_1_bar),
  ];

  final energyOptions = [
    _Option('Low',    '#5B8CDE', Icons.battery_1_bar),
    _Option('Medium', '#F5A623', Icons.battery_3_bar),
    _Option('High',   '#1D9E75', Icons.battery_charging_full),
  ];

  final sleepOptions = [
    _Option('Poor', '#E05D6F', Icons.bedtime_outlined),
    _Option('OK',   '#F5A623', Icons.dark_mode_outlined),
    _Option('Good', '#1D9E75', Icons.mode_night_outlined),
  ];

  // ── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('How are you today?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(_formatDate(widget.date ?? DateTime.now()),
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFlowSection(),
            const SizedBox(height: 24),
            _buildChipSection('Mood', moodOptions,
                selectedMoods, (v) => setState(() {
                  selectedMoods.contains(v)
                      ? selectedMoods.remove(v)
                      : selectedMoods.add(v);
                })),
            const SizedBox(height: 24),
            _buildChipSection('Symptoms', symptomOptions,
                selectedSymptoms, (v) => setState(() {
                  selectedSymptoms.contains(v)
                      ? selectedSymptoms.remove(v)
                      : selectedSymptoms.add(v);
                })),
            const SizedBox(height: 24),
            _buildSingleSection('Energy', energyOptions,
                selectedEnergy, (v) => setState(() => selectedEnergy = v)),
            const SizedBox(height: 24),
            _buildSingleSection('Sleep', sleepOptions,
                selectedSleep, (v) => setState(() => selectedSleep = v)),
            const SizedBox(height: 24),
            _buildNotesSection(),
            const SizedBox(height: 32),
            _buildSaveButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Flow ─────────────────────────────────────────────────────
  Widget _buildFlowSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Flow'),
        const SizedBox(height: 10),
        Row(
          children: flowOptions.map((opt) {
            final isSelected = selectedFlow == opt.label;
            final color = _hexColor(opt.color);
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => selectedFlow = opt.label),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? color : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? color : Colors.grey[200]!,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(opt.icon, size: 18,
                          color: isSelected ? Colors.white : Colors.grey[400]),
                      const SizedBox(height: 4),
                      Text(opt.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected ? Colors.white : Colors.grey[500],
                            fontWeight: isSelected
                                ? FontWeight.w600 : FontWeight.normal,
                          )),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Multi-select chip section ────────────────────────────────
  Widget _buildChipSection(String title, List<_Option> options,
      Set<String> selected, void Function(String) onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(title),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: options.map((opt) {
            final isSelected = selected.contains(opt.label);
            final color = _hexColor(opt.color);
            return GestureDetector(
              onTap: () => onTap(opt.label),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? color : Colors.grey[200]!,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(opt.icon, size: 15,
                        color: isSelected ? Colors.white : Colors.grey[400]),
                    const SizedBox(width: 6),
                    Text(opt.label,
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected ? Colors.white : Colors.grey[600],
                          fontWeight: isSelected
                              ? FontWeight.w500 : FontWeight.normal,
                        )),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Single-select chip section ───────────────────────────────
  Widget _buildSingleSection(String title, List<_Option> options,
      String? selected, void Function(String) onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(title),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: options.map((opt) {
            final isSelected = selected == opt.label;
            final color = _hexColor(opt.color);
            return GestureDetector(
              onTap: () => onTap(opt.label),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? color : Colors.grey[200]!,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(opt.icon, size: 15,
                        color: isSelected ? Colors.white : Colors.grey[400]),
                    const SizedBox(width: 6),
                    Text(opt.label,
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected ? Colors.white : Colors.grey[600],
                          fontWeight: isSelected
                              ? FontWeight.w500 : FontWeight.normal,
                        )),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Notes ────────────────────────────────────────────────────
  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Notes'),
        const SizedBox(height: 10),
        TextField(
          controller: noteCtrl,
          maxLines: 3,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Anything else to note today...',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!, width: 0.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!, width: 0.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE05D6F), width: 1),
            ),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
      ],
    );
  }

  // ── Save button ──────────────────────────────────────────────
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveLog,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE05D6F),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: Text(widget.date != null && !_isSameDay(widget.date!, DateTime.now())
            ? 'Save log for ${_formatDate(widget.date!)}'
            : 'Save today\'s log',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      ),
    );
  }
  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  void _saveLog() async {
    final date = widget.date ?? DateTime.now();
    final entry = {
      'date':     date.toIso8601String().split('T')[0],
      'flow':     selectedFlow ?? 'none',
      'moods':    selectedMoods.toList(),
      'symptoms': selectedSymptoms.toList(),
      'energy':   selectedEnergy ?? '',
      'sleep':    selectedSleep ?? '',
      'notes':    noteCtrl.text.trim(),
    };
    final success = await ApiService.saveEntry(entry);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success ? 'Saved!' : 'Saved locally'),
      backgroundColor: success
          ? const Color(0xFF1D9E75) : const Color(0xFFF5A623),
      behavior: SnackBarBehavior.floating,
    ));
    if (success) Navigator.pop(context); // ← go back to calendar
  }

  // ── Helpers ──────────────────────────────────────────────────
  Widget _sectionTitle(String title) => Text(
    title.toUpperCase(),
    style: TextStyle(
      fontSize: 11, fontWeight: FontWeight.w600,
      color: Colors.grey[500], letterSpacing: 0.8,
    ),
  );

  Color _hexColor(String hex) =>
      Color(int.parse(hex.replaceFirst('#', '0xFF')));

  String _formatDate(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  @override
  void dispose() {
    noteCtrl.dispose();
    super.dispose();
  }
}

// ── Option model ─────────────────────────────────────────────
class _Option {
  final String label, color;
  final IconData icon;
  const _Option(this.label, this.color, this.icon);
}