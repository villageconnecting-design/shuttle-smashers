import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/tournament_bracket_widget.dart';
import '../../services/firestore_service.dart';

/// Tournament details screen with bracket view and team management
class TournamentDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> tournament;

  const TournamentDetailsScreen({
    super.key,
    required this.tournament,
  });

  @override
  State<TournamentDetailsScreen> createState() => _TournamentDetailsScreenState();
}

class _TournamentDetailsScreenState extends State<TournamentDetailsScreen> {
  final _firestoreService = FirestoreService();
  final _participantController = TextEditingController();
  late Map<String, dynamic> _tournament;

  @override
  void initState() {
    super.initState();
    _tournament = Map<String, dynamic>.from(widget.tournament);
  }

  @override
  void dispose() {
    _participantController.dispose();
    super.dispose();
  }

  String _formatDate(dynamic date) {
    if (date is DateTime) {
      return '${date.day}/${date.month}/${date.year}';
    }
    return date.toString();
  }

  List<String> get _participants {
    final participants = _tournament['participants'];
    if (participants is List) {
      return List<String>.from(participants);
    }
    return [];
  }

  int get _maxParticipants => _tournament['maxParticipants'] ?? 16;
  int get _availableSlots => _maxParticipants - _participants.length;
  bool get _isFull => _participants.length >= _maxParticipants;
  bool get _isUpcoming => _tournament['status']?.toString().toLowerCase() == 'upcoming';

