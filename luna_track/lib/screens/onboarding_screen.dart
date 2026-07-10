import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_theme.dart';
import '../widgets/onboarding_illustrations.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  int _cycleLength = 28;
  int _periodLength = 5;
  DateTime? _lastPeriodDate;
  bool _saving = false;

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _prevPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastPeriodDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
              primary: Color(0xFFE05D6F)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _lastPeriodDate = picked);
    }
  }

  Future<void> _finish() async {
    // Validate — must pick a date
    if (_lastPeriodDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              AppLocalizations.of(context)!.pleasePickDate),
          backgroundColor: const Color(0xFFE05D6F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      // 1. Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('cycle_length', _cycleLength);
      await prefs.setInt('period_length', _periodLength);
      await prefs.setString('last_period_start',
          _lastPeriodDate!.toIso8601String().split('T')[0]);
      await prefs.setBool('onboarding_done', true);

      // 2. Save last period start as a cycle entry to the API
      await ApiService.saveEntry({
        'date': _lastPeriodDate!.toIso8601String().split('T')[0],
        'flow': 'medium',
        'moods': [],
        'symptoms': [],
        'energy': '',
        'sleep': '',
        'notes': 'Kỳ kinh gần nhất (onboarding)',
      });
    } catch (e) {
      // Even if API fails, still proceed — data is saved locally
      debugPrint('Onboarding API save error: $e');
    }

    if (!mounted) return;

    // 3. Navigate to HomeScreen
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: Column(
          children: [
            // Back button (steps 2 and 3 only)
            SizedBox(
              height: 48,
              child: _currentPage > 0
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: _prevPage,
                        icon: Icon(Icons.arrow_back,
                            size: 20,
                            color: AppColors.textSecondary(context)),
                      ),
                    )
                  : null,
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) =>
                    setState(() => _currentPage = i),
                children: [
                  _buildWelcomeStep(),
                  _buildCycleInfoStep(),
                  _buildDateStep(),
                ],
              ),
            ),
            _buildDots(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Step 1: Welcome ──────────────────────────────────────────
  Widget _buildWelcomeStep() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          const Spacer(),
          const OnboardingIllustration(step: 0),
          const SizedBox(height: 24),
          Text(AppLocalizations.of(context)!.welcomeTitle,
              style: AppTheme.displayMedium,
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(AppLocalizations.of(context)!.welcomeSubtitle,
              style: AppTheme.bodyLarge.copyWith(
                  color: AppColors.textSecondary(context)),
              textAlign: TextAlign.center),
          const Spacer(),
          _primaryButton(
              AppLocalizations.of(context)!.getStarted, _nextPage),
        ],
      ),
    );
  }

  // ── Step 2: Cycle info ───────────────────────────────────────
  Widget _buildCycleInfoStep() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: OnboardingIllustration(step: 1)),
          const SizedBox(height: 24),
          Text(AppLocalizations.of(context)!.cycleInfo,
              style: AppTheme.displayMedium),
          const SizedBox(height: 32),
          _stepperRow(
            AppLocalizations.of(context)!.avgCycleLength,
            _cycleLength, 21, 45,
            (v) => setState(() => _cycleLength = v),
          ),
          const SizedBox(height: 20),
          _stepperRow(
            AppLocalizations.of(context)!.periodDuration,
            _periodLength, 2, 10,
            (v) => setState(() => _periodLength = v),
          ),
          const Spacer(),
          _primaryButton(
              AppLocalizations.of(context)!.continueBtn, _nextPage),
        ],
      ),
    );
  }

  // ── Step 3: Last period date ─────────────────────────────────
  Widget _buildDateStep() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: OnboardingIllustration(step: 2)),
          const SizedBox(height: 24),
          Text(AppLocalizations.of(context)!.lastPeriodTitle,
              style: AppTheme.displayMedium),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _pickDate,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE05D6F),
                side: const BorderSide(color: Color(0xFFE05D6F)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.calendar_today_outlined,
                  size: 18),
              label: const Text('Chọn ngày',
                  style: TextStyle(fontSize: 15,
                      fontWeight: FontWeight.w500)),
            ),
          ),
          const SizedBox(height: 16),
          if (_lastPeriodDate != null)
            Center(
              child: Text(_dateLabel(_lastPeriodDate!),
                  style: const TextStyle(fontSize: 15,
                      fontWeight: FontWeight.w500)),
            ),
          const Spacer(),
          ElevatedButton(
            onPressed: _saving ? null : _finish,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE05D6F),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: _saving
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Text(AppLocalizations.of(context)!.finish,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  String _dateLabel(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  // ── Progress dots ────────────────────────────────────────────
  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final active = i == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFFE05D6F)
                : AppColors.cardBorder(context),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  // ── Shared widgets ───────────────────────────────────────────
  Widget _primaryButton(String text, VoidCallback? onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE05D6F),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: Text(text,
            style: const TextStyle(fontSize: 15,
                fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _stepperRow(String label, int value, int min, int max,
      ValueChanged<int> onChanged) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: TextStyle(fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary(context))),
        ),
        _stepperButton(Icons.remove,
            value > min ? () => onChanged(value - 1) : null),
        SizedBox(
          width: 64,
          child: Text(
              '$value ${AppLocalizations.of(context)!.days}',
              style: const TextStyle(fontSize: 14,
                  fontWeight: FontWeight.w500),
              textAlign: TextAlign.center),
        ),
        _stepperButton(Icons.add,
            value < max ? () => onChanged(value + 1) : null),
      ],
    );
  }

  Widget _stepperButton(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
              color: AppColors.cardBorder(context)),
        ),
        child: Icon(icon, size: 16,
            color: onTap == null
                ? AppColors.textHint(context)
                : AppColors.textSecondary(context)),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
