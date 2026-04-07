import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Shared, hardened [FlutterSecureStorage] instance.
///
/// On Android, uses EncryptedSharedPreferences (Jetpack Security)
/// instead of the default RSA/ECB/PKCS1Padding wrapping, which is
/// vulnerable to padding-oracle attacks and stores values in plain
/// SharedPreferences XML extractable on rooted devices.
///
/// On iOS, uses the strictest accessibility class that still allows
/// background reads after first unlock.
const hardenedSecureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
);
