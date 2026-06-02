import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

/// AR Overlay Renderer - Handles all 3D/2D projection math for hairstyles, beards, nails
class ArOverlayRenderer {
  /// Calculate hairstyle overlay position and scale based on face landmarks
  HairstyleOverlay calculateHairstyleOverlay(
    Face face,
    Size canvasSize,
  ) {
    final boundingBox = face.boundingBox;
    
    // Get key landmarks for hair positioning
    final topHead = face.landmarks
        .firstWhere(
          (l) => l.type == FaceLandmarkType.topHead,
          orElse: () => Face(landmarks: [], boundingBox: boundingBox).landmarks.first,
        )
        .position;
    
    final faceWidth = boundingBox.width;
    final faceHeight = boundingBox.height;
    
    // Position: center of face, top edge
    final position = Offset(
      boundingBox.left + faceWidth / 2,
      boundingBox.top - (faceHeight * 0.3), // Above face
    );
    
    // Scale hairstyle based on face size (30-40% larger than face)
    final scale = (faceWidth + faceHeight) / 2 * 1.35 / 100;
    
    // Rotation based on head tilt
    final rotation = _calculateHeadRotation(face);
    
    return HairstyleOverlay(
      position: position,
      scale: scale,
      rotationZ: rotation['yaw'] ?? 0,
      rotationX: rotation['pitch'] ?? 0,
      rotationY: rotation['roll'] ?? 0,
    );
  }

  /// Calculate beard overlay position and scale
  BeardOverlay calculateBeardOverlay(
    Face face,
    Size canvasSize,
  ) {
    final boundingBox = face.boundingBox;
    
    // Get jawline landmarks
    final noseBase = face.landmarks
        .firstWhere(
          (l) => l.type == FaceLandmarkType.noseBase,
          orElse: () => Face(landmarks: [], boundingBox: boundingBox).landmarks.first,
        )
        .position;
    
    final bottomMouth = face.landmarks
        .firstWhere(
          (l) => l.type == FaceLandmarkType.bottomMouth,
          orElse: () => Face(landmarks: [], boundingBox: boundingBox).landmarks.first,
        )
        .position;
    
    // Position: center of lower face
    final position = Offset(
      boundingBox.left + boundingBox.width / 2,
      bottomMouth.y, // At chin level
    );
    
    // Scale based on face width (20-25% of face width)
    final scale = boundingBox.width * 0.45 / 100;
    
    // Rotation from head tilt
    final rotation = _calculateHeadRotation(face);
    
    return BeardOverlay(
      position: position,
      scale: scale,
      rotationZ: rotation['yaw'] ?? 0,
      rotationX: rotation['pitch'] ?? 0,
      rotationY: rotation['roll'] ?? 0,
      jawlineWidth: boundingBox.width,
    );
  }

  /// Calculate nail overlay positions for hand
  List<NailOverlay> calculateNailOverlays(
    List<Offset> fingerTips,
    Size canvasSize,
  ) {
    return fingerTips.asMap().entries.map((entry) {
      final index = entry.key;
      final position = entry.value;
      
      // Scale nail based on finger size (estimated from distance to hand center)
      const nailScale = 0.05; // 5% of screen
      
      return NailOverlay(
        position: position,
        scale: nailScale,
        fingerIndex: index,
        rotationZ: 0, // Will be calculated from hand landmarks
      );
    }).toList();
  }

  /// Calculate head rotation from face angles
  Map<String, double> _calculateHeadRotation(Face face) {
    return {
      'yaw': face.headEulerAngleY ?? 0,    // Left-right tilt
      'pitch': face.headEulerAngleX ?? 0,  // Up-down tilt
      'roll': face.headEulerAngleZ ?? 0,   // Clockwise tilt
    };
  }

  /// Get face proportions for adaptive sizing
  FaceProportions getFaceProportions(Face face) {
    final boundingBox = face.boundingBox;
    
    final leftEye = face.landmarks.firstWhere(
      (l) => l.type == FaceLandmarkType.leftEye,
      orElse: () => Face(landmarks: [], boundingBox: boundingBox).landmarks.first,
    ).position;
    
    final rightEye = face.landmarks.firstWhere(
      (l) => l.type == FaceLandmarkType.rightEye,
      orElse: () => Face(landmarks: [], boundingBox: boundingBox).landmarks.first,
    ).position;
    
    final eyeDistance = (rightEye.x - leftEye.x).abs();
    final faceWidth = boundingBox.width;
    final faceHeight = boundingBox.height;
    
    return FaceProportions(
      faceWidth: faceWidth,
      faceHeight: faceHeight,
      eyeDistance: eyeDistance,
      aspectRatio: faceWidth / faceHeight,
    );
  }

