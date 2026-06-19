import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

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
        content: const Row(children: [
          Icon(Icons.check_circle, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Text('Profile saved'),
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
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHero(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Personal info'),
                  _buildPersonalInfo(),
                  _buildSectionTitle('Cycle settings'),
                  _buildCycleSettings(),
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
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
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
    return Column(
      children: [
        _fieldRow('Name',
            _editing
                ? _editableField(_nameCtrl, 'Your name')
                : Text(_name.isEmpty ? '— not set —' : _name,
                style: _valStyle)),
        _fieldRow('Email',
            Text(_email, style: _valStyle)),
      ],
    );
  }

  // ── Cycle settings ───────────────────────────────────────────
  Widget _buildCycleSettings() {
    return Column(
      children: [
        _fieldRow('Cycle length',
            _editing
                ? _counterWidget(
                value: _cycleLength,
                min: 21, max: 45,
                onChanged: (v) =>
                    setState(() => _cycleLength = v),
                unit: 'days')
                : Text('$_cycleLength days',
                style: _valStyle)),

        _fieldRow('Period duration',
            _editing
                ? _counterWidget(
                value: _periodLength,
                min: 2, max: 10,
                onChanged: (v) =>
                    setState(() => _periodLength = v),
                unit: 'days')
                : Text('$_periodLength days',
                style: _valStyle)),

        _fieldRow('Last period start',
            _editing
                ? GestureDetector(
              onTap: _pickLastPeriodDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 14,
                        color: Colors.grey[500]),
                    const SizedBox(width: 6),
                    Text(
                      _lastPeriodStart != null
                          ? _formatDate(_lastPeriodStart!)
                          : 'Pick a date',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700]),
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
          child: const Text('Save changes',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────
  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
    child: Text(title.toUpperCase(),
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey[500],
            letterSpacing: 0.8)),
  );

  Widget _fieldRow(String label, Widget value) => Container(
    padding: const EdgeInsets.symmetric(
        horizontal: 20, vertical: 14),
    decoration: BoxDecoration(
      border: Border(
          bottom: BorderSide(
              color: Colors.grey[100]!, width: 0.5)),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 140,
          child: Text(label,
              style: TextStyle(
                  fontSize: 13, color: Colors.grey[500])),
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
                  fontSize: 12, color: Colors.grey[500])),
        ],
      );

  Widget _counterBtn(IconData icon, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Icon(icon, size: 14, color: Colors.grey[600]),
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
            hintStyle: TextStyle(color: Colors.grey[400]),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
              BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
              BorderSide(color: Colors.grey[300]!),
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