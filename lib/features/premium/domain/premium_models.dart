import 'package:flutter/material.dart';

enum PremiumFeature { aiHair, aiBeard, aiNails, aiMehndi }

extension PremiumFeatureDetails on PremiumFeature {
  String get label => switch (this) {
    PremiumFeature.aiHair => 'AI Hair Studio',
    PremiumFeature.aiBeard => 'AI Beard Studio',
    PremiumFeature.aiNails => 'AI Nail Studio',
    PremiumFeature.aiMehndi => 'AI Mehndi Studio',
  };

  IconData get icon => switch (this) {
    PremiumFeature.aiHair => Icons.content_cut,
    PremiumFeature.aiBeard => Icons.face_retouching_natural,
    PremiumFeature.aiNails => Icons.back_hand_outlined,
    PremiumFeature.aiMehndi => Icons.draw_outlined,
  };

  String get description => switch (this) {
    PremiumFeature.aiHair => 'Realistic hairstyle and color previews.',
    PremiumFeature.aiBeard => 'Beard, moustache, and grooming previews.',
    PremiumFeature.aiNails => 'Premium nail shapes, colors, and designs.',
    PremiumFeature.aiMehndi =>
        'Bridal, Arabic, mandala, and wrist mehndi renders.',
  };

  int get monthlyPrice => switch (this) {
    PremiumFeature.aiHair => 79,
    PremiumFeature.aiBeard => 59,
    PremiumFeature.aiNails => 69,
    PremiumFeature.aiMehndi => 49,
  };
}

const allPremiumFeatures = {
  PremiumFeature.aiHair,
  PremiumFeature.aiBeard,
  PremiumFeature.aiNails,
  PremiumFeature.aiMehndi,
};

String formatRupees(int amount) => '\u20b9$amount';
