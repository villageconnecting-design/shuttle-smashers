import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../services/firestore_service.dart';
import '../../models/player_model.dart' as models;
import '../../widgets/custom_app_bar.dart';
import 'live_score_screen.dart';

/// Local player model for match creation (supports both registered and guest players)
class MatchPlayer {
  final String id;
  final String name;
  final String avatar;
  final bool isGuest;
  final int? wins;
  final int? matches;

  MatchPlayer({
    required this.id,
    required this.name,
    required this.avatar,
    this.isGuest = false,
    this.wins,
    this.matches,
  });

  factory MatchPlayer.fromPlayerModel(models.PlayerModel player) {
    return MatchPlayer(
      id: player.id,
      name: player.name,
      avatar: player.avatar,
      isGuest: player.isGuest,
      wins: player.wins,
      matches: player.matchesPlayed,
    );
  }
}

/// Enhanced create match screen with guest player support and team formation
class CreateMatchScreen extends StatefulWidget {
  const CreateMatchScreen({super.key});

  @override
  State<CreateMatchScreen> createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends State<CreateMatchScreen>
    with SingleTickerProviderStateMixin {
  final _firestoreService = FirestoreService();
  String _selectedMatchType = AppConstants.matchTypeSingles;
  final List<MatchPlayer> _allPlayers = [];
  final List<MatchPlayer> _teamA = [];
  final List<MatchPlayer> _teamB = [];
  final TextEditingController _guestNameController = TextEditingController();
  late TabController _tabController;
  int _guestIdCounter = 1000;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRegisteredPlayers();
  }

