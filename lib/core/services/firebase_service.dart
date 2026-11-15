import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:forma/firebase_options.dart';

enum FirebaseInitStatus { uninitialized, connected, failed, offlineFallback }

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  FirebaseInitStatus _status = FirebaseInitStatus.uninitialized;
  String _errorMessage = '';

  FirebaseInitStatus get status => _status;
  String get errorMessage => _errorMessage;

  FirebaseAuth get auth => FirebaseAuth.instance;
  FirebaseFirestore get firestore => FirebaseFirestore.instance;
  FirebaseStorage get storage => FirebaseStorage.instance;

  Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Initialize App Check for verified Android clients (Play Integrity in prod, Debug provider in dev)
      await FirebaseAppCheck.instance.activate(
        androidProvider:
            kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
        appleProvider:
            kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
      );

      // Enable Firestore offline caching
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      _status = FirebaseInitStatus.connected;
    } catch (e) {
      _errorMessage = e.toString();
      // Graceful offline fallback: app remains genuinely functional locally
      _status = FirebaseInitStatus.offlineFallback;
    }
  }
}
