import 'package:dio/dio.dart';

class Hairstyle {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final String modelPath;
  final String category;
  final int trialCount;
  final bool isActive;
  final Map<String, dynamic>? metadata;

  Hairstyle({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.modelPath,
    required this.category,
    required this.trialCount,
    required this.isActive,
    this.metadata,
  });

  factory Hairstyle.fromJson(Map<String, dynamic> json) {
    return Hairstyle(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      modelPath: json['modelPath'] as String,
      category: json['category'] as String,
      trialCount: json['trialCount'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'imageUrl': imageUrl,
    'modelPath': modelPath,
    'category': category,
    'trialCount': trialCount,
    'isActive': isActive,
    'metadata': metadata,
  };
}

class Beard {
  final String id;
  final String name;
  final String style;
  final String? description;
  final String? imageUrl;
  final String modelPath;
  final int trialCount;
  final bool isActive;
  final Map<String, dynamic>? metadata;

  Beard({
    required this.id,
    required this.name,
    required this.style,
    this.description,
    this.imageUrl,
    required this.modelPath,
    required this.trialCount,
    required this.isActive,
    this.metadata,
  });

  factory Beard.fromJson(Map<String, dynamic> json) {
    return Beard(
      id: json['id'] as String,
      name: json['name'] as String,
      style: json['style'] as String,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      modelPath: json['modelPath'] as String,
      trialCount: json['trialCount'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'style': style,
    'description': description,
    'imageUrl': imageUrl,
    'modelPath': modelPath,
    'trialCount': trialCount,
    'isActive': isActive,
    'metadata': metadata,
  };
}

class Nail {
  final String id;
  final String name;
  final String design;
  final String? description;
  final String? imageUrl;
  final String overlayPath;
  final int trialCount;
  final bool isActive;
  final Map<String, dynamic>? colorPalette;
  final Map<String, dynamic>? metadata;

  Nail({
    required this.id,
    required this.name,
    required this.design,
    this.description,
    this.imageUrl,
    required this.overlayPath,
    required this.trialCount,
    required this.isActive,
    this.colorPalette,
    this.metadata,
  });

  factory Nail.fromJson(Map<String, dynamic> json) {
    return Nail(
      id: json['id'] as String,
      name: json['name'] as String,
      design: json['design'] as String,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      overlayPath: json['overlayPath'] as String,
      trialCount: json['trialCount'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      colorPalette: json['colorPalette'] as Map<String, dynamic>?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'design': design,
    'description': description,
    'imageUrl': imageUrl,
    'overlayPath': overlayPath,
    'trialCount': trialCount,
    'isActive': isActive,
    'colorPalette': colorPalette,
    'metadata': metadata,
  };
}

class TryOnResult {
  final String id;
  final String userId;
  final String? hairstyleId;
  final String? beardId;
  final String? nailId;
  final String? originalImageUrl;
  final String? resultImageUrl;
  final bool isShared;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  TryOnResult({
    required this.id,
    required this.userId,
    this.hairstyleId,
    this.beardId,
    this.nailId,
    this.originalImageUrl,
    this.resultImageUrl,
    required this.isShared,
    required this.createdAt,
    this.metadata,
  });

  factory TryOnResult.fromJson(Map<String, dynamic> json) {
    return TryOnResult(
      id: json['id'] as String,
      userId: json['userId'] as String,
      hairstyleId: json['hairstyleId'] as String?,
      beardId: json['beardId'] as String?,
      nailId: json['nailId'] as String?,
      originalImageUrl: json['originalImageUrl'] as String?,
      resultImageUrl: json['resultImageUrl'] as String?,
      isShared: json['isShared'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'hairstyleId': hairstyleId,
    'beardId': beardId,
    'nailId': nailId,
    'originalImageUrl': originalImageUrl,
    'resultImageUrl': resultImageUrl,
    'isShared': isShared,
    'createdAt': createdAt.toIso8601String(),
    'metadata': metadata,
  };
}

class Recommendations {
  final List<Hairstyle> hairstyles;
  final List<Beard> beards;
  final List<Nail> nails;
  final String? basedOnFaceShape;
  final bool personalized;

  Recommendations({
    required this.hairstyles,
    required this.beards,
    required this.nails,
    this.basedOnFaceShape,
    required this.personalized,
  });

  factory Recommendations.fromJson(Map<String, dynamic> json) {
    return Recommendations(
      hairstyles: (json['hairstyles'] as List?)
          ?.map((e) => Hairstyle.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      beards: (json['beards'] as List?)
          ?.map((e) => Beard.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      nails: (json['nails'] as List?)
          ?.map((e) => Nail.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      basedOnFaceShape: json['basedOnFaceShape'] as String?,
      personalized: json['personalized'] as bool? ?? false,
    );
  }
}