  @override
  void dispose() {
    _guestNameController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _loadRegisteredPlayers() async {
    setState(() => _isLoading = true);

    // Listen to players stream
    _firestoreService.getPlayers().listen((players) {
      if (mounted) {
        setState(() {
          _allPlayers.clear();
          for (var player in players) {
            _allPlayers.add(MatchPlayer.fromPlayerModel(player));
          }
          _isLoading = false;
        });
      }
    }, onError: (error) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  int get _requiredPlayersPerTeam {
    return _selectedMatchType == AppConstants.matchTypeSingles ? 1 : 2;
  }

  bool get _isValidSelection {
    return _teamA.length == _requiredPlayersPerTeam &&
        _teamB.length == _requiredPlayersPerTeam;
  }

  List<MatchPlayer> get _selectedPlayers => [..._teamA, ..._teamB];

  void _addGuestPlayer() {
    final name = _guestNameController.text.trim();
    if (name.isEmpty) return;

    final initials = name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();

    setState(() {
      _allPlayers.insert(0, MatchPlayer(
        id: 'guest_${_guestIdCounter++}',
        name: name,
        avatar: initials.isEmpty ? 'G' : initials,
        isGuest: true,
      ));
      _guestNameController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name added as guest player'),
        backgroundColor: AppColors.accentGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _togglePlayerSelection(MatchPlayer player) {
    setState(() {
      // Check if already selected
      if (_teamA.any((p) => p.id == player.id)) {
        _teamA.removeWhere((p) => p.id == player.id);
        return;
      }
      if (_teamB.any((p) => p.id == player.id)) {
        _teamB.removeWhere((p) => p.id == player.id);
        return;
      }

      // Add to appropriate team
      if (_teamA.length < _requiredPlayersPerTeam) {
        _teamA.add(player);
      } else if (_teamB.length < _requiredPlayersPerTeam) {
        _teamB.add(player);
      }
    });
  }

  void _assignToTeam(MatchPlayer player, bool isTeamA) {
    setState(() {
      // Remove from both teams first
      _teamA.removeWhere((p) => p.id == player.id);
      _teamB.removeWhere((p) => p.id == player.id);

      // Add to selected team if space available
      if (isTeamA && _teamA.length < _requiredPlayersPerTeam) {
        _teamA.add(player);
      } else if (!isTeamA && _teamB.length < _requiredPlayersPerTeam) {
        _teamB.add(player);
      }
    });
  }

  void _removeFromTeam(MatchPlayer player) {
    setState(() {
      _teamA.removeWhere((p) => p.id == player.id);
      _teamB.removeWhere((p) => p.id == player.id);
    });
  }

  void _clearSelection() {
    setState(() {
      _teamA.clear();
      _teamB.clear();
    });
  }

  String _getTeamDisplayName(List<MatchPlayer> team) {
    if (team.isEmpty) return '';
    if (team.length == 1) return team[0].name;
    return '${team[0].name.split(' ')[0]} & ${team[1].name.split(' ')[0]}';
  }

  Future<void> _startMatch() async {
    if (!_isValidSelection) return;

    try {
      // Create match in Firestore
      final match = await _firestoreService.createMatch(
        matchType: _selectedMatchType,
        teamAIds: _teamA.map((p) => p.id).toList(),
        teamBIds: _teamB.map((p) => p.id).toList(),
        teamANames: _getTeamDisplayName(_teamA),
        teamBNames: _getTeamDisplayName(_teamB),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LiveScoreScreen(
              matchId: match.id,
              teamA: _getTeamDisplayName(_teamA),
              teamB: _getTeamDisplayName(_teamB),
              matchType: _selectedMatchType,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating match: $e'),
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
        title: 'Create Match',
        showBackButton: true,
        actions: [
          if (_selectedPlayers.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
              onPressed: _clearSelection,
              tooltip: 'Clear Selection',
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.darkGradient,
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Match Type Selection
                    _buildMatchTypeSection(),

                    // Team Formation Preview
                    _buildTeamFormationSection(),

                    // Player Selection Tabs
                    _buildPlayerSelectionSection(),
                  ],
                ),
              ),
            ),
            // Start Match Button
            _buildStartMatchButton(),
          ],
        ),
      ),
    );
  }

  // Match Type Selection Section
  Widget _buildMatchTypeSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.sports_tennis,
                  color: AppColors.accentGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Match Type',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMatchTypeCard(
                AppConstants.matchTypeSingles,
                Icons.person,
                '1 vs 1',
              ),
              const SizedBox(width: 12),
              _buildMatchTypeCard(
                AppConstants.matchTypeDoubles,
                Icons.people,
                '2 vs 2',
              ),
              const SizedBox(width: 12),
              _buildMatchTypeCard(
                AppConstants.matchTypeMixedDoubles,
                Icons.group,
                'Mixed',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMatchTypeCard(String type, IconData icon, String subtitle) {
    final isSelected = _selectedMatchType == type;
    final label = type == AppConstants.matchTypeMixedDoubles ? 'Mixed' : type;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedMatchType = type;
            _clearSelection();
          });
        },
        child: AnimatedContainer(
          duration: AppConstants.animationFast,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
          decoration: BoxDecoration(
            gradient: isSelected ? AppColors.accentGradient : null,
            color: isSelected ? null : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
            border: Border.all(
              color: isSelected ? AppColors.accentGreen : AppColors.surfaceColor,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.accentGreen.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.darkBackground : AppColors.textSecondary,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.darkBackground : AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.darkBackground.withValues(alpha: 0.7)
                      : AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Team Formation Section
  Widget _buildTeamFormationSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        border: Border.all(
          color: AppColors.surfaceColor,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.groups, color: AppColors.accentGreen, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Team Formation',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _isValidSelection
                      ? AppColors.accentGreen.withValues(alpha: 0.2)
                      : AppColors.surfaceColor,
                  borderRadius: BorderRadius.circular(AppConstants.radiusRound),
                ),
                child: Text(
                  '${_selectedPlayers.length} / ${_requiredPlayersPerTeam * 2}',
                  style: TextStyle(
                    color: _isValidSelection
                        ? AppColors.accentGreen
                        : AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTeamCard(
                  'Team A',
                  _teamA,
                  AppColors.primaryBlue,
                  true,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    'VS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _buildTeamCard(
                  'Team B',
                  _teamB,
                  AppColors.accentGreen,
                  false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCard(String title, List<MatchPlayer> team, Color color, bool isTeamA) {
    final requiredPlayers = _requiredPlayersPerTeam;
    final isEmpty = team.isEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isEmpty)
            ...List.generate(requiredPlayers, (index) => _buildEmptySlot())
          else
            ...team.map((player) => _buildTeamPlayerTile(player, color)),
          if (team.length < requiredPlayers && team.isNotEmpty)
            ...List.generate(
              requiredPlayers - team.length,
              (index) => _buildEmptySlot(),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptySlot() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
        border: Border.all(
          color: AppColors.surfaceColor,
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.add_circle_outline, color: AppColors.textMuted, size: 14),
          SizedBox(width: 4),
          Flexible(
            child: Text(
              'Add',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamPlayerTile(MatchPlayer player, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.7)],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                player.avatar,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name.split(' ')[0],
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (player.isGuest)
                  const Text(
                    'Guest',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 9,
                    ),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _removeFromTeam(player),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: AppColors.error, size: 12),
            ),
          ),
        ],
      ),
    );
  }

  // Player Selection Section with Tabs
  Widget _buildPlayerSelectionSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person_add,
                  color: AppColors.accentGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Select Players',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Tabs for Registered vs Add Guest
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                gradient: AppColors.accentGradient,
                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: AppColors.darkBackground,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Registered Players'),
                Tab(text: 'Add Guest'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 320,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRegisteredPlayersGrid(),
                _buildAddGuestSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisteredPlayersGrid() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accentGreen),
      );
    }

