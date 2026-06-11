import 'dart:ui';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class ArOverlayRenderer {
  HairstyleOverlay calculateHairstyleOverlay(Face face) {
    final box = face.boundingBox;
    return HairstyleOverlay(
      center: Offset(box.center.dx, box.top - box.height * 0.12),
      width: box.width * 1.55,
      height: box.height * 0.75,
      rotation: (face.headEulerAngleZ ?? 0) * 3.14159265359 / 180,
    );
  }

  BeardOverlay calculateBeardOverlay(Face face) {
    final box = face.boundingBox;
    return BeardOverlay(
      center: Offset(box.center.dx, box.top + box.height * 0.78),
      width: box.width * 0.95,
      height: box.height * 0.52,
      rotation: (face.headEulerAngleZ ?? 0) * 3.14159265359 / 180,
    );
  }

  ArSuitability checkFaceSuitability(Face face) {
    final yaw = (face.headEulerAngleY ?? 0).abs();
    final pitch = (face.headEulerAngleX ?? 0).abs();
    final roll = (face.headEulerAngleZ ?? 0).abs();
    final landmarkCount = face.landmarks.values
        .where((landmark) => landmark != null)
        .length;

    return ArSuitability(
      isSuitable:
          yaw < 28 && pitch < 28 && roll < 28 && face.boundingBox.width > 80,
      yawAngle: yaw,
      pitchAngle: pitch,
      rollAngle: roll,
      faceSize: face.boundingBox.width,
      landmarkCount: landmarkCount,
    );
  }
}

class HairstyleOverlay {
  final Offset center;
  final double width;
  final double height;
  final double rotation;

  const HairstyleOverlay({
    required this.center,
    required this.width,
    required this.height,
    required this.rotation,
  });
}

class BeardOverlay {
  final Offset center;
  final double width;
  final double height;
  final double rotation;

  const BeardOverlay({
    required this.center,
    required this.width,
    required this.height,
    required this.rotation,
  });
}

class ArSuitability {
  final bool isSuitable;
  final double yawAngle;
  final double pitchAngle;
  final double rollAngle;
  final double faceSize;
  final int landmarkCount;

  const ArSuitability({
    required this.isSuitable,
    required this.yawAngle,
    required this.pitchAngle,
    required this.rollAngle,
    required this.faceSize,
    required this.landmarkCount,
  });

  String get suitabilityReason {
    if (yawAngle >= 28) return 'Look straight at the camera';
    if (pitchAngle >= 28) return 'Keep your chin level';
    if (rollAngle >= 28) return 'Keep your head upright';
    if (faceSize <= 80) return 'Move closer to the camera';
    return 'Ready to try a style';
  }
}
