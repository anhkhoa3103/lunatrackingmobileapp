import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_colors.dart';

class AnimatedFlowButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color selectedColor;
  final VoidCallback onTap;

  const AnimatedFlowButton({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  State<AnimatedFlowButton> createState() => _AnimatedFlowButtonState();
}

class _AnimatedFlowButtonState extends State<AnimatedFlowButton>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scale = TweenSequence([
      TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: 0.9), weight: 50),
      TweenSequenceItem(
          tween: Tween<double>(begin: 0.9, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
        parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _controller.forward(from: 0);
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(
            scale: _scale.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.selectedColor
                : AppColors.isDark(context)
                    ? const Color(0xFF2A2A2A)
                    : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: widget.isSelected
                ? [BoxShadow(
                    color: widget.selectedColor.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )]
                : AppColors.subtleShadow,
          ),
          child: Column(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  widget.icon,
                  key: ValueKey(widget.isSelected),
                  size: 18,
                  color: widget.isSelected
                      ? Colors.white
                      : AppColors.textHint(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: widget.isSelected
                      ? Colors.white
                      : AppColors.textSecondary(context),
                  fontWeight: widget.isSelected
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
