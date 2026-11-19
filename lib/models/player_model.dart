import 'package:cloud_firestore/cloud_firestore.dart';

class PlayerModel {
  final String id;
  final String name;
  final String avatar;
  final bool isGuest;
  final int wins;
  final int losses;
  final int points;
  final int matchesPlayed;
  final DateTime? createdAt;

  PlayerModel({
    required this.id,
    required this.name,
    required this.avatar,
    this.isGuest = false,
    this.wins = 0,
    this.losses = 0,
    this.points = 0,
    this.matchesPlayed = 0,
    this.createdAt,
  });

  // Calculate win rate
  double get winRate {
    if (matchesPlayed == 0) return 0;
    return (wins / matchesPlayed) * 100;
  }

  // Create from Firestore document
  factory PlayerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PlayerModel(
      id: doc.id,
      name: data['name'] ?? 'Unknown',
      avatar: data['avatar'] ?? 'P',
      isGuest: data['isGuest'] ?? false,
      wins: data['wins'] ?? 0,
      losses: data['losses'] ?? 0,
      points: data['points'] ?? 0,
      matchesPlayed: data['matchesPlayed'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  // Create from Map (for local use)
  factory PlayerModel.fromMap(Map<String, dynamic> data) {
    return PlayerModel(
      id: data['id'] ?? '',
      name: data['name'] ?? 'Unknown',
      avatar: data['avatar'] ?? 'P',
      isGuest: data['isGuest'] ?? false,
      wins: data['wins'] ?? 0,
      losses: data['losses'] ?? 0,
      points: data['points'] ?? 0,
      matchesPlayed: data['matchesPlayed'] ?? 0,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'avatar': avatar,
      'isGuest': isGuest,
      'wins': wins,
      'losses': losses,
      'points': points,
      'matchesPlayed': matchesPlayed,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  // Copy with method for updates
  PlayerModel copyWith({
    String? id,
    String? name,
    String? avatar,
    bool? isGuest,
    int? wins,
    int? losses,
    int? points,
    int? matchesPlayed,
    DateTime? createdAt,
  }) {
    return PlayerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      isGuest: isGuest ?? this.isGuest,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      points: points ?? this.points,
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'PlayerModel(id: $id, name: $name, wins: $wins, points: $points)';
  }
}