  /// Apply perspective transform based on head rotation
  Matrix4 getPerspectiveTransform(Map<String, double> rotation) {
    var matrix = Matrix4.identity();
    
    // Apply rotations in order: X (pitch), Y (roll), Z (yaw)
    matrix.rotateX((rotation['pitch'] ?? 0) * math.pi / 180);
    matrix.rotateY((rotation['roll'] ?? 0) * math.pi / 180);
    matrix.rotateZ((rotation['yaw'] ?? 0) * math.pi / 180);
    
    return matrix;
  }

  /// Check if face is suitable for AR (front-facing, visible, not too tilted)
  ArSuitability checkFaceSuitability(Face face) {
    final rotation = _calculateHeadRotation(face);
    final yaw = (rotation['yaw'] ?? 0).abs();
    final pitch = (rotation['pitch'] ?? 0).abs();
    final roll = (rotation['roll'] ?? 0).abs();
    
    final isFrontFacing = yaw < 30 && pitch < 30 && roll < 30;
    final isLargeEnough = face.boundingBox.width > 50; // Min 50px width
    final hasLandmarks = face.landmarks.isNotEmpty;
    
    return ArSuitability(
      isSuitable: isFrontFacing && isLargeEnough && hasLandmarks,
      yawAngle: yaw,
      pitchAngle: pitch,
      rollAngle: roll,
      faceSize: face.boundingBox.width,
      landmarkCount: face.landmarks.length,
    );
  }

  /// Smooth landmarks over time to reduce jitter (frame-to-frame stability)
  Map<String, Offset> smoothLandmarks(
    Map<String, Offset> currentLandmarks,
    Map<String, Offset>? previousLandmarks,
    double smoothingFactor = 0.7,
  ) {
    if (previousLandmarks == null || previousLandmarks.isEmpty) {
      return currentLandmarks;
    }
    
    final smoothed = <String, Offset>{};
    
    for (final entry in currentLandmarks.entries) {
      final key = entry.key;
      final current = entry.value;
      final previous = previousLandmarks[key] ?? current;
      
      // Linear interpolation: new = current * (1 - factor) + previous * factor
      smoothed[key] = Offset(
        current.dx * (1 - smoothingFactor) + previous.dx * smoothingFactor,
        current.dy * (1 - smoothingFactor) + previous.dy * smoothingFactor,
      );
    }
    
    return smoothed;
  }
}

/// Data class for hairstyle overlay properties
class HairstyleOverlay {
  final Offset position;     // Center position on screen
  final double scale;        // 0-1, relative to face
  final double rotationZ;    // Yaw (left-right tilt)
  final double rotationX;    // Pitch (up-down tilt)
  final double rotationY;    // Roll (clockwise tilt)

  HairstyleOverlay({
    required this.position,
    required this.scale,
    required this.rotationZ,
    required this.rotationX,
    required this.rotationY,
  });
}

/// Data class for beard overlay properties
class BeardOverlay {
  final Offset position;
  final double scale;
  final double rotationZ;
  final double rotationX;
  final double rotationY;
  final double jawlineWidth;

  BeardOverlay({
    required this.position,
    required this.scale,
    required this.rotationZ,
    required this.rotationX,
    required this.rotationY,
    required this.jawlineWidth,
  });
}

/// Data class for nail overlay
class NailOverlay {
  final Offset position;
  final double scale;
  final int fingerIndex;    // 0-4: thumb, index, middle, ring, pinky
  final double rotationZ;

  NailOverlay({
    required this.position,
    required this.scale,
    required this.fingerIndex,
    required this.rotationZ,
  });
}

/// Face proportions for adaptive rendering
class FaceProportions {
  final double faceWidth;
  final double faceHeight;
  final double eyeDistance;
  final double aspectRatio;

  FaceProportions({
    required this.faceWidth,
    required this.faceHeight,
    required this.eyeDistance,
    required this.aspectRatio,
  });
}

/// AR suitability check results
class ArSuitability {
  final bool isSuitable;
  final double yawAngle;
  final double pitchAngle;
  final double rollAngle;
  final double faceSize;
  final int landmarkCount;

  ArSuitability({
    required this.isSuitable,
    required this.yawAngle,
    required this.pitchAngle,
    required this.rollAngle,
    required this.faceSize,
    required this.landmarkCount,
  });

  String get suitabilityReason {
    if (!isSuitable) {
      if (yawAngle > 30) return 'Turn face forward (left-right tilt too high)';
      if (pitchAngle > 30) return 'Adjust head position (up-down tilt too high)';
      if (rollAngle > 30) return 'Keep head level (clockwise tilt too high)';
      if (faceSize < 50) return 'Move closer to camera';
      if (landmarkCount < 10) return 'Face not clearly visible';
      return 'Face not suitable for AR';
    }
    return 'Ready for AR overlay';
  }
}
