import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  // Email/Password Sign Up
  Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await userCredential.user?.updateDisplayName(name);

      // Create user profile in Firestore
      if (userCredential.user != null) {
        await _createUserProfileWithDetails(
          userCredential.user!,
          name: name,
          phone: phone,
        );
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Email/Password Sign In
  Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update last login
      if (userCredential.user != null) {
        await _updateLastLogin(userCredential.user!.uid);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      await currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Check if email is verified
  bool get isEmailVerified => currentUser?.emailVerified ?? false;

  // Reload user to check email verification status
  Future<void> reloadUser() async {
    await currentUser?.reload();
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Phone Authentication - Send OTP
  Future<void> sendOTP({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(String error) onError,
    required Function(PhoneAuthCredential credential) onAutoVerify,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification (Android only)
          onAutoVerify(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? 'Verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Timeout - user needs to enter OTP manually
        },
      );
    } catch (e) {
      onError(e.toString());
    }
  }

  // Verify OTP and Sign In
  Future<UserCredential?> verifyOTP({
    required String verificationId,
    required String otp,
  }) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);

      // Create/update user profile in Firestore
      if (userCredential.user != null) {
        await _createOrUpdateUserProfile(userCredential.user!);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with Phone Credential (for auto-verify)
  Future<UserCredential?> signInWithCredential(PhoneAuthCredential credential) async {
    try {
      UserCredential userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        await _createOrUpdateUserProfile(userCredential.user!);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Google Sign In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      UserCredential userCredential = await _auth.signInWithCredential(credential);

      // Create/update user profile in Firestore
      if (userCredential.user != null) {
        await _createOrUpdateUserProfile(userCredential.user!);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to sign in with Google: $e';
    }
  }

  // Create user profile with specific details
  Future<void> _createUserProfileWithDetails(
    User user, {
    required String name,
    String? phone,
  }) async {
    final userDoc = _firestore.collection('users').doc(user.uid);

    await userDoc.set({
      'uid': user.uid,
      'name': name,
      'email': user.email ?? '',
      'phone': phone ?? '',
      'avatar': _getInitials(name),
      'wins': 0,
      'losses': 0,
      'points': 0,
      'matchesPlayed': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
    });
  }

  // Create or update user profile in Firestore
  Future<void> _createOrUpdateUserProfile(User user) async {
    final userDoc = _firestore.collection('users').doc(user.uid);
    final docSnapshot = await userDoc.get();

    if (!docSnapshot.exists) {
      // Create new user profile
      await userDoc.set({
        'uid': user.uid,
        'name': user.displayName ?? 'Player',
        'email': user.email ?? '',
        'phone': user.phoneNumber ?? '',
        'avatar': _getInitials(user.displayName ?? 'P'),
        'wins': 0,
        'losses': 0,
        'points': 0,
        'matchesPlayed': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } else {
      // Update last login
      await userDoc.update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    }
  }

  // Update last login timestamp
  Future<void> _updateLastLogin(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'lastLogin': FieldValue.serverTimestamp(),
    });
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'P';
  }

  // Sign Out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Update user profile
  Future<void> updateProfile({
    String? name,
    String? avatar,
  }) async {
    if (currentUser == null) return;

    final Map<String, dynamic> updates = {};
    if (name != null) updates['name'] = name;
    if (avatar != null) updates['avatar'] = avatar;

    if (updates.isNotEmpty) {
      await _firestore.collection('users').doc(currentUser!.uid).update(updates);
    }
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (currentUser == null) return null;

    final doc = await _firestore.collection('users').doc(currentUser!.uid).get();
    return doc.data();
  }

  // Get user profile stream
  Stream<Map<String, dynamic>?> getUserProfileStream() {
    if (currentUser == null) {
      return Stream.value(null);
    }
    return _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .snapshots()
        .map((doc) => doc.data());
  }

  // Handle Firebase Auth Exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-verification-code':
        return 'Invalid OTP. Please try again.';
      case 'invalid-phone-number':
        return 'Invalid phone number format.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';
      case 'email-already-in-use':
        return 'This email is already registered. Please login instead.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid email or password. Please try again.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}
