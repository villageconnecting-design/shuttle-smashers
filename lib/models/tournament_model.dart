import 'package:cloud_firestore/cloud_firestore.dart';

enum TournamentStatus { upcoming, live, completed, cancelled }

enum TournamentType { singles, doubles, mixed }

class TournamentModel {
  final String id;
  final String name;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String prizePool;
  final TournamentStatus status;
  final TournamentType type;
  final String venue;
  final int maxParticipants;
  final List<String> participants;
  final Map<String, dynamic>? bracket;
  final String? winner;
  final String createdBy;
  final DateTime createdAt;

  TournamentModel({
    required this.id,
    required this.name,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.prizePool,
    required this.status,
    this.type = TournamentType.singles,
    this.venue = '',
    this.maxParticipants = 16,
    required this.participants,
    this.bracket,
    this.winner,
    required this.createdBy,
    required this.createdAt,
  });

  // Get participant count
  int get participantCount => participants.length;

  // Check status
  bool get isUpcoming => status == TournamentStatus.upcoming;
  bool get isLive => status == TournamentStatus.live;
  bool get isCompleted => status == TournamentStatus.completed;

  // Get status display text
  String get statusText {
    switch (status) {
      case TournamentStatus.upcoming:
        return 'Upcoming';
      case TournamentStatus.live:
        return 'Live';
      case TournamentStatus.completed:
        return 'Completed';
      case TournamentStatus.cancelled:
        return 'Cancelled';
    }
  }

  // Get type display text
  String get typeText {
    switch (type) {
      case TournamentType.singles:
        return 'Singles';
      case TournamentType.doubles:
        return 'Doubles';
      case TournamentType.mixed:
        return 'Mixed Doubles';
    }
  }

  // Check if tournament is full
  bool get isFull => participants.length >= maxParticipants;

  // Get available slots
  int get availableSlots => maxParticipants - participants.length;

  // Format date range
  String get dateRange {
    final startFormatted =
        '${startDate.day}/${startDate.month}/${startDate.year}';
    final endFormatted = '${endDate.day}/${endDate.month}/${endDate.year}';
    return '$startFormatted - $endFormatted';
  }

  // Create from Firestore document
  factory TournamentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return TournamentModel(
      id: doc.id,
      name: data['name'] ?? 'Tournament',
      description: data['description'] ?? '',
      startDate:
          (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      prizePool: data['prizePool'] ?? '0',
      status: _parseStatus(data['status']),
      type: _parseType(data['type']),
      venue: data['venue'] ?? '',
      maxParticipants: data['maxParticipants'] ?? 16,
      participants: List<String>.from(data['participants'] ?? []),
      bracket: data['bracket'] as Map<String, dynamic>?,
      winner: data['winner'],
      createdBy: data['createdBy'] ?? '',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static TournamentStatus _parseStatus(String? status) {
    switch (status) {
      case 'upcoming':
        return TournamentStatus.upcoming;
      case 'live':
        return TournamentStatus.live;
      case 'completed':
        return TournamentStatus.completed;
      case 'cancelled':
        return TournamentStatus.cancelled;
      default:
        return TournamentStatus.upcoming;
    }
  }

  static TournamentType _parseType(String? type) {
    switch (type) {
      case 'singles':
        return TournamentType.singles;
      case 'doubles':
        return TournamentType.doubles;
      case 'mixed':
        return TournamentType.mixed;
      default:
        return TournamentType.singles;
    }
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'prizePool': prizePool,
      'status': status.name,
      'type': type.name,
      'venue': venue,
      'maxParticipants': maxParticipants,
      'participants': participants,
      'bracket': bracket,
      'winner': winner,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Copy with method
  TournamentModel copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? prizePool,
    TournamentStatus? status,
    TournamentType? type,
    String? venue,
    int? maxParticipants,
    List<String>? participants,
    Map<String, dynamic>? bracket,
    String? winner,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return TournamentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      prizePool: prizePool ?? this.prizePool,
      status: status ?? this.status,
      type: type ?? this.type,
      venue: venue ?? this.venue,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      participants: participants ?? this.participants,
      bracket: bracket ?? this.bracket,
      winner: winner ?? this.winner,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'TournamentModel(id: $id, name: $name, status: $status)';
  }
}
