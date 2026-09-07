import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GlowingButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool isSecondary;

  const GlowingButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.borderRadius = 14.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = isSecondary
        ? null
        : AppColors.brandGradient;
    final bgColor = isSecondary ? AppColors.surfaceElevated : null;

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: isSecondary ? Border.all(color: AppColors.borderLight) : null,
        boxShadow: isSecondary
            ? null
            : const [
                BoxShadow(
                  color: AppColors.accentGlow,
                  blurRadius: 18,
                  spreadRadius: -2,
                  offset: Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onPressed,
          child: Padding(
            padding: padding,
            child: DefaultTextStyle(
              style: TextStyle(
                color: isSecondary ? AppColors.textPrimary : Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
