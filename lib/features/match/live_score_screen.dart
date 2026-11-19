import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/score_button.dart';

/// Live score screen for tracking match scores
class LiveScoreScreen extends StatefulWidget {
  final String? matchId;
  final String teamA;
  final String teamB;
  final int? initialScoreA;
  final int? initialScoreB;
  final String matchType;

  const LiveScoreScreen({
    super.key,
    this.matchId,
    required this.teamA,
    required this.teamB,
    this.initialScoreA,
    this.initialScoreB,
    required this.matchType,
  });

  @override
  State<LiveScoreScreen> createState() => _LiveScoreScreenState();
}

class _LiveScoreScreenState extends State<LiveScoreScreen>
    with SingleTickerProviderStateMixin {
  late int _scoreA;
  late int _scoreB;
  int _currentSet = 1;
  bool _isTeamAServing = true;
  final List<Map<String, int>> _setHistory = [];
  final List<Map<String, dynamic>> _scoreHistory = [];

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _scoreA = widget.initialScoreA ?? 0;
    _scoreB = widget.initialScoreB ?? 0;

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _incrementScore(bool isTeamA) {
    setState(() {
      _scoreHistory.add({
        'scoreA': _scoreA,
        'scoreB': _scoreB,
        'serving': _isTeamAServing,
      });

      if (isTeamA) {
        _scoreA++;
        _isTeamAServing = true;
      } else {
        _scoreB++;
        _isTeamAServing = false;
      }

      // Check for set win
      if (_checkSetWin()) {
        _showSetWinDialog();
      }
    });
  }

  void _undo() {
    if (_scoreHistory.isNotEmpty) {
      setState(() {
        final lastState = _scoreHistory.removeLast();
        _scoreA = lastState['scoreA'];
        _scoreB = lastState['scoreB'];
        _isTeamAServing = lastState['serving'];
      });
    }
  }

  bool _checkSetWin() {
    final pointsToWin = AppConstants.matchPointsToWin;
    final minLead = AppConstants.matchMinimumLead;
    final maxPoints = AppConstants.matchMaxPoints;

    // Win at 21 with 2 point lead
    if ((_scoreA >= pointsToWin || _scoreB >= pointsToWin) &&
        (_scoreA - _scoreB).abs() >= minLead) {
      return true;
    }

    // Win at 30 regardless of lead
    if (_scoreA >= maxPoints || _scoreB >= maxPoints) {
      return true;
    }

    return false;
  }

  void _showSetWinDialog() {
    final winner = _scoreA > _scoreB ? widget.teamA : widget.teamB;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        ),
        title: Column(
          children: [
            const Icon(
              Icons.emoji_events,
              color: AppColors.accentGreen,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'Set $_currentSet Complete!',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$winner wins the set',
              style: const TextStyle(
                color: AppColors.accentGreen,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$_scoreA - $_scoreB',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _endMatch();
            },
            child: const Text('End Match'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startNextSet();
            },
            child: const Text('Next Set'),
          ),
        ],
      ),
    );
  }

  void _startNextSet() {
    setState(() {
      _setHistory.add({'scoreA': _scoreA, 'scoreB': _scoreB});
      _scoreA = 0;
      _scoreB = 0;
      _currentSet++;
      _scoreHistory.clear();
    });
  }

  void _endMatch() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        ),
        title: const Text(
          'End Match?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to end this match?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('End Match'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.darkGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'LIVE',
                              style: TextStyle(
                                color: AppColors.error,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.matchType,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              // Score display
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Set indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceColor,
                          borderRadius: BorderRadius.circular(AppConstants.radiusRound),
                        ),
                        child: Text(
                          'Set $_currentSet',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Main scoreboard
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: AppColors.cardGradient,
                            borderRadius: BorderRadius.circular(AppConstants.radiusXLarge),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Team A
                              _buildTeamRow(
                                widget.teamA,
                                _scoreA,
                                _isTeamAServing,
                                _scoreA > _scoreB,
                              ),
                              const SizedBox(height: 24),
                              // VS divider
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 2,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.transparent,
                                            AppColors.surfaceColor,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: AnimatedBuilder(
                                      animation: _pulseAnimation,
                                      builder: (context, child) {
                                        return Transform.scale(
                                          scale: _pulseAnimation.value,
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              gradient: AppColors.primaryGradient,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Text(
                                              'VS',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      height: 2,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.surfaceColor,
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              // Team B
                              _buildTeamRow(
                                widget.teamB,
                                _scoreB,
                                !_isTeamAServing,
                                _scoreB > _scoreA,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Set history
                      if (_setHistory.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceColor.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Previous Sets: ',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                              ...List.generate(_setHistory.length, (index) {
                                final set = _setHistory[index];
                                return Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Text(
                                    '${set['scoreA']}-${set['scoreB']}',
                                    style: TextStyle(
                                      color: set['scoreA']! > set['scoreB']!
                                          ? AppColors.accentGreen
                                          : AppColors.error,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Score buttons
                      Row(
                        children: [
                          Expanded(
                            child: ScoreIncrementButton(
                              teamName: widget.teamA.split(' ')[0],
                              color: AppColors.primaryBlue,
                              onPressed: () => _incrementScore(true),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ScoreIncrementButton(
                              teamName: widget.teamB.split(' ')[0],
                              color: AppColors.accentGreen,
                              onPressed: () => _incrementScore(false),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: ScoreButton(
                              label: 'Undo',
                              icon: Icons.undo,
                              onPressed: _undo,
                              backgroundColor: AppColors.surfaceColor,
                              foregroundColor: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ScoreButton(
                              label: 'End Match',
                              icon: Icons.stop_circle_outlined,
                              onPressed: _endMatch,
                              backgroundColor: AppColors.error,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamRow(String name, int score, bool isServing, bool isLeading) {
    return Row(
      children: [
        // Serving indicator
        AnimatedContainer(
          duration: AppConstants.animationFast,
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isServing ? AppColors.accentGreen : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: isServing ? AppColors.accentGreen : AppColors.surfaceColor,
              width: 2,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Team name and avatar
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: isLeading ? AppColors.accentGradient : AppColors.primaryGradient,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            style: TextStyle(
              color: isLeading ? AppColors.accentGreen : AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Score
        AnimatedContainer(
          duration: AppConstants.animationFast,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: isLeading ? AppColors.accentGradient : null,
            color: isLeading ? null : AppColors.surfaceColor,
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          ),
          child: Text(
            score.toString(),
            style: TextStyle(
              color: isLeading ? AppColors.darkBackground : AppColors.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
