/// Dummy data for UI development
class DummyData {
  // Players
  static final List<Map<String, dynamic>> players = [
    {
      'id': '1',
      'name': 'Rahul Sharma',
      'avatar': 'RS',
      'wins': 45,
      'matches': 52,
      'points': 1250,
      'rank': 1,
    },
    {
      'id': '2',
      'name': 'Priya Patel',
      'avatar': 'PP',
      'wins': 38,
      'matches': 48,
      'points': 1100,
      'rank': 2,
    },
    {
      'id': '3',
      'name': 'Amit Kumar',
      'avatar': 'AK',
      'wins': 35,
      'matches': 45,
      'points': 980,
      'rank': 3,
    },
    {
      'id': '4',
      'name': 'Sneha Reddy',
      'avatar': 'SR',
      'wins': 32,
      'matches': 42,
      'points': 920,
      'rank': 4,
    },
    {
      'id': '5',
      'name': 'Vikram Singh',
      'avatar': 'VS',
      'wins': 30,
      'matches': 40,
      'points': 850,
      'rank': 5,
    },
    {
      'id': '6',
      'name': 'Ananya Gupta',
      'avatar': 'AG',
      'wins': 28,
      'matches': 38,
      'points': 780,
      'rank': 6,
    },
  ];

  // Live matches
  static final List<Map<String, dynamic>> liveMatches = [
    {
      'id': '1',
      'teamA': 'Rahul S.',
      'teamB': 'Amit K.',
      'scoreA': 18,
      'scoreB': 15,
      'set': 2,
      'type': 'Singles',
      'isLive': true,
    },
    {
      'id': '2',
      'teamA': 'Priya & Sneha',
      'teamB': 'Ananya & Vikram',
      'scoreA': 12,
      'scoreB': 14,
      'set': 1,
      'type': 'Doubles',
      'isLive': true,
    },
  ];

  // Upcoming matches
  static final List<Map<String, dynamic>> upcomingMatches = [
    {
      'id': '3',
      'teamA': 'Vikram S.',
      'teamB': 'Rahul S.',
      'time': '3:00 PM',
      'date': 'Today',
      'type': 'Singles',
      'venue': 'Court 1',
    },
    {
      'id': '4',
      'teamA': 'Team Alpha',
      'teamB': 'Team Beta',
      'time': '5:30 PM',
      'date': 'Today',
      'type': 'Doubles',
      'venue': 'Court 2',
    },
    {
      'id': '5',
      'teamA': 'Sneha R.',
      'teamB': 'Priya P.',
      'time': '10:00 AM',
      'date': 'Tomorrow',
      'type': 'Singles',
      'venue': 'Court 1',
    },
  ];

  // Match history
  static final List<Map<String, dynamic>> matchHistory = [
    {
      'id': '10',
      'teamA': 'Rahul S.',
      'teamB': 'Vikram S.',
      'scoreA': '21-19, 21-18',
      'scoreB': '',
      'winner': 'Rahul S.',
      'date': '28 Apr 2026',
      'type': 'Singles',
    },
    {
      'id': '11',
      'teamA': 'Priya P.',
      'teamB': 'Sneha R.',
      'scoreA': '21-15, 18-21, 21-17',
      'scoreB': '',
      'winner': 'Priya P.',
      'date': '27 Apr 2026',
      'type': 'Singles',
    },
    {
      'id': '12',
      'teamA': 'Team Alpha',
      'teamB': 'Team Beta',
      'scoreA': '21-18, 21-20',
      'scoreB': '',
      'winner': 'Team Alpha',
      'date': '26 Apr 2026',
      'type': 'Doubles',
    },
  ];

  // Tournaments
  static final List<Map<String, dynamic>> tournaments = [
    {
      'id': '1',
      'name': 'Spring Championship 2026',
      'type': 'Singles & Doubles',
      'players': 32,
      'status': 'Live',
      'startDate': '25 Apr 2026',
      'endDate': '30 Apr 2026',
      'prize': '50,000',
    },
    {
      'id': '2',
      'name': 'Corporate League',
      'type': 'Doubles',
      'players': 24,
      'status': 'Upcoming',
      'startDate': '5 May 2026',
      'endDate': '10 May 2026',
      'prize': '30,000',
    },
    {
      'id': '3',
      'name': 'Weekend Warriors',
      'type': 'Singles',
      'players': 16,
      'status': 'Completed',
      'startDate': '15 Apr 2026',
      'endDate': '20 Apr 2026',
      'prize': '25,000',
      'winner': 'Rahul Sharma',
    },
  ];

  // Tournament brackets (simplified)
  static final List<Map<String, dynamic>> brackets = [
    {
      'round': 'Quarter Finals',
      'matches': [
        {'teamA': 'Rahul S.', 'teamB': 'Player 8', 'scoreA': 21, 'scoreB': 15, 'winner': 'Rahul S.'},
        {'teamA': 'Priya P.', 'teamB': 'Player 7', 'scoreA': 21, 'scoreB': 18, 'winner': 'Priya P.'},
        {'teamA': 'Amit K.', 'teamB': 'Player 6', 'scoreA': 21, 'scoreB': 19, 'winner': 'Amit K.'},
        {'teamA': 'Sneha R.', 'teamB': 'Player 5', 'scoreA': 21, 'scoreB': 12, 'winner': 'Sneha R.'},
      ],
    },
    {
      'round': 'Semi Finals',
      'matches': [
        {'teamA': 'Rahul S.', 'teamB': 'Priya P.', 'scoreA': 21, 'scoreB': 17, 'winner': 'Rahul S.'},
        {'teamA': 'Amit K.', 'teamB': 'Sneha R.', 'scoreA': 19, 'scoreB': 21, 'winner': 'Sneha R.'},
      ],
    },
    {
      'round': 'Finals',
      'matches': [
        {'teamA': 'Rahul S.', 'teamB': 'Sneha R.', 'scoreA': 21, 'scoreB': 18, 'winner': 'Rahul S.'},
      ],
    },
  ];
}
