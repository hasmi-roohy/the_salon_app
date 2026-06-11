import 'dart:ui';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectionService {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableContours: true,
      enableLandmarks: true,
      enableTracking: true,
      performanceMode: FaceDetectorMode.fast,
      minFaceSize: 0.15,
    ),
  );

  Future<List<Face>> detectFaces(InputImage inputImage) {
    return _faceDetector.processImage(inputImage);
  }

  Map<FaceLandmarkType, Offset> getFaceLandmarks(Face face) {
    final landmarks = <FaceLandmarkType, Offset>{};
    for (final entry in face.landmarks.entries) {
      final landmark = entry.value;
      if (landmark != null) {
        landmarks[entry.key] = Offset(
          landmark.position.x.toDouble(),
          landmark.position.y.toDouble(),
        );
      }
    }
    return landmarks;
  }

  Future<void> dispose() => _faceDetector.close();
}
