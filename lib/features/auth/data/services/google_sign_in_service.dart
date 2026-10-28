import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInService {
  GoogleSignInService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static Future<void>? _initialization;

  static const String _serverClientId =
      '527162910733-0gdcmvho5o2tbqt3obu9jhe38hh87a8o.apps.googleusercontent.com';
  static const String _iosClientId =
      '527162910733-o36b1qahqpen1d7ka7l6u77qs4cebbkb.apps.googleusercontent.com';

  static Future<void> _initialize() {
    return _initialization ??= _googleSignIn.initialize(
      clientId: Platform.isIOS ? _iosClientId : null,
      serverClientId: _serverClientId,
    );
  }

  /// Authenticates with Google, signs in to Firebase, and ensures that the
  /// user's public Firebase profile exists. A null result means the user
  /// cancelled the Google account chooser.
  static Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      await _initialize();

      final googleUser = await _googleSignIn.authenticate(
        scopeHint: const ['email', 'profile'],
      );
      final googleAuthentication = googleUser.authentication;
      final idToken = googleAuthentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw FirebaseAuthException(
          code: 'missing-google-id-token',
          message: 'Google did not return an ID token. Please try again.',
        );
      }

      String? accessToken;
      try {
        final authorizationClient = googleUser.authorizationClient;
        var authorization = await authorizationClient.authorizationForScopes(
          const ['email', 'profile'],
        );
        authorization ??= await authorizationClient.authorizeScopes(const [
          'email',
          'profile',
        ]);
        accessToken = authorization.accessToken;
      } catch (_) {
        // Fallback: idToken is sufficient for Firebase Auth credential
      }

      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: accessToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'missing-firebase-user',
          message: 'Google sign-in completed without a user account.',
        );
      }

      return {
        'userCredential': userCredential,
        'user': user,
        'idToken': idToken,
        'accessToken': accessToken,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'uid': user.uid,
        'emailVerified': user.emailVerified,
        'phoneNumber': user.phoneNumber,
      };
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      rethrow;
    }
  }

  static Future<void> signOut() async {
    await _initialize();
    await Future.wait([_googleSignIn.signOut(), _auth.signOut()]);
  }

  static User? get currentUser => _auth.currentUser;
}
