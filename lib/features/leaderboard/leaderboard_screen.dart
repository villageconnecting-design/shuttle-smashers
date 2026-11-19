import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../services/firestore_service.dart';
import '../../models/player_model.dart';
import '../../widgets/leaderboard_tile.dart';

/// Leaderboard screen showing player rankings from Firebase
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final _firestoreService = FirestoreService();
  String _sortBy = 'points';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.darkGradient,
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Leaderboard',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Leaderboard content
            Expanded(
              child: StreamBuilder<List<PlayerModel>>(
                stream: _firestoreService.getLeaderboard(limit: 50),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accentGreen,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading leaderboard',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final players = snapshot.data ?? [];

                  if (players.isEmpty) {
                    return _buildEmptyState();
                  }

                  // Sort players based on selected criteria
                  final sortedPlayers = _sortPlayers(players);
                  final topThreePlayers = sortedPlayers.take(3).toList();
                  final otherPlayers = sortedPlayers.skip(3).toList();

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        // Top 3 podium
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: AppColors.cardGradient,
                            borderRadius: BorderRadius.circular(AppConstants.radiusXLarge),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Top Players',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // 2nd place
                                  if (topThreePlayers.length > 1)
                                    _buildPodiumItem(
                                      topThreePlayers[1],
                                      2,
                                      80,
                                      const Color(0xFFC0C0C0),
                                    ),
                                  const SizedBox(width: 8),
                                  // 1st place
                                  if (topThreePlayers.isNotEmpty)
                                    _buildPodiumItem(
                                      topThreePlayers[0],
                                      1,
                                      100,
                                      const Color(0xFFFFD700),
                                    ),
                                  const SizedBox(width: 8),
                                  // 3rd place
                                  if (topThreePlayers.length > 2)
                                    _buildPodiumItem(
                                      topThreePlayers[2],
                                      3,
                                      60,
                                      const Color(0xFFCD7F32),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Stats filter
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              _buildFilterChip('Points', _sortBy == 'points', () {
                                setState(() => _sortBy = 'points');
                              }),
                              const SizedBox(width: 8),
                              _buildFilterChip('Wins', _sortBy == 'wins', () {
                                setState(() => _sortBy = 'wins');
                              }),
                              const SizedBox(width: 8),
                              _buildFilterChip('Win Rate', _sortBy == 'winRate', () {
                                setState(() => _sortBy = 'winRate');
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Rankings list
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: otherPlayers.length,
                          itemBuilder: (context, index) {
                            final player = otherPlayers[index];
                            return LeaderboardTile(
                              rank: index + 4,
                              name: player.name,
                              avatar: player.avatar,
                              wins: player.wins,
                              matches: player.matchesPlayed,
                              points: player.points,
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PlayerModel> _sortPlayers(List<PlayerModel> players) {
    final sorted = List<PlayerModel>.from(players);
    switch (_sortBy) {
      case 'wins':
        sorted.sort((a, b) => b.wins.compareTo(a.wins));
        break;
      case 'winRate':
        sorted.sort((a, b) {
          final aRate = a.matchesPlayed > 0 ? a.wins / a.matchesPlayed : 0;
          final bRate = b.matchesPlayed > 0 ? b.wins / b.matchesPlayed : 0;
          return bRate.compareTo(aRate);
        });
        break;
      default:
        sorted.sort((a, b) => b.points.compareTo(a.points));
    }
    return sorted;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.leaderboard_outlined,
            size: 64,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          const Text(
            'No players yet',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start playing matches to see the leaderboard',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(
    PlayerModel player,
    int rank,
    double height,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Crown for 1st place
        if (rank == 1)
          Icon(
            Icons.workspace_premium,
            color: color,
            size: 32,
          ),
        const SizedBox(height: 8),
        // Avatar
        Container(
          width: rank == 1 ? 72 : 56,
          height: rank == 1 ? 72 : 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withValues(alpha: 0.7)],
            ),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 3),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Text(
              player.avatar,
              style: TextStyle(
                color: Colors.white,
                fontSize: rank == 1 ? 20 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Name
        SizedBox(
          width: 80,
          child: Text(
            player.name.split(' ')[0],
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 4),
        // Points
        Text(
          '${player.points} pts',
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        // Podium base
        Container(
          width: 70,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withValues(alpha: 0.6),
                color.withValues(alpha: 0.3),
              ],
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(8),
            ),
          ),
          child: Center(
            child: Text(
              rank.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.accentGradient : null,
          color: isSelected ? null : AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(AppConstants.radiusRound),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.darkBackground : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
