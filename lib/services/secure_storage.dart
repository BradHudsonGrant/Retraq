import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Shared, hardened [FlutterSecureStorage] instance.
///
/// On Android (flutter_secure_storage ^10.0.0), the default backend is
/// a custom AES-256-GCM cipher implementation. The previously-recommended
/// EncryptedSharedPreferences (Jetpack Security) backend is deprecated by
/// Google and by the plugin; setting `encryptedSharedPreferences: true`
/// is now a no-op and produces a deprecation warning. Existing
/// EncryptedSharedPreferences-backed data is auto-migrated to custom
/// ciphers on first access.
///
/// The custom-cipher backend does NOT fall back to the old
/// RSA/ECB/PKCS1Padding wrapping that was vulnerable to padding-oracle
/// attacks — it uses AES-GCM directly with a per-device key material
/// derived on the device.
///
/// On iOS, uses the strictest accessibility class that still allows
/// background reads after first unlock.
///
/// Task 3.1: original audit flagged this file because an older
/// version of flutter_secure_storage required an explicit
/// `encryptedSharedPreferences: true` to opt in to a hardened backend.
/// In v10 the flag is deprecated / ignored and the default backend is
/// already hardened. This docstring was rewritten to reflect current
/// reality; no behavior change was needed.
const hardenedSecureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(),
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
);
