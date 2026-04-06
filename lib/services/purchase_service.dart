import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PurchaseService {
  PurchaseService._();
  static final PurchaseService instance = PurchaseService._();

  // ── ID ەکانی گووگڵ پلەی ──────────────────────────────────────────────────
  static const String kYearlyId = 'wisdom_gates_pro_yearly';
  static const Set<String> _kIds = {kYearlyId};
  static const String _kProKey = 'is_pro_user';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _isProUser = false;
  bool get isProUser => _isProUser;

  // ── لیستی گوێگرانی گۆڕانکاری ─────────────────────────────────────────────
  final List<VoidCallback> _listeners = [];
  void addListener(VoidCallback cb) => _listeners.add(cb);
  void removeListener(VoidCallback cb) => _listeners.remove(cb);
  void _notify() {
    for (final cb in _listeners) {
      cb();
    }
  }

  // ── دەستپێکردن ───────────────────────────────────────────────────────────
  Future<void> initialize() async {
    // بارکردنی دۆخی پرۆ لە مێموری ناوخۆ
    final prefs = await SharedPreferences.getInstance();
    _isProUser = prefs.getBool(_kProKey) ?? false;

    final stream = _iap.purchaseStream;
    _subscription = stream.listen(
      _onPurchaseUpdate,
      onError: (e) => debugPrint('IAP Error: $e'),
    );
  }

  // ── لاکردنەوە ────────────────────────────────────────────────────────────
  void dispose() {
    _subscription?.cancel();
  }

  // ── کڕینی ساڵانە ─────────────────────────────────────────────────────────
  Future<bool> buyYearlyPro() async {
    final bool available = await _iap.isAvailable();
    if (!available) return false;

    final ProductDetailsResponse response =
        await _iap.queryProductDetails(_kIds);

    if (response.error != null || response.productDetails.isEmpty) {
      debugPrint('IAP Product not found: ${response.error}');
      return false;
    }

    final ProductDetails product = response.productDetails.first;
    final PurchaseParam param = PurchaseParam(productDetails: product);

    try {
      return await _iap.buyNonConsumable(purchaseParam: param);
    } catch (e) {
      debugPrint('Purchase Error: $e');
      return false;
    }
  }

  // ── گەڕاندنەوەی کڕینی کونەکان ────────────────────────────────────────────
  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  // ── پشکنینی نوێکاریەکانی کڕین ────────────────────────────────────────────
  void _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _setProUser(true);
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;
        case PurchaseStatus.error:
          debugPrint('Purchase Error: ${purchase.error}');
          break;
        case PurchaseStatus.canceled:
        case PurchaseStatus.pending:
          break;
      }
    }
  }

  // ── هەڵگرتنی دۆخی پرۆ ───────────────────────────────────────────────────
  Future<void> _setProUser(bool value) async {
    _isProUser = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kProKey, value);
    _notify();
  }
}
