import 'dart:math' as math;
import 'dart:ui';

import 'package:google_mlkit_face_mesh_detection/google_mlkit_face_mesh_detection.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class ArOverlayRenderer {
  HairstyleOverlay calculateHairstyleOverlay(Face face) {
    final box = face.boundingBox;
    final faceContour = _contourPoints(face, FaceContourType.face);
    final contourBox = _bounds(faceContour);
    final anchor = contourBox ?? box;
    final roll = _rollRadians(face);

    final width = anchor.width * 1.62;
    final height = anchor.height * 0.72;
    final topLift = anchor.height * 0.09;

    return HairstyleOverlay(
      center: Offset(anchor.center.dx, anchor.top - topLift),
      width: width,
      height: height,
      rotation: roll,
    );
  }

  BeardOverlay calculateBeardOverlay(Face face) {
    final box = face.boundingBox;
    final faceContour = _contourPoints(face, FaceContourType.face);
    final contourBox = _bounds(faceContour);
    final anchor = contourBox ?? box;
    final chin =
        _lowestPoint(faceContour) ?? Offset(anchor.center.dx, anchor.bottom);
    final mouth =
        _landmark(face, FaceLandmarkType.bottomMouth) ??
        Offset(anchor.center.dx, anchor.top + anchor.height * 0.64);
    final beardHeight = ((chin.dy - mouth.dy) * 1.7).clamp(
      anchor.height * 0.28,
      anchor.height * 0.58,
    );
    final beardCenterY = mouth.dy + beardHeight * 0.48;

    return BeardOverlay(
      center: Offset(anchor.center.dx, beardCenterY),
      width: anchor.width * 0.92,
      height: beardHeight.toDouble(),
      rotation: _rollRadians(face),
    );
  }

  HairstyleOverlay calculateHairstyleOverlayFromMesh(FaceMesh mesh) {
    final oval = _meshContourPoints(mesh, FaceMeshContourType.faceOval);
    final ovalBox = _bounds(oval) ?? mesh.boundingBox;
    final eyebrowTop = [
      ..._meshContourPoints(mesh, FaceMeshContourType.leftEyebrowTop),
      ..._meshContourPoints(mesh, FaceMeshContourType.rightEyebrowTop),
    ];
    final foreheadLine = eyebrowTop.isEmpty
        ? ovalBox.top + ovalBox.height * 0.26
        : eyebrowTop.map((point) => point.dy).reduce(math.min);
    final meshRoll = _meshRoll(mesh);

    return HairstyleOverlay(
      center: Offset(ovalBox.center.dx, foreheadLine - ovalBox.height * 0.34),
      width: ovalBox.width * 1.68,
      height: ovalBox.height * 0.82,
      rotation: meshRoll,
    );
  }

  BeardOverlay calculateBeardOverlayFromMesh(FaceMesh mesh) {
    final oval = _meshContourPoints(mesh, FaceMeshContourType.faceOval);
    final ovalBox = _bounds(oval) ?? mesh.boundingBox;
    final lowerLip = [
      ..._meshContourPoints(mesh, FaceMeshContourType.lowerLipTop),
      ..._meshContourPoints(mesh, FaceMeshContourType.lowerLipBottom),
    ];
    final mouthY = lowerLip.isEmpty
        ? ovalBox.top + ovalBox.height * 0.62
        : lowerLip.map((point) => point.dy).reduce(math.max);
    final chin =
        _lowestPoint(oval) ?? Offset(ovalBox.center.dx, ovalBox.bottom);
    final height = ((chin.dy - mouthY) * 1.65).clamp(
      ovalBox.height * 0.28,
      ovalBox.height * 0.56,
    );

    return BeardOverlay(
      center: Offset(ovalBox.center.dx, mouthY + height * 0.48),
      width: ovalBox.width * 0.92,
      height: height.toDouble(),
      rotation: _meshRoll(mesh),
    );
  }

  TattooOverlay? calculateTattooOverlayFromPose(Pose pose) {
    final leftWrist = _posePoint(pose, PoseLandmarkType.leftWrist);
    final leftElbow = _posePoint(pose, PoseLandmarkType.leftElbow);
    final rightWrist = _posePoint(pose, PoseLandmarkType.rightWrist);
    final rightElbow = _posePoint(pose, PoseLandmarkType.rightElbow);
    final leftShoulder = _posePoint(pose, PoseLandmarkType.leftShoulder);
    final rightShoulder = _posePoint(pose, PoseLandmarkType.rightShoulder);

    final arm = _bestSegment(leftElbow, leftWrist, rightElbow, rightWrist);
    if (arm != null) {
      final start = arm.$1;
      final end = arm.$2;
      final length = (end - start).distance;
      final center = Offset.lerp(start, end, 0.48)!;
      return TattooOverlay(
        center: center,
        width: length * 0.5,
        height: length * 0.5,
        rotation:
            math.atan2(end.dy - start.dy, end.dx - start.dx) + math.pi / 2,
      );
    }

    if (leftShoulder != null && rightShoulder != null) {
      final shoulderWidth = (rightShoulder - leftShoulder).distance;
      return TattooOverlay(
        center:
            Offset.lerp(leftShoulder, rightShoulder, 0.5)! +
            Offset(0, shoulderWidth * 0.28),
        width: shoulderWidth * 0.28,
        height: shoulderWidth * 0.28,
        rotation: math.atan2(
          rightShoulder.dy - leftShoulder.dy,
          rightShoulder.dx - leftShoulder.dx,
        ),
      );
    }

    return null;
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

  List<Offset> _contourPoints(Face face, FaceContourType type) {
    final contour = face.contours[type];
    if (contour == null) return const [];
    return contour.points
        .map((point) => Offset(point.x.toDouble(), point.y.toDouble()))
        .toList();
  }

  Rect? _bounds(List<Offset> points) {
    if (points.isEmpty) return null;
    var left = points.first.dx;
    var right = points.first.dx;
    var top = points.first.dy;
    var bottom = points.first.dy;
    for (final point in points.skip(1)) {
      left = math.min(left, point.dx);
      right = math.max(right, point.dx);
      top = math.min(top, point.dy);
      bottom = math.max(bottom, point.dy);
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  Offset? _lowestPoint(List<Offset> points) {
    if (points.isEmpty) return null;
    return points.reduce((a, b) => a.dy > b.dy ? a : b);
  }

  Offset? _landmark(Face face, FaceLandmarkType type) {
    final landmark = face.landmarks[type];
    if (landmark == null) return null;
    return Offset(
      landmark.position.x.toDouble(),
      landmark.position.y.toDouble(),
    );
  }

  double _rollRadians(Face face) {
    return (face.headEulerAngleZ ?? 0) * math.pi / 180;
  }

  List<Offset> _meshContourPoints(FaceMesh mesh, FaceMeshContourType type) {
    final points = mesh.contours[type];
    if (points == null) return const [];
    return points.map((point) => Offset(point.x, point.y)).toList();
  }

  double _meshRoll(FaceMesh mesh) {
    final leftEye = _meshContourPoints(mesh, FaceMeshContourType.leftEye);
    final rightEye = _meshContourPoints(mesh, FaceMeshContourType.rightEye);
    final leftCenter = _center(leftEye);
    final rightCenter = _center(rightEye);
    if (leftCenter == null || rightCenter == null) return 0;
    return math.atan2(
      rightCenter.dy - leftCenter.dy,
      rightCenter.dx - leftCenter.dx,
    );
  }

  Offset? _center(List<Offset> points) {
    if (points.isEmpty) return null;
    final sum = points.reduce((a, b) => a + b);
    return sum / points.length.toDouble();
  }

  Offset? _posePoint(Pose pose, PoseLandmarkType type) {
    final landmark = pose.landmarks[type];
    if (landmark == null || landmark.likelihood < 0.45) return null;
    return Offset(landmark.x, landmark.y);
  }

  (Offset, Offset)? _bestSegment(
    Offset? firstStart,
    Offset? firstEnd,
    Offset? secondStart,
    Offset? secondEnd,
  ) {
    final first = firstStart != null && firstEnd != null
        ? (firstStart, firstEnd)
        : null;
    final second = secondStart != null && secondEnd != null
        ? (secondStart, secondEnd)
        : null;
    if (first == null) return second;
    if (second == null) return first;
    final firstLength = (first.$2 - first.$1).distance;
    final secondLength = (second.$2 - second.$1).distance;
    return firstLength >= secondLength ? first : second;
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

class TattooOverlay {
  final Offset center;
  final double width;
  final double height;
  final double rotation;

  const TattooOverlay({
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
