import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// RevenueCat entitlement identifier for premium access.
const kPremiumEntitlement = 'premium';

/// Wraps RevenueCat SDK for subscription management.
///
/// Premium gates: cloud AI recap, advanced mood analytics.
/// Free tier keeps: core journaling, basic stats, template recap, mood tracking.
class PurchaseService extends ChangeNotifier {
  PurchaseService._();
  static final instance = PurchaseService._();

  // TODO: Replace with real RevenueCat API keys before release.
  static const _androidApiKey = 'goog_REPLACE_ME';
  static const _iosApiKey = 'appl_REPLACE_ME';

  bool _initialized = false;
  bool _isPremium = false;
  List<Package> _packages = [];

  bool get isPremium => _isPremium;
  List<Package> get packages => List.unmodifiable(_packages);

  /// Initialize RevenueCat. Safe to call multiple times.
  Future<void> init() async {
    if (_initialized) return;

    try {
      final apiKey = Platform.isIOS ? _iosApiKey : _androidApiKey;

      // Skip initialization if placeholder keys are still present.
      if (apiKey.contains('REPLACE_ME')) {
        debugPrint('PurchaseService: placeholder API key detected, skipping init');
        _initialized = true;
        return;
      }

      await Purchases.configure(
        PurchasesConfiguration(apiKey)..appUserID = null,
      );

      // Listen for customer info changes (e.g. subscription renewal/expiry).
      Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);

      // Check current entitlements.
      final info = await Purchases.getCustomerInfo();
      _updatePremiumStatus(info);

      _initialized = true;
    } catch (e) {
      debugPrint('PurchaseService init failed (non-fatal): $e');
      _initialized = true;
    }
  }

  void _onCustomerInfoUpdated(CustomerInfo info) {
    _updatePremiumStatus(info);
  }

  void _updatePremiumStatus(CustomerInfo info) {
    final wasPremium = _isPremium;
    _isPremium = info.entitlements.active.containsKey(kPremiumEntitlement);
    if (_isPremium != wasPremium) notifyListeners();
  }

  /// Fetch available subscription packages.
  Future<List<Package>> fetchPackages() async {
    try {
      final offerings = await Purchases.getOfferings();
      _packages = offerings.current?.availablePackages ?? [];
      return _packages;
    } catch (e) {
      debugPrint('PurchaseService fetchPackages failed: $e');
      return [];
    }
  }

  /// Purchase a package. Returns true on success.
  Future<bool> purchasePackage(Package package_) async {
    try {
      final result = await Purchases.purchase(PurchaseParams.package(package_));
      _updatePremiumStatus(result.customerInfo);
      return _isPremium;
    } catch (e) {
      if (e is PlatformException) {
        // User cancelled — not an error.
        final code = PurchasesErrorHelper.getErrorCode(e);
        if (code == PurchasesErrorCode.purchaseCancelledError) {
          return false;
        }
      }
      debugPrint('PurchaseService purchase failed: $e');
      return false;
    }
  }

  /// Restore previous purchases (e.g. after reinstall).
  Future<bool> restore() async {
    try {
      final info = await Purchases.restorePurchases();
      _updatePremiumStatus(info);
      return _isPremium;
    } catch (e) {
      debugPrint('PurchaseService restore failed: $e');
      return false;
    }
  }
}
