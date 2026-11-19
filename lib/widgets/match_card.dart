import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';

/// Match card widget for displaying live and upcoming matches
class MatchCard extends StatelessWidget {
  final String teamA;
  final String teamB;
  final int? scoreA;
  final int? scoreB;
  final String? time;
  final String? date;
  final String matchType;
  final bool isLive;
  final String? venue;
  final int? currentSet;
  final VoidCallback? onTap;

  const MatchCard({
    super.key,
    required this.teamA,
    required this.teamB,
    this.scoreA,
    this.scoreB,
    this.time,
    this.date,
    required this.matchType,
    this.isLive = false,
    this.venue,
    this.currentSet,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Match type and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                    ),
                    child: Text(
                      matchType,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (isLive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (!isLive && currentSet != null)
                    Text(
                      'Set $currentSet',
                      style: const TextStyle(
                        color: AppColors.accentGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // Teams and scores
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _buildTeamAvatar(teamA),
                        const SizedBox(height: 8),
                        Text(
                          teamA,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Score or VS
                  if (isLive && scoreA != null && scoreB != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceColor,
                        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$scoreA',
                            style: TextStyle(
                              color: scoreA! > scoreB! ? AppColors.accentGreen : AppColors.textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '-',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          Text(
                            '$scoreB',
                            style: TextStyle(
                              color: scoreB! > scoreA! ? AppColors.accentGreen : AppColors.textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const Text(
                      'VS',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  Expanded(
                    child: Column(
                      children: [
                        _buildTeamAvatar(teamB),
                        const SizedBox(height: 8),
                        Text(
                          teamB,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Time and venue for upcoming matches
              if (!isLive && time != null) ...[
                const SizedBox(height: 16),
                const Divider(color: AppColors.surfaceColor, height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time, color: AppColors.textMuted, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '$time, $date',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    if (venue != null)
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: AppColors.textMuted, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            venue!,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamAvatar(String name) {
    final initials = name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join();
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
