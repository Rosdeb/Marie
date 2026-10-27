import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatPurchaseService {
  static const bool isRcTest = bool.fromEnvironment('RC_TEST', defaultValue: true);
  static const String testApiKey = String.fromEnvironment(
    'RC_TEST_API_KEY',
    defaultValue: 'test_FyhEeGsYzCAHcXnHaCOnIlQxNyg',
  );
  static const String appleApiKey = String.fromEnvironment(
    'RC_APPLE_KEY',
    defaultValue: 'appl_revenuecat_key',
  );
  static const String googleApiKey = String.fromEnvironment(
    'RC_GOOGLE_KEY',
    defaultValue: 'goog_revenuecat_key',
  );

  bool _isConfigured = false;
  bool get isConfigured => _isConfigured;

  Future<void> initialize({void Function(CustomerInfo)? onCustomerInfoUpdated}) async {
    if (_isConfigured) return;

    // Safety check: Release builds must never use Test Store key
    if (kReleaseMode && isRcTest) {
      throw StateError('Release builds must never use the Test Store key.');
    }

    String apiKey;
    if (isRcTest) {
      apiKey = testApiKey;
    } else if (Platform.isIOS || Platform.isMacOS) {
      apiKey = appleApiKey;
    } else {
      apiKey = googleApiKey;
    }

    try {
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.info);
      final configuration = PurchasesConfiguration(apiKey);
      await Purchases.configure(configuration);
      _isConfigured = true;

      if (onCustomerInfoUpdated != null) {
        Purchases.addCustomerInfoUpdateListener(onCustomerInfoUpdated);
      }
    } catch (e) {
      debugPrint('[RevenueCat] Init error: $e');
    }
  }

  Future<CustomerInfo?> logIn(String userId) async {
    try {
      if (!_isConfigured) await initialize();
      final result = await Purchases.logIn(userId);
      return result.customerInfo;
    } catch (e) {
      debugPrint('[RevenueCat] logIn error: $e');
      return null;
    }
  }

  Future<CustomerInfo?> logOut() async {
    try {
      if (!_isConfigured) return null;
      return await Purchases.logOut();
    } catch (e) {
      debugPrint('[RevenueCat] logOut error: $e');
      return null;
    }
  }

  Future<Offerings?> getOfferings() async {
    try {
      if (!_isConfigured) await initialize();
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint('[RevenueCat] getOfferings error: $e');
      return null;
    }
  }

  Future<PurchaseResult?> purchasePackage(Package package) async {
    try {
      if (!_isConfigured) await initialize();
      return await Purchases.purchase(PurchaseParams.package(package));
    } on PurchasesErrorCode catch (e) {
      if (e == PurchasesErrorCode.purchaseCancelledError) {
        debugPrint('[RevenueCat] User cancelled purchase');
        return null;
      }
      rethrow;
    } catch (e) {
      debugPrint('[RevenueCat] purchase error: $e');
      rethrow;
    }
  }

  Future<CustomerInfo?> restorePurchases() async {
    try {
      if (!_isConfigured) await initialize();
      return await Purchases.restorePurchases();
    } catch (e) {
      debugPrint('[RevenueCat] restorePurchases error: $e');
      rethrow;
    }
  }

  Future<CustomerInfo?> getCustomerInfo() async {
    try {
      if (!_isConfigured) await initialize();
      return await Purchases.getCustomerInfo();
    } catch (e) {
      debugPrint('[RevenueCat] getCustomerInfo error: $e');
      return null;
    }
  }
}

final revenueCatServiceProvider = Provider<RevenueCatPurchaseService>((ref) {
  return RevenueCatPurchaseService();
});
