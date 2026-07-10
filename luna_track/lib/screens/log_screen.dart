import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n.dart';
import '../models/cycle_entry.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../widgets/animated_chip.dart';
import '../widgets/animated_flow_button.dart';
import '../widgets/save_success_overlay.dart';

// Thin full-screen wrapper — kept for backward compatibility
class LogScreen extends StatelessWidget {
  final DateTime? date;           // ← which day to log
  final CycleEntry? existingLog;  // ← prefill if editing

  const LogScreen({super.key, this.date, this.existingLog});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        elevation: 0,
        title: Text(
          _formatDate(date ?? DateTime.now()),
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w500),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: LogScreenBody(
        date: date,
        existingLog: existingLog,
        onSaved: () => Navigator.pop(context),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }
}

// The scrollable log form — works inside a screen or a bottom sheet
class LogScreenBody extends StatefulWidget {
  final DateTime? date;
  final CycleEntry? existingLog;
  final ScrollController? scrollController;
  final VoidCallback? onSaved;  // ← callback instead of Navigator.pop

  const LogScreenBody({
    super.key,
    this.date,
    this.existingLog,
    this.scrollController,
    this.onSaved,
  });

  @override
  State<LogScreenBody> createState() => _LogScreenBodyState();
}

class _LogScreenBodyState extends State<LogScreenBody> {

  String? selectedFlow;
  final Set<String> selectedMoods    = {};
  final Set<String> selectedSymptoms = {};
  String? selectedEnergy;
  String? selectedSleep;
  final TextEditingController noteCtrl = TextEditingController();
  bool _saving = false;

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
    return SingleChildScrollView(
      controller: widget.scrollController,  // ← use passed controller
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFlowSection(),
          const SizedBox(height: 24),
          _buildChipSection(
              AppLocalizations.of(context)!.mood, moodOptions,
              selectedMoods, (v) => setState(() {
                selectedMoods.contains(v)
                    ? selectedMoods.remove(v)
                    : selectedMoods.add(v);
              })),
          const SizedBox(height: 24),
          _buildChipSection(
              AppLocalizations.of(context)!.symptoms, symptomOptions,
              selectedSymptoms, (v) => setState(() {
                selectedSymptoms.contains(v)
                    ? selectedSymptoms.remove(v)
                    : selectedSymptoms.add(v);
              })),
          const SizedBox(height: 24),
          _buildSingleSection(
              AppLocalizations.of(context)!.energy, energyOptions,
              selectedEnergy, (v) => setState(() => selectedEnergy = v)),
          const SizedBox(height: 24),
          _buildSingleSection(
              AppLocalizations.of(context)!.sleep, sleepOptions,
              selectedSleep, (v) => setState(() => selectedSleep = v)),
          const SizedBox(height: 24),
          _buildNotesSection(),
          const SizedBox(height: 32),
          _buildSaveButton(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Flow ─────────────────────────────────────────────────────
  Widget _buildFlowSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(AppLocalizations.of(context)!.flow),
        const SizedBox(height: 10),
        Row(
          children: flowOptions.map((opt) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: AnimatedFlowButton(
                  label: AppLocalizations.of(context)!
                      .optionLabel(opt.label),
                  icon: opt.icon,
                  isSelected: selectedFlow == opt.label,
                  selectedColor: _hexColor(opt.color),
                  onTap: () =>
                      setState(() => selectedFlow = opt.label),
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
            return AnimatedChip(
              label: AppLocalizations.of(context)!
                  .optionLabel(opt.label),
              icon: opt.icon,
              isSelected: selected.contains(opt.label),
              selectedColor: _hexColor(opt.color),
              onTap: () => onTap(opt.label),
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
            return AnimatedChip(
              label: AppLocalizations.of(context)!
                  .optionLabel(opt.label),
              icon: opt.icon,
              isSelected: selected == opt.label,
              selectedColor: _hexColor(opt.color),
              onTap: () => onTap(opt.label),
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
        _sectionTitle(AppLocalizations.of(context)!.notes),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppColors.subtleShadow,
          ),
          child: TextField(
            controller: noteCtrl,
            maxLines: 3,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Anything else to note today...',
              hintStyle: TextStyle(
                  color: AppColors.textHint(context), fontSize: 13),
              filled: true,
              fillColor: AppColors.surface(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE05D6F), width: 1),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
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
        onPressed: _saving ? null : _saveLog,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE05D6F),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ).copyWith(
          shadowColor: WidgetStateProperty.all(
              const Color(0xFFE05D6F).withOpacity(0.4)),
          elevation: WidgetStateProperty.all(8),
        ),
        child: Text(widget.date != null && !_isSameDay(widget.date!, DateTime.now())
            ? '${AppLocalizations.of(context)!.saveLog} '
                '${_formatDate(widget.date!)}'
            : AppLocalizations.of(context)!.saveTodayLog,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      ),
    );
  }
  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  void _saveLog() async {
    setState(() => _saving = true);

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
    setState(() => _saving = false);

    if (success) {
      HapticFeedback.mediumImpact(); // ← on save success
      // Show success overlay
      showDialog(
        context: context,
        barrierColor: Colors.black26,
        barrierDismissible: false,
        builder: (_) => Center(
          child: SaveSuccessOverlay(
            onComplete: () {
              Navigator.pop(context); // close dialog
              widget.onSaved?.call(); // close bottom sheet / screen
            },
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!.savedLocally),
        backgroundColor: const Color(0xFFF5A623),
        behavior: SnackBarBehavior.floating,
      ));
      widget.onSaved?.call();
    }
  }

  // ── Helpers ──────────────────────────────────────────────────
  Widget _sectionTitle(String title) => Text(
    title.toUpperCase(),
    style: TextStyle(
      fontSize: 11, fontWeight: FontWeight.w600,
      color: AppColors.textSecondary(context), letterSpacing: 0.8,
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
