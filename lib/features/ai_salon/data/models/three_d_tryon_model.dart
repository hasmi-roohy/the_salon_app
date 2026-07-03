import 'package:flutter/material.dart';

enum ThreeDCategory { hair, beard, nails, mehndi }

class ThreeDModel {
  final String id;
  final String name;
  final ThreeDCategory category;
  final String assetPath;
  final IconData icon;
  final Color previewColor;
  final bool premium;

  const ThreeDModel({
    required this.id,
    required this.name,
    required this.category,
    required this.assetPath,
    required this.icon,
    required this.previewColor,
    this.premium = true,
  });
}
