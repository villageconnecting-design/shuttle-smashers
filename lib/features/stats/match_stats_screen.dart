import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/match_model.dart';

/// Match statistics and analytics screen
class MatchStatsScreen extends StatefulWidget {
  const MatchStatsScreen({super.key});

  @override
  State<MatchStatsScreen> createState() => _MatchStatsScreenState();
}

class _MatchStatsScreenState extends State<MatchStatsScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Statistics',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accentGreen,
          labelColor: AppColors.accentGreen,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Matches'),
            Tab(text: 'Trends'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.darkGradient,
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(),
            _buildMatchesTab(),
            _buildTrendsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      return const Center(
        child: Text(
          'Please login to view stats',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return StreamBuilder<Map<String, dynamic>?>(
      stream: _authService.getUserProfileStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.accentGreen),
          );
        }

        final userData = snapshot.data;
        if (userData == null) {
          return const Center(
            child: Text(
              'No profile data',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        final wins = userData['wins'] ?? 0;
        final losses = userData['losses'] ?? 0;
        final matchesPlayed = userData['matchesPlayed'] ?? 0;
        final points = userData['points'] ?? 0;
        final winRate = matchesPlayed > 0 ? (wins / matchesPlayed * 100) : 0.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overall performance card
              _buildPerformanceCard(
                wins: wins,
                losses: losses,
                matchesPlayed: matchesPlayed,
                points: points,
                winRate: winRate,
              ),
              const SizedBox(height: 24),

              // Quick stats
              const Text(
                'Quick Stats',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _buildQuickStats(wins, losses, matchesPlayed, points),
              const SizedBox(height: 24),

              // Win/Loss breakdown
              const Text(
                'Win/Loss Breakdown',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _buildWinLossBreakdown(wins, losses),
              const SizedBox(height: 24),

              // Recent form
              const Text(
                'Recent Form',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _buildRecentForm(userId),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPerformanceCard({
    required int wins,
    required int losses,
    required int matchesPlayed,
    required int points,
    required double winRate,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Overall Performance',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppConstants.radiusRound),
                ),
                child: Text(
                  '$points PTS',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn('Win Rate', '${winRate.toStringAsFixed(1)}%'),
              Container(
                height: 50,
                width: 1,
                color: Colors.white24,
              ),
              _buildStatColumn('Matches', matchesPlayed.toString()),
              Container(
                height: 50,
                width: 1,
                color: Colors.white24,
              ),
              _buildStatColumn('W - L', '$wins - $losses'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats(int wins, int losses, int matchesPlayed, int points) {
    return Row(
      children: [
        Expanded(
          child: _buildStatTile(
            icon: Icons.emoji_events,
            color: AppColors.warning,
            label: 'Best Streak',
            value: '${wins > 3 ? 3 : wins}', // Placeholder
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatTile(
            icon: Icons.sports_tennis,
            color: AppColors.accentGreen,
            label: 'Avg Points',
            value: matchesPlayed > 0
                ? (points / matchesPlayed).toStringAsFixed(1)
                : '0',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatTile(
            icon: Icons.trending_up,
            color: AppColors.info,
            label: 'Form',
            value: wins >= losses ? 'Good' : 'Improve',
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWinLossBreakdown(int wins, int losses) {
    final total = wins + losses;
    final winPercent = total > 0 ? (wins / total) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBreakdownItem('Wins', wins, AppColors.accentGreen),
              _buildBreakdownItem('Losses', losses, AppColors.error),
            ],
          ),
          const SizedBox(height: 20),
          // Visual bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  Flexible(
                    flex: (winPercent * 100).round(),
                    child: Container(color: AppColors.accentGreen),
                  ),
                  Flexible(
                    flex: ((1 - winPercent) * 100).round(),
                    child: Container(color: AppColors.error),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(String label, int value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: $value',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentForm(String userId) {
    return StreamBuilder<List<MatchModel>>(
      stream: _firestoreService.getUserMatchHistory(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.accentGreen),
          );
        }

        final matches = snapshot.data ?? [];
        final recentMatches = matches.take(5).toList();

        if (recentMatches.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
            ),
            child: const Center(
              child: Text(
                'No recent matches',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: recentMatches.map((match) {
              final isTeamA = match.teamAIds.contains(userId);
              final isWin = (isTeamA && match.winner == 'teamA') ||
                  (!isTeamA && match.winner == 'teamB');

              return Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isWin
                      ? AppColors.accentGreen.withValues(alpha: 0.2)
                      : AppColors.error.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isWin ? AppColors.accentGreen : AppColors.error,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    isWin ? 'W' : 'L',
                    style: TextStyle(
                      color: isWin ? AppColors.accentGreen : AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildMatchesTab() {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      return const Center(
        child: Text(
          'Please login to view matches',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return StreamBuilder<List<MatchModel>>(
      stream: _firestoreService.getUserMatchHistory(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.accentGreen),
          );
        }

        final matches = snapshot.data ?? [];

        if (matches.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.sports_tennis_outlined,
                  size: 64,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No matches yet',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Start playing to see your match history',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: matches.length,
          itemBuilder: (context, index) {
            final match = matches[index];
            return _buildMatchDetailCard(match, userId);
          },
        );
      },
    );
  }

  Widget _buildMatchDetailCard(MatchModel match, String userId) {
    final isTeamA = match.teamAIds.contains(userId);
    final isWin = (isTeamA && match.winner == 'teamA') ||
        (!isTeamA && match.winner == 'teamB');
    final opponent = isTeamA ? match.teamBNames : match.teamANames;
    final yourScore = isTeamA ? match.teamASetsWon : match.teamBSetsWon;
    final opponentScore = isTeamA ? match.teamBSetsWon : match.teamASetsWon;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(
          color: isWin
              ? AppColors.accentGreen.withValues(alpha: 0.3)
              : AppColors.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isWin
                      ? AppColors.accentGreen.withValues(alpha: 0.2)
                      : AppColors.error.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                ),
                child: Text(
                  isWin ? 'VICTORY' : 'DEFEAT',
                  style: TextStyle(
                    color: isWin ? AppColors.accentGreen : AppColors.error,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Text(
                _formatDate(match.completedAt ?? match.createdAt),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'vs',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      opponent,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$yourScore - $opponentScore',
                    style: TextStyle(
                      color: isWin ? AppColors.accentGreen : AppColors.error,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    match.matchType,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (match.scores.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.surfaceColor),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: match.scores.asMap().entries.map((entry) {
                final setIndex = entry.key;
                final setScore = entry.value;
                final yourSetScore = isTeamA ? setScore.teamAScore : setScore.teamBScore;
                final oppSetScore = isTeamA ? setScore.teamBScore : setScore.teamAScore;
                final setWon = yourSetScore > oppSetScore;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: setWon
                        ? AppColors.accentGreen.withValues(alpha: 0.1)
                        : AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Set ${setIndex + 1}: $yourSetScore-$oppSetScore',
                    style: TextStyle(
                      color: setWon ? AppColors.accentGreen : AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrendsTab() {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      return const Center(
        child: Text(
          'Please login to view trends',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return StreamBuilder<List<MatchModel>>(
      stream: _firestoreService.getUserMatchHistory(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.accentGreen),
          );
        }

        final matches = snapshot.data ?? [];

        if (matches.length < 2) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.trending_up,
                  size: 64,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Not enough data',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Play more matches to see trends',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        // Calculate trends
        final matchesByType = <String, int>{};
        final winsByType = <String, int>{};
        int currentStreak = 0;
        bool isWinStreak = true;
        int maxWinStreak = 0;
        int maxLoseStreak = 0;

        for (final match in matches) {
          final type = match.matchType;
          matchesByType[type] = (matchesByType[type] ?? 0) + 1;

          final isTeamA = match.teamAIds.contains(userId);
          final isWin = (isTeamA && match.winner == 'teamA') ||
              (!isTeamA && match.winner == 'teamB');

          if (isWin) {
            winsByType[type] = (winsByType[type] ?? 0) + 1;
          }

          // Calculate streak
          if (matches.indexOf(match) == 0) {
            currentStreak = 1;
            isWinStreak = isWin;
          } else {
            if (isWin == isWinStreak) {
              currentStreak++;
            } else {
              if (isWinStreak) {
                maxWinStreak = currentStreak > maxWinStreak ? currentStreak : maxWinStreak;
              } else {
                maxLoseStreak = currentStreak > maxLoseStreak ? currentStreak : maxLoseStreak;
              }
              currentStreak = 1;
              isWinStreak = isWin;
            }
          }
        }

        // Final streak
        if (isWinStreak) {
          maxWinStreak = currentStreak > maxWinStreak ? currentStreak : maxWinStreak;
        } else {
          maxLoseStreak = currentStreak > maxLoseStreak ? currentStreak : maxLoseStreak;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Streaks
              const Text(
                'Streaks',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStreakCard(
                      'Best Win Streak',
                      maxWinStreak,
                      AppColors.accentGreen,
                      Icons.local_fire_department,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStreakCard(
                      'Worst Lose Streak',
                      maxLoseStreak,
                      AppColors.error,
                      Icons.trending_down,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Match type breakdown
              const Text(
                'Match Type Performance',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...matchesByType.entries.map((entry) {
                final type = entry.key;
                final total = entry.value;
                final wins = winsByType[type] ?? 0;
                final winRate = total > 0 ? (wins / total * 100) : 0.0;

                return _buildMatchTypeCard(type, total, wins, winRate);
              }),
              const SizedBox(height: 24),

              // Monthly activity (simplified)
              const Text(
                'Activity Summary',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                ),
                child: Column(
                  children: [
                    _buildActivityRow('Total Matches', matches.length.toString()),
                    const SizedBox(height: 12),
                    _buildActivityRow(
                      'This Month',
                      matches
                          .where((m) =>
                              m.createdAt.month == DateTime.now().month &&
                              m.createdAt.year == DateTime.now().year)
                          .length
                          .toString(),
                    ),
                    const SizedBox(height: 12),
                    _buildActivityRow(
                      'Most Played',
                      matchesByType.entries
                          .reduce((a, b) => a.value > b.value ? a : b)
                          .key,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStreakCard(String label, int value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value.toString(),
            style: TextStyle(
              color: color,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMatchTypeCard(String type, int total, int wins, double winRate) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                type,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: winRate >= 50
                      ? AppColors.accentGreen.withValues(alpha: 0.2)
                      : AppColors.error.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                ),
                child: Text(
                  '${winRate.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: winRate >= 50 ? AppColors.accentGreen : AppColors.error,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: winRate / 100,
              minHeight: 8,
              backgroundColor: AppColors.surfaceColor,
              valueColor: AlwaysStoppedAnimation<Color>(
                winRate >= 50 ? AppColors.accentGreen : AppColors.error,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$wins wins / $total matches',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
