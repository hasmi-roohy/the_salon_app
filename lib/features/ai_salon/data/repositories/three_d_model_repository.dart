import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../models/three_d_tryon_model.dart';

abstract class ThreeDModelRepository {
  List<ThreeDModel> modelsFor(ThreeDCategory category);
}

class LocalThreeDModelRepository implements ThreeDModelRepository {
  static const _models = [
    ThreeDModel(
      id: 'hair-textured-crop-3d',
      name: 'Textured crop AI',
      category: ThreeDCategory.hair,
      assetPath: '',
      icon: Icons.face_retouching_natural,
      previewColor: Color(0xff3d2b1f),
    ),
    ThreeDModel(
      id: 'hair-long-layers-3d',
      name: 'Long layers AI',
      category: ThreeDCategory.hair,
      assetPath: '',
      icon: Icons.face,
      previewColor: Color(0xff8d5a3b),
    ),
    ThreeDModel(
      id: 'hair-curls-3d',
      name: 'Curls AI',
      category: ThreeDCategory.hair,
      assetPath: '',
      icon: Icons.view_in_ar_outlined,
      previewColor: Color(0xff24150f),
    ),
    ThreeDModel(
      id: 'hair-wolf-cut-3d',
      name: 'Wolf cut AI',
      category: ThreeDCategory.hair,
      assetPath: '',
      icon: Icons.auto_awesome,
      previewColor: Color(0xff6b3f2a),
    ),
    ThreeDModel(
      id: 'hair-braided-3d',
      name: 'Braids AI',
      category: ThreeDCategory.hair,
      assetPath: '',
      icon: Icons.face_4_outlined,
      previewColor: Color(0xff21150f),
    ),
    ThreeDModel(
      id: 'hair-pixie-3d',
      name: 'Pixie AI',
      category: ThreeDCategory.hair,
      assetPath: '',
      icon: Icons.face_3_outlined,
      previewColor: Color(0xff7a4b2b),
    ),
    ThreeDModel(
      id: 'beard-full-3d',
      name: 'Full beard AI',
      category: ThreeDCategory.beard,
      assetPath: '',
      icon: Icons.face,
      previewColor: Color(0xff4a2c21),
    ),
    ThreeDModel(
      id: 'beard-stubble-3d',
      name: 'Stubble AI',
      category: ThreeDCategory.beard,
      assetPath: '',
      icon: Icons.face_retouching_natural,
      previewColor: Color(0xff2f2a27),
    ),
    ThreeDModel(
      id: 'beard-boxed-3d',
      name: 'Boxed beard AI',
      category: ThreeDCategory.beard,
      assetPath: '',
      icon: Icons.view_in_ar_outlined,
      previewColor: Color(0xff5d3a27),
    ),
    ThreeDModel(
      id: 'beard-goatee-3d',
      name: 'Goatee AI',
      category: ThreeDCategory.beard,
      assetPath: '',
      icon: Icons.face_6_outlined,
      previewColor: Color(0xff3b241b),
    ),
    ThreeDModel(
      id: 'beard-moustache-3d',
      name: 'Moustache AI',
      category: ThreeDCategory.beard,
      assetPath: '',
      icon: Icons.face_retouching_natural,
      previewColor: Color(0xff231a15),
    ),
    ThreeDModel(
      id: 'nails-glossy-3d',
      name: 'Glossy nails AI',
      category: ThreeDCategory.nails,
      assetPath: '',
      icon: Icons.back_hand_outlined,
      previewColor: Color(0xff8b1620),
    ),
    ThreeDModel(
      id: 'nails-chrome-3d',
      name: 'Chrome nails AI',
      category: ThreeDCategory.nails,
      assetPath: '',
      icon: Icons.auto_awesome,
      previewColor: Color(0xffb8a56a),
    ),
    ThreeDModel(
      id: 'nails-french-3d',
      name: 'French tips AI',
      category: ThreeDCategory.nails,
      assetPath: '',
      icon: Icons.view_in_ar_outlined,
      previewColor: Color(0xffffdbe4),
    ),
    ThreeDModel(
      id: 'nails-ombre-3d',
      name: 'Ombre nails AI',
      category: ThreeDCategory.nails,
      assetPath: '',
      icon: Icons.gradient_outlined,
      previewColor: Color(0xffd9859c),
    ),
    ThreeDModel(
      id: 'nails-almond-3d',
      name: 'Almond nails AI',
      category: ThreeDCategory.nails,
      assetPath: '',
      icon: Icons.back_hand_outlined,
      previewColor: Color(0xff8f2440),
    ),
    ThreeDModel(
      id: 'nails-short-nude-3d',
      name: 'Short nude AI',
      category: ThreeDCategory.nails,
      assetPath: '',
      icon: Icons.pan_tool_alt_outlined,
      previewColor: Color(0xffd4a28e),
    ),
  ];

  @override
  List<ThreeDModel> modelsFor(ThreeDCategory category) {
    return _models.where((model) => model.category == category).toList();
  }
}

class ThreeDGenerationResult {
  final String provider;
  final String message;
  final String? modelUrl;
  final String? previewImageUrl;
  final String? taskId;

  const ThreeDGenerationResult({
    required this.provider,
    required this.message,
    this.modelUrl,
    this.previewImageUrl,
    this.taskId,
  });

  factory ThreeDGenerationResult.fromJson(Map<String, dynamic> json) {
    return ThreeDGenerationResult(
      provider: json['provider']?.toString() ?? 'ai_tryon',
      message: json['message']?.toString() ?? 'AI provider response received.',
      modelUrl: json['imageUrl']?.toString() ?? json['modelUrl']?.toString(),
      previewImageUrl: json['previewImageUrl']?.toString(),
      taskId: json['taskId']?.toString(),
    );
  }
}

class PremiumThreeDRepository {
  final Dio _dio;

  PremiumThreeDRepository({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'http://192.168.1.10:3000',
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 45),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
            ),
          );

  Future<ThreeDGenerationResult> generate({
    required ThreeDCategory category,
    required String styleId,
    required String prompt,
    String? imageBase64,
  }) async {
    try {
      final payload = {
        'category': _categoryName(category),
        'styleId': styleId,
        'prompt': prompt,
      };
      if (imageBase64 != null) {
        payload['imageBase64'] = imageBase64;
      }
      final response = await _dio.post(
        '/api/ar-tryon/ai-image/generate',
        data: payload,
      );
      return ThreeDGenerationResult.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (error) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null) {
        final message = data['message'];
        if (message is Map) {
          return ThreeDGenerationResult(
            provider: message['provider']?.toString() ?? 'ai_tryon',
            message:
                message['message']?.toString() ??
                'AI image provider is not configured.',
          );
        }
        return ThreeDGenerationResult(
          provider: data['provider']?.toString() ?? 'ai_tryon',
          message: message.toString(),
        );
      }
      return const ThreeDGenerationResult(
        provider: 'ai_tryon',
        message:
            'Could not reach the AI try-on backend. Start NestJS or update the API base URL.',
      );
    }
  }

  String _categoryName(ThreeDCategory category) {
    return switch (category) {
      ThreeDCategory.hair => 'hair',
      ThreeDCategory.beard => 'beard',
      ThreeDCategory.nails => 'nails',
    };
  }
}
