import 'dart:io';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:google_mlkit_face_mesh_detection/google_mlkit_face_mesh_detection.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';

class HandLandmarkPoint {
  final double x;
  final double y;
  final double z;

  const HandLandmarkPoint({
    required this.x,
    required this.y,
    required this.z,
  });

  Offset get normalizedOffset => Offset(x, y);
}

class AdvancedTryOnDetectionService {
  static const _handChannel = MethodChannel('the_salon_app/hand_landmarks');

  final FaceMeshDetector _faceMeshDetector = FaceMeshDetector(
    option: FaceMeshDetectorOptions.faceMesh,
  );
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      model: PoseDetectionModel.accurate,
      mode: PoseDetectionMode.single,
    ),
  );
  final SelfieSegmenter _segmenter = SelfieSegmenter(
    mode: SegmenterMode.single,
  );

  Future<List<FaceMesh>> detectFaceMeshes(InputImage inputImage) async {
    if (!Platform.isAndroid) return const [];
    return _faceMeshDetector.processImage(inputImage);
  }

  Future<List<Pose>> detectPoses(InputImage inputImage) {
    return _poseDetector.processImage(inputImage);
  }

  Future<SegmentationMask?> detectPersonMask(InputImage inputImage) {
    return _segmenter.processImage(inputImage);
  }

  Future<List<HandLandmarkPoint>> detectHandLandmarks(String imagePath) async {
    if (!Platform.isAndroid) return const [];
    final result = await _handChannel.invokeMethod<List<dynamic>>(
      'detectHandLandmarks',
      {'imagePath': imagePath},
    );
    if (result == null) return const [];
    return result
        .whereType<Map>()
        .map(
          (point) => HandLandmarkPoint(
            x: (point['x'] as num).toDouble(),
            y: (point['y'] as num).toDouble(),
            z: (point['z'] as num).toDouble(),
          ),
        )
        .toList(growable: false);
  }

  Future<void> dispose() async {
    await _faceMeshDetector.close();
    await _poseDetector.close();
    await _segmenter.close();
  }
}
