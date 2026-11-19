import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/player_model.dart';
import '../models/match_model.dart';
import '../models/tournament_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  // ==================== PLAYERS ====================

  // Get all players
  Stream<List<PlayerModel>> getPlayers() {
    return _firestore
        .collection('players')
        .orderBy('points', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PlayerModel.fromFirestore(doc))
            .toList());
  }

  // Get leaderboard (top players)
  Stream<List<PlayerModel>> getLeaderboard({int limit = 50}) {
    return _firestore
        .collection('players')
        .orderBy('points', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PlayerModel.fromFirestore(doc))
            .toList());
  }

  // Get single player
  Future<PlayerModel?> getPlayer(String playerId) async {
    final doc = await _firestore.collection('players').doc(playerId).get();
    if (doc.exists) {
      return PlayerModel.fromFirestore(doc);
    }
    return null;
  }

  // Create guest player
  Future<PlayerModel> createGuestPlayer(String name) async {
    final docRef = _firestore.collection('players').doc();
    final player = PlayerModel(
      id: docRef.id,
      name: name,
      avatar: _getInitials(name),
      isGuest: true,
      wins: 0,
      losses: 0,
      points: 0,
      matchesPlayed: 0,
    );

    await docRef.set(player.toFirestore());
    return player;
  }

  // Update player stats after match
  Future<void> updatePlayerStats({
    required String playerId,
    required bool isWinner,
    int pointsEarned = 0,
  }) async {
    final playerRef = _firestore.collection('players').doc(playerId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(playerRef);
      if (!snapshot.exists) return;

      final currentWins = snapshot.data()?['wins'] ?? 0;
      final currentLosses = snapshot.data()?['losses'] ?? 0;
      final currentPoints = snapshot.data()?['points'] ?? 0;
      final currentMatches = snapshot.data()?['matchesPlayed'] ?? 0;

      transaction.update(playerRef, {
        'wins': isWinner ? currentWins + 1 : currentWins,
        'losses': isWinner ? currentLosses : currentLosses + 1,
        'points': currentPoints + pointsEarned,
        'matchesPlayed': currentMatches + 1,
      });
    });
  }

  // ==================== MATCHES ====================

  // Create new match
  Future<MatchModel> createMatch({
    required String matchType,
    required List<String> teamAIds,
    required List<String> teamBIds,
    required String teamANames,
    required String teamBNames,
  }) async {
    final docRef = _firestore.collection('matches').doc();

    final match = MatchModel(
      id: docRef.id,
      matchType: matchType,
      teamAIds: teamAIds,
      teamBIds: teamBIds,
      teamANames: teamANames,
      teamBNames: teamBNames,
      scores: [SetScore(teamAScore: 0, teamBScore: 0)],
      currentSet: 1,
      status: MatchStatus.live,
      createdBy: _currentUserId ?? '',
      createdAt: DateTime.now(),
    );

    await docRef.set(match.toFirestore());
    return match;
  }

  // Get live matches
  Stream<List<MatchModel>> getLiveMatches() {
    return _firestore
        .collection('matches')
        .where('status', isEqualTo: 'live')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MatchModel.fromFirestore(doc))
            .toList());
  }

  // Get recent matches
  Stream<List<MatchModel>> getRecentMatches({int limit = 20}) {
    return _firestore
        .collection('matches')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MatchModel.fromFirestore(doc))
            .toList());
  }

  // Get match by ID
  Stream<MatchModel?> getMatch(String matchId) {
    return _firestore
        .collection('matches')
        .doc(matchId)
        .snapshots()
        .map((doc) => doc.exists ? MatchModel.fromFirestore(doc) : null);
  }

  // Update match score
  Future<void> updateMatchScore({
    required String matchId,
    required int setIndex,
    required int teamAScore,
    required int teamBScore,
  }) async {
    final matchRef = _firestore.collection('matches').doc(matchId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(matchRef);
      if (!snapshot.exists) return;

      final scores = List<Map<String, dynamic>>.from(snapshot.data()?['scores'] ?? []);

      // Update or add score for the set
      while (scores.length <= setIndex) {
        scores.add({'teamAScore': 0, 'teamBScore': 0});
      }

      scores[setIndex] = {
        'teamAScore': teamAScore,
        'teamBScore': teamBScore,
      };

      transaction.update(matchRef, {'scores': scores});
    });
  }

  // Complete match
  Future<void> completeMatch({
    required String matchId,
    required String winner,
    required List<SetScore> finalScores,
  }) async {
    final matchRef = _firestore.collection('matches').doc(matchId);

    await matchRef.update({
      'status': 'completed',
      'winner': winner,
      'scores': finalScores.map((s) => s.toMap()).toList(),
      'completedAt': FieldValue.serverTimestamp(),
    });

    // Get match data to update player stats
    final matchDoc = await matchRef.get();
    if (matchDoc.exists) {
      final data = matchDoc.data()!;
      final teamAIds = List<String>.from(data['teamAIds'] ?? []);
      final teamBIds = List<String>.from(data['teamBIds'] ?? []);

      // Update player stats
      final winnerIds = winner == 'teamA' ? teamAIds : teamBIds;
      final loserIds = winner == 'teamA' ? teamBIds : teamAIds;

      for (final playerId in winnerIds) {
        await updatePlayerStats(
          playerId: playerId,
          isWinner: true,
          pointsEarned: 10,
        );
      }

      for (final playerId in loserIds) {
        await updatePlayerStats(
          playerId: playerId,
          isWinner: false,
          pointsEarned: 2,
        );
      }
    }
  }

  // Start new set
  Future<void> startNewSet(String matchId) async {
    final matchRef = _firestore.collection('matches').doc(matchId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(matchRef);
      if (!snapshot.exists) return;

      final currentSet = snapshot.data()?['currentSet'] ?? 1;
      final scores = List<Map<String, dynamic>>.from(snapshot.data()?['scores'] ?? []);

      scores.add({'teamAScore': 0, 'teamBScore': 0});

      transaction.update(matchRef, {
        'currentSet': currentSet + 1,
        'scores': scores,
      });
    });
  }

  // ==================== TOURNAMENTS ====================

  // Create tournament
  Future<TournamentModel> createTournament({
    required String name,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    required String prizePool,
    TournamentType type = TournamentType.singles,
    String venue = '',
    int maxParticipants = 16,
  }) async {
    final docRef = _firestore.collection('tournaments').doc();

    final tournament = TournamentModel(
      id: docRef.id,
      name: name,
      description: description,
      startDate: startDate,
      endDate: endDate,
      prizePool: prizePool,
      status: TournamentStatus.upcoming,
      type: type,
      venue: venue,
      maxParticipants: maxParticipants,
      participants: [],
      createdBy: _currentUserId ?? '',
      createdAt: DateTime.now(),
    );

    await docRef.set(tournament.toFirestore());
    return tournament;
  }

  // Update tournament
  Future<void> updateTournament({
    required String tournamentId,
    String? name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? prizePool,
    TournamentType? type,
    String? venue,
    int? maxParticipants,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (startDate != null) updates['startDate'] = Timestamp.fromDate(startDate);
    if (endDate != null) updates['endDate'] = Timestamp.fromDate(endDate);
    if (prizePool != null) updates['prizePool'] = prizePool;
    if (type != null) updates['type'] = type.name;
    if (venue != null) updates['venue'] = venue;
    if (maxParticipants != null) updates['maxParticipants'] = maxParticipants;

    if (updates.isNotEmpty) {
      await _firestore.collection('tournaments').doc(tournamentId).update(updates);
    }
  }

  // Delete tournament
  Future<void> deleteTournament(String tournamentId) async {
    await _firestore.collection('tournaments').doc(tournamentId).delete();
  }

  // Add participant to tournament
  Future<void> addParticipant(String tournamentId, String participantName) async {
    await _firestore.collection('tournaments').doc(tournamentId).update({
      'participants': FieldValue.arrayUnion([participantName]),
    });
  }

  // Remove participant from tournament
  Future<void> removeParticipant(String tournamentId, String participantName) async {
    await _firestore.collection('tournaments').doc(tournamentId).update({
      'participants': FieldValue.arrayRemove([participantName]),
    });
  }

  // Get tournaments by status
  Stream<List<TournamentModel>> getTournaments({TournamentStatus? status}) {
    Query query = _firestore.collection('tournaments');

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    return query
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TournamentModel.fromFirestore(doc))
            .toList());
  }

  // Get single tournament
  Stream<TournamentModel?> getTournament(String tournamentId) {
    return _firestore
        .collection('tournaments')
        .doc(tournamentId)
        .snapshots()
        .map((doc) => doc.exists ? TournamentModel.fromFirestore(doc) : null);
  }

  // Join tournament
  Future<void> joinTournament(String tournamentId, String playerId) async {
    await _firestore.collection('tournaments').doc(tournamentId).update({
      'participants': FieldValue.arrayUnion([playerId]),
    });
  }

  // Update tournament status
  Future<void> updateTournamentStatus(
    String tournamentId,
    TournamentStatus status,
  ) async {
    await _firestore.collection('tournaments').doc(tournamentId).update({
      'status': status.name,
    });
  }

  // Set tournament winner
  Future<void> setTournamentWinner(String tournamentId, String winnerId) async {
    await _firestore.collection('tournaments').doc(tournamentId).update({
      'winner': winnerId,
      'status': 'completed',
    });
  }

  // Update tournament bracket
  Future<void> updateTournamentBracket(
    String tournamentId,
    Map<String, dynamic> bracket,
  ) async {
    await _firestore.collection('tournaments').doc(tournamentId).update({
      'bracket': bracket,
    });
  }

  // Update bracket match result
  Future<void> updateBracketMatch({
    required String tournamentId,
    required String matchId,
    required String winner,
    int? score1,
    int? score2,
  }) async {
    final tournamentRef = _firestore.collection('tournaments').doc(tournamentId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(tournamentRef);
      if (!snapshot.exists) return;

      final bracket = Map<String, dynamic>.from(snapshot.data()?['bracket'] ?? {});
      final matches = List<Map<String, dynamic>>.from(bracket['matches'] ?? []);

      // Find and update the match
      for (var i = 0; i < matches.length; i++) {
        if (matches[i]['id'] == matchId) {
          matches[i]['winner'] = winner;
          if (score1 != null) matches[i]['score1'] = score1;
          if (score2 != null) matches[i]['score2'] = score2;

          // Advance winner to next round
          final currentRound = matches[i]['round'] as int;
          final currentPosition = matches[i]['position'] as int;
          final nextRound = currentRound + 1;
          final nextPosition = currentPosition ~/ 2;

          // Find next round match and update player
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
      transaction.update(tournamentRef, {'bracket': bracket});
    });
  }

  // ==================== USER PROFILE ====================

  // Get current user profile
  Stream<Map<String, dynamic>?> getCurrentUserProfile() {
    if (_currentUserId == null) return Stream.value(null);

    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .snapshots()
        .map((doc) => doc.data());
  }

  // Get user's match history
  Stream<List<MatchModel>> getUserMatchHistory(String userId) {
    return _firestore
        .collection('matches')
        .where('status', isEqualTo: 'completed')
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MatchModel.fromFirestore(doc))
            .where((match) =>
                match.teamAIds.contains(userId) ||
                match.teamBIds.contains(userId))
            .toList());
  }

  // ==================== HELPERS ====================

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'G';
  }
}
