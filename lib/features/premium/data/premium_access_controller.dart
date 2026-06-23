import 'package:flutter/foundation.dart';

import '../domain/premium_models.dart';

class PremiumAccessController extends ChangeNotifier {
  PremiumAccessController._();

  static final instance = PremiumAccessController._();

  final Set<PremiumFeature> _unlocked = {};

  bool isUnlocked(PremiumFeature feature) =>
      _unlocked.contains(feature) || isPremiumUnlocked;

  bool get isPremiumUnlocked =>
      allPremiumFeatures.every((feature) => _unlocked.contains(feature));

  Set<PremiumFeature> get unlockedFeatures => Set.unmodifiable(_unlocked);

  void applyVerifiedEntitlement(Set<PremiumFeature> features) {
    _unlocked.addAll(features);
    notifyListeners();
  }
}
