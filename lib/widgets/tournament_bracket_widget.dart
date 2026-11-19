import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';

/// Model for a bracket match
class BracketMatch {
  final String id;
  final String? player1;
  final String? player2;
  final int? score1;
  final int? score2;
  final String? winner;
  final int round;
  final int position;

  BracketMatch({
    required this.id,
    this.player1,
    this.player2,
    this.score1,
    this.score2,
    this.winner,
    required this.round,
    required this.position,
  });

  bool get isComplete => winner != null;
  bool get hasPlayers => player1 != null && player2 != null;
}

/// Tournament bracket visualization widget
class TournamentBracketWidget extends StatelessWidget {
  final List<String> participants;
  final Map<String, dynamic>? bracketData;
  final String tournamentStatus;
  final Function(BracketMatch)? onMatchTap;
  final Function()? onGenerateBracket;

  const TournamentBracketWidget({
    super.key,
    required this.participants,
    this.bracketData,
    required this.tournamentStatus,
    this.onMatchTap,
    this.onGenerateBracket,
  });

  @override
  Widget build(BuildContext context) {
    if (participants.length < 2) {
      return _buildEmptyState(
        icon: Icons.people_outline,
        title: 'Need More Players',
        subtitle: 'Add at least 2 participants to generate a bracket',
      );
    }

    if (bracketData == null || bracketData!.isEmpty) {
      return _buildGenerateBracketState();
    }

    return _buildBracketView();
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateBracketState() {
    final isUpcoming = tournamentStatus.toLowerCase() == 'upcoming';

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
      ),
      child: Column(
        children: [
          Icon(
            Icons.account_tree_outlined,
            size: 48,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            isUpcoming ? 'Ready to Generate Bracket' : 'No Bracket Generated',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${participants.length} participants registered',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          if (isUpcoming && onGenerateBracket != null) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onGenerateBracket,
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('Generate Bracket'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBracketView() {
    final matches = _parseBracketData();
    if (matches.isEmpty) {
      return _buildGenerateBracketState();
    }

    final rounds = _groupMatchesByRound(matches);
    final roundNames = _getRoundNames(rounds.length);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Round labels
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(rounds.length, (index) {
                  return Container(
                    width: 140,
                    margin: EdgeInsets.only(right: index < rounds.length - 1 ? 24 : 0),
                    child: Text(
                      roundNames[index],
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }),
              ),
            ),
          ),
          const Divider(color: AppColors.surfaceColor, height: 1),
          // Bracket matches
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List.generate(rounds.length, (roundIndex) {
                  final roundMatches = rounds[roundIndex] ?? [];
                  return _buildRoundColumn(roundMatches, roundIndex, rounds.length);
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundColumn(List<BracketMatch> matches, int roundIndex, int totalRounds) {
    // Calculate spacing based on round
    final spacingMultiplier = (roundIndex + 1).toDouble();

    return Container(
      width: 140,
      margin: EdgeInsets.only(right: roundIndex < totalRounds - 1 ? 24 : 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(matches.length, (index) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 8 * spacingMultiplier),
            child: _buildMatchCard(matches[index]),
          );
        }),
      ),
    );
  }

  Widget _buildMatchCard(BracketMatch match) {
    return GestureDetector(
      onTap: match.hasPlayers && onMatchTap != null
          ? () => onMatchTap!(match)
          : null,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          border: Border.all(
            color: match.isComplete
                ? AppColors.accentGreen.withValues(alpha: 0.5)
                : AppColors.surfaceColor,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPlayerRow(
              match.player1 ?? 'TBD',
              match.score1,
              match.winner == match.player1,
            ),
            const Divider(color: AppColors.cardBackground, height: 8),
            _buildPlayerRow(
              match.player2 ?? 'TBD',
              match.score2,
              match.winner == match.player2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerRow(String name, int? score, bool isWinner) {
    final isTBD = name == 'TBD';

    return Row(
      children: [
        if (isWinner)
          Container(
            width: 3,
            height: 20,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: AppColors.accentGreen,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        Expanded(
          child: Text(
            name,
            style: TextStyle(
              color: isTBD
                  ? AppColors.textMuted
                  : isWinner
                      ? AppColors.accentGreen
                      : AppColors.textPrimary,
              fontSize: 12,
              fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (score != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isWinner
                  ? AppColors.accentGreen.withValues(alpha: 0.2)
                  : AppColors.cardBackground,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              score.toString(),
              style: TextStyle(
                color: isWinner ? AppColors.accentGreen : AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  List<BracketMatch> _parseBracketData() {
    if (bracketData == null) return [];

    final matches = <BracketMatch>[];
    final matchesData = bracketData!['matches'] as List<dynamic>?;

    if (matchesData != null) {
      for (var i = 0; i < matchesData.length; i++) {
        final matchData = matchesData[i] as Map<String, dynamic>;
        matches.add(BracketMatch(
          id: matchData['id'] ?? 'match_$i',
          player1: matchData['player1'],
          player2: matchData['player2'],
          score1: matchData['score1'],
          score2: matchData['score2'],
          winner: matchData['winner'],
          round: matchData['round'] ?? 1,
          position: matchData['position'] ?? i,
        ));
      }
    }

    return matches;
  }

  Map<int, List<BracketMatch>> _groupMatchesByRound(List<BracketMatch> matches) {
    final grouped = <int, List<BracketMatch>>{};
    for (final match in matches) {
      grouped.putIfAbsent(match.round, () => []).add(match);
    }

    // Sort matches within each round by position
    for (final round in grouped.keys) {
      grouped[round]!.sort((a, b) => a.position.compareTo(b.position));
    }

    return grouped;
  }

  List<String> _getRoundNames(int totalRounds) {
    if (totalRounds <= 0) return [];

    final names = <String>[];
    for (var i = 0; i < totalRounds; i++) {
      final remainingRounds = totalRounds - i;
      if (remainingRounds == 1) {
        names.add('Final');
      } else if (remainingRounds == 2) {
        names.add('Semi-Finals');
      } else if (remainingRounds == 3) {
        names.add('Quarter-Finals');
      } else {
        names.add('Round ${i + 1}');
      }
    }
    return names;
  }

  /// Generate bracket data from participants
  static Map<String, dynamic> generateBracket(List<String> participants) {
    if (participants.length < 2) return {};

    // Shuffle participants for random seeding
    final shuffled = List<String>.from(participants)..shuffle();

    // Calculate number of rounds needed
    final numParticipants = shuffled.length;
    int bracketSize = 2;
    while (bracketSize < numParticipants) {
      bracketSize *= 2;
    }

    final numRounds = (bracketSize - 1).bitLength;
    final matches = <Map<String, dynamic>>[];

    // Generate first round matches
    int matchIndex = 0;
    for (var i = 0; i < bracketSize ~/ 2; i++) {
      final player1Index = i * 2;
      final player2Index = i * 2 + 1;

      matches.add({
        'id': 'match_1_$matchIndex',
        'player1': player1Index < shuffled.length ? shuffled[player1Index] : null,
        'player2': player2Index < shuffled.length ? shuffled[player2Index] : null,
        'score1': null,
        'score2': null,
        'winner': null,
        'round': 1,
        'position': matchIndex,
      });

      // Auto-advance if only one player (bye)
      if (player1Index < shuffled.length && player2Index >= shuffled.length) {
        matches.last['winner'] = shuffled[player1Index];
      } else if (player2Index < shuffled.length && player1Index >= shuffled.length) {
        matches.last['winner'] = shuffled[player2Index];
      }

      matchIndex++;
    }

    // Generate subsequent rounds (empty matches)
    int matchesInPreviousRound = bracketSize ~/ 2;
    for (var round = 2; round <= numRounds; round++) {
      final matchesInRound = matchesInPreviousRound ~/ 2;
      for (var i = 0; i < matchesInRound; i++) {
        matches.add({
          'id': 'match_${round}_$i',
          'player1': null,
          'player2': null,
          'score1': null,
          'score2': null,
          'winner': null,
          'round': round,
          'position': i,
        });
      }
      matchesInPreviousRound = matchesInRound;
    }

    return {
      'matches': matches,
      'totalRounds': numRounds,
      'bracketSize': bracketSize,
      'generatedAt': DateTime.now().toIso8601String(),
    };
  }
}
