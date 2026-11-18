import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class PremiumProvider extends ChangeNotifier {
  bool _isPremium = false;
  bool get isPremium => _isPremium;
  
  StreamSubscription<DocumentSnapshot>? _subscription;

  PremiumProvider() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _subscription = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots()
            .listen((doc) {
          if (doc.exists && doc.data() != null) {
            _isPremium = doc.data()!['isPremium'] == true;
            notifyListeners();
          }
        });
      } else {
        _subscription?.cancel();
        _isPremium = false;
        notifyListeners();
      }
    });
  }

  Future<void> upgradeToPremium() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'isPremium': true,
      }, SetOptions(merge: true));
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
