import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// As chaves sao lidas de variaveis de ambiente (.env) via flutter_dotenv.
/// NAO voltar a embutir chaves hardcoded neste arquivo. Ver context/erros-a-evitar.md.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you may reconfigure this by running the FlutterFire CLI again '
          'and then migrating the values to .env.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you may reconfigure this by running the FlutterFire CLI again '
          'and then migrating the values to .env.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you may reconfigure this by running the FlutterFire CLI again '
          'and then migrating the values to .env.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you may reconfigure this by running the FlutterFire CLI again '
          'and then migrating the values to .env.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static String _s(String key, {String fallback = ''}) =>
      dotenv.maybeGet(key) ?? fallback;

  static String get _projectId => _s('FIREBASE_PROJECT_ID');

  static FirebaseOptions get web => FirebaseOptions(
        apiKey: _s('FIREBASE_WEB_API_KEY'),
        appId: _s('FIREBASE_WEB_APP_ID'),
        messagingSenderId: _s('FIREBASE_MESSAGING_SENDER_ID'),
        projectId: _projectId,
        authDomain:
            _s('FIREBASE_AUTH_DOMAIN', fallback: '$_projectId.firebaseapp.com'),
        storageBucket: _s(
          'FIREBASE_STORAGE_BUCKET',
          fallback: '$_projectId.firebasestorage.app',
        ),
        measurementId: dotenv.maybeGet('FIREBASE_WEB_MEASUREMENT_ID'),
      );

  static FirebaseOptions get android => FirebaseOptions(
        apiKey: _s('FIREBASE_ANDROID_API_KEY'),
        appId: _s('FIREBASE_ANDROID_APP_ID'),
        messagingSenderId: _s('FIREBASE_MESSAGING_SENDER_ID'),
        projectId: _projectId,
        storageBucket: _s(
          'FIREBASE_STORAGE_BUCKET',
          fallback: '$_projectId.firebasestorage.app',
        ),
      );
}