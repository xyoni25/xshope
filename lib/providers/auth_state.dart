import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';

class AuthState extends ChangeNotifier {
  User? _user;
  UserProfile? _userProfile;
  bool _isLoading = false;
  String _errorMessage = '';

  User? get user => _user;
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  AuthState() {
    _initAuth();
  }

  Future<void> _initAuth() async {
    _isLoading = true;
    notifyListeners();

    // Listen to auth state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      _user = user;
      if (user != null) {
        await _loadUserProfile();
      } else {
        _userProfile = null;
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      
      _user = credential.user;
      await _loadUserProfile();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getAuthErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String password, String name) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      _user = credential.user;

      // Create user profile in Firestore
      final userProfile = UserProfile(
        uid: _user!.uid,
        name: name,
        email: email,
        photoUrl: null,
        joinDate: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .set(userProfile.toMap());

      _userProfile = userProfile;
      
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getAuthErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await FirebaseAuth.instance.signOut();
      _user = null;
      _userProfile = null;
    } catch (e) {
      _errorMessage = 'Error during logout: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadUserProfile() async {
    if (_user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get();

      if (doc.exists) {
        _userProfile = UserProfile.fromMap(doc.data()!, _user!.uid);
      }
    } catch (e) {
      _errorMessage = 'Failed to load user profile: $e';
    }
  }

  Future<String?> uploadProfileImage(File imageFile) async {
    if (_user == null) return null;

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // Upload to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_images')
          .child('${_user!.uid}.jpg');
      
      await storageRef.putFile(imageFile);
      final downloadUrl = await storageRef.getDownloadURL();

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .update({'photoUrl': downloadUrl});

      // Update local state
      if (_userProfile != null) {
        _userProfile = UserProfile(
          uid: _userProfile!.uid,
          name: _userProfile!.name,
          email: _userProfile!.email,
          photoUrl: downloadUrl,
          joinDate: _userProfile!.joinDate,
        );
      }

      _isLoading = false;
      notifyListeners();
      return downloadUrl;
    } catch (e) {
      _errorMessage = 'Failed to upload image: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateProfile({String? name}) async {
    if (_user == null || _userProfile == null) return false;

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final updates = <String, dynamic>{};
      
      if (name != null && name.isNotEmpty) {
        updates['name'] = name;
      }

      if (updates.isEmpty) {
        _isLoading = false;
        notifyListeners();
        return true;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .update(updates);

      // Update local state
      _userProfile = UserProfile(
        uid: _userProfile!.uid,
        name: name ?? _userProfile!.name,
        email: _userProfile!.email,
        photoUrl: _userProfile!.photoUrl,
        joinDate: _userProfile!.joinDate,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update profile: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'The email address is already in use.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'weak-password':
        return 'The password is too weak.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      default:
        return 'Authentication error: $code';
    }
  }
}