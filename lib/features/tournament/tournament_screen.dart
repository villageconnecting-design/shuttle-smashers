import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../services/firestore_service.dart';
import '../../models/tournament_model.dart';
import '../../widgets/tournament_card.dart';
import 'tournament_details_screen.dart';

/// Tournament list screen with Firebase data
class TournamentScreen extends StatefulWidget {
  const TournamentScreen({super.key});

  @override
  State<TournamentScreen> createState() => _TournamentScreenState();
}

class _TournamentScreenState extends State<TournamentScreen> {
  final _firestoreService = FirestoreService();
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['All', 'Live', 'Upcoming', 'Completed'];

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _venueController = TextEditingController();
  final _prizeController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  TournamentType _selectedType = TournamentType.singles;
  int _maxParticipants = 16;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _venueController.dispose();
    _prizeController.dispose();
    super.dispose();
  }

  TournamentStatus? _getStatusFromTab(String tab) {
    switch (tab.toLowerCase()) {
      case 'live':
        return TournamentStatus.live;
      case 'upcoming':
        return TournamentStatus.upcoming;
      case 'completed':
        return TournamentStatus.completed;
      default:
        return null;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

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
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tournaments',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      _showCreateTournamentDialog();
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Create'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Horizontally scrollable tabs
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _tabs.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedTabIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTabIndex = index;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: isSelected ? AppColors.accentGradient : null,
                          color: isSelected ? null : AppColors.surfaceColor,
                          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                          border: isSelected
                              ? null
                              : Border.all(
                                  color: AppColors.textMuted.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                        ),
                        child: Center(
                          child: Text(
                            _tabs[index],
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.darkBackground
                                  : AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            // Tournament list
            Expanded(
              child: _buildTournamentList(_tabs[_selectedTabIndex]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTournamentList(String tab) {
    final status = _getStatusFromTab(tab);

    return StreamBuilder<List<TournamentModel>>(
      stream: _firestoreService.getTournaments(status: status),
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
                  Icons.wifi_off_rounded,
                  color: AppColors.textMuted,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Unable to load tournaments',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please check your internet connection',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () {
                    setState(() {});
                  },
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final tournaments = snapshot.data ?? [];

        if (tournaments.isEmpty) {
          return _buildEmptyState(tab);
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: tournaments.length,
          itemBuilder: (context, index) {
            final tournament = tournaments[index];
            return TournamentCard(
              name: tournament.name,
              type: 'Singles',
              playersCount: tournament.participantCount,
              status: tournament.statusText,
              startDate: _formatDate(tournament.startDate),
              endDate: _formatDate(tournament.endDate),
              prize: tournament.prizePool,
              winner: tournament.winner,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TournamentDetailsScreen(
                      tournament: _tournamentToMap(tournament),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Map<String, dynamic> _tournamentToMap(TournamentModel tournament) {
    return {
      'id': tournament.id,
      'name': tournament.name,
      'description': tournament.description,
      'type': tournament.typeText,
      'players': tournament.participantCount,
      'maxParticipants': tournament.maxParticipants,
      'status': tournament.statusText,
      'startDate': tournament.startDate,
      'endDate': tournament.endDate,
      'prize': tournament.prizePool,
      'venue': tournament.venue,
      'winner': tournament.winner,
      'participants': tournament.participants,
      'isFull': tournament.isFull,
      'availableSlots': tournament.availableSlots,
    };
  }

  Widget _buildEmptyState(String filter) {
    String title;
    String subtitle;
    IconData icon;

    switch (filter.toLowerCase()) {
      case 'live':
        title = 'No Live Tournaments';
        subtitle = 'There are no tournaments in progress right now';
        icon = Icons.play_circle_outline;
        break;
      case 'upcoming':
        title = 'No Upcoming Tournaments';
        subtitle = 'Create a tournament to schedule it for later';
        icon = Icons.event_note_outlined;
        break;
      case 'completed':
        title = 'No Completed Tournaments';
        subtitle = 'Finished tournaments will appear here';
        icon = Icons.check_circle_outline;
        break;
      default:
        title = 'No Tournaments Yet';
        subtitle = 'Create your first tournament to get started!';
        icon = Icons.emoji_events_outlined;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (filter != 'All')
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedTabIndex = 0;
                  });
                },
                child: const Text('View all tournaments'),
              ),
            if (filter == 'All')
              ElevatedButton.icon(
                onPressed: () {
                  _showCreateTournamentDialog();
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Create Tournament'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? (_startDate ?? DateTime.now()).add(const Duration(days: 1))),
      firstDate: isStartDate ? DateTime.now() : (_startDate ?? DateTime.now()),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accentGreen,
              onPrimary: Colors.white,
              surface: AppColors.cardBackground,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate!.add(const Duration(days: 1));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _showCreateTournamentDialog() {
    _nameController.clear();
    _descriptionController.clear();
    _venueController.clear();
    _prizeController.clear();
    _startDate = null;
    _endDate = null;
    _selectedType = TournamentType.singles;
    _maxParticipants = 16;

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
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
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
                      'Create Tournament',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Tournament Name
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: 'Tournament Name *',
                        prefixIcon: Icon(Icons.emoji_events),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Description
                    TextField(
                      controller: _descriptionController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Description (optional)',
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Tournament Type
                    const Text(
                      'Tournament Type',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildTypeChip('Singles', TournamentType.singles, setModalState),
                        const SizedBox(width: 8),
                        _buildTypeChip('Doubles', TournamentType.doubles, setModalState),
                        const SizedBox(width: 8),
                        _buildTypeChip('Mixed', TournamentType.mixed, setModalState),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Venue
                    TextField(
                      controller: _venueController,
                      decoration: const InputDecoration(
                        hintText: 'Venue / Location',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Prize Pool
                    TextField(
                      controller: _prizeController,
                      decoration: const InputDecoration(
                        hintText: 'Prize Pool (e.g., Rs. 5000)',
                        prefixIcon: Icon(Icons.monetization_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Max Participants
                    const Text(
                      'Max Participants',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildParticipantChip(8, setModalState),
                        const SizedBox(width: 8),
                        _buildParticipantChip(16, setModalState),
                        const SizedBox(width: 8),
                        _buildParticipantChip(32, setModalState),
                        const SizedBox(width: 8),
                        _buildParticipantChip(64, setModalState),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Dates
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              await _selectDate(context, true);
                              setModalState(() {});
                            },
                            child: AbsorbPointer(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: _startDate != null
                                      ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                                      : 'Start Date *',
                                  prefixIcon: const Icon(Icons.calendar_today),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              await _selectDate(context, false);
                              setModalState(() {});
                            },
                            child: AbsorbPointer(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: _endDate != null
                                      ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                                      : 'End Date *',
                                  prefixIcon: const Icon(Icons.event),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_nameController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter tournament name'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            return;
                          }
                          if (_startDate == null || _endDate == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select start and end dates'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            return;
                          }

                          try {
                            await _firestoreService.createTournament(
                              name: _nameController.text.trim(),
                              description: _descriptionController.text.trim(),
                              startDate: _startDate!,
                              endDate: _endDate!,
                              prizePool: _prizeController.text.trim().isEmpty
                                  ? 'TBD'
                                  : _prizeController.text.trim(),
                              type: _selectedType,
                              venue: _venueController.text.trim(),
                              maxParticipants: _maxParticipants,
                            );
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Tournament created successfully!'),
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
                        },
                        child: const Text('Create Tournament'),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTypeChip(String label, TournamentType type, StateSetter setModalState) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () {
        setModalState(() {
          _selectedType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.accentGradient : null,
          color: isSelected ? null : AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.darkBackground : AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildParticipantChip(int count, StateSetter setModalState) {
    final isSelected = _maxParticipants == count;
    return GestureDetector(
      onTap: () {
        setModalState(() {
          _maxParticipants = count;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.accentGradient : null,
          color: isSelected ? null : AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        ),
        child: Text(
          count.toString(),
          style: TextStyle(
            color: isSelected ? AppColors.darkBackground : AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
