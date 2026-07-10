import 'package:flutter/material.dart';

// ── Base shimmer widget ──────────────────────────────────────
class _Shimmer extends StatefulWidget {
  final Widget child;
  const _Shimmer({required this.child});
  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    _anim = Tween<double>(begin: -1, end: 2).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF2A2A2A) : Colors.grey[200]!;
    final hi   = isDark ? const Color(0xFF3A3A3A) : Colors.grey[50]!;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          colors: [base, hi, base],
          stops: [
            (_anim.value - 1).clamp(0.0, 1.0),
            _anim.value.clamp(0.0, 1.0),
            (_anim.value + 1).clamp(0.0, 1.0),
          ],
        ).createShader(bounds),
        child: child,
      ),
      child: widget.child,
    );
  }
}

// ── Skeleton box ─────────────────────────────────────────────
class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _Shimmer(
      child: Container(
        width: width, height: height,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[200],
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

// ── Home screen skeleton ─────────────────────────────────────
class HomeScreenSkeleton extends StatelessWidget {
  const HomeScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          Row(children: [
            const Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 180, height: 22, borderRadius: 6),
                  SizedBox(height: 6),
                  SkeletonBox(width: 120, height: 14, borderRadius: 6),
                ]),
            const Spacer(),
            const SkeletonBox(width: 40, height: 40,
                borderRadius: 20),
          ]),
          const SizedBox(height: 24),

          // Cycle ring
          const Center(
            child: SkeletonBox(width: 280, height: 280,
                borderRadius: 140),
          ),
          const SizedBox(height: 20),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: SkeletonBox(width: 60, height: 12,
                  borderRadius: 6),
            )),
          ),
          const SizedBox(height: 20),

          // Phase card
          const SkeletonBox(
              width: double.infinity, height: 100,
              borderRadius: 16),
          const SizedBox(height: 12),

          // Stats row
          Row(children: List.generate(3, (i) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
              child: const SkeletonBox(
                  width: double.infinity, height: 72,
                  borderRadius: 12),
            ),
          ))),
          const SizedBox(height: 16),

          // Today card
          const SkeletonBox(
              width: double.infinity, height: 72,
              borderRadius: 16),
        ],
      ),
    );
  }
}

// ── Insights screen skeleton ─────────────────────────────────
class InsightsScreenSkeleton extends StatelessWidget {
  const InsightsScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Stat cards
          Row(children: List.generate(3, (i) => Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: i == 1 ? 4 : 0),
              child: const SkeletonBox(
                  width: double.infinity, height: 80,
                  borderRadius: 12),
            ),
          ))),
          const SizedBox(height: 24),

          // Section title
          const Align(alignment: Alignment.centerLeft,
              child: SkeletonBox(width: 140, height: 12,
                  borderRadius: 6)),
          const SizedBox(height: 10),

          // Chart
          const SkeletonBox(width: double.infinity, height: 160,
              borderRadius: 12),
          const SizedBox(height: 24),

          // Symptom bars
          const Align(alignment: Alignment.centerLeft,
              child: SkeletonBox(width: 120, height: 12,
                  borderRadius: 6)),
          const SizedBox(height: 10),
          ...List.generate(4, (i) => const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Row(children: [
              SkeletonBox(width: 70, height: 18, borderRadius: 4),
              SizedBox(width: 8),
              Expanded(child: SkeletonBox(
                  width: double.infinity, height: 18,
                  borderRadius: 4)),
              SizedBox(width: 8),
              SkeletonBox(width: 20, height: 18, borderRadius: 4),
            ]),
          )),
          const SizedBox(height: 24),

          // Mood grid
          const Align(alignment: Alignment.centerLeft,
              child: SkeletonBox(width: 130, height: 12,
                  borderRadius: 6)),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 3, shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8, mainAxisSpacing: 8,
            childAspectRatio: 1.4,
            children: List.generate(6, (_) =>
                const SkeletonBox(
                    width: double.infinity, height: double.infinity,
                    borderRadius: 10)),
          ),
        ],
      ),
    );
  }
}

// ── Calendar skeleton ────────────────────────────────────────
class CalendarScreenSkeleton extends StatelessWidget {
  const CalendarScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Month nav
        const Padding(
          padding: EdgeInsets.symmetric(
              horizontal: 20, vertical: 8),
          child: Row(children: [
            SkeletonBox(width: 32, height: 32,
                borderRadius: 16),
            Spacer(),
            SkeletonBox(width: 140, height: 18,
                borderRadius: 6),
            Spacer(),
            SkeletonBox(width: 32, height: 32,
                borderRadius: 16),
          ]),
        ),

        // Day labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: List.generate(7, (i) =>
              const Expanded(child: Center(
                child: SkeletonBox(width: 20, height: 12,
                    borderRadius: 4),
              )),
          )),
        ),
        const SizedBox(height: 4),

        // Calendar grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: GridView.count(
            crossAxisCount: 7, shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: List.generate(35, (_) => const Padding(
              padding: EdgeInsets.all(2),
              child: SkeletonBox(
                  width: double.infinity,
                  height: double.infinity,
                  borderRadius: 50),
            )),
          ),
        ),

        const SizedBox(height: 12),
        const Divider(height: 1),

        // Detail panel
        const Padding(
          padding: EdgeInsets.all(14),
          child: SkeletonBox(
              width: double.infinity, height: 120,
              borderRadius: 12),
        ),
      ],
    );
  }
}
