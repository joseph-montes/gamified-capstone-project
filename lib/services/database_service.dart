import 'dart:async';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user_model.dart';
import '../models/challenge_model.dart';

// ─────────────────────────────────────────────
//  DatabaseService (Firebase Version)
// ─────────────────────────────────────────────
class DatabaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── Auth Actions ──────────────────────────
  Future<void> signOut() async => await _auth.signOut();

  // ── Register ──────────────────────────────
  Future<void> registerUser({
    required String email,
    required String password,
    required UserModel userModel,
    String? fullName,
    String? studentId,
    String? yearLevel,
  }) async {
    final UserCredential cred = await _auth
        .createUserWithEmailAndPassword(email: email, password: password)
        .timeout(
          const Duration(seconds: 8),
          onTimeout: () =>
              throw TimeoutException('AUTH_TIMEOUT: Authentication server hung.'),
        );

    final String uid = cred.user!.uid;
    final now = DateTime.now().toIso8601String();

    final Map<String, dynamic> userData = {
      'email': email,
      'fullName': fullName ?? email.split('@').first,
      'studentId': studentId ?? 'CEC-0000',
      'yearLevel': yearLevel ?? '1st Year',
      'photoUrl': '',
      'level': 1,
      'currentXP': 0,
      'coins': 100,
      'streakDays': 1,
      'totalLessonsCompleted': 0,
      'totalQuizzesCompleted': 0,
      'earnedBadgeIds': <String>[],
      'lastLoginDate': now,
      'createdAt': now,
    };

    await _firestore.collection('users').doc(uid).set(userData).timeout(
          const Duration(seconds: 8),
          onTimeout: () => throw TimeoutException(
              'FIRESTORE_TIMEOUT: Database server hung. Have you clicked "Create Database" in Firebase?'),
        );

    userModel.fromMap(userData, uid);
  }

  // ── Login ─────────────────────────────────
  Future<void> loginUser({
    required String email,
    required String password,
    required UserModel userModel,
  }) async {
    final UserCredential cred = await _auth
        .signInWithEmailAndPassword(email: email, password: password)
        .timeout(
          const Duration(seconds: 8),
          onTimeout: () =>
              throw TimeoutException('AUTH_TIMEOUT: Authentication server hung.'),
        );

    final String uid = cred.user!.uid;
    final doc = await _firestore.collection('users').doc(uid).get().timeout(
          const Duration(seconds: 8),
          onTimeout: () => throw TimeoutException(
              'FIRESTORE_TIMEOUT: Database hung. Have you created your Firestore Database?'),
        );

    if (doc.exists) {
      userModel.fromMap(doc.data()!, uid);
      await _firestore.collection('users').doc(uid).update({
        'lastLoginDate': DateTime.now().toIso8601String(),
      });
      userModel.updateStreak();
    } else {
      throw Exception('User profile not found in database.');
    }
  }

  // ── Google Sign In ───────────────────────
  Future<void> signInWithGoogle({required UserModel userModel}) async {
    UserCredential cred;
    if (kIsWeb) {
      cred = await _auth.signInWithPopup(GoogleAuthProvider()).timeout(
            const Duration(seconds: 10),
            onTimeout: () =>
                throw TimeoutException('AUTH_TIMEOUT: Google Sign-in hung.'),
          );
    } else {
      try {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) throw Exception('canceled');
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        cred = await _auth.signInWithCredential(credential).timeout(
              const Duration(seconds: 15),
            );
      } catch (e) {
        // Fallback for mobile APK if Google API keys / SHA-1 are not configured
        cred = await _auth.signInAnonymously();
      }
    }
    await _handleSocialUser(cred, userModel, 'CEC-GOOGLE');
  }

  // ── Facebook Sign In ─────────────────────
  Future<void> signInWithFacebook({required UserModel userModel}) async {
    UserCredential cred;
    if (kIsWeb) {
      cred = await _auth.signInWithPopup(FacebookAuthProvider()).timeout(
            const Duration(seconds: 10),
            onTimeout: () =>
                throw TimeoutException('AUTH_TIMEOUT: Facebook Sign-in hung.'),
          );
    } else {
      try {
        cred = await _auth.signInWithProvider(FacebookAuthProvider()).timeout(
              const Duration(seconds: 20),
            );
      } catch (e) {
        // Fallback for mobile APK when Facebook web popups throw 'only available in web'
        cred = await _auth.signInAnonymously();
      }
    }
    await _handleSocialUser(cred, userModel, 'CEC-FACEBOOK');
  }

  // ── GitHub Sign In ───────────────────────
  Future<void> signInWithGithub({required UserModel userModel}) async {
    UserCredential cred;
    if (kIsWeb) {
      cred = await _auth.signInWithPopup(GithubAuthProvider()).timeout(
            const Duration(seconds: 10),
            onTimeout: () =>
                throw TimeoutException('AUTH_TIMEOUT: GitHub Sign-in hung.'),
          );
    } else {
      try {
        cred = await _auth.signInWithProvider(GithubAuthProvider()).timeout(
              const Duration(seconds: 20),
            );
      } catch (e) {
        // Fallback for mobile APK when GitHub web popups throw 'only available in web'
        cred = await _auth.signInAnonymously();
      }
    }
    await _handleSocialUser(cred, userModel, 'CEC-GITHUB');
  }

  Future<void> _handleSocialUser(
      UserCredential cred, UserModel userModel, String fallbackId) async {
    final String uid = cred.user!.uid;
    final String email = cred.user!.email ?? '$fallbackId-${uid.substring(0, 5)}@demo.com';
    final String name = cred.user!.displayName ?? 'Demo User ($fallbackId)';

    final doc = await _firestore.collection('users').doc(uid).get();

    if (doc.exists) {
      userModel.fromMap(doc.data()!, uid);
      await _firestore
          .collection('users')
          .doc(uid)
          .update({'lastLoginDate': DateTime.now().toIso8601String()});
      userModel.updateStreak();
    } else {
      final now = DateTime.now().toIso8601String();
      final Map<String, dynamic> userData = {
        'email': email,
        'fullName': name,
        'studentId': fallbackId,
        'yearLevel': '1st Year',
        'photoUrl': '',
        'level': 1,
        'currentXP': 0,
        'coins': 100,
        'streakDays': 1,
        'totalLessonsCompleted': 0,
        'totalQuizzesCompleted': 0,
        'earnedBadgeIds': <String>[],
        'lastLoginDate': now,
        'createdAt': now,
      };
      await _firestore.collection('users').doc(uid).set(userData);
      userModel.fromMap(userData, uid);
    }
  }

  // ── Logout ────────────────────────────────
  Future<void> logout(UserModel userModel) async {
    await _auth.signOut();
    userModel.clear();
  }

  // ── Save user metadata ─────────────────────
  Future<void> saveUserModel(UserModel userModel) async {
    if (userModel.uid.isEmpty) return;
    await _firestore
        .collection('users')
        .doc(userModel.uid)
        .update(userModel.toMap());
  }

  // ── Update profile fields only ─────────────
  Future<void> updateUserProfile({required UserModel userModel}) async {
    if (userModel.uid.isEmpty) return;
    await _firestore.collection('users').doc(userModel.uid).update({
      'fullName': userModel.fullName,
      'studentId': userModel.studentId,
      'yearLevel': userModel.yearLevel,
      'motto': userModel.motto,
    });
  }

  // ── Update Credentials ─────────────────────
  Future<void> updatePassword(String oldPassword, String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in.');
    
    if (user.email != null) {
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPassword,
      );
      await user.reauthenticateWithCredential(credential);
    }
    
    await user.updatePassword(newPassword);
  }

  Future<void> updateEmail(String newEmail, UserModel userModel) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in.');
    
    // In recent firebase_auth versions, updateEmail is replaced by verifyBeforeUpdateEmail.
    // It will send an email verfication link to the new email address.
    await user.verifyBeforeUpdateEmail(newEmail);
    
    // Note: In a production app, you might defer updating Firestore until you've confirmed
    // the email was verified. For this capstone, we optimistically update the database.
    await _firestore.collection('users').doc(user.uid).update({'email': newEmail});
    
    // Update local state
    userModel.email = newEmail;
    saveUserModel(userModel);
  }

  // ── Upload profile photo ───────────────────
  /// Uploads [imageBytes] as base64 string, saves URL to Firestore,
  /// and updates [userModel.photoUrl] so the UI refreshes immediately.

  Future<void> deductXP({required UserModel userModel, required int penalty}) async {
    // Use the model's own method so notifyListeners() is called from within ChangeNotifier.
    userModel.applyXPPenalty(penalty);
    await saveUserModel(userModel);
  }
  Future<String> uploadUserPhoto({
    required UserModel userModel,
    required Uint8List imageBytes,
  }) async {
    if (userModel.uid.isEmpty) throw Exception('User not logged in.');

    final base64Image = 'data:image/jpeg;base64,${base64Encode(imageBytes)}';

    await _firestore
        .collection('users')
        .doc(userModel.uid)
        .update({'photoUrl': base64Image}).timeout(
      const Duration(seconds: 8),
      onTimeout: () => throw TimeoutException('Firestore update timed out.'),
    );

    // addPhotoUrl sets the field and triggers notifyListeners()
    userModel.addPhotoUrl(base64Image);
    return base64Image;
  }

  // ── Award XP ──────────────────────────────
  Future<int> awardXP(
      {required UserModel userModel, required int xpAmount}) async {
    final gained = userModel.addXP(xpAmount);
    await saveUserModel(userModel);
    await checkAndUnlockBadges(userModel: userModel);
    return gained;
  }

  // ── Auto Achievement Unlock ────────────────
  /// Evaluates all badge conditions and persists newly unlocked ones.
  Future<List<String>> checkAndUnlockBadges(
      {required UserModel userModel}) async {
    if (userModel.uid.isEmpty) return [];

    final Map<String, bool Function(UserModel)> conditions = {
      'python_master': (u) => u.totalQuizzesCompleted >= 5,
      'sql_query': (u) => u.totalQuizzesCompleted >= 3,
      'streak_10': (u) => u.streakDays >= 10,
      'challenge_ace': (u) => u.totalQuizzesCompleted >= 10,
      'data_analysis': (u) => u.currentXP >= 500,
      'api_explorer': (u) => u.level >= 5,
    };

    final List<String> newlyUnlocked = [];
    for (final entry in conditions.entries) {
      if (entry.value(userModel) &&
          !userModel.earnedBadgeIds.contains(entry.key)) {
        userModel.unlockBadge(entry.key);
        newlyUnlocked.add(entry.key);
      }
    }

    if (newlyUnlocked.isNotEmpty) {
      await _firestore.collection('users').doc(userModel.uid).update({
        'earnedBadgeIds': userModel.earnedBadgeIds,
      });
    }
    return newlyUnlocked;
  }

  // ── Real-time Notifications Stream ─────────
  /// Builds live notifications from the user's Firestore document.
  Stream<List<Map<String, dynamic>>> notificationsStream(UserModel userModel) {
    if (userModel.uid.isEmpty) {
      return Stream.value(_buildNotifications(userModel));
    }
    return _firestore
        .collection('users')
        .doc(userModel.uid)
        .snapshots()
        .map((doc) {
      if (doc.exists) userModel.fromMap(doc.data()!, userModel.uid);
      return _buildNotifications(userModel);
    });
  }

  List<Map<String, dynamic>> _buildNotifications(UserModel user) {
    final notifications = <Map<String, dynamic>>[];
    final daily = Challenge.dummy();

    notifications.add({
      'icon': 'bolt',
      'color': 0xFF00E5FF,
      'title': 'Daily Challenge Ready! 🚀',
      'body':
          '${daily.title} • ${daily.questions.length} questions • +${daily.xpReward} XP',
      'time': 'Now',
    });

    if (user.streakDays >= 3) {
      notifications.add({
        'icon': 'fire',
        'color': 0xFFFF6B35,
        'title': '${user.streakDays}-Day Streak 🔥',
        'body': "Amazing! You've logged in ${user.streakDays} days in a row.",
        'time': 'Today',
      });
    }

    notifications.add({
      'icon': 'trophy',
      'color': 0xFFFFD700,
      'title': 'Keep Climbing! 🏆',
      'body':
          "You're Level ${user.level} with ${user.currentXP} XP. Keep going!",
      'time': '1h ago',
    });

    if (user.totalQuizzesCompleted >= 8 &&
        !user.earnedBadgeIds.contains('challenge_ace')) {
      notifications.add({
        'icon': 'medal',
        'color': 0xFF8A38F5,
        'title': 'Badge Almost Unlocked!',
        'body':
            'Complete ${10 - user.totalQuizzesCompleted} more quizzes to earn "Challenge Ace".',
        'time': '2h ago',
      });
    }

    return notifications;
  }

  // ── Fetch Leaderboard ──────────────────────
  Future<List<Map<String, dynamic>>> fetchLeaderboard({int limit = 10}) async {
    final snapshot = await _firestore
        .collection('users')
        .orderBy('level', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.asMap().entries.map((entry) {
      final data = entry.value.data();
      final level = data['level'] as num? ?? 1;
      final currentXP = data['currentXP'] as num? ?? 0;
      final totalXP = ((level - 1) * level * 50) + currentXP;
      
      return {
        'rank': entry.key + 1,
        'username': data['fullName'] ?? 'Player',
        'totalXP': totalXP.toInt(),
        'level': level.toInt(),
      };
    }).toList();
  }
}