    final registeredPlayers = _allPlayers.where((p) => !p.isGuest).toList();
    final guestPlayers = _allPlayers.where((p) => p.isGuest).toList();
    final allDisplayPlayers = [...guestPlayers, ...registeredPlayers];

    if (allDisplayPlayers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            const Text(
              'No players found',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add a guest player to start',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.75,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: allDisplayPlayers.length,
      itemBuilder: (context, index) {
        final player = allDisplayPlayers[index];
        return _buildPlayerSelectionCard(player);
      },
    );
  }

  Widget _buildPlayerSelectionCard(MatchPlayer player) {
    final isInTeamA = _teamA.any((p) => p.id == player.id);
    final isInTeamB = _teamB.any((p) => p.id == player.id);
    final isSelected = isInTeamA || isInTeamB;
    final selectionColor = isInTeamA ? AppColors.primaryBlue : (isInTeamB ? AppColors.accentGreen : null);

    return GestureDetector(
      onTap: () => _togglePlayerSelection(player),
      child: AnimatedContainer(
        duration: AppConstants.animationFast,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [selectionColor!, selectionColor.withValues(alpha: 0.7)],
                )
              : AppColors.cardGradient,
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          border: Border.all(
            color: isSelected ? selectionColor! : AppColors.surfaceColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: selectionColor!.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                Container(
                  width: 48,
                  height: 48,
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
                      player.avatar,
                      style: TextStyle(
                        color: isSelected ? selectionColor : Colors.white,
                        fontSize: 16,
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
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: selectionColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          isInTeamA ? 'A' : 'B',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (player.isGuest)
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'G',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              player.name,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (player.wins != null && !player.isGuest) ...[
              const SizedBox(height: 4),
              Text(
                '${player.wins}W / ${player.matches}M',
                style: TextStyle(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.8)
                      : AppColors.textMuted,
                  fontSize: 9,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddGuestSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        border: Border.all(color: AppColors.surfaceColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_add_alt_1,
                  color: AppColors.warning,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Guest Player',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Players not registered in the app',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _guestNameController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Enter player name',
              prefixIcon: const Icon(Icons.person_outline, color: AppColors.textMuted),
              suffixIcon: _guestNameController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.textMuted),
                      onPressed: () {
                        _guestNameController.clear();
                        setState(() {});
                      },
                    )
                  : null,
            ),
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _guestNameController.text.trim().isNotEmpty
                  ? _addGuestPlayer
                  : null,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Add Player'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: AppColors.warning,
                disabledBackgroundColor: AppColors.surfaceColor,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Show guest players list
          if (_allPlayers.any((p) => p.isGuest)) ...[
            const Divider(color: AppColors.surfaceColor),
            const SizedBox(height: 12),
            const Text(
              'Added Guests',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: _allPlayers
                    .where((p) => p.isGuest)
                    .map((player) => _buildGuestPlayerTile(player))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGuestPlayerTile(MatchPlayer player) {
    final isInTeamA = _teamA.any((p) => p.id == player.id);
    final isInTeamB = _teamB.any((p) => p.id == player.id);
    final isSelected = isInTeamA || isInTeamB;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected
            ? (isInTeamA ? AppColors.primaryBlue : AppColors.accentGreen).withValues(alpha: 0.2)
            : AppColors.surfaceColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(
          color: isSelected
              ? (isInTeamA ? AppColors.primaryBlue : AppColors.accentGreen)
              : AppColors.surfaceColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.warning,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                player.avatar,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Text(
                  'Guest Player',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (isSelected)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isInTeamA ? AppColors.primaryBlue : AppColors.accentGreen,
                borderRadius: BorderRadius.circular(AppConstants.radiusRound),
              ),
              child: Text(
                isInTeamA ? 'Team A' : 'Team B',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            Row(
              children: [
                _buildAssignButton('A', AppColors.primaryBlue, () => _assignToTeam(player, true)),
                const SizedBox(width: 8),
                _buildAssignButton('B', AppColors.accentGreen, () => _assignToTeam(player, false)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildAssignButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(color: color),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // Start Match Button
  Widget _buildStartMatchButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_isValidSelection && _selectedPlayers.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.warning, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      _selectedMatchType == AppConstants.matchTypeSingles
                          ? 'Select 1 player for each team'
                          : 'Select 2 players for each team',
                      style: const TextStyle(
                        color: AppColors.warning,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isValidSelection ? _startMatch : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  disabledBackgroundColor: AppColors.surfaceColor,
                  disabledForegroundColor: AppColors.textMuted,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isValidSelection ? Icons.play_arrow_rounded : Icons.lock_outline,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isValidSelection ? 'Start Match' : 'Complete Selection',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
