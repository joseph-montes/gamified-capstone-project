import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────
//  Rank Titles (Gamification tiers)
// ─────────────────────────────────────────────
const List<String> _rankTitles = [
  'Novice Learner', // Level 1–4
  'Apprentice', // Level 5–9
  'Scholar', // Level 10–14
  'Expert', // Level 15–19
  'Master', // Level 20–29
  'Grand Master', // Level 30–39
  'Legend', // Level 40+
];

String _rankFromLevel(int level) {
  if (level < 5) return _rankTitles[0];
  if (level < 10) return _rankTitles[1];
  if (level < 15) return _rankTitles[2];
  if (level < 20) return _rankTitles[3];
  if (level < 30) return _rankTitles[4];
  if (level < 40) return _rankTitles[5];
  return _rankTitles[6];
}

// ─────────────────────────────────────────────
//  UserModel
// ─────────────────────────────────────────────
class UserModel extends ChangeNotifier {
  // ── Core Identity ─────────────────────────
  String uid = '';
  String email = '';
  String username = '';
  String fullName = '';
  String studentId = '';
  String yearLevel = '';
  String motto = ''; // User's personal catchphrase or bio
  String photoUrl = ''; // Cloud Storage download URL

  // ── Gamification Stats ────────────────────
  int level = 1;
  int currentXP = 0;
  int coins = 0;
  int streakDays = 0;
  int totalLessonsCompleted = 0;
  int totalQuizzesCompleted = 0;
  List<String> earnedBadgeIds = [];
  List<String> completedChallengeIds = []; // track challenge history

  // ── Timestamps ────────────────────────────
  DateTime? lastLoginDate;
  DateTime? createdAt;
  DateTime? lastPhotoChangeDate; // for 7-day photo cooldown

  // ─────────────────────────────────────────
  //  Computed Properties
  // ─────────────────────────────────────────

  int get nextLevelXP => (level * 250) + 50;

  double get xpProgress =>
      nextLevelXP > 0 ? (currentXP / nextLevelXP).clamp(0.0, 1.0) : 0.0;

  String get displayName =>
      username.isNotEmpty ? username : email.split('@').first;

  String get displayInitials {
    final name = fullName.isNotEmpty ? fullName : displayName;
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String get rankTitle => _rankFromLevel(level);

  int get totalXP => _totalXPForLevel(level) + currentXP;

  /// Whether the 7-day photo-change cooldown has passed.
  bool get canChangePhoto {
    if (lastPhotoChangeDate == null) return true;
    return DateTime.now().difference(lastPhotoChangeDate!).inDays >= 7;
  }

  /// Days remaining until photo can be changed again (0 if allowed).
  int get daysUntilPhotoChange {
    if (canChangePhoto) return 0;
    final elapsed = DateTime.now().difference(lastPhotoChangeDate!).inDays;
    return (7 - elapsed).clamp(0, 7);
  }

  // ─────────────────────────────────────────
  //  Mutations
  // ─────────────────────────────────────────

  void fromMap(Map<String, dynamic> data, String userId) {
    uid = userId;
    email = data['email'] as String? ?? '';
    username = data['username'] as String? ?? '';
    fullName = data['fullName'] as String? ?? '';
    studentId = data['studentId'] as String? ?? '';
    yearLevel = data['yearLevel'] as String? ?? '';
    motto = data['motto'] as String? ?? '';
    photoUrl = data['photoUrl'] as String? ?? '';
    level = (data['level'] as num?)?.toInt() ?? 1;
    currentXP = (data['currentXP'] as num?)?.toInt() ?? 0;
    coins = (data['coins'] as num?)?.toInt() ?? 0;
    streakDays = (data['streakDays'] as num?)?.toInt() ?? 0;
    totalLessonsCompleted = (data['totalLessonsCompleted'] as num?)?.toInt() ?? 0;
    totalQuizzesCompleted = (data['totalQuizzesCompleted'] as num?)?.toInt() ?? 0;
    earnedBadgeIds = List<String>.from(data['earnedBadgeIds'] as List? ?? []);
    completedChallengeIds =
        List<String>.from(data['completedChallengeIds'] as List? ?? []);

    final lastLoginTs = data['lastLoginDate'];
    if (lastLoginTs != null) {
      lastLoginDate = DateTime.tryParse(lastLoginTs.toString());
    }
    final createdTs = data['createdAt'];
    if (createdTs != null) {
      createdAt = DateTime.tryParse(createdTs.toString());
    }
    final photoTs = data['lastPhotoChangeDate'];
    if (photoTs != null) {
      lastPhotoChangeDate = DateTime.tryParse(photoTs.toString());
    }

    notifyListeners();
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'username': username,
      'fullName': fullName,
      'studentId': studentId,
      'yearLevel': yearLevel,
      'motto': motto,
      'photoUrl': photoUrl,
      'level': level,
      'currentXP': currentXP,
      'coins': coins,
      'streakDays': streakDays,
      'totalLessonsCompleted': totalLessonsCompleted,
      'totalQuizzesCompleted': totalQuizzesCompleted,
      'earnedBadgeIds': earnedBadgeIds,
      'completedChallengeIds': completedChallengeIds,
      'lastLoginDate': lastLoginDate?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'lastPhotoChangeDate': lastPhotoChangeDate?.toIso8601String(),
    };
  }

  // ── XP & Level Logic ──────────────────────
  int addXP(int amount) {
    int levelsGained = 0;
    currentXP += amount;
    while (currentXP >= nextLevelXP) {
      currentXP -= nextLevelXP;
      level++;
      levelsGained++;
      coins += 25;
    }
    notifyListeners();
    return levelsGained;
  }

  /// Deducts [penalty] XP without dropping below 0 or causing a level drop.
  void applyXPPenalty(int penalty) {
    currentXP -= penalty;
    if (currentXP < 0) currentXP = 0;
    notifyListeners();
  }

  bool spendCoins(int amount) {
    if (coins < amount) return false;
    coins -= amount;
    notifyListeners();
    return true;
  }

  void updateStreak() {
    final now = DateTime.now();
    if (lastLoginDate == null) {
      streakDays = 1;
    } else {
      final diff = now.difference(lastLoginDate!).inDays;
      if (diff == 1) {
        streakDays++;
      } else if (diff > 1) {
        streakDays = 1;
      }
    }
    lastLoginDate = now;
    notifyListeners();
  }

  bool unlockBadge(String badgeId) {
    if (earnedBadgeIds.contains(badgeId)) return false;
    earnedBadgeIds.add(badgeId);
    notifyListeners();
    return true;
  }

  bool markChallengeCompleted(String challengeId) {
    if (completedChallengeIds.contains(challengeId)) return false;
    completedChallengeIds.add(challengeId);
    totalQuizzesCompleted++;
    notifyListeners();
    return true;
  }

  void addPhotoUrl(String url) {
    photoUrl = url;
    lastPhotoChangeDate = DateTime.now();
    notifyListeners();
  }

  void clear() {
    uid = '';
    email = '';
    username = '';
    fullName = '';
    studentId = '';
    yearLevel = '';
    motto = '';
    photoUrl = '';
    level = 1;
    currentXP = 0;
    coins = 0;
    streakDays = 0;
    totalLessonsCompleted = 0;
    totalQuizzesCompleted = 0;
    earnedBadgeIds = [];
    completedChallengeIds = [];
    lastLoginDate = null;
    createdAt = null;
    lastPhotoChangeDate = null;
    notifyListeners();
  }

  // ─────────────────────────────────────────
  int _totalXPForLevel(int targetLevel) {
    return (targetLevel - 1) * targetLevel * 50;
  }
}
