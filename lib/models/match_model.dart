import 'package:cloud_firestore/cloud_firestore.dart';

enum MatchStatus { live, completed, cancelled }

class SetScore {
  final int teamAScore;
  final int teamBScore;

  SetScore({
    required this.teamAScore,
    required this.teamBScore,
  });

  factory SetScore.fromMap(Map<String, dynamic> data) {
    return SetScore(
      teamAScore: data['teamAScore'] ?? 0,
      teamBScore: data['teamBScore'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'teamAScore': teamAScore,
      'teamBScore': teamBScore,
    };
  }

  SetScore copyWith({int? teamAScore, int? teamBScore}) {
    return SetScore(
      teamAScore: teamAScore ?? this.teamAScore,
      teamBScore: teamBScore ?? this.teamBScore,
    );
  }

  // Check if this set is complete (first to 21 with 2 point lead, max 30)
  bool get isComplete {
    if (teamAScore >= 21 || teamBScore >= 21) {
      if ((teamAScore - teamBScore).abs() >= 2) return true;
    }
    if (teamAScore >= 30 || teamBScore >= 30) return true;
    return false;
  }

  // Get winner of this set (null if not complete)
  String? get winner {
    if (!isComplete) return null;
    return teamAScore > teamBScore ? 'teamA' : 'teamB';
  }
}

class MatchModel {
  final String id;
  final String matchType; // Singles, Doubles, Mixed Doubles
  final List<String> teamAIds;
  final List<String> teamBIds;
  final String teamANames;
  final String teamBNames;
  final List<SetScore> scores;
  final int currentSet;
  final MatchStatus status;
  final String? winner;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? tournamentId;

  MatchModel({
    required this.id,
    required this.matchType,
    required this.teamAIds,
    required this.teamBIds,
    required this.teamANames,
    required this.teamBNames,
    required this.scores,
    required this.currentSet,
    required this.status,
    this.winner,
    required this.createdBy,
    required this.createdAt,
    this.completedAt,
    this.tournamentId,
  });

  // Get current set score
  SetScore get currentSetScore {
    if (scores.isEmpty) return SetScore(teamAScore: 0, teamBScore: 0);
    return scores[currentSet - 1];
  }

  // Get sets won by each team
  int get teamASetsWon => scores.where((s) => s.winner == 'teamA').length;
  int get teamBSetsWon => scores.where((s) => s.winner == 'teamB').length;

  // Check if match is live
  bool get isLive => status == MatchStatus.live;

  // Check if match is completed
  bool get isCompleted => status == MatchStatus.completed;

  // Create from Firestore document
  factory MatchModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return MatchModel(
      id: doc.id,
      matchType: data['matchType'] ?? 'Singles',
      teamAIds: List<String>.from(data['teamAIds'] ?? []),
      teamBIds: List<String>.from(data['teamBIds'] ?? []),
      teamANames: data['teamANames'] ?? 'Team A',
      teamBNames: data['teamBNames'] ?? 'Team B',
      scores: (data['scores'] as List<dynamic>?)
              ?.map((s) => SetScore.fromMap(s as Map<String, dynamic>))
              .toList() ??
          [SetScore(teamAScore: 0, teamBScore: 0)],
      currentSet: data['currentSet'] ?? 1,
      status: _parseStatus(data['status']),
      winner: data['winner'],
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      tournamentId: data['tournamentId'],
    );
  }

  static MatchStatus _parseStatus(String? status) {
    switch (status) {
      case 'live':
        return MatchStatus.live;
      case 'completed':
        return MatchStatus.completed;
      case 'cancelled':
        return MatchStatus.cancelled;
      default:
        return MatchStatus.live;
    }
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'matchType': matchType,
      'teamAIds': teamAIds,
      'teamBIds': teamBIds,
      'teamANames': teamANames,
      'teamBNames': teamBNames,
      'scores': scores.map((s) => s.toMap()).toList(),
      'currentSet': currentSet,
      'status': status.name,
      'winner': winner,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'tournamentId': tournamentId,
    };
  }

  // Copy with method
  MatchModel copyWith({
    String? id,
    String? matchType,
    List<String>? teamAIds,
    List<String>? teamBIds,
    String? teamANames,
    String? teamBNames,
    List<SetScore>? scores,
    int? currentSet,
    MatchStatus? status,
    String? winner,
    String? createdBy,
    DateTime? createdAt,
    DateTime? completedAt,
    String? tournamentId,
  }) {
    return MatchModel(
      id: id ?? this.id,
      matchType: matchType ?? this.matchType,
      teamAIds: teamAIds ?? this.teamAIds,
      teamBIds: teamBIds ?? this.teamBIds,
      teamANames: teamANames ?? this.teamANames,
      teamBNames: teamBNames ?? this.teamBNames,
      scores: scores ?? this.scores,
      currentSet: currentSet ?? this.currentSet,
      status: status ?? this.status,
      winner: winner ?? this.winner,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      tournamentId: tournamentId ?? this.tournamentId,
    );
  }

  @override
  String toString() {
    return 'MatchModel(id: $id, $teamANames vs $teamBNames, status: $status)';
  }
}
