import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? color;
  final List<BoxShadow>? shadows;
  final VoidCallback? onTap;
  final Gradient? gradient;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 16,
    this.color,
    this.shadows,
    this.onTap,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final bgColor = color ??
        (isDark ? const Color(0xFF2A2A2A) : Colors.white);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          color: gradient == null ? bgColor : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: shadows ?? AppColors.getShadow(context),
        ),
        child: child,
      ),
    );
  }
}
