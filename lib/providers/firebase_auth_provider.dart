import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart' as model;
import '../services/firestore_service.dart';

/// Provider for Firebase Authentication state
class FirebaseAuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseService _firebaseService = FirebaseService.instance;
  
  User? _user;
  model.UserModel? _userModel;
  bool _isLoading = false;
  String? _errorMessage;
  
  User? get user => _user;
  model.UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  String get userRole => _userModel?.role ?? 'student';
  
  /// ONLY this email gets admin access — checked against Firebase Auth email
  /// (works even when Firestore is offline/unavailable)
  static const List<String> _adminEmails = [
    'swasthikaponnusamy05@gmail.com',
    // Add teammate emails here if you want them to be admins regardless of Firestore
  ];

  bool get isAdmin {
    final email = _user?.email?.toLowerCase().trim();
    if (email == null) return false;
    
    // 1. Direct email check (Master Admins)
    if (_adminEmails.contains(email)) return true;
    
    // 2. Trust Firestore role if we have it
    if (_userModel?.role == 'admin') return true;
    
    // 3. Fallback: non-student email domains (as per AuthService logic)
    if (!email.endsWith('@cb.students.amrita.edu')) return true;

    return false;
  }
  
  FirebaseAuthProvider() {
    _initAuthListener();
  }
  
  /// Initialize auth state listener
  void _initAuthListener() {
    _authService.authStateChanges.listen((User? user) {
      // Role is determined by email — no Firestore fetch needed at startup
      _user = user;
      _userModel = null; // Will be lazily fetched only when explicitly needed
      notifyListeners();
    });
  }
  
  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _errorMessage = null;
    
    try {
      final userCredential = await _authService.signInWithGoogle();
      if (userCredential?.user != null) {
        _user = userCredential!.user;
        // Role is email-based — no Firestore fetch needed
      }
      _setLoading(false);
      return userCredential != null;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      _setLoading(false);
      return false;
    }
  }
  
  /// Sign in with email and password
  Future<bool> signInWithEmailPassword(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;
    
    try {
      final userCredential = await _authService.signInWithEmailPassword(email, password);
      if (userCredential.user != null) {
        _user = userCredential.user;
        // Role is email-based — no Firestore fetch needed
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      _setLoading(false);
      return false;
    }
  }
  
  /// Sign up with email and password
  Future<bool> signUpWithEmailPassword(
    String email,
    String password,
    String name,
  ) async {
    _setLoading(true);
    _errorMessage = null;
    
    try {
      await _authService.signUpWithEmailPassword(email, password, name);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      _setLoading(false);
      return false;
    }
  }
  
  /// Sign out
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authService.signOut();
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
    } finally {
      _setLoading(false);
    }
  }
  
  /// Refresh user data
  Future<void> refreshUserData() async {
    if (_user != null) {
      _userModel = await _firestoreService.getUserData(_user!.uid);
      notifyListeners();
    }
  }
  
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  String _getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email.';
        case 'wrong-password':
          return 'Incorrect password.';
        case 'email-already-in-use':
          return 'An account already exists with this email.';
        case 'weak-password':
          return 'Password is too weak.';
        case 'invalid-email':
          return 'Invalid email address.';
        default:
          return 'Authentication error: ${error.message}';
      }
    }
    return error.toString();
  }
}
