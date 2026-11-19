import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../models/match_model.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/match_card.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../match/create_match_screen.dart';
import '../match/live_score_screen.dart';
import '../match/quick_score_screen.dart';
import '../tournament/tournament_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../profile/profile_screen.dart';
import '../stats/match_stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const _HomeContent(),
    const TournamentScreen(),
    const LeaderboardScreen(),
    const QuickScoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateMatchScreen(),
                  ),
                );
              },
              backgroundColor: AppColors.accentGreen,
              icon: const Icon(Icons.add, color: AppColors.darkBackground),
              label: const Text(
                'Create Match',
                style: TextStyle(
                  color: AppColors.darkBackground,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

class _HomeContent extends StatefulWidget {
  const _HomeContent();

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  final _firestoreService = FirestoreService();
  final _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.darkGradient,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with greeting and profile icon
              _buildHeader(),
              // Live matches section
              const _SectionHeader(
                title: 'Live Matches',
                icon: Icons.circle,
                iconColor: AppColors.error,
              ),
              _buildLiveMatches(),
              const SizedBox(height: 24),
              // Upcoming matches section
              const _SectionHeader(
                title: 'Recent Matches',
                icon: Icons.history,
                iconColor: AppColors.accentGreen,
              ),
              _buildRecentMatches(),
              const SizedBox(height: 24),
              // Quick stats
              _buildUserStats(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: _authService.getUserProfileStream(),
      builder: (context, snapshot) {
        final userData = snapshot.data;
        final userName = userData?['name'] ?? 'Player';
        final avatar = userData?['avatar'] ?? 'P';

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello $userName',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Ready to smash today?',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              // Profile icon - navigates to profile screen
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      avatar,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLiveMatches() {
    return StreamBuilder<List<MatchModel>>(
      stream: _firestoreService.getLiveMatches(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.accentGreen),
            ),
          );
        }

        final matches = snapshot.data ?? [];

        if (matches.isEmpty) {
          return _buildEmptyState(
            'No Live Matches',
            'Start a new match to see it here!',
            Icons.sports_tennis,
          );
        }

        return SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              return MatchCard(
                teamA: match.teamANames,
                teamB: match.teamBNames,
                scoreA: match.currentSetScore.teamAScore,
                scoreB: match.currentSetScore.teamBScore,
                matchType: match.matchType,
                isLive: true,
                currentSet: match.currentSet,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LiveScoreScreen(
                        matchId: match.id,
                        teamA: match.teamANames,
                        teamB: match.teamBNames,
                        initialScoreA: match.currentSetScore.teamAScore,
                        initialScoreB: match.currentSetScore.teamBScore,
                        matchType: match.matchType,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRecentMatches() {
    return StreamBuilder<List<MatchModel>>(
      stream: _firestoreService.getRecentMatches(limit: 10),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.accentGreen),
            ),
          );
        }

        final allMatches = snapshot.data ?? [];
        // Filter out live matches - show only completed ones
        final matches = allMatches
            .where((m) => m.status == MatchStatus.completed)
            .toList();

        if (matches.isEmpty) {
          return _buildEmptyState(
            'No Recent Matches',
            'Complete a match to see history!',
            Icons.history,
          );
        }

        return SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              final isTeamAWinner = match.winner == 'teamA';
              return MatchCard(
                teamA: match.teamANames,
                teamB: match.teamBNames,
                scoreA: match.teamASetsWon,
                scoreB: match.teamBSetsWon,
                matchType: match.matchType,
                isLive: false,
                date: _formatDate(match.completedAt ?? match.createdAt),
                time: isTeamAWinner ? '${match.teamANames} won' : '${match.teamBNames} won',
                venue: '${match.scores.length} sets',
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildUserStats() {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: _authService.getUserProfileStream(),
      builder: (context, snapshot) {
        final userData = snapshot.data;
        final wins = userData?['wins'] ?? 0;
        final matchesPlayed = userData?['matchesPlayed'] ?? 0;
        final points = userData?['points'] ?? 0;
        final winRate = matchesPlayed > 0
            ? ((wins / matchesPlayed) * 100).toStringAsFixed(0)
            : '0';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MatchStatsScreen(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.cardGradient,
                borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Your Stats',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right,
                            color: AppColors.textMuted,
                            size: 20,
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppColors.accentGradient,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$points pts',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('$matchesPlayed', 'Matches', Icons.sports_tennis),
                      _buildStatItem('$wins', 'Wins', Icons.emoji_events),
                      _buildStatItem('$winRate%', 'Win Rate', Icons.trending_up),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Container(
      height: 160,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        border: Border.all(
          color: AppColors.surfaceColor.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 40,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.accentGreen, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 12),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {},
            child: const Text('See All'),
          ),
        ],
      ),
    );
  }
}
