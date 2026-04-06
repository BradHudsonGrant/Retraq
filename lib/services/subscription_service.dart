import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Singleton service managing RevenueCat subscriptions.
///
/// Call [init] once at app startup (after `WidgetsFlutterBinding.ensureInitialized()`).
/// All purchase state flows through [watchEntitlements].
class SubscriptionService {
  SubscriptionService._();
  static final SubscriptionService instance = SubscriptionService._();

  // TODO: Replace with your actual RevenueCat entitlement identifier.
  static const _entitlementId = 'premium';

  bool _initialised = false;

  final StreamController<bool> _premiumController =
      StreamController<bool>.broadcast();

  bool _isPremium = false;

  /// Whether the user currently has an active premium entitlement.
  bool get isPremium => _isPremium;

  /// Stream that emits whenever the premium status changes.
  Stream<bool> get watchEntitlements => _premiumController.stream;

  /// Initialise the RevenueCat SDK.
  ///
  /// [apiKey] is the platform-specific RevenueCat public API key.
  /// Call this once in `main()` before `runApp()`.
  Future<void> init(String apiKey) async {
    if (_initialised) return;

    // TODO: Configure RevenueCat API key per platform.
    // You can find your API keys in the RevenueCat dashboard:
    //   https://app.revenuecat.com
    final configuration = PurchasesConfiguration(apiKey);
    await Purchases.configure(configuration);

    // Listen for entitlement changes (e.g. renewals, cancellations).
    Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);

    // Seed initial state.
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      _updatePremiumStatus(customerInfo);
    } catch (e) {
      debugPrint('SubscriptionService.init: failed to fetch customer info: $e');
    }

    _initialised = true;
  }

  void _onCustomerInfoUpdated(CustomerInfo info) {
    _updatePremiumStatus(info);
  }

  void _updatePremiumStatus(CustomerInfo info) {
    final wasPremium = _isPremium;
    _isPremium = info.entitlements.all[_entitlementId]?.isActive == true;
    if (_isPremium != wasPremium) {
      _premiumController.add(_isPremium);
    }
  }

  /// Fetch available offerings from RevenueCat.
  ///
  /// Returns the current [Offerings], which contains packages the user
  /// can purchase. Returns `null` if offerings are unavailable.
  Future<Offerings?> getOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      return offerings;
    } catch (e) {
      debugPrint('SubscriptionService.getOfferings: $e');
      return null;
    }
  }

  /// Purchase a specific [package].
  ///
  /// Returns `true` if the purchase succeeded, `false` otherwise.
  /// The premium status will be updated automatically via the listener.
  Future<bool> purchasePackage(Package package) async {
    try {
      final customerInfo = await Purchases.purchasePackage(package);
      _updatePremiumStatus(customerInfo);
      return _isPremium;
    } on PlatformException catch (e) {
      // TODO: Handle specific error codes (e.g. user cancelled).
      debugPrint('SubscriptionService.purchasePackage: $e');
      return false;
    }
  }

  /// Restore previous purchases (e.g. after reinstall or device switch).
  ///
  /// Returns `true` if premium entitlement was restored.
  Future<bool> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      _updatePremiumStatus(customerInfo);
      return _isPremium;
    } on PlatformException catch (e) {
      debugPrint('SubscriptionService.restorePurchases: $e');
      return false;
    }
  }

  /// Clean up resources. Called when the app shuts down.
  void dispose() {
    Purchases.removeCustomerInfoUpdateListener(_onCustomerInfoUpdated);
    _premiumController.close();
  }
}
