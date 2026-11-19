import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';

/// Leaderboard tile widget for player rankings
class LeaderboardTile extends StatelessWidget {
  final int rank;
  final String name;
  final String? avatar;
  final int wins;
  final int matches;
  final int points;
  final VoidCallback? onTap;

  const LeaderboardTile({
    super.key,
    required this.rank,
    required this.name,
    this.avatar,
    required this.wins,
    required this.matches,
    required this.points,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isTopThree = rank <= 3;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isTopThree ? _getTopThreeGradient() : AppColors.cardGradient,
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          border: isTopThree
              ? Border.all(color: _getRankColor(), width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: isTopThree
                  ? _getRankColor().withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Rank badge
            _buildRankBadge(),
            const SizedBox(width: 16),
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  avatar ?? name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Player info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildStatChip(Icons.emoji_events, '$wins W'),
                      const SizedBox(width: 8),
                      _buildStatChip(Icons.sports_tennis, '$matches M'),
                    ],
                  ),
                ],
              ),
            ),
            // Points
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  points.toString(),
                  style: TextStyle(
                    color: isTopThree ? _getRankColor() : AppColors.accentGreen,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'pts',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankBadge() {
    if (rank <= 3) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          gradient: _getTopThreeGradient(),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _getRankColor().withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            rank == 1 ? Icons.looks_one : (rank == 2 ? Icons.looks_two : Icons.looks_3),
            color: Colors.white,
            size: 20,
          ),
        ),
      );
    }
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          rank.toString(),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.textMuted, size: 12),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Color _getRankColor() {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return AppColors.accentGreen;
    }
  }

  LinearGradient _getTopThreeGradient() {
    final color = _getRankColor();
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        color.withValues(alpha: 0.2),
        AppColors.cardBackground,
      ],
    );
  }
}
