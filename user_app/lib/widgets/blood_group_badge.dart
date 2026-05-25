import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class BloodGroupBadge extends StatelessWidget {
  final String bloodGroup;
  final bool isSmall;

  const BloodGroupBadge({
    super.key,
    required this.bloodGroup,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 7 : 11,
        vertical: isSmall ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkSurface
            : Colors.white,
        borderRadius: BorderRadius.circular(isSmall ? 6 : 9),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.55),
          width: 1.5,
        ),
      ),
      child: Text(
        bloodGroup,
        style: TextStyle(
          color: AppTheme.primary,
          fontSize: isSmall ? 10 : 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
