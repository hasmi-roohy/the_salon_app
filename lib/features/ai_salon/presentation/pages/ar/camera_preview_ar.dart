import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:async';
import 'dart:developer' as developer;
import '../services/face_detection_service.dart';
import '../services/ar_overlay_renderer.dart';

class CameraPreviewWithAR extends StatefulWidget {
  final void Function(HairstyleOverlay?)? onHairstyleOverlay;
  final void Function(BeardOverlay?)? onBeardOverlay;
  final void Function(ArSuitability)? onSuitabilityChanged;

  const CameraPreviewWithAR({
    Key? key,
    this.onHairstyleOverlay,
    this.onBeardOverlay,
    this.onSuitabilityChanged,
  }) : super(key: key);

  @override
  State<CameraPreviewWithAR> createState() => _CameraPreviewWithARState();
}

class _CameraPreviewWithARState extends State<CameraPreviewWithAR>
    with WidgetsBindingObserver {
  late CameraController _cameraController;
  late FaceDetectionService _faceDetectionService;
  late ArOverlayRenderer _arRenderer;

  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  Face? _detectedFace;
  HairstyleOverlay? _hairstyleOverlay;
  BeardOverlay? _beardOverlay;
  ArSuitability? _suitability;

  // Performance monitoring
  final List<int> _processingTimes = [];
  int _frameCount = 0;
  double _fps = 0;

  // Landmark smoothing
  Map<String, Offset>? _previousLandmarks;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    _faceDetectionService = FaceDetectionService();
    _arRenderer = ArOverlayRenderer();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium, // 480x640 - good balance for AR
        enableAudio: false,
      );

      await _cameraController.initialize();

      if (mounted) {
        setState(() => _isCameraInitialized = true);
        _startFaceDetection();
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      _showError('Failed to initialize camera: $e');
    }
  }

  void _startFaceDetection() {
    _cameraController.startImageStream(_processCameraImage);
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessing) return;
    _isProcessing = true;

    final stopwatch = Stopwatch()..start();

    try {
      final rotation = _getImageRotation();

      // Detect faces
      final faces = await _faceDetectionService.detectFaces(
        image.planes[0].bytes,
        width: image.width,
        height: image.height,
        rotation: rotation,
      );

      stopwatch.stop();
      final processingTime = stopwatch.elapsedMilliseconds;

      if (mounted) {
        setState(() {
          _detectedFace = faces.isNotEmpty ? faces[0] : null;

          if (_detectedFace != null) {
            // Calculate AR overlays
            _hairstyleOverlay =
                _arRenderer.calculateHairstyleOverlay(_detectedFace!, Size(image.width.toDouble(), image.height.toDouble()));
            _beardOverlay = _arRenderer.calculateBeardOverlay(_detectedFace!, Size(image.width.toDouble(), image.height.toDouble()));
            _suitability = _arRenderer.checkFaceSuitability(_detectedFace!);

            // Callback to parent
            widget.onHairstyleOverlay?.call(_hairstyleOverlay);
            widget.onBeardOverlay?.call(_beardOverlay);
            widget.onSuitabilityChanged?.call(_suitability!);
          } else {
            _hairstyleOverlay = null;
            _beardOverlay = null;
            _suitability = null;
          }

          // Performance tracking
          _processingTimes.add(processingTime);
          if (_processingTimes.length > 30) {
            _processingTimes.removeAt(0);
          }
          _frameCount++;

          if (_frameCount % 30 == 0) {
            final avgTime = _processingTimes.isEmpty
                ? 0
                : _processingTimes.reduce((a, b) => a + b) ~/ _processingTimes.length;
            _fps = 1000 / avgTime;
            developer.log('FPS: ${_fps.toStringAsFixed(1)}, Avg time: ${avgTime}ms');
          }
        });
      }
    } catch (e) {
      debugPrint('Face detection processing error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  InputImageRotation _getImageRotation() {
    final sensorOrientation = _cameraController.description.sensorOrientation;
    switch (sensorOrientation) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isCameraInitialized) return;

    if (state == AppLifecycleState.paused) {
      _cameraController.stopImageStream();
    } else if (state == AppLifecycleState.resumed) {
      _startFaceDetection();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController.dispose();
    _faceDetectionService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        // Camera preview
        CameraPreview(_cameraController),

        // AR Overlay painter
        if (_detectedFace != null)
          CustomPaint(
            painter: FaceLandmarkPainter(
              face: _detectedFace!,
              hairstyleOverlay: _hairstyleOverlay,
              beardOverlay: _beardOverlay,
            ),
            size: Size.infinite,
          ),

        // UI Overlays (top-left)
        Positioned(
          top: 16,
          left: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // FPS Counter
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'FPS: ${_fps.toStringAsFixed(1)}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Suitability status
              if (_suitability != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _suitability!.isSuitable
                        ? Colors.green.withOpacity(0.8)
                        : Colors.orange.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _suitability!.suitabilityReason,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),

        // Overlay data (top-right)
        if (_detectedFace != null)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Face Detected',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Landmarks: ${_detectedFace!.landmarks.length}',
                    style: const TextStyle(color: Colors.cyan, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  if (_suitability != null) ...[
                    Text(
                      'Yaw: ${_suitability!.yawAngle.toStringAsFixed(1)}°',
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                    Text(
                      'Pitch: ${_suitability!.pitchAngle.toStringAsFixed(1)}°',
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Custom painter for face landmarks and AR overlay visualization
class FaceLandmarkPainter extends CustomPainter {
  final Face face;
  final HairstyleOverlay? hairstyleOverlay;
  final BeardOverlay? beardOverlay;

  FaceLandmarkPainter({
    required this.face,
    this.hairstyleOverlay,
    this.beardOverlay,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw face bounding box
    final boundingBox = face.boundingBox;
    canvas.drawRect(
      boundingBox,
      Paint()
        ..color = Colors.green
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    // Draw face landmarks
    final landmarkPaint = Paint()
      ..color = Colors.cyan
      ..strokeWidth = 3;

    for (final landmark in face.landmarks) {
      canvas.drawCircle(landmark.position, 3, landmarkPaint);
    }

    // Draw face contours (outline)
    final contourPaint = Paint()
      ..color = Colors.yellow.withOpacity(0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final contour in face.contours) {
      if (contour.points.isEmpty) continue;

      final points = contour.points.map((p) => p.toOffset()).toList();
      for (int i = 0; i < points.length - 1; i++) {
        canvas.drawLine(points[i], points[i + 1], contourPaint);
      }
    }

    // Draw hairstyle overlay position
    if (hairstyleOverlay != null) {
      _drawOverlayPosition(
        canvas,
        hairstyleOverlay!.position,
        100,
        Colors.purple.withOpacity(0.3),
        'Hair',
      );
    }

    // Draw beard overlay position
    if (beardOverlay != null) {
      _drawOverlayPosition(
        canvas,
        beardOverlay!.position,
        80,
        Colors.orange.withOpacity(0.3),
        'Beard',
      );
    }
  }

  void _drawOverlayPosition(
    Canvas canvas,
    Offset position,
    double size,
    Color color,
    String label,
  ) {
    // Draw circle at overlay position
    canvas.drawCircle(
      position,
      size / 2,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );

    // Draw circle outline
    canvas.drawCircle(
      position,
      size / 2,
      Paint()
        ..color = color.withOpacity(1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Draw label
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(position.dx - textPainter.width / 2, position.dy - 30),
    );
  }

  @override
  bool shouldRepaint(FaceLandmarkPainter oldDelegate) {
    return oldDelegate.face != face;
  }
}

extension on Offset {
  Offset toOffset() => this;
}
