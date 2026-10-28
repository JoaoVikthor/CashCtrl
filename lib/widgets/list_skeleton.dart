import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

class ListSkeleton extends StatefulWidget {
  final int itemCount;
  final double itemHeight;

  const ListSkeleton({
    super.key,
    this.itemCount = 4,
    this.itemHeight = 76,
  });

  @override
  State<ListSkeleton> createState() => _ListSkeletonState();
}

class _ListSkeletonState extends State<ListSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _opacity = Tween<double>(begin: 0.35, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: List.generate(widget.itemCount, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.m),
            child: AnimatedBuilder(
              animation: _opacity,
              builder: (context, child) {
                return Container(
                  height: widget.itemHeight,
                  decoration: BoxDecoration(
                    color: AppColors.card.withValues(alpha: _opacity.value),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }
}
