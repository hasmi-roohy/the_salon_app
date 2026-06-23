import 'package:flutter/material.dart';

enum PremiumFeature { aiHair, aiBeard, aiNails }

extension PremiumFeatureDetails on PremiumFeature {
  String get label => switch (this) {
    PremiumFeature.aiHair => 'AI Hair Studio',
    PremiumFeature.aiBeard => 'AI Beard Studio',
    PremiumFeature.aiNails => 'AI Nail Studio',
  };

  IconData get icon => switch (this) {
    PremiumFeature.aiHair => Icons.content_cut,
    PremiumFeature.aiBeard => Icons.face_retouching_natural,
    PremiumFeature.aiNails => Icons.back_hand_outlined,
  };
}

const allPremiumFeatures = {
  PremiumFeature.aiHair,
  PremiumFeature.aiBeard,
  PremiumFeature.aiNails,
};

class PremiumPlan {
  final String id;
  final String name;
  final String priceLabel;
  final String billingLabel;
  final Set<PremiumFeature> features;
  final bool recommended;

  const PremiumPlan({
    required this.id,
    required this.name,
    required this.priceLabel,
    required this.billingLabel,
    required this.features,
    this.recommended = false,
  });
}

const premiumPlans = [
  PremiumPlan(
    id: 'all_access_monthly',
    name: 'Premium Studio',
    priceLabel: '\u20b9199',
    billingLabel: 'per month',
    features: allPremiumFeatures,
    recommended: true,
  ),
  PremiumPlan(
    id: 'all_access_yearly',
    name: 'Premium Studio Annual',
    priceLabel: '\u20b91,499',
    billingLabel: 'per year',
    features: allPremiumFeatures,
  ),
];