  Future<void> _addParticipant() async {
    final name = _participantController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a participant name'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_isFull) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tournament is full'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      await _firestoreService.addParticipant(_tournament['id'], name);
      setState(() {
        final participants = List<String>.from(_participants);
        participants.add(name);
        _tournament['participants'] = participants;
      });
      _participantController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name added to tournament'),
            backgroundColor: AppColors.accentGreen,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _removeParticipant(String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          'Remove Participant',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Remove $name from the tournament?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestoreService.removeParticipant(_tournament['id'], name);
        setState(() {
          final participants = List<String>.from(_participants);
          participants.remove(name);
          _tournament['participants'] = participants;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$name removed from tournament'),
              backgroundColor: AppColors.accentGreen,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteTournament() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          'Delete Tournament',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to delete this tournament? This action cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestoreService.deleteTournament(_tournament['id']);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tournament deleted'),
              backgroundColor: AppColors.accentGreen,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _tournament['name'] ?? 'Tournament',
        showBackButton: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            color: AppColors.cardBackground,
            onSelected: (value) {
              if (value == 'delete') {
                _deleteTournament();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                    SizedBox(width: 8),
                    Text('Delete Tournament', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.darkGradient,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tournament info header
              _buildInfoHeader(),

              // Winner highlight (if completed)
              if (_tournament['winner'] != null) _buildWinnerSection(),

              // Tournament description if available
              if (_tournament['description'] != null &&
                  _tournament['description'].toString().isNotEmpty)
                _buildDescriptionSection(),

              // Participants section
              _buildParticipantsSection(),

              // Tournament bracket placeholder
              _buildBracketSection(),

              // Match list placeholder
              _buildMatchesSection(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoHeader() {
    return Container(
      margin: const EdgeInsets.all(20),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _tournament['type'] ?? 'Tournament',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_participants.length}/$_maxParticipants Players',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_availableSlots > 0 && _isUpcoming)
                      Text(
                        '$_availableSlots slots available',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              _buildStatusBadge(_tournament['status'] ?? 'Unknown'),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoColumn(
                Icons.calendar_today,
                'Start',
                _formatDate(_tournament['startDate']),
              ),
              _buildInfoColumn(
                Icons.event,
                'End',
                _formatDate(_tournament['endDate']),
              ),
              if (_tournament['prize'] != null)
                _buildInfoColumn(
                  Icons.emoji_events,
                  'Prize',
                  _tournament['prize'],
                ),
            ],
          ),
          if (_tournament['venue'] != null && _tournament['venue'].toString().isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _tournament['venue'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWinnerSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.accentGradient,
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentGreen.withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.emoji_events,
                color: Color(0xFFFFD700),
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CHAMPION',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _tournament['winner'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            ),
            child: Text(
              _tournament['description'],
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildParticipantsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Participants (${_participants.length}/$_maxParticipants)',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_isUpcoming && !_isFull)
                TextButton.icon(
                  onPressed: _showAddParticipantDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
            ),
            child: _participants.isEmpty
                ? _buildEmptyParticipants()
                : _buildParticipantsList(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildEmptyParticipants() {
    return Column(
      children: [
        Icon(
          Icons.people_outline,
          size: 48,
          color: AppColors.textMuted,
        ),
        const SizedBox(height: 16),
        const Text(
          'No participants yet',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        if (_isUpcoming)
          const Text(
            'Add players to start the tournament',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
          ),
        if (_isUpcoming) ...[
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showAddParticipantDialog,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Participant'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildParticipantsList() {
    return Column(
      children: [
        ...List.generate(_participants.length, (index) {
          final participant = _participants[index];
          return Container(
            margin: EdgeInsets.only(bottom: index < _participants.length - 1 ? 8 : 0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    participant,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (_isUpcoming)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
                    onPressed: () => _removeParticipant(participant),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  void _showAddParticipantDialog() {
    _participantController.clear();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusXLarge),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Add Participant',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$_availableSlots slots remaining',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _participantController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Player / Team Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                onSubmitted: (_) {
                  _addParticipant();
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _addParticipant();
                    Navigator.pop(context);
                  },
                  child: const Text('Add Participant'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _generateBracket() async {
    if (_participants.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Need at least 2 participants to generate bracket'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          'Generate Bracket',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Generate a bracket with ${_participants.length} participants? '
          'This will randomize the seeding.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Generate'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final bracket = TournamentBracketWidget.generateBracket(_participants);
        await _firestoreService.updateTournamentBracket(_tournament['id'], bracket);
        setState(() {
          _tournament['bracket'] = bracket;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bracket generated successfully'),
              backgroundColor: AppColors.accentGreen,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _onMatchTap(BracketMatch match) {
    if (!match.hasPlayers || match.isComplete) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusXLarge),
        ),
      ),
      builder: (context) => _BracketMatchResultSheet(
        match: match,
        tournamentId: _tournament['id'],
        firestoreService: _firestoreService,
        onResult: (winner, score1, score2) {
          setState(() {
            // Update local bracket data
            final bracket = Map<String, dynamic>.from(_tournament['bracket'] ?? {});
            final matches = List<Map<String, dynamic>>.from(bracket['matches'] ?? []);

            for (var i = 0; i < matches.length; i++) {
              if (matches[i]['id'] == match.id) {
                matches[i]['winner'] = winner;
                matches[i]['score1'] = score1;
                matches[i]['score2'] = score2;

                // Advance winner to next round
                final currentRound = matches[i]['round'] as int;
                final currentPosition = matches[i]['position'] as int;
                final nextRound = currentRound + 1;
                final nextPosition = currentPosition ~/ 2;

                for (var j = 0; j < matches.length; j++) {
                  if (matches[j]['round'] == nextRound && matches[j]['position'] == nextPosition) {
                    if (currentPosition % 2 == 0) {
                      matches[j]['player1'] = winner;
                    } else {
                      matches[j]['player2'] = winner;
                    }
                    break;
                  }
                }
                break;
              }
            }

            bracket['matches'] = matches;
            _tournament['bracket'] = bracket;
          });
        },
      ),
    );
  }

  Widget _buildBracketSection() {
    final bracket = _tournament['bracket'] as Map<String, dynamic>?;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tournament Bracket',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (bracket != null && bracket.isNotEmpty)
                TextButton(
                  onPressed: () => _showFullBracketView(),
                  child: const Text('Full View'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TournamentBracketWidget(
            participants: _participants,
            bracketData: bracket,
            tournamentStatus: _tournament['status'] ?? 'upcoming',
            onGenerateBracket: _isUpcoming ? _generateBracket : null,
            onMatchTap: _onMatchTap,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showFullBracketView() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FullBracketScreen(
          tournamentName: _tournament['name'] ?? 'Tournament',
          participants: _participants,
          bracketData: _tournament['bracket'] as Map<String, dynamic>?,
          tournamentStatus: _tournament['status'] ?? 'upcoming',
          onMatchTap: _onMatchTap,
        ),
      ),
    );
  }

  Widget _buildMatchesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Matches',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.sports_tennis_outlined,
                  size: 48,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No matches yet',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isUpcoming
                      ? 'Matches will appear here when the tournament starts'
                      : 'No match data available',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor = Colors.white;

    switch (status.toLowerCase()) {
      case 'live':
        bgColor = AppColors.error;
        break;
      case 'upcoming':
        bgColor = AppColors.warning;
        textColor = AppColors.darkBackground;
        break;
      case 'completed':
        bgColor = AppColors.accentGreen;
        break;
      default:
        bgColor = AppColors.surfaceColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusRound),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoColumn(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet for entering bracket match results
class _BracketMatchResultSheet extends StatefulWidget {
  final BracketMatch match;
  final String tournamentId;
  final FirestoreService firestoreService;
  final Function(String winner, int score1, int score2) onResult;

  const _BracketMatchResultSheet({
    required this.match,
    required this.tournamentId,
    required this.firestoreService,
    required this.onResult,
  });

  @override
  State<_BracketMatchResultSheet> createState() => _BracketMatchResultSheetState();
}

class _BracketMatchResultSheetState extends State<_BracketMatchResultSheet> {
  final _score1Controller = TextEditingController();
  final _score2Controller = TextEditingController();
  String? _selectedWinner;
  bool _isLoading = false;

  @override
  void dispose() {
    _score1Controller.dispose();
    _score2Controller.dispose();
    super.dispose();
  }

  Future<void> _submitResult() async {
    if (_selectedWinner == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a winner'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final score1 = int.tryParse(_score1Controller.text) ?? 0;
      final score2 = int.tryParse(_score2Controller.text) ?? 0;

      await widget.firestoreService.updateBracketMatch(
        tournamentId: widget.tournamentId,
        matchId: widget.match.id,
        winner: _selectedWinner!,
        score1: score1,
        score2: score2,
      );

      widget.onResult(_selectedWinner!, score1, score2);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Match result saved'),
            backgroundColor: AppColors.accentGreen,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Enter Match Result',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          // Player 1
          _buildPlayerOption(
            widget.match.player1 ?? 'Player 1',
            _score1Controller,
            widget.match.player1,
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'VS',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Player 2
          _buildPlayerOption(
            widget.match.player2 ?? 'Player 2',
            _score2Controller,
            widget.match.player2,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitResult,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save Result'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPlayerOption(
    String playerName,
    TextEditingController scoreController,
    String? playerId,
  ) {
    final isSelected = _selectedWinner == playerId;

    return GestureDetector(
      onTap: () => setState(() => _selectedWinner = playerId),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          border: Border.all(
            color: isSelected ? AppColors.accentGreen : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.accentGreen : AppColors.cardBackground,
                border: Border.all(
                  color: isSelected ? AppColors.accentGreen : AppColors.textMuted,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                playerName,
                style: TextStyle(
                  color: isSelected ? AppColors.accentGreen : AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            SizedBox(
              width: 60,
              child: TextField(
                controller: scoreController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: TextStyle(color: AppColors.textMuted),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  filled: true,
                  fillColor: AppColors.cardBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full screen bracket view
class _FullBracketScreen extends StatelessWidget {
  final String tournamentName;
  final List<String> participants;
  final Map<String, dynamic>? bracketData;
  final String tournamentStatus;
  final Function(BracketMatch)? onMatchTap;

  const _FullBracketScreen({
    required this.tournamentName,
    required this.participants,
    this.bracketData,
    required this.tournamentStatus,
    this.onMatchTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '$tournamentName Bracket',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.darkGradient,
        ),
        child: InteractiveViewer(
          boundaryMargin: const EdgeInsets.all(100),
          minScale: 0.5,
          maxScale: 2.0,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: TournamentBracketWidget(
                participants: participants,
                bracketData: bracketData,
                tournamentStatus: tournamentStatus,
                onMatchTap: onMatchTap,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
