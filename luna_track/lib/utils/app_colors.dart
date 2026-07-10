import 'package:flutter/material.dart';

class AppColors {
  static const pink   = Color(0xFFE05D6F);
  static const teal   = Color(0xFF1D9E75);
  static const amber  = Color(0xFFF5A623);
  static const blue   = Color(0xFF5B8CDE);
  static const gray   = Color(0xFFB4B2A9);

  // ── Phase gradients ──────────────────────────────────────────
  static const phaseGradients = {
    'Menstrual': [
      Color(0xFFFFF5F6),   // very light pink top
      Color(0xFFFFF0F2),   // slightly deeper pink bottom
    ],
    'Follicular': [
      Color(0xFFFFFBF5),   // very light amber top
      Color(0xFFFFF6EC),   // warm peach bottom
    ],
    'Ovulation': [
      Color(0xFFF5FFFB),   // very light teal top
      Color(0xFFEEFCF6),   // fresh green bottom
    ],
    'Luteal': [
      Color(0xFFF5F8FF),   // very light blue top
      Color(0xFFEEF3FF),   // calm indigo bottom
    ],
  };

  // Dark mode phase gradients (darker, muted)
  static const phaseGradientsDark = {
    'Menstrual': [
      Color(0xFF2A1A1D),
      Color(0xFF1F1215),
    ],
    'Follicular': [
      Color(0xFF2A221A),
      Color(0xFF1F1A12),
    ],
    'Ovulation': [
      Color(0xFF1A2A22),
      Color(0xFF121F1A),
    ],
    'Luteal': [
      Color(0xFF1A1E2A),
      Color(0xFF12151F),
    ],
  };

  static List<Color> getPhaseGradient(String phaseName, bool isDark) {
    final map = isDark ? phaseGradientsDark : phaseGradients;
    return map[phaseName] ?? (isDark
        ? [const Color(0xFF1A1A1A), const Color(0xFF121212)]
        : [Colors.white, const Color(0xFFFAFAFA)]);
  }

  // Dynamic colors — use these in widgets
  static Color background(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;

  static Color surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF2A2A2A)
          : Colors.grey[50]!;

  static Color cardBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF3A3A3A)
          : Colors.grey[200]!;

  static Color textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : Colors.grey[800]!;

  static Color textSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[400]!
          : Colors.grey[600]!;

  static Color textHint(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[600]!
          : Colors.grey[400]!;

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  // ── Card shadows ─────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.03),
      blurRadius: 4,
      offset: const Offset(0, 1),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get cardShadowDark => [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 12,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get subtleShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> coloredShadow(Color color) => [
    BoxShadow(
      color: color.withOpacity(0.25),
      blurRadius: 12,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> getShadow(BuildContext context) =>
      isDark(context) ? cardShadowDark : cardShadow;
}
