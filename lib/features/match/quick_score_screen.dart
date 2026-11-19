import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';

/// Quick Score screen for directly entering player names and starting a match
class QuickScoreScreen extends StatefulWidget {
  const QuickScoreScreen({super.key});

  @override
  State<QuickScoreScreen> createState() => _QuickScoreScreenState();
}

class _QuickScoreScreenState extends State<QuickScoreScreen>
    with SingleTickerProviderStateMixin {
  String _selectedMatchType = AppConstants.matchTypeSingles;

  // Controllers for player names
  final _teamAPlayer1Controller = TextEditingController();
  final _teamAPlayer2Controller = TextEditingController();
  final _teamBPlayer1Controller = TextEditingController();
  final _teamBPlayer2Controller = TextEditingController();

  // Score tracking
  int _scoreA = 0;
  int _scoreB = 0;
  int _currentSet = 1;
  bool _isTeamAServing = true;
  bool _isMatchStarted = false;
  final List<Map<String, int>> _setHistory = [];
  final List<Map<String, dynamic>> _scoreHistory = [];

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
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
    _teamAPlayer1Controller.dispose();
    _teamAPlayer2Controller.dispose();
    _teamBPlayer1Controller.dispose();
    _teamBPlayer2Controller.dispose();
    super.dispose();
  }

  bool get _isDoubles => _selectedMatchType != AppConstants.matchTypeSingles;

  String get _teamAName {
    if (_isDoubles) {
      final p1 = _teamAPlayer1Controller.text.trim();
      final p2 = _teamAPlayer2Controller.text.trim();
      if (p1.isEmpty && p2.isEmpty) return 'Team A';
      if (p1.isEmpty) return p2;
      if (p2.isEmpty) return p1;
      return '${p1.split(' ')[0]} & ${p2.split(' ')[0]}';
    }
    return _teamAPlayer1Controller.text.trim().isEmpty
        ? 'Player A'
        : _teamAPlayer1Controller.text.trim();
  }

  String get _teamBName {
    if (_isDoubles) {
      final p1 = _teamBPlayer1Controller.text.trim();
      final p2 = _teamBPlayer2Controller.text.trim();
      if (p1.isEmpty && p2.isEmpty) return 'Team B';
      if (p1.isEmpty) return p2;
      if (p2.isEmpty) return p1;
      return '${p1.split(' ')[0]} & ${p2.split(' ')[0]}';
    }
    return _teamBPlayer1Controller.text.trim().isEmpty
        ? 'Player B'
        : _teamBPlayer1Controller.text.trim();
  }

  void _startMatch() {
    setState(() {
      _isMatchStarted = true;
      _scoreA = 0;
      _scoreB = 0;
      _currentSet = 1;
      _setHistory.clear();
      _scoreHistory.clear();
    });
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

    if ((_scoreA >= pointsToWin || _scoreB >= pointsToWin) &&
        (_scoreA - _scoreB).abs() >= minLead) {
      return true;
    }

    if (_scoreA >= maxPoints || _scoreB >= maxPoints) {
      return true;
    }

    return false;
  }

  void _showSetWinDialog() {
    final winner = _scoreA > _scoreB ? _teamAName : _teamBName;

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
    setState(() {
      _isMatchStarted = false;
    });
  }

  void _resetMatch() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        ),
        title: const Text(
          'Reset Match?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'This will clear all scores and start fresh.',
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
              setState(() {
                _isMatchStarted = false;
                _scoreA = 0;
                _scoreB = 0;
                _currentSet = 1;
                _setHistory.clear();
                _scoreHistory.clear();
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.darkGradient,
      ),
      child: SafeArea(
        child: _isMatchStarted ? _buildScoreboard() : _buildSetupScreen(),
      ),
    );
  }

  Widget _buildSetupScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Quick Score',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start a match quickly by entering player names',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),

          // Match Type Selection
          const Text(
            'Match Type',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMatchTypeChip(AppConstants.matchTypeSingles, 'Singles'),
              const SizedBox(width: 12),
              _buildMatchTypeChip(AppConstants.matchTypeDoubles, 'Doubles'),
              const SizedBox(width: 12),
              _buildMatchTypeChip(AppConstants.matchTypeMixedDoubles, 'Mixed'),
            ],
          ),
          const SizedBox(height: 24),

          // Team A
          _buildTeamInput(
            'Team A',
            AppColors.primaryBlue,
            _teamAPlayer1Controller,
            _teamAPlayer2Controller,
          ),
          const SizedBox(height: 16),

          // VS Divider
          Center(
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
          ),
          const SizedBox(height: 16),

          // Team B
          _buildTeamInput(
            'Team B',
            AppColors.accentGreen,
            _teamBPlayer1Controller,
            _teamBPlayer2Controller,
          ),
          const SizedBox(height: 32),

          // Start Match Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _startMatch,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow_rounded, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Start Match',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchTypeChip(String type, String label) {
    final isSelected = _selectedMatchType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedMatchType = type;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected ? AppColors.accentGradient : null,
            color: isSelected ? null : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            border: Border.all(
              color: isSelected ? AppColors.accentGreen : AppColors.surfaceColor,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.darkBackground : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeamInput(
    String title,
    Color color,
    TextEditingController player1Controller,
    TextEditingController player2Controller,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: player1Controller,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: _isDoubles ? 'Player 1 name' : 'Player name',
              prefixIcon: const Icon(Icons.person_outline, color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.surfaceColor,
            ),
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
          ),
          if (_isDoubles) ...[
            const SizedBox(height: 12),
            TextField(
              controller: player2Controller,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Player 2 name',
                prefixIcon: Icon(Icons.person_outline, color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surfaceColor,
              ),
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScoreboard() {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
                onPressed: _resetMatch,
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
                    _selectedMatchType,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
                onPressed: _resetMatch,
              ),
            ],
          ),
        ),

        // Score display
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
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
                  Container(
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
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Team A
                        _buildTeamRow(
                          _teamAName,
                          _scoreA,
                          _isTeamAServing,
                          _scoreA > _scoreB,
                          AppColors.primaryBlue,
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
                          _teamBName,
                          _scoreB,
                          !_isTeamAServing,
                          _scoreB > _scoreA,
                          AppColors.accentGreen,
                        ),
                      ],
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
                                      ? AppColors.primaryBlue
                                      : AppColors.accentGreen,
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
                        child: _buildScoreButton(
                          _teamAName.split(' ')[0],
                          AppColors.primaryBlue,
                          () => _incrementScore(true),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildScoreButton(
                          _teamBName.split(' ')[0],
                          AppColors.accentGreen,
                          () => _incrementScore(false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Undo button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _scoreHistory.isNotEmpty ? _undo : null,
                      icon: const Icon(Icons.undo),
                      label: const Text('Undo'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.surfaceColor),
                        foregroundColor: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamRow(String name, int score, bool isServing, bool isLeading, Color color) {
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
        // Team avatar
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: isLeading
                ? LinearGradient(colors: [color, color.withValues(alpha: 0.7)])
                : AppColors.primaryGradient,
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
              color: isLeading ? color : AppColors.textPrimary,
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
            gradient: isLeading
                ? LinearGradient(colors: [color, color.withValues(alpha: 0.8)])
                : null,
            color: isLeading ? null : AppColors.surfaceColor,
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          ),
          child: Text(
            score.toString(),
            style: TextStyle(
              color: isLeading ? Colors.white : AppColors.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreButton(String label, Color color, VoidCallback onPressed) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              const Icon(Icons.add, color: Colors.white, size: 28),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
