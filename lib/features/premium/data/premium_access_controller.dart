import 'package:flutter/foundation.dart';

import '../domain/premium_models.dart';

class PremiumAccessController extends ChangeNotifier {
  PremiumAccessController._();

  static final instance = PremiumAccessController._();

  final Set<PremiumFeature> _unlocked = {};
  DateTime _expiresAt = DateTime.now().add(const Duration(days: 30));

  bool isUnlocked(PremiumFeature feature) =>
      _unlocked.contains(feature) || isPremiumUnlocked;

  bool get isPremiumUnlocked =>
      allPremiumFeatures.every((feature) => _unlocked.contains(feature));

  Set<PremiumFeature> get unlockedFeatures => Set.unmodifiable(_unlocked);

  DateTime get expiresAt => _expiresAt;
  bool get isExpiringSoon {
    final remaining = _expiresAt.difference(DateTime.now()).inDays;
    return remaining <= 3 && remaining >= 0;
  }

  String get expiryMessage {
    if (!isExpiringSoon) return '';
    final remaining = _expiresAt.difference(DateTime.now()).inDays;
    return remaining <= 0
        ? 'Your premium access expires today. Renew to keep premium AI editing available.'
        : 'Your premium access expires in $remaining day${remaining == 1 ? '' : 's'}. Renew soon to keep premium AI editing available.';
  }

  void applyVerifiedEntitlement(Set<PremiumFeature> features) {
    _unlocked.addAll(features);
    _expiresAt = DateTime.now().add(const Duration(days: 30));
    notifyListeners();
  }

  void expirePremiumForDemo() {
    _expiresAt = DateTime.now().add(const Duration(days: 2));
    notifyListeners();
  }
}
