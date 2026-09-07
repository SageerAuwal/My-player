import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SpatialCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool hasGlow;
  final Color? borderColor;

  const SpatialCard({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.all(12.0),
    this.hasGlow = false,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? (hasGlow ? AppColors.borderGlow : AppColors.borderLight),
          width: hasGlow ? 1.5 : 1.0,
        ),
        boxShadow: hasGlow
            ? const [
                BoxShadow(
                  color: AppColors.accentGlow,
                  blurRadius: 20,
                  spreadRadius: -2,
                  offset: Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onTap,
          splashColor: AppColors.primary.withOpacity(0.12),
          highlightColor: AppColors.primary.withOpacity(0.06),
          child: Padding(
            padding: padding ?? EdgeInsets.zero,
            child: child,
          ),
        ),
      ),
    );
  }
}
