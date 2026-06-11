import 'package:dio/dio.dart';

class AiDiagnosticRepository {
  final Dio _dio;

  AiDiagnosticRepository({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'http://192.168.1.10:3000',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
            ),
          );

  Future<List<dynamic>> searchStylists(String query) async {
    try {
      final response = await _dio.post('/ai/search', data: {'query': query});

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as List<dynamic>;
      } else {
        throw Exception('Failed to load recommendations');
      }
    } on DioException {
      // For demonstration purposes, if the backend is not running,
      // we will return some mock data after a delay to simulate the pgvector response.
      await Future.delayed(const Duration(seconds: 2));
      return [
        {
          'id': '1',
          'name': 'Elena Rodriguez',
          'specialty': 'Balayage & Color Correction',
          'score': 0.98,
        },
        {
          'id': '2',
          'name': 'Marcus Chen',
          'specialty': 'Precision Cuts & Styling',
          'score': 0.85,
        },
        {
          'id': '3',
          'name': 'Sarah Jenkins',
          'specialty': 'Extensions & Volume',
          'score': 0.72,
        },
      ];
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}
