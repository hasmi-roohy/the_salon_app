import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class FaceDetectionService {
  late final FaceDetector _faceDetector;
  bool _initialized = false;

  FaceDetectionService() {
    _initializeFaceDetector();
  }

  void _initializeFaceDetector() {
    final options = FaceDetectorOptions(
      enableClassification: true,
      enableTracking: true,
      enableContour: true,
      enableLandmarks: true,
      minFaceSize: 0.1,
    );
    _faceDetector = FaceDetector(options: options);
    _initialized = true;
  }

  /// Detect faces and landmarks from image bytes
  Future<List<Face>> detectFaces(
    Uint8List imageBytes, {
    required int width,
    required int height,
    required InputImageRotation rotation,
  }) async {
    if (!_initialized) {
      throw Exception('FaceDetectionService not initialized');
    }

    try {
      final inputImage = InputImage.fromBytes(
        bytes: imageBytes,
        metadata: InputImageMetadata(
          size: Size(width.toDouble(), height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.yuv420,
          bytesPerRow: width,
        ),
      );

      final faces = await _faceDetector.processImage(inputImage);
      return faces;
    } catch (e) {
      debugPrint('Face detection error: $e');
      return [];
    }
  }

  /// Get face landmarks for AR overlay positioning
  Map<String, Offset> getFaceLandmarks(Face face) {
    final landmarks = <String, Offset>{};

    if (face.landmarks.isEmpty) return landmarks;

    for (final landmark in face.landmarks) {
      final position = landmark.position;
      landmarks[landmark.type.toString()] = Offset(position.x, position.y);
    }

    return landmarks;
  }

  /// Get face bounding box
  Rect getFaceBoundingBox(Face face) {
    return face.boundingBox;
  }

  /// Get face rotation angles (yaw, pitch, roll)
  Map<String, double> getFaceRotation(Face face) {
    return {
      'headEulerAngleX': face.headEulerAngleX ?? 0,
      'headEulerAngleY': face.headEulerAngleY ?? 0,
      'headEulerAngleZ': face.headEulerAngleZ ?? 0,
    };
  }

  /// Get face contour points (outline of face)
  Map<String, List<Offset>> getFaceContours(Face face) {
    final contours = <String, List<Offset>>{};

    for (final contour in face.contours) {
      final points = contour.points.map((p) => Offset(p.x, p.y)).toList();
      contours[contour.type.toString()] = points;
    }

    return contours;
  }

  /// Clean up resources
  void dispose() {
    _faceDetector.close();
    _initialized = false;
  }

  /// Get specific landmark by type
  Offset? getLandmarkByType(Face face, FaceLandmarkType type) {
    try {
      final landmark = face.landmarks.firstWhere((l) => l.type == type);
      final pos = landmark.position;
      return Offset(pos.x, pos.y);
    } catch (e) {
      return null;
    }
  }

  /// Get multiple landmarks at once
  Map<FaceLandmarkType, Offset> getMultipleLandmarks(
    Face face,
    List<FaceLandmarkType> types,
  ) {
    final result = <FaceLandmarkType, Offset>{};
    for (final type in types) {
      final pos = getLandmarkByType(face, type);
      if (pos != null) {
        result[type] = pos;
      }
    }
    return result;
  }
}
