import 'package:flutter/material.dart';

class SaveSuccessOverlay extends StatefulWidget {
  final VoidCallback onComplete;

  const SaveSuccessOverlay({super.key, required this.onComplete});

  @override
  State<SaveSuccessOverlay> createState() => _SaveSuccessOverlayState();
}

class _SaveSuccessOverlayState extends State<SaveSuccessOverlay>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;
  late Animation<double> _checkScale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scale = TweenSequence([
      TweenSequenceItem(
          tween: Tween<double>(begin: 0.0, end: 1.1), weight: 40),
      TweenSequenceItem(
          tween: Tween<double>(begin: 1.1, end: 1.0), weight: 20),
      TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: 1.0), weight: 20),
      TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(CurvedAnimation(
        parent: _controller, curve: Curves.easeInOut));

    _opacity = TweenSequence([
      TweenSequenceItem(
          tween: Tween<double>(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_controller);

    _checkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.7, curve: Curves.elasticOut),
      ),
    );

    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Opacity(
        opacity: _opacity.value,
        child: Transform.scale(
          scale: _scale.value,
          child: Container(
            width: 100, height: 100,
            decoration: const BoxDecoration(
              color: Color(0xFF1D9E75),
              shape: BoxShape.circle,
            ),
            child: Transform.scale(
              scale: _checkScale.value,
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
