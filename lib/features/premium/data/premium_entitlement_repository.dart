import 'package:dio/dio.dart';

import '../domain/premium_models.dart';

class PremiumVerificationResult {
  final bool verified;
  final Set<PremiumFeature> features;
  final String message;

  const PremiumVerificationResult({
    required this.verified,
    required this.features,
    required this.message,
  });
}

class PremiumEntitlementRepository {
  final Dio _dio;

  PremiumEntitlementRepository({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'http://192.168.1.10:3000',
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 20),
              headers: {'Content-Type': 'application/json'},
            ),
          );

  Future<PremiumVerificationResult> verifyDevelopmentPurchase({
    required String userId,
    required Set<PremiumFeature> features,
    required String provider,
    required String productId,
  }) async {
    try {
      final response = await _dio.post(
        '/api/ar-tryon/premium/verify',
        data: {
          'userId': userId,
          'featureIds': features.map((feature) => feature.name).toList(),
          'provider': provider,
          'productId': productId,
          'purchaseToken':
              'development-${DateTime.now().millisecondsSinceEpoch}',
          'developmentMock': true,
        },
      );
      final data = Map<String, dynamic>.from(response.data as Map);
      final verifiedIds = (data['featureIds'] as List<dynamic>? ?? const [])
          .map((id) => id.toString())
          .toSet();
      return PremiumVerificationResult(
        verified: data['verified'] == true,
        features: PremiumFeature.values
            .where((feature) => verifiedIds.contains(feature.name))
            .toSet(),
        message: data['verified'] == true
            ? 'Purchase verified by backend.'
            : 'Backend did not verify this purchase.',
      );
    } on DioException catch (error) {
      final response = error.response?.data;
      return PremiumVerificationResult(
        verified: false,
        features: const {},
        message: response is Map && response['message'] != null
            ? response['message'].toString()
            : 'Could not reach the payment verification backend.',
      );
    }
  }
}
