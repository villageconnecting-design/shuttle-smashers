import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';

/// Player card widget for player selection
class PlayerCard extends StatelessWidget {
  final String name;
  final String? avatar;
  final int? wins;
  final int? matches;
  final bool isSelected;
  final VoidCallback? onTap;

  const PlayerCard({
    super.key,
    required this.name,
    this.avatar,
    this.wins,
    this.matches,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppConstants.animationFast,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.accentGradient : AppColors.cardGradient,
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          border: isSelected
              ? Border.all(color: AppColors.accentGreen, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.accentGreen.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [Colors.white, Color(0xFFE0E0E0)],
                          )
                        : AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      avatar ?? name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase(),
                      style: TextStyle(
                        color: isSelected ? AppColors.primaryBlue : Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (isSelected)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: AppColors.accentGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Name
            Text(
              name,
              style: TextStyle(
                color: isSelected ? AppColors.darkBackground : AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Stats
            if (wins != null && matches != null) ...[
              const SizedBox(height: 8),
              Text(
                '$wins W / $matches M',
                style: TextStyle(
                  color: isSelected
                      ? AppColors.darkBackground.withValues(alpha: 0.7)
                      : AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
