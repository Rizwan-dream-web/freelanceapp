import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream for auth changes
  Stream<User?> get user => _auth.authStateChanges();
  
  // Current user
  User? get currentUser => _auth.currentUser;

  // 1. Google Sign-In (Improved)
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return {'success': false, 'error': 'Sign-in cancelled'};
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        return {'success': false, 'error': 'Failed to get credentials'};
      }

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCred = await _auth.signInWithCredential(credential);
      
      // Create profile if new user
      if (userCred.additionalUserInfo?.isNewUser ?? false) {
        await _createUserProfile(
          uid: userCred.user!.uid,
          name: userCred.user!.displayName ?? 'User',
          email: userCred.user!.email ?? '',
          photoUrl: userCred.user!.photoURL,
        );
      }
      
      return {'success': true, 'user': userCred.user};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // 2. Email/Password (Login)
  Future<Map<String, dynamic>> signInWithEmail(String email, String password) async {
    try {
      final userCred = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password,
      );

      // Enforce email verification before allowing full login
      final user = userCred.user;
      if (user != null && !user.emailVerified) {
        // Trigger (re)send of verification email
        await user.sendEmailVerification();
        // Sign the user out so they cannot proceed without verification
        await _auth.signOut();
        return {
          'success': false,
          'needsVerification': true,
          'error': 'Please verify your email. A verification link has been sent.'
        };
      }

      return {'success': true, 'user': user};
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed';
      if (e.code == 'user-not-found') message = 'No account found with this email';
      if (e.code == 'wrong-password') message = 'Incorrect password';
      if (e.code == 'invalid-email') message = 'Invalid email address';
      return {'success': false, 'error': message};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // 3. Email/Password (Register with verification)
  Future<Map<String, dynamic>> registerWithEmail(String email, String password, String name, String? phone) async {
    try {
      final userCred = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password,
      );
      
      // Send verification email
      await userCred.user!.sendEmailVerification();
      
      // Update display name
      await userCred.user!.updateDisplayName(name);
      
      // Create user profile
      await _createUserProfile(
        uid: userCred.user!.uid,
        name: name,
        email: email,
        phone: phone,
      );
      
      return {'success': true, 'user': userCred.user, 'needsVerification': true};
    } on FirebaseAuthException catch (e) {
      String message = 'Registration failed';
      if (e.code == 'weak-password') message = 'Password is too weak';
      if (e.code == 'email-already-in-use') message = 'Email already registered';
      if (e.code == 'invalid-email') message = 'Invalid email address';
      return {'success': false, 'error': message};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // 4. Phone Auth (Improved)
  Future<void> verifyPhone({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
    );
  }

  // 5. Sign in with phone credential
  Future<Map<String, dynamic>> signInWithPhoneCredential(PhoneAuthCredential credential) async {
    try {
      final userCred = await _auth.signInWithCredential(credential);
      
      // Create profile if new user
      if (userCred.additionalUserInfo?.isNewUser ?? false) {
        await _createUserProfile(
          uid: userCred.user!.uid,
          name: userCred.user!.phoneNumber ?? 'User',
          email: '',
        );
      }
      
      return {'success': true, 'user': userCred.user};
    } catch (e) {
      return {'success': false, 'error': 'Invalid OTP code'};
    }
  }

  // 6. Create user profile in Firestore
  Future<void> _createUserProfile({
    required String uid,
    required String name,
    required String email,
    String? photoUrl,
    String? phone,
  }) async {
    try {
      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'name': name,
        'email': email,
        'photoUrl': photoUrl,
        'phone': phone,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Firestore might be disabled - log but don't fail authentication
      print('Warning: Could not create Firestore profile: $e');
      print('Please enable Cloud Firestore API in Firebase Console');
      // Authentication still succeeds even if profile creation fails
    }
  }

  // 7. Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      // Firestore might be disabled - return null gracefully
      print('Warning: Could not fetch Firestore profile: $e');
      return null;
    }
  }

  // 8. Update user profile
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _db.collection('users').doc(uid).update(data);
    } catch (e) {
      // If document doesn't exist, create it
      if (e.toString().contains('NOT_FOUND')) {
        try {
          await _db.collection('users').doc(uid).set(data);
        } catch (e2) {
          print('Warning: Could not update/create Firestore profile: $e2');
          throw Exception('Firestore API not enabled. Please enable it in Firebase Console.');
        }
      } else {
        print('Warning: Could not update Firestore profile: $e');
        throw Exception('Firestore API not enabled. Please enable it in Firebase Console.');
      }
    }
  }

  // 9. Sign Out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // 10. Send password reset email
  Future<Map<String, dynamic>> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': 'Failed to send reset email'};
    }
  }
}
