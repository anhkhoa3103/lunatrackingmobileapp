import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n.dart';
import '../providers/locale_notifier.dart';
import '../providers/theme_notifier.dart';
import '../utils/app_colors.dart';
import '../utils/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name  = '';
  String _email = '';
  int _cycleLength  = 28;
  int _periodLength = 5;
  DateTime? _lastPeriodStart;
  bool _editing = false;

  final _nameCtrl = TextEditingController();

  static const _pink = Color(0xFFE05D6F);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name  = prefs.getString('user_name')  ?? '';
      _email = prefs.getString('user_email') ?? '';
      _cycleLength  = prefs.getInt('cycle_length')  ?? 28;
      _periodLength = prefs.getInt('period_length') ?? 5;
      final lastStr = prefs.getString('last_period_start');
      if (lastStr != null) {
        _lastPeriodStart = DateTime.tryParse(lastStr);
      }
      _nameCtrl.text = _name;
    });
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _nameCtrl.text.trim());
    await prefs.setInt('cycle_length', _cycleLength);
    await prefs.setInt('period_length', _periodLength);
    if (_lastPeriodStart != null) {
      await prefs.setString('last_period_start',
          _lastPeriodStart!.toIso8601String().split('T')[0]);
    }
    setState(() {
      _name   = _nameCtrl.text.trim();
      _editing = false;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(AppLocalizations.of(context)!.profileSaved),
        ]),
        backgroundColor: const Color(0xFF1D9E75),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Avatar initials ──────────────────────────────────────────
  String get _initials {
    if (_name.isEmpty) return '?';
    final parts = _name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return _name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: Column(
        children: [
          _buildHero(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(
                      AppLocalizations.of(context)!.personalInfo),
                  _buildPersonalInfo(),
                  _buildSectionTitle(
                      AppLocalizations.of(context)!.cycleSettings),
                  _buildCycleSettings(),
                  _buildSectionTitle(
                      AppLocalizations.of(context)!.appearance),
                  _buildThemeSelector(),
                  _buildSectionTitle(
                      AppLocalizations.of(context)!.language),
                  _buildLanguageSelector(),
                  const SizedBox(height: 24),
                  if (_editing) _buildSaveButton(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero header ──────────────────────────────────────────────
  Widget _buildHero() {
    return Container(
      color: _pink,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20, right: 20, bottom: 24,
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),

          // Avatar
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.25),
            ),
            child: Center(
              child: Text(_initials,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: Colors.white)),
            ),
          ),
          const SizedBox(width: 14),

          // Name & email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_name.isEmpty ? 'Your name' : _name,
                    style: AppTheme.headlineMedium.copyWith(
                        color: Colors.white)),
                const SizedBox(height: 2),
                Text(_email,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.75))),
              ],
            ),
          ),

          // Edit button
          GestureDetector(
            onTap: () => setState(() => _editing = !_editing),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(_editing ? 'Cancel' : 'Edit',
                  style: const TextStyle(
                      fontSize: 12, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Personal info ────────────────────────────────────────────
  Widget _buildPersonalInfo() {
    return _sectionCard(
      children: [
        _fieldRow(AppLocalizations.of(context)!.name,
            _editing
                ? _editableField(_nameCtrl, 'Your name')
                : Text(_name.isEmpty ? '— not set —' : _name,
                style: _valStyle)),
        _fieldRow(AppLocalizations.of(context)!.email,
            Text(_email, style: _valStyle)),
      ],
    );
  }

  // ── Cycle settings ───────────────────────────────────────────
  Widget _buildCycleSettings() {
    return _sectionCard(
      children: [
        _fieldRow(AppLocalizations.of(context)!.avgCycleLength,
            _editing
                ? _counterWidget(
                value: _cycleLength,
                min: 21, max: 45,
                onChanged: (v) =>
                    setState(() => _cycleLength = v),
                unit: AppLocalizations.of(context)!.days)
                : Text(
                '$_cycleLength ${AppLocalizations.of(context)!.days}',
                style: _valStyle)),

        _fieldRow(AppLocalizations.of(context)!.periodDuration,
            _editing
                ? _counterWidget(
                value: _periodLength,
                min: 2, max: 10,
                onChanged: (v) =>
                    setState(() => _periodLength = v),
                unit: AppLocalizations.of(context)!.days)
                : Text(
                '$_periodLength ${AppLocalizations.of(context)!.days}',
                style: _valStyle)),

        _fieldRow(AppLocalizations.of(context)!.lastPeriodStart,
            _editing
                ? GestureDetector(
              onTap: _pickLastPeriodDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: AppColors.cardBorder(context)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 14,
                        color: AppColors.textSecondary(context)),
                    const SizedBox(width: 6),
                    Text(
                      _lastPeriodStart != null
                          ? _formatDate(_lastPeriodStart!)
                          : 'Pick a date',
                      style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary(context)),
                    ),
                  ],
                ),
              ),
            )
                : Text(
                _lastPeriodStart != null
                    ? _formatDate(_lastPeriodStart!)
                    : '— not set —',
                style: _valStyle)),
      ],
    );
  }

  // ── Theme selector ───────────────────────────────────────────
  Widget _buildThemeSelector() {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final options = [
      {'label': AppLocalizations.of(context)!.system,
       'value': ThemeMode.system,
       'icon': Icons.brightness_auto_outlined},
      {'label': AppLocalizations.of(context)!.lightMode,
       'value': ThemeMode.light,
       'icon': Icons.light_mode_outlined},
      {'label': AppLocalizations.of(context)!.darkMode,
       'value': ThemeMode.dark,
       'icon': Icons.dark_mode_outlined},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: options.map((opt) {
          final isSelected =
              themeNotifier.themeMode == opt['value'];
          return Expanded(
            child: GestureDetector(
              onTap: () => themeNotifier
                  .setTheme(opt['value'] as ThemeMode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(
                    vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFE05D6F)
                      : AppColors.surface(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFE05D6F)
                        : AppColors.cardBorder(context),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(opt['icon'] as IconData,
                        size: 20,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary(context)),
                    const SizedBox(height: 4),
                    Text(opt['label'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary(context),
                          fontWeight: isSelected
                              ? FontWeight.w500
                              : FontWeight.normal,
                        )),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Language selector ────────────────────────────────────────
  Widget _buildLanguageSelector() {
    final localeNotifier = Provider.of<LocaleNotifier>(context);
    final options = [
      {'label': 'Tiếng Việt', 'code': 'vi', 'flag': '🇻🇳'},
      {'label': 'English',    'code': 'en', 'flag': '🇺🇸'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: options.map((opt) {
          final isSelected =
              localeNotifier.locale.languageCode == opt['code'];
          return Expanded(
            child: GestureDetector(
              onTap: () => localeNotifier
                  .setLocale(Locale(opt['code'] as String)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(
                    vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFE05D6F)
                      : AppColors.surface(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFE05D6F)
                        : AppColors.cardBorder(context),
                  ),
                ),
                child: Column(
                  children: [
                    Text(opt['flag'] as String,
                        style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 4),
                    Text(opt['label'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary(context),
                          fontWeight: isSelected
                              ? FontWeight.w500
                              : FontWeight.normal,
                        )),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _pickLastPeriodDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastPeriodStart ?? DateTime.now(),
      firstDate: DateTime.now().subtract(
          const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
                primary: Color(0xFFE05D6F))),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _lastPeriodStart = picked);
    }
  }

  // ── Save button ──────────────────────────────────────────────
  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _saveProfile,
          style: ElevatedButton.styleFrom(
            backgroundColor: _pink,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: Text(AppLocalizations.of(context)!.saveChanges,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────
  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
    child: Text(title.toUpperCase(),
        style: AppTheme.labelSmall.copyWith(
            color: AppColors.textSecondary(context))),
  );

  Widget _sectionCard({required List<Widget> children}) => Container(
    margin: const EdgeInsets.symmetric(
        horizontal: 16, vertical: 4),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(12),
      boxShadow: AppColors.subtleShadow,
    ),
    child: Column(children: children),
  );

  Widget _fieldRow(String label, Widget value) => Container(
    padding: const EdgeInsets.symmetric(
        horizontal: 20, vertical: 14),
    child: Row(
      children: [
        SizedBox(
          width: 140,
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary(context))),
        ),
        Expanded(child: value),
      ],
    ),
  );

  Widget _counterWidget({
    required int value,
    required int min,
    required int max,
    required void Function(int) onChanged,
    required String unit,
  }) =>
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _counterBtn(Icons.remove, () {
            if (value > min) onChanged(value - 1);
          }),
          const SizedBox(width: 10),
          Text('$value',
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500)),
          const SizedBox(width: 10),
          _counterBtn(Icons.add, () {
            if (value < max) onChanged(value + 1);
          }),
          const SizedBox(width: 6),
          Text(unit,
              style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary(context))),
        ],
      );

  Widget _counterBtn(IconData icon, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: AppColors.cardBorder(context)),
          ),
          child: Icon(icon, size: 14,
              color: AppColors.textSecondary(context)),
        ),
      );

  Widget _editableField(
      TextEditingController ctrl, String hint) =>
      SizedBox(
        height: 36,
        child: TextField(
          controller: ctrl,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                color: AppColors.textHint(context)),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
              BorderSide(color: AppColors.cardBorder(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
              BorderSide(color: AppColors.cardBorder(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
              const BorderSide(color: Color(0xFFE05D6F)),
            ),
          ),
        ),
      );

  TextStyle get _valStyle => const TextStyle(
      fontSize: 13, fontWeight: FontWeight.w500);

  String _formatDate(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }
}