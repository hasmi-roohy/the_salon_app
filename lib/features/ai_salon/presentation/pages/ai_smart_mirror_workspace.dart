import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_face_mesh_detection/google_mlkit_face_mesh_detection.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models/three_d_tryon_model.dart';
import '../../data/repositories/three_d_model_repository.dart';
import '../../domain/services/advanced_tryon_detection_service.dart';
import '../../domain/services/ar_overlay_renderer.dart';
import '../../domain/services/face_detection_service.dart';
import '../../../premium/data/premium_access_controller.dart';
import '../../../premium/domain/premium_models.dart';
import '../../../premium/presentation/pages/premium_plans_page.dart';

enum TryOnCategory { hairstyle, beard, nailArt, tattoo }

enum HairLookGroup { men, women }

enum TryOnMode { twoD, threeD }

class TryOnStyle {
  final String id;
  final String name;
  final TryOnCategory category;
  final String assetPath;
  final HairLookGroup? hairGroup;
  final Color? tint;
  final double size;
  final double widthFactor;
  final double heightFactor;
  final double verticalOffsetFactor;

  const TryOnStyle({
    required this.id,
    required this.name,
    required this.category,
    required this.assetPath,
    this.hairGroup,
    this.tint,
    this.size = 1,
    this.widthFactor = 1,
    this.heightFactor = 1,
    this.verticalOffsetFactor = 0,
  });
}

class AiSmartMirrorWorkspace extends StatefulWidget {
  final bool enableThreeDViewer;

  const AiSmartMirrorWorkspace({super.key, this.enableThreeDViewer = true});

  @override
  State<AiSmartMirrorWorkspace> createState() => _AiSmartMirrorWorkspaceState();
}

class _AiSmartMirrorWorkspaceState extends State<AiSmartMirrorWorkspace> {
  static const _styles = [
    TryOnStyle(
      id: 'textured-black',
      name: 'Textured black',
      category: TryOnCategory.hairstyle,
      assetPath: 'assets/tryon/hair/textured-black.png',
      hairGroup: HairLookGroup.men,
      size: 1.08,
    ),
    TryOnStyle(
      id: 'textured-brown',
      name: 'Warm brown quiff',
      category: TryOnCategory.hairstyle,
      assetPath: 'assets/tryon/hair/warm-brown-quiff.png',
      hairGroup: HairLookGroup.men,
      size: 1.12,
    ),
    TryOnStyle(
      id: 'textured-burgundy',
      name: 'Burgundy crop',
      category: TryOnCategory.hairstyle,
      assetPath: 'assets/tryon/hair/burgundy-crop.png',
      hairGroup: HairLookGroup.men,
      size: 1.1,
    ),
    TryOnStyle(
      id: 'slick-back',
      name: 'Slick back',
      category: TryOnCategory.hairstyle,
      assetPath: 'assets/tryon/hair/slick-back.png',
      hairGroup: HairLookGroup.men,
      size: 1.12,
    ),
    TryOnStyle(
      id: 'curly-fade',
      name: 'Curly fade',
      category: TryOnCategory.hairstyle,
      assetPath: 'assets/tryon/hair/curly-fade.png',
      hairGroup: HairLookGroup.men,
      size: 1.12,
    ),
    TryOnStyle(
      id: 'classic-side-part',
      name: 'Classic side part',
      category: TryOnCategory.hairstyle,
      assetPath: 'assets/tryon/hair/classic-side-part.png',
      hairGroup: HairLookGroup.men,
      size: 1.12,
    ),
    TryOnStyle(
      id: 'long-layered',
      name: 'Long butterfly',
      category: TryOnCategory.hairstyle,
      assetPath: 'assets/tryon/hair/long-layered.png',
      hairGroup: HairLookGroup.women,
      widthFactor: 1.12,
      heightFactor: 3.2,
      verticalOffsetFactor: 1.05,
    ),
    TryOnStyle(
      id: 'layered-lob',
      name: 'Layered lob',
      category: TryOnCategory.hairstyle,
      assetPath: 'assets/tryon/hair/layered-lob.png',
      hairGroup: HairLookGroup.women,
      widthFactor: 1.08,
      heightFactor: 2.25,
      verticalOffsetFactor: 0.62,
    ),
    TryOnStyle(
      id: 'long-curly',
      name: 'Long curls',
      category: TryOnCategory.hairstyle,
      assetPath: 'assets/tryon/hair/long-curly.png',
      hairGroup: HairLookGroup.women,
      widthFactor: 1.18,
      heightFactor: 3.15,
      verticalOffsetFactor: 1.02,
    ),
    TryOnStyle(
      id: 'sleek-bob',
      name: 'Sleek bob',
      category: TryOnCategory.hairstyle,
      assetPath: 'assets/tryon/hair/sleek-bob.png',
      hairGroup: HairLookGroup.women,
      widthFactor: 1.05,
      heightFactor: 2.15,
      verticalOffsetFactor: 0.58,
    ),
    TryOnStyle(
      id: 'box-braids',
      name: 'Box braids',
      category: TryOnCategory.hairstyle,
      assetPath: 'assets/tryon/hair/box-braids.png',
      hairGroup: HairLookGroup.women,
      widthFactor: 1.08,
      heightFactor: 3.35,
      verticalOffsetFactor: 1.12,
    ),
    TryOnStyle(
      id: 'high-ponytail',
      name: 'High ponytail',
      category: TryOnCategory.hairstyle,
      assetPath: 'assets/tryon/hair/high-ponytail.png',
      hairGroup: HairLookGroup.women,
      widthFactor: 1.18,
      heightFactor: 3.1,
      verticalOffsetFactor: 0.72,
    ),
    TryOnStyle(
      id: 'full-beard-black',
      name: 'Full beard',
      category: TryOnCategory.beard,
      assetPath: 'assets/tryon/beard/full-beard.png',
    ),
    TryOnStyle(
      id: 'full-beard-brown',
      name: 'Brown beard',
      category: TryOnCategory.beard,
      assetPath: 'assets/tryon/beard/full-beard.png',
      tint: Color(0xff69402e),
    ),
    TryOnStyle(
      id: 'burgundy-gold',
      name: 'Burgundy gold',
      category: TryOnCategory.nailArt,
      assetPath: 'assets/tryon/nail/burgundy-gold.png',
    ),
    TryOnStyle(
      id: 'rose-gold',
      name: 'Rose gold',
      category: TryOnCategory.nailArt,
      assetPath: 'assets/tryon/nail/burgundy-gold.png',
      tint: Color(0xffc87878),
    ),
    TryOnStyle(
      id: 'minimal-rose',
      name: 'Minimal rose',
      category: TryOnCategory.tattoo,
      assetPath: 'assets/tryon/tattoo/minimal-rose.png',
      widthFactor: 0.75,
      heightFactor: 1.15,
    ),
    TryOnStyle(
      id: 'fine-line-butterfly',
      name: 'Fine-line butterfly',
      category: TryOnCategory.tattoo,
      assetPath: 'assets/tryon/tattoo/fine-line-butterfly.png',
      widthFactor: 0.85,
      heightFactor: 0.9,
    ),
    TryOnStyle(
      id: 'tribal-band',
      name: 'Tribal band',
      category: TryOnCategory.tattoo,
      assetPath: 'assets/tryon/tattoo/tribal-band.png',
      widthFactor: 1.25,
      heightFactor: 0.55,
    ),
  ];

  final _picker = ImagePicker();
  final _detector = FaceDetectionService();
  final _advancedDetector = AdvancedTryOnDetectionService();
  final _threeDRepository = LocalThreeDModelRepository();
  final _premiumThreeDRepository = PremiumThreeDRepository();
  final _threeDPrompt = TextEditingController();
  final _renderer = ArOverlayRenderer();
  final _resultKey = GlobalKey();

  Uint8List? _photo;
  Size? _photoSize;
  Face? _face;
  FaceMesh? _faceMesh;
  Pose? _pose;
  TryOnMode _mode = TryOnMode.twoD;
  TryOnCategory _category = TryOnCategory.hairstyle;
  ThreeDCategory _threeDCategory = ThreeDCategory.hair;
  ThreeDModel? _selectedThreeDModel;
  Color? _threeDPreviewColor;
  String? _generatedThreeDModelUrl;
  String _threeDPromptStatus = 'Ask for a color change, like "brown hair".';
  HairLookGroup _hairLookGroup = HairLookGroup.men;
  TryOnStyle _style = _styles.first;
  Offset _adjustment = Offset.zero;
  Offset _startAdjustment = Offset.zero;
  Offset _startFocalPoint = Offset.zero;
  List<_NailTransform> _nailTransforms = _defaultNailTransforms();
  List<_NailAnchor> _nailAnchors = _fallbackNailAnchors;
  int? _activeNailIndex;
  int _selectedNailIndex = 0;
  _NailTransform _startNailTransform = const _NailTransform();
  double _scale = 1;
  double _startScale = 1;
  double _rotation = 0;
  double _startRotation = 0;
  double _overlayOpacity = 1;
  bool _overlayVisible = true;
  bool _editPanelExpanded = false;
  bool _premiumBannerVisible = true;
  bool _working = false;
  bool _threeDGenerating = false;
  String _status = 'Upload a photo, then tap a style model below.';

  @override
  void dispose() {
    _detector.dispose();
    _advancedDetector.dispose();
    _threeDPrompt.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final selected = await _picker.pickImage(
      source: source,
      imageQuality: 95,
      maxWidth: 1600,
    );
    if (selected == null) return;
    setState(() {
      _working = true;
      _status = 'Preparing your photo...';
    });
    final selectedCategory = _category;

    try {
      final bytes = await selected.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) throw StateError('Could not read this photo.');
      final inputImage = InputImage.fromFilePath(selected.path);
      var detectionWarning = '';
      var faces = <Face>[];
      var faceMeshes = <FaceMesh>[];
      var poses = <Pose>[];
      var handLandmarks = <HandLandmarkPoint>[];

      if (selectedCategory != TryOnCategory.nailArt &&
          selectedCategory != TryOnCategory.tattoo) {
        try {
          faces = await _detector.detectFaces(inputImage);
        } catch (_) {
          detectionWarning = ' Face detection was skipped; use manual adjust.';
        }
      }

      if (selectedCategory == TryOnCategory.hairstyle ||
          selectedCategory == TryOnCategory.beard) {
        try {
          faceMeshes = await _advancedDetector.detectFaceMeshes(inputImage);
        } catch (_) {
          detectionWarning = ' Face mesh was skipped; use manual adjust.';
        }
      }

      if (selectedCategory == TryOnCategory.tattoo) {
        try {
          poses = await _advancedDetector.detectPoses(inputImage);
        } catch (_) {
          detectionWarning = ' Pose detection was skipped; use manual adjust.';
        }
      }

      if (selectedCategory == TryOnCategory.nailArt) {
        try {
          handLandmarks = await _advancedDetector.detectHandLandmarks(
            selected.path,
          );
        } catch (_) {
          detectionWarning =
              ' Hand detection was skipped; drag each nail manually.';
        }
      }
      final nailAnchors = _anchorsFromHandLandmarks(handLandmarks);
      final face = faces.isEmpty
          ? null
          : faces.reduce(
              (a, b) =>
                  a.boundingBox.width * a.boundingBox.height >
                      b.boundingBox.width * b.boundingBox.height
                  ? a
                  : b,
            );
      if (!mounted) return;
      setState(() {
        _photo = bytes;
        _photoSize = Size(decoded.width.toDouble(), decoded.height.toDouble());
        _face = face;
        _faceMesh = faceMeshes.isEmpty
            ? null
            : faceMeshes.reduce(
                (a, b) =>
                    a.boundingBox.width * a.boundingBox.height >
                        b.boundingBox.width * b.boundingBox.height
                    ? a
                    : b,
              );
        _pose = poses.isEmpty
            ? null
            : poses.reduce(
                (a, b) => a.landmarks.length >= b.landmarks.length ? a : b,
              );
        _nailAnchors = selectedCategory == TryOnCategory.nailArt
            ? nailAnchors ?? _fallbackNailAnchors
            : _fallbackNailAnchors;
        _resetTransform();
        final readyStatus = _mode == TryOnMode.threeD
            ? 'Photo ready for Premium AI. Choose a style and generate when provider credits are available.'
            : selectedCategory == TryOnCategory.nailArt
            ? nailAnchors == null
                  ? 'Hand photo ready, but landmarks were not clear. Drag each nail onto the fingertips.'
                  : 'Hand landmarks detected. Nails auto-fitted to each fingertip; adjust if needed.'
            : selectedCategory == TryOnCategory.tattoo
            ? _pose == null
                  ? 'Tattoo photo ready. Pose was not detected, so use the edit controls.'
                  : 'Tattoo auto-fitted from body pose. Adjust if needed.'
            : face == null
            ? 'No face found. Nail models still work; use a clearer portrait for hair or beard.'
            : _faceMesh == null
            ? 'Photo ready. Face detected; contour auto-fit is active.'
            : 'Photo ready. Face mesh auto-fit is active.';
        _status = '$readyStatus$detectionWarning';
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _status =
              'Could not process this photo. Try a clear, upright photo with the face visible.';
        });
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _selectCategory(TryOnCategory category) {
    setState(() {
      _category = category;
      _style = _firstStyleFor(category);
      _resetTransform();
      _editPanelExpanded = false;
      _status = category == TryOnCategory.nailArt
          ? _photo == null
                ? 'Upload a top-down hand photo with fingers slightly spread.'
                : 'Drag each nail onto its matching fingertip.'
          : category == TryOnCategory.tattoo
          ? _photo == null
                ? 'Upload a clear photo of arm, wrist, neck, or shoulder skin.'
                : 'Drag, resize, and rotate the tattoo over clean skin.'
          : _photo == null
          ? 'Upload a clear, upright portrait, then tap a style model.'
          : 'Tap a model below to update the converted preview.';
    });
  }

  void _selectMode(TryOnMode mode) {
    setState(() {
      _mode = mode;
      _editPanelExpanded = false;
      _status = mode == TryOnMode.twoD
          ? '2D try-on ready. Upload a photo and choose a model.'
          : 'Premium AI edit ready. Upload a photo and choose a style.';
    });
  }

  void _selectThreeDCategory(ThreeDCategory category) {
    setState(() {
      _threeDCategory = category;
      _selectedThreeDModel = null;
      _threeDPreviewColor = null;
      _generatedThreeDModelUrl = null;
      _threeDPrompt.clear();
      _threeDPromptStatus = 'Describe the realistic blended look you want.';
      _status = '${_threeDCategoryLabel(category)} AI styles shown.';
    });
  }

  ThreeDModel _activeThreeDModel(List<ThreeDModel> models) {
    return _selectedThreeDModel ??
        models.firstWhere((model) => model.category == _threeDCategory);
  }

  void _selectThreeDModel(ThreeDModel model) {
    setState(() {
      _selectedThreeDModel = model;
      _threeDPreviewColor = null;
      _generatedThreeDModelUrl = null;
      _threeDPromptStatus = '${model.name} selected.';
      _status = '${model.name} selected for AI edit.';
    });
  }

  void _selectPremiumPreview(String name) {
    setState(() {
      _threeDPrompt.text = name;
      _threeDPromptStatus =
          '$name selected as preview inspiration. Upload a photo and generate when premium is unlocked.';
      _status = '$name preview selected.';
    });
  }

  void _applyThreeDPrompt() {
    final prompt = _threeDPrompt.text.trim().toLowerCase();
    if (prompt.isEmpty) {
      setState(() {
        _threeDPromptStatus = 'Type a color command first.';
      });
      return;
    }

    final color = _colorFromPrompt(prompt);
    setState(() {
      if (prompt.contains('reset') || prompt.contains('original')) {
        _threeDPreviewColor = null;
        _threeDPromptStatus = 'AI prompt reset.';
      } else if (color != null) {
        _threeDPreviewColor = color;
        _threeDPromptStatus =
            'Prompt color noted. Real blending happens through the AI image provider.';
      } else {
        _threeDPromptStatus =
            'Try prompts like "brown hair", "black beard", or "red nails".';
      }
    });
  }

  Future<void> _generatePremiumThreeD(ThreeDModel model) async {
    if (_threeDGenerating) return;
    final prompt = _threeDPrompt.text.trim().isEmpty
        ? model.name
        : _threeDPrompt.text.trim();
    setState(() {
      _threeDGenerating = true;
      _threeDPromptStatus = 'Requesting premium AI image edit from backend...';
      _status = 'Generating premium AI try-on...';
    });

    final result = await _premiumThreeDRepository.generate(
      category: _threeDCategory,
      styleId: model.id,
      prompt: prompt,
      imageBase64: _photo == null ? null : base64Encode(_photo!),
    );

    if (!mounted) return;
    setState(() {
      _threeDGenerating = false;
      _generatedThreeDModelUrl = result.modelUrl;
      _threeDPromptStatus = result.message;
      _status = result.modelUrl == null
          ? 'AI provider setup needed.'
          : 'Premium AI image generated.';
    });
  }

  Color? _colorFromPrompt(String prompt) {
    if (prompt.contains('black')) return const Color(0xff17110d);
    if (prompt.contains('brown')) return const Color(0xff6b3f2a);
    if (prompt.contains('blonde') || prompt.contains('gold')) {
      return const Color(0xffc9963a);
    }
    if (prompt.contains('red') || prompt.contains('burgundy')) {
      return const Color(0xff8b1620);
    }
    if (prompt.contains('pink') || prompt.contains('rose')) {
      return const Color(0xffd9778f);
    }
    if (prompt.contains('silver') || prompt.contains('chrome')) {
      return const Color(0xffaeb6c1);
    }
    return null;
  }

  String _threeDCategoryLabel(ThreeDCategory category) {
    return switch (category) {
      ThreeDCategory.hair => 'Hair',
      ThreeDCategory.beard => 'Beard',
      ThreeDCategory.nails => 'Nails',
    };
  }

  PremiumFeature get _selectedPremiumFeature => switch (_threeDCategory) {
    ThreeDCategory.hair => PremiumFeature.aiHair,
    ThreeDCategory.beard => PremiumFeature.aiBeard,
    ThreeDCategory.nails => PremiumFeature.aiNails,
  };

  Future<void> _openPremiumPlans(PremiumFeature feature) async {
    final unlocked = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PremiumPlansPage(
          initialFeature: feature,
          allowLocalDevelopmentSimulation: !widget.enableThreeDViewer,
        ),
      ),
    );
    if (unlocked == true && mounted) {
      setState(() {
        _status = '${feature.label} unlocked for this development session.';
      });
    }
  }

  Future<void> _showPremiumUnlockDialog({
    required PremiumFeature feature,
    required String previewName,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
        title: Row(
          children: [
            const Expanded(child: Text('Unlock premium preview')),
            IconButton(
              onPressed: () => Navigator.pop(dialogContext),
              icon: const Icon(Icons.close),
              tooltip: 'Close',
            ),
          ],
        ),
        content: Text(
          '$previewName is part of Premium Studio. One unlock gives you AI hair, beard, and nail previews.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Not now'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              _openPremiumPlans(feature);
            },
            icon: const Icon(Icons.lock_open_outlined),
            label: const Text('Unlock premium'),
          ),
        ],
      ),
    );
  }

  TryOnStyle _firstStyleFor(TryOnCategory category) {
    return _styles.firstWhere(
      (style) =>
          style.category == category &&
          (category != TryOnCategory.hairstyle ||
              style.hairGroup == _hairLookGroup),
    );
  }

  void _selectHairLookGroup(HairLookGroup group) {
    setState(() {
      _hairLookGroup = group;
      _style = _firstStyleFor(TryOnCategory.hairstyle);
      _resetTransform();
      _status =
          '${group == HairLookGroup.men ? 'Men' : 'Women'} hairstyle models shown.';
    });
  }

  void _selectStyle(TryOnStyle style) {
    setState(() {
      _style = style;
      _resetTransform();
      _status = _photo == null
          ? 'Now upload a photo to try ${style.name}.'
          : '${style.name} applied automatically.';
    });
  }

  void _resetTransform() {
    _adjustment = Offset.zero;
    _scale = 1;
    _rotation = 0;
    _overlayOpacity = 1;
    _overlayVisible = true;
    _activeNailIndex = null;
    _selectedNailIndex = 0;
    _nailTransforms = _defaultNailTransforms();
  }

  List<_NailAnchor>? _anchorsFromHandLandmarks(
    List<HandLandmarkPoint> landmarks,
  ) {
    if (landmarks.length < 21) return null;

    _NailAnchor anchorFor({
      required int tip,
      required int dip,
      required int pip,
      required double widthFactor,
      required double heightFactor,
      required double minWidth,
      required double maxWidth,
    }) {
      final tipPoint = landmarks[tip].normalizedOffset;
      final dipPoint = landmarks[dip].normalizedOffset;
      final pipPoint = landmarks[pip].normalizedOffset;
      final fingerVector = tipPoint - dipPoint;
      final jointVector = dipPoint - pipPoint;
      final baseLength = math.max(fingerVector.distance, jointVector.distance);
      final center = Offset.lerp(dipPoint, tipPoint, 0.78)!;
      final width = (baseLength * widthFactor).clamp(minWidth, maxWidth);
      final height = (baseLength * heightFactor).clamp(0.055, 0.16);
      final rotation = math.atan2(fingerVector.dy, fingerVector.dx) + math.pi / 2;
      return _NailAnchor(
        x: center.dx.clamp(0.02, 0.98),
        y: center.dy.clamp(0.02, 0.98),
        width: width.toDouble(),
        height: height.toDouble(),
        rotation: rotation,
      );
    }

    return [
      anchorFor(
        tip: 4,
        dip: 3,
        pip: 2,
        widthFactor: 0.55,
        heightFactor: 1.35,
        minWidth: 0.045,
        maxWidth: 0.1,
      ),
      anchorFor(
        tip: 8,
        dip: 7,
        pip: 6,
        widthFactor: 0.5,
        heightFactor: 1.55,
        minWidth: 0.04,
        maxWidth: 0.095,
      ),
      anchorFor(
        tip: 12,
        dip: 11,
        pip: 10,
        widthFactor: 0.52,
        heightFactor: 1.6,
        minWidth: 0.042,
        maxWidth: 0.1,
      ),
      anchorFor(
        tip: 16,
        dip: 15,
        pip: 14,
        widthFactor: 0.5,
        heightFactor: 1.52,
        minWidth: 0.038,
        maxWidth: 0.092,
      ),
      anchorFor(
        tip: 20,
        dip: 19,
        pip: 18,
        widthFactor: 0.47,
        heightFactor: 1.45,
        minWidth: 0.034,
        maxWidth: 0.084,
      ),
    ];
  }

  static List<_NailTransform> _defaultNailTransforms() {
    return List.generate(5, (_) => const _NailTransform());
  }

  void _startNailGesture(int index, ScaleStartDetails details) {
    _activeNailIndex = index;
    _selectedNailIndex = index;
    _startFocalPoint = details.focalPoint;
    _startNailTransform = _nailTransforms[index];
  }

  void _updateNailGesture(ScaleUpdateDetails details) {
    final index = _activeNailIndex;
    if (index == null) return;
    final updated = [..._nailTransforms];
    updated[index] = _startNailTransform.copyWith(
      adjustment: updated[index].adjustment,
      scale: (_startNailTransform.scale * details.scale)
          .clamp(0.45, 2.6)
          .toDouble(),
      rotation: _startNailTransform.rotation + details.rotation,
    );
    _nailTransforms = updated;
  }

  void _dragNail(int index, Offset delta) {
    _selectedNailIndex = index;
    final updated = [..._nailTransforms];
    updated[index] = updated[index].copyWith(
      adjustment: updated[index].adjustment + delta,
    );
    _nailTransforms = updated;
  }

  bool get _isNailEditorActive => _category == TryOnCategory.nailArt;

  double get _editorScale =>
      _isNailEditorActive ? _nailTransforms[_selectedNailIndex].scale : _scale;

  double get _editorRotation => _isNailEditorActive
      ? _nailTransforms[_selectedNailIndex].rotation
      : _rotation;

  void _nudgeEditor(Offset delta) {
    if (_isNailEditorActive) {
      _dragNail(_selectedNailIndex, delta);
    } else {
      _adjustment += delta;
    }
  }

  void _setEditorScale(double value) {
    if (_isNailEditorActive) {
      final updated = [..._nailTransforms];
      updated[_selectedNailIndex] = updated[_selectedNailIndex].copyWith(
        scale: value,
      );
      _nailTransforms = updated;
      return;
    }
    _scale = value;
  }

  void _setEditorRotation(double value) {
    if (_isNailEditorActive) {
      final updated = [..._nailTransforms];
      updated[_selectedNailIndex] = updated[_selectedNailIndex].copyWith(
        rotation: value,
      );
      _nailTransforms = updated;
      return;
    }
    _rotation = value;
  }

  Future<Uint8List> _captureResult() async {
    await WidgetsBinding.instance.endOfFrame;
    final boundary =
        _resultKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      throw StateError('The try-on result is not ready.');
    }
    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (byteData == null) {
      throw StateError('Could not create the result image.');
    }
    return byteData.buffer.asUint8List();
  }

  Future<void> _saveResult() async {
    if (_photo == null || _working) return;
    setState(() {
      _working = true;
      _status = 'Saving result to your gallery...';
    });
    try {
      final bytes = await _captureResult();
      await Gal.putImageBytes(
        bytes,
        name: 'salon_tryon_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (mounted) {
        setState(() => _status = 'Result saved to your gallery.');
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _status = 'Could not save the result. Check photo access.',
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _shareResult() async {
    if (_photo == null || _working) return;
    setState(() {
      _working = true;
      _status = 'Preparing result to share...';
    });
    try {
      final bytes = await _captureResult();
      final fileName =
          'salon_tryon_${DateTime.now().millisecondsSinceEpoch}.png';
      final resultBox =
          _resultKey.currentContext?.findRenderObject() as RenderBox?;
      final shareOrigin = resultBox == null
          ? null
          : resultBox.localToGlobal(Offset.zero) & resultBox.size;
      await SharePlus.instance.share(
        ShareParams(
          text: 'My virtual try-on result from The Salon App',
          files: [XFile.fromData(bytes, mimeType: 'image/png')],
          fileNameOverrides: [fileName],
          sharePositionOrigin: shareOrigin,
        ),
      );
      if (mounted) {
        setState(() => _status = 'Result ready to share.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _status = 'Could not share the result.');
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final models = _styles
        .where(
          (style) =>
              style.category == _category &&
              (_category != TryOnCategory.hairstyle ||
                  style.hairGroup == _hairLookGroup),
        )
        .toList();
    final threeDModels = _threeDRepository.modelsFor(_threeDCategory);
    final activeThreeDModel = _activeThreeDModel(threeDModels);
    return Scaffold(
      backgroundColor: const Color(0xfff7f3f0),
      appBar: AppBar(title: const Text('AI Virtual Try-On')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Upload your photo',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            const Text('Then tap a model to instantly preview the style.'),
            const SizedBox(height: 12),
            SegmentedButton<TryOnMode>(
              segments: const [
                ButtonSegment(
                  value: TryOnMode.twoD,
                  label: Text('2D Try-On'),
                  icon: Icon(Icons.layers_outlined),
                ),
                ButtonSegment(
                  value: TryOnMode.threeD,
                  label: Text('AI Premium'),
                  icon: Icon(Icons.auto_awesome),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (value) => _selectMode(value.first),
            ),
            const SizedBox(height: 14),
            if (_mode == TryOnMode.threeD && _premiumBannerVisible) ...[
              _PremiumBanner(
                onClose: () => setState(() => _premiumBannerVisible = false),
                onUnlock: () => _openPremiumPlans(_selectedPremiumFeature),
              ),
              const SizedBox(height: 12),
            ],
            if (_mode == TryOnMode.twoD) ...[
              RepaintBoundary(
                key: _resultKey,
                child: _ResultPreview(
                  photo: _photo,
                  photoSize: _photoSize,
                  face: _face,
                  faceMesh: _faceMesh,
                  pose: _pose,
                  category: _category,
                  style: _style,
                  renderer: _renderer,
                  adjustment: _adjustment,
                  nailAnchors: _nailAnchors,
                  nailTransforms: _nailTransforms,
                  overlayOpacity: _overlayOpacity,
                  overlayVisible: _overlayVisible,
                  scale: _scale,
                  rotation: _rotation,
                  onGestureStart: (details) {
                    _startAdjustment = _adjustment;
                    _startFocalPoint = details.focalPoint;
                    _startScale = _scale;
                    _startRotation = _rotation;
                  },
                  onGestureUpdate: (details) => setState(() {
                    _adjustment =
                        _startAdjustment +
                        details.focalPoint -
                        _startFocalPoint;
                    _scale = (_startScale * details.scale).clamp(0.3, 3);
                    _rotation = _startRotation + details.rotation;
                  }),
                  onNailGestureStart: (index, details) => setState(() {
                    _startNailGesture(index, details);
                    _status =
                        'Adjusting nail ${index + 1}. Drag, pinch, or rotate it.';
                  }),
                  onNailGestureUpdate: (details) => setState(() {
                    _updateNailGesture(details);
                  }),
                  onNailDrag: (index, delta) => setState(() {
                    _dragNail(index, delta);
                    _status =
                        'Moved nail ${index + 1}. Pinch it if the size still needs correction.';
                  }),
                  onChoosePhoto: () => _pickPhoto(ImageSource.gallery),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _working
                          ? null
                          : () => _pickPhoto(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Upload photo'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _working
                          ? null
                          : () => _pickPhoto(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Take photo'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _EditControls(
                category: _category,
                expanded: _editPanelExpanded,
                selectedNailIndex: _selectedNailIndex,
                scale: _editorScale,
                rotation: _editorRotation,
                opacity: _overlayOpacity,
                visible: _overlayVisible,
                onSelectNail: (index) => setState(() {
                  _selectedNailIndex = index;
                  _activeNailIndex = index;
                  _status = 'Editing nail ${index + 1}.';
                }),
                onNudge: (delta) => setState(() {
                  _nudgeEditor(delta);
                  _status = _isNailEditorActive
                      ? 'Moved nail ${_selectedNailIndex + 1}.'
                      : 'Moved overlay.';
                }),
                onScaleChanged: (value) => setState(() {
                  _setEditorScale(value);
                  _status = _isNailEditorActive
                      ? 'Resized nail ${_selectedNailIndex + 1}.'
                      : 'Resized overlay.';
                }),
                onRotationChanged: (value) => setState(() {
                  _setEditorRotation(value);
                  _status = _isNailEditorActive
                      ? 'Rotated nail ${_selectedNailIndex + 1}.'
                      : 'Rotated overlay.';
                }),
                onOpacityChanged: (value) => setState(() {
                  _overlayOpacity = value;
                  _status = 'Changed overlay opacity.';
                }),
                onReset: () => setState(() {
                  _resetTransform();
                  _status = _category == TryOnCategory.nailArt
                      ? 'Nail layout reset. Adjust each nail if needed.'
                      : 'Auto fit reapplied from detected landmarks.';
                }),
                onToggleVisible: () => setState(() {
                  _overlayVisible = !_overlayVisible;
                  _status = _overlayVisible
                      ? 'Overlay visible again.'
                      : 'Overlay hidden.';
                }),
                onToggleExpanded: () => setState(() {
                  _editPanelExpanded = !_editPanelExpanded;
                }),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: _photo == null || _working
                          ? null
                          : _saveResult,
                      icon: const Icon(Icons.download_outlined),
                      label: const Text('Save result'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _photo == null || _working
                          ? null
                          : _shareResult,
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('Share'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              _ThreeDTryOnPreview(
                model: activeThreeDModel,
                previewColor: _threeDPreviewColor,
                enableViewer: widget.enableThreeDViewer,
                photo: _photo,
                generatedModelUrl: _generatedThreeDModelUrl,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _working
                          ? null
                          : () => _pickPhoto(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Upload photo'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _working
                          ? null
                          : () => _pickPhoto(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Take photo'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: _threeDGenerating
                    ? null
                    : () {
                        if (!PremiumAccessController.instance.isUnlocked(
                          _selectedPremiumFeature,
                        )) {
                          _showPremiumUnlockDialog(
                            feature: _selectedPremiumFeature,
                            previewName: activeThreeDModel.name,
                          );
                          return;
                        }
                        _generatePremiumThreeD(activeThreeDModel);
                      },
                icon: _threeDGenerating
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload_outlined),
                label: Text(
                  _threeDGenerating ? 'Generating AI...' : 'Generate AI try-on',
                ),
              ),
              const SizedBox(height: 8),
              _ThreeDPromptBar(
                controller: _threeDPrompt,
                status: _threeDPromptStatus,
                onApply: _applyThreeDPrompt,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                if (_working)
                  const Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                Expanded(child: Text(_status)),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              _mode == TryOnMode.twoD ? 'Choose a model' : 'Choose AI style',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            if (_mode == TryOnMode.twoD)
              SegmentedButton<TryOnCategory>(
                segments: const [
                  ButtonSegment(
                    value: TryOnCategory.hairstyle,
                    label: Text('Hair'),
                  ),
                  ButtonSegment(
                    value: TryOnCategory.beard,
                    label: Text('Beard'),
                  ),
                  ButtonSegment(
                    value: TryOnCategory.nailArt,
                    label: Text('Nails'),
                  ),
                  ButtonSegment(
                    value: TryOnCategory.tattoo,
                    label: Text('Tattoo'),
                  ),
                ],
                selected: {_category},
                onSelectionChanged: (value) => _selectCategory(value.first),
              )
            else
              SegmentedButton<ThreeDCategory>(
                segments: const [
                  ButtonSegment(
                    value: ThreeDCategory.hair,
                    label: Text('AI Hair'),
                    icon: Icon(Icons.view_in_ar_outlined),
                  ),
                  ButtonSegment(
                    value: ThreeDCategory.beard,
                    label: Text('AI Beard'),
                    icon: Icon(Icons.face_retouching_natural),
                  ),
                  ButtonSegment(
                    value: ThreeDCategory.nails,
                    label: Text('AI Nails'),
                    icon: Icon(Icons.back_hand_outlined),
                  ),
                ],
                selected: {_threeDCategory},
                onSelectionChanged: (value) =>
                    _selectThreeDCategory(value.first),
              ),
            if (_mode == TryOnMode.twoD &&
                _category == TryOnCategory.hairstyle) ...[
              const SizedBox(height: 10),
              SegmentedButton<HairLookGroup>(
                segments: const [
                  ButtonSegment(
                    value: HairLookGroup.men,
                    label: Text('Men'),
                    icon: Icon(Icons.face_retouching_natural),
                  ),
                  ButtonSegment(
                    value: HairLookGroup.women,
                    label: Text('Women'),
                    icon: Icon(Icons.face),
                  ),
                ],
                selected: {_hairLookGroup},
                onSelectionChanged: (value) =>
                    _selectHairLookGroup(value.first),
              ),
            ],
            if (_mode == TryOnMode.twoD &&
                _category == TryOnCategory.nailArt) ...[
              const SizedBox(height: 12),
              _NailPhotoGuide(
                onReset: () => setState(() {
                  _resetTransform();
                  _status =
                      'Nail positions reset. Drag each nail onto its fingertip.';
                }),
              ),
            ],
            if (_mode == TryOnMode.twoD &&
                _category == TryOnCategory.tattoo) ...[
              const SizedBox(height: 12),
              _TattooPhotoGuide(
                onReset: () => setState(() {
                  _resetTransform();
                  _status = 'Tattoo position reset. Drag it over clean skin.';
                }),
              ),
            ],
            const SizedBox(height: 12),
            if (_mode == TryOnMode.twoD)
              SizedBox(
                height: 142,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: models.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final model = models[index];
                    return _ModelCard(
                      style: model,
                      selected: _style.id == model.id,
                      onTap: () => _selectStyle(model),
                    );
                  },
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PremiumPreviewShowcase(
                    category: _threeDCategory,
                    onTap: _selectPremiumPreview,
                  ),
                ],
              ),
            if (_mode == TryOnMode.threeD) ...[
              const SizedBox(height: 12),
              _Premium3DCard(
                model: activeThreeDModel,
                unlocked: PremiumAccessController.instance.isUnlocked(
                  _selectedPremiumFeature,
                ),
                onUnlock: () => _openPremiumPlans(_selectedPremiumFeature),
              ),
            ],
            const SizedBox(height: 18),
            Text(
              _mode == TryOnMode.twoD
                  ? 'Drag anywhere on the photo to move. Pinch to resize and twist to rotate.'
                  : 'Premium AI uses backend image editing for realistic blended results.',
            ),
          ],
        ),
      ),
    );
  }
}

class _EditControls extends StatelessWidget {
  final TryOnCategory category;
  final bool expanded;
  final int selectedNailIndex;
  final double scale;
  final double rotation;
  final double opacity;
  final bool visible;
  final ValueChanged<int> onSelectNail;
  final ValueChanged<Offset> onNudge;
  final ValueChanged<double> onScaleChanged;
  final ValueChanged<double> onRotationChanged;
  final ValueChanged<double> onOpacityChanged;
  final VoidCallback onReset;
  final VoidCallback onToggleVisible;
  final VoidCallback onToggleExpanded;

  const _EditControls({
    required this.category,
    required this.expanded,
    required this.selectedNailIndex,
    required this.scale,
    required this.rotation,
    required this.opacity,
    required this.visible,
    required this.onSelectNail,
    required this.onNudge,
    required this.onScaleChanged,
    required this.onRotationChanged,
    required this.onOpacityChanged,
    required this.onReset,
    required this.onToggleVisible,
    required this.onToggleExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final isNailMode = category == TryOnCategory.nailArt;
    final title = isNailMode
        ? 'Edit nail ${selectedNailIndex + 1}'
        : 'Edit overlay';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(expanded ? 218 : 178),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withAlpha(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(14),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onToggleExpanded,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      isNailMode ? Icons.back_hand_outlined : Icons.tune,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                    ),
                  ],
                ),
              ),
            ),
            if (expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: visible ? 'Hide overlay' : 'Show overlay',
                          onPressed: onToggleVisible,
                          icon: Icon(
                            visible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Auto fit',
                          onPressed: onReset,
                          icon: const Icon(Icons.restart_alt),
                        ),
                        const Spacer(),
                        Text(
                          visible ? 'Visible' : 'Hidden',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    if (isNailMode) ...[
                      const SizedBox(height: 2),
                      Wrap(
                        spacing: 6,
                        children: List.generate(5, (index) {
                          return ChoiceChip(
                            label: Text('${index + 1}'),
                            selected: selectedNailIndex == index,
                            visualDensity: VisualDensity.compact,
                            onSelected: (_) => onSelectNail(index),
                          );
                        }),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _NudgeButton(
                            icon: Icons.arrow_upward,
                            label: 'Up',
                            onPressed: () => onNudge(const Offset(0, -8)),
                          ),
                          _NudgeButton(
                            icon: Icons.arrow_downward,
                            label: 'Down',
                            onPressed: () => onNudge(const Offset(0, 8)),
                          ),
                          _NudgeButton(
                            icon: Icons.arrow_back,
                            label: 'Left',
                            onPressed: () => onNudge(const Offset(-8, 0)),
                          ),
                          _NudgeButton(
                            icon: Icons.arrow_forward,
                            label: 'Right',
                            onPressed: () => onNudge(const Offset(8, 0)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    _EditorSlider(
                      label: 'Size',
                      value: scale,
                      min: category == TryOnCategory.nailArt ? 0.45 : 0.3,
                      max: category == TryOnCategory.nailArt ? 2.6 : 3,
                      onChanged: onScaleChanged,
                    ),
                    _EditorSlider(
                      label: 'Rotate',
                      value: rotation,
                      min: -0.9,
                      max: 0.9,
                      onChanged: onRotationChanged,
                    ),
                    _EditorSlider(
                      label: 'Opacity',
                      value: opacity,
                      min: 0.25,
                      max: 1,
                      onChanged: onOpacityChanged,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ThreeDTryOnPreview extends StatelessWidget {
  final ThreeDModel model;
  final Color? previewColor;
  final bool enableViewer;
  final Uint8List? photo;
  final String? generatedModelUrl;

  const _ThreeDTryOnPreview({
    required this.model,
    required this.previewColor,
    required this.enableViewer,
    required this.photo,
    required this.generatedModelUrl,
  });

  @override
  Widget build(BuildContext context) {
    final color = previewColor ?? model.previewColor;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [const Color(0xffeef4ff), color.withAlpha(42)],
            ),
          ),
          child: Stack(
            children: [
              if (generatedModelUrl != null)
                Positioned.fill(
                  child: Image.network(
                    generatedModelUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: progress.expectedTotalBytes == null
                              ? null
                              : progress.cumulativeBytesLoaded /
                                    progress.expectedTotalBytes!,
                        ),
                      );
                    },
                    errorBuilder: (_, _, _) => _ThreeDPreviewBody(
                      model: model,
                      color: color,
                      photo: photo,
                      enableViewer: enableViewer,
                      generatedModelUrl: generatedModelUrl,
                    ),
                  ),
                )
              else
                Positioned.fill(
                  child: _ThreeDPreviewBody(
                    model: model,
                    color: color,
                    photo: photo,
                    enableViewer: enableViewer,
                    generatedModelUrl: generatedModelUrl,
                  ),
                ),
              Positioned(
                left: 12,
                bottom: 12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(225),
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(18),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(radius: 7, backgroundColor: color),
                        const SizedBox(width: 8),
                        Text(
                          generatedModelUrl == null
                              ? model.name
                              : 'AI result: ${model.name}',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThreeDPreviewBody extends StatelessWidget {
  final ThreeDModel model;
  final Color color;
  final bool enableViewer;
  final Uint8List? photo;
  final String? generatedModelUrl;

  const _ThreeDPreviewBody({
    required this.model,
    required this.color,
    required this.enableViewer,
    required this.photo,
    required this.generatedModelUrl,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Expanded(
                child: _ThreeDViewerFallback(model: model, color: color),
              ),
              const SizedBox(height: 8),
              _ThreeDPreviewNotes(
                model: model,
                photoReady: photo != null,
                viewerEnabled: enableViewer,
                generatedModelUrl: generatedModelUrl,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ThreeDPreviewNotes extends StatelessWidget {
  final ThreeDModel model;
  final bool photoReady;
  final bool viewerEnabled;
  final String? generatedModelUrl;

  const _ThreeDPreviewNotes({
    required this.model,
    required this.photoReady,
    required this.viewerEnabled,
    required this.generatedModelUrl,
  });

  @override
  Widget build(BuildContext context) {
    final generated = generatedModelUrl != null;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(218),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withAlpha(18)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              generated ? 'AI result ready' : 'Nano Banana AI edit',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              photoReady
                  ? 'Photo attached. Selected: ${model.name}'
                  : 'Upload a photo, choose a style, then generate.',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            if (generated) ...[
              Text(
                'Realistic edit received.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              generated
                  ? 'The generated image is shown in the preview.'
                  : 'Mock mode is free. fal.ai credits are needed for realistic output.',
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ThreeDViewerFallback extends StatelessWidget {
  final ThreeDModel model;
  final Color color;

  const _ThreeDViewerFallback({required this.model, required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest.shortestSide.clamp(86.0, 132.0);
        return Center(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withAlpha(210),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(24),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(model.icon, size: size * 0.48, color: color),
          ),
        );
      },
    );
  }
}

class _PremiumBanner extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onUnlock;

  const _PremiumBanner({required this.onClose, required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 6, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff102a43), Color(0xff245ca8)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium, color: Colors.amber),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Premium studio previews',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close, color: Colors.white),
                tooltip: 'Hide premium banner',
              ),
            ],
          ),
          const Text(
            'Explore sample looks, then unlock one Premium Studio for hair, beard, and nails.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: onUnlock,
              icon: const Icon(Icons.lock_open_outlined),
              label: const Text('View premium options'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumPreviewShowcase extends StatelessWidget {
  final ThreeDCategory category;
  final ValueChanged<String> onTap;

  const _PremiumPreviewShowcase({required this.category, required this.onTap});

  static const _hair = [
    _PremiumPreviewItem(
      name: 'Textured crop motion',
      assetPath: 'assets/tryon/hair/textured-black.png',
    ),
    _PremiumPreviewItem(
      name: 'Long layers motion',
      assetPath: 'assets/tryon/hair/long-layered.png',
    ),
    _PremiumPreviewItem(
      name: 'Curly volume motion',
      assetPath: 'assets/tryon/hair/long-curly.png',
    ),
  ];

  static const _beard = [
    _PremiumPreviewItem(
      name: 'Full beard preview',
      assetPath: 'assets/tryon/beard/full-beard.png',
    ),
    _PremiumPreviewItem(
      name: 'Brown beard preview',
      assetPath: 'assets/tryon/beard/full-beard.png',
      tint: Color(0xff69402e),
    ),
    _PremiumPreviewItem(
      name: 'Dark beard preview',
      assetPath: 'assets/tryon/beard/full-beard.png',
      tint: Color(0xff21150f),
    ),
  ];

  static const _nails = [
    _PremiumPreviewItem(
      name: 'Burgundy nail preview',
      assetPath: 'assets/tryon/nail/burgundy-gold.png',
    ),
    _PremiumPreviewItem(
      name: 'Rose nail preview',
      assetPath: 'assets/tryon/nail/burgundy-gold.png',
      tint: Color(0xffc87878),
    ),
    _PremiumPreviewItem(
      name: 'Gold nail preview',
      assetPath: 'assets/tryon/nail/burgundy-gold.png',
      tint: Color(0xffc9963a),
    ),
  ];

  List<_PremiumPreviewItem> get _items => switch (category) {
    ThreeDCategory.hair => _hair,
    ThreeDCategory.beard => _beard,
    ThreeDCategory.nails => _nails,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Preview clips',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            const Icon(Icons.touch_app_outlined, size: 18),
            const SizedBox(width: 4),
            const Text('Tap to use prompt'),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = _items[index];
              Widget image = Image.asset(item.assetPath, fit: BoxFit.contain);
              if (item.tint != null) {
                image = ColorFiltered(
                  colorFilter: ColorFilter.mode(item.tint!, BlendMode.color),
                  child: image,
                );
              }
              return InkWell(
                onTap: () => onTap(item.name),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 132,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Padding(padding: const EdgeInsets.all(8), child: image),
                      Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(230),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: const Text(
                            'Preview',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(7),
                          color: Colors.black54,
                          child: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PremiumPreviewItem {
  final String name;
  final String assetPath;
  final Color? tint;

  const _PremiumPreviewItem({
    required this.name,
    required this.assetPath,
    this.tint,
  });
}

class _Premium3DCard extends StatelessWidget {
  final ThreeDModel model;
  final bool unlocked;
  final VoidCallback onUnlock;

  const _Premium3DCard({
    required this.model,
    required this.unlocked,
    required this.onUnlock,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xff102a43),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lock_outline, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Premium AI Try-On',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${model.name} is selected. In development, mock mode returns a test response. When fal.ai credits are available, Nano Banana edits the uploaded photo for a realistic blended result.',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                _PremiumPill(label: 'AI Hair'),
                _PremiumPill(label: 'AI Beard'),
                _PremiumPill(label: 'AI Nails'),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: unlocked ? null : onUnlock,
                icon: Icon(
                  unlocked ? Icons.verified_outlined : Icons.lock_open_outlined,
                ),
                label: Text(
                  unlocked ? 'Unlocked' : 'Unlock Premium Studio',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThreeDPromptBar extends StatelessWidget {
  final TextEditingController controller;
  final String status;
  final VoidCallback onApply;

  const _ThreeDPromptBar({
    required this.controller,
    required this.status,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(190),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withAlpha(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            onSubmitted: (_) => onApply(),
            decoration: InputDecoration(
              isDense: true,
              labelText: 'AI style prompt',
              hintText: 'Example: realistic brown layered haircut',
              suffixIcon: IconButton(
                onPressed: onApply,
                icon: const Icon(Icons.auto_awesome),
              ),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 6),
          Text(status, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _PremiumPill extends StatelessWidget {
  final String label;

  const _PremiumPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(28),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white)),
    );
  }
}

class _NudgeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _NudgeButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton.outlined(
      onPressed: onPressed,
      tooltip: label,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 40, height: 36),
      icon: Icon(icon, size: 18),
    );
  }
}

class _EditorSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _EditorSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: value.clamp(min, max).toDouble(),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _ModelCard extends StatelessWidget {
  final TryOnStyle style;
  final bool selected;
  final VoidCallback onTap;

  const _ModelCard({
    required this.style,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 118,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xffdfe8ff) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xff245ca8) : Colors.black12,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Expanded(child: _StyleImage(style: style)),
            const SizedBox(height: 5),
            Text(
              style.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _NailPhotoGuide extends StatelessWidget {
  final VoidCallback onReset;

  const _NailPhotoGuide({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xfffff4df),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.back_hand_outlined, size: 30),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'For nails: place one hand flat on a plain surface, point '
                'fingertips upward, spread fingers slightly, and photograph '
                'straight from above. Then drag each nail separately onto the '
                'matching fingertip.',
              ),
            ),
            IconButton(
              onPressed: onReset,
              tooltip: 'Reset nail position',
              icon: const Icon(Icons.restart_alt),
            ),
          ],
        ),
      ),
    );
  }
}

class _TattooPhotoGuide extends StatelessWidget {
  final VoidCallback onReset;

  const _TattooPhotoGuide({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xffeef5ff),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.brush_outlined, size: 30),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'For tattoos: use a clear close-up of clean skin on the arm, '
                'wrist, neck, or shoulder. Drag, pinch, and rotate the tattoo '
                'until it follows the skin area.',
              ),
            ),
            IconButton(
              onPressed: onReset,
              tooltip: 'Reset tattoo position',
              icon: const Icon(Icons.restart_alt),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultPreview extends StatelessWidget {
  final Uint8List? photo;
  final Size? photoSize;
  final Face? face;
  final FaceMesh? faceMesh;
  final Pose? pose;
  final TryOnCategory category;
  final TryOnStyle style;
  final ArOverlayRenderer renderer;
  final Offset adjustment;
  final List<_NailAnchor> nailAnchors;
  final List<_NailTransform> nailTransforms;
  final double overlayOpacity;
  final bool overlayVisible;
  final double scale;
  final double rotation;
  final ValueChanged<ScaleStartDetails> onGestureStart;
  final ValueChanged<ScaleUpdateDetails> onGestureUpdate;
  final void Function(int index, ScaleStartDetails details) onNailGestureStart;
  final ValueChanged<ScaleUpdateDetails> onNailGestureUpdate;
  final void Function(int index, Offset delta) onNailDrag;
  final VoidCallback onChoosePhoto;

  const _ResultPreview({
    required this.photo,
    required this.photoSize,
    required this.face,
    required this.faceMesh,
    required this.pose,
    required this.category,
    required this.style,
    required this.renderer,
    required this.adjustment,
    required this.nailAnchors,
    required this.nailTransforms,
    required this.overlayOpacity,
    required this.overlayVisible,
    required this.scale,
    required this.rotation,
    required this.onGestureStart,
    required this.onGestureUpdate,
    required this.onNailGestureStart,
    required this.onNailGestureUpdate,
    required this.onNailDrag,
    required this.onChoosePhoto,
  });

  @override
  Widget build(BuildContext context) {
    if (photo == null || photoSize == null) {
      return Card(
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: Center(
            child: FilledButton.tonalIcon(
              onPressed: onChoosePhoto,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Upload photo'),
            ),
          ),
        ),
      );
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: photoSize!.width / photoSize!.height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final viewSize = constraints.biggest;
            final placement = _placement(viewSize);
            final isNailMode = category == TryOnCategory.nailArt;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onScaleStart: placement == null || isNailMode
                  ? null
                  : onGestureStart,
              onScaleUpdate: placement == null || isNailMode
                  ? null
                  : onGestureUpdate,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(photo!, fit: BoxFit.fill),
                  if (isNailMode && overlayVisible)
                    ..._buildNailOverlays(viewSize)
                  else if (overlayVisible && placement != null)
                    Positioned(
                      left: placement.center.dx - placement.width / 2,
                      top: placement.center.dy - placement.height / 2,
                      width: placement.width,
                      height: placement.height,
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: overlayOpacity,
                          child: Transform.rotate(
                            angle: placement.rotation,
                            child: _StyleImage(style: style),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: Chip(label: Text('Result: ${style.name}')),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  _Placement? _placement(Size viewSize) {
    final imageScale = viewSize.width / photoSize!.width;
    if (category == TryOnCategory.nailArt) {
      return _Placement(
        center: Offset(viewSize.width * 0.5, viewSize.height * 0.45),
        width: viewSize.width,
        height: viewSize.height,
        rotation: rotation,
      );
    }
    if (category == TryOnCategory.tattoo) {
      final detectedPose = pose;
      if (detectedPose != null) {
        final overlay = renderer.calculateTattooOverlayFromPose(detectedPose);
        if (overlay != null) {
          return _Placement(
            center: overlay.center * imageScale + adjustment,
            width:
                overlay.width *
                imageScale *
                scale *
                style.size *
                style.widthFactor,
            height:
                overlay.height *
                imageScale *
                scale *
                style.size *
                style.heightFactor,
            rotation: overlay.rotation + rotation,
          );
        }
      }
      return _Placement(
        center:
            Offset(viewSize.width * 0.5, viewSize.height * 0.52) + adjustment,
        width: viewSize.width * 0.42 * scale * style.size * style.widthFactor,
        height: viewSize.width * 0.42 * scale * style.size * style.heightFactor,
        rotation: rotation,
      );
    }
    if (category == TryOnCategory.beard) {
      final mesh = faceMesh;
      final detectedFace = face;
      if (mesh == null && detectedFace == null) return null;
      final overlay = mesh != null
          ? renderer.calculateBeardOverlayFromMesh(mesh)
          : renderer.calculateBeardOverlay(detectedFace!);
      return _Placement(
        center: overlay.center * imageScale + adjustment,
        width: overlay.width * imageScale * scale * style.size,
        height: overlay.height * imageScale * scale * style.size,
        rotation: -overlay.rotation + rotation,
      );
    }
    final mesh = faceMesh;
    final detectedFace = face;
    if (mesh == null && detectedFace == null) return null;
    final overlay = mesh != null
        ? renderer.calculateHairstyleOverlayFromMesh(mesh)
        : renderer.calculateHairstyleOverlay(detectedFace!);
    return _Placement(
      center:
          overlay.center * imageScale +
          Offset(0, overlay.height * imageScale * style.verticalOffsetFactor) +
          adjustment,
      width:
          overlay.width * imageScale * scale * style.size * style.widthFactor,
      height:
          overlay.height * imageScale * scale * style.size * style.heightFactor,
      rotation: -overlay.rotation + rotation,
    );
  }

  List<Widget> _buildNailOverlays(Size viewSize) {
    return List.generate(nailAnchors.length, (index) {
      final anchor = nailAnchors[index];
      final transform = nailTransforms[index];
      final width =
          viewSize.width * anchor.width * transform.scale * style.size;
      final height =
          viewSize.height * anchor.height * transform.scale * style.size;
      final center =
          Offset(viewSize.width * anchor.x, viewSize.height * anchor.y) +
          transform.adjustment;
      final hitWidth = width * 2.4;
      final hitHeight = height * 1.9;
      return Positioned(
        left: center.dx - hitWidth / 2,
        top: center.dy - hitHeight / 2,
        width: hitWidth,
        height: hitHeight,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerMove: (event) => onNailDrag(index, event.delta),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onScaleStart: (details) => onNailGestureStart(index, details),
            onScaleUpdate: onNailGestureUpdate,
            child: Center(
              child: SizedBox(
                width: width,
                height: height,
                child: Opacity(
                  opacity: overlayOpacity,
                  child: Transform.rotate(
                    angle: anchor.rotation + transform.rotation,
                    child: _NailPiece(style: style, sourceIndex: index),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _NailPiece extends StatelessWidget {
  final TryOnStyle style;
  final int sourceIndex;

  const _NailPiece({required this.style, required this.sourceIndex});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _NailArtPainter(
        designIndex: sourceIndex,
        roseGold: style.tint != null,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _NailArtPainter extends CustomPainter {
  final int designIndex;
  final bool roseGold;

  const _NailArtPainter({required this.designIndex, required this.roseGold});

  @override
  void paint(Canvas canvas, Size size) {
    final nail = _nailPath(size);
    canvas.save();
    canvas.clipPath(nail);
    _paintBase(canvas, size);
    _paintDesign(canvas, size);
    _paintGloss(canvas, size);
    canvas.restore();

    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.035
      ..color = Colors.black.withAlpha(28);
    canvas.drawPath(nail, edge);
  }

  Path _nailPath(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.19, h * 0.16)
      ..cubicTo(w * 0.19, h * 0.02, w * 0.81, h * 0.02, w * 0.81, h * 0.16)
      ..lineTo(w * 0.74, h * 0.78)
      ..quadraticBezierTo(w * 0.5, h * 1.02, w * 0.26, h * 0.78)
      ..close();
  }

  void _paintBase(Canvas canvas, Size size) {
    final burgundy = roseGold
        ? const Color(0xffc87878)
        : const Color(0xff7d0509);
    final dark = roseGold ? const Color(0xff7d343e) : const Color(0xff2b0002);
    final gold = roseGold ? const Color(0xffffd0b2) : const Color(0xffd9a029);
    final basePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: designIndex == 3
            ? [gold, const Color(0xffffefb3), gold]
            : [dark, burgundy, dark],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, basePaint);
  }

  void _paintDesign(Canvas canvas, Size size) {
    switch (designIndex) {
      case 0:
        _paintGlitterFade(canvas, size);
        break;
      case 1:
        _paintMarble(canvas, size);
        break;
      case 2:
        _paintLeaf(canvas, size);
        break;
      case 3:
        _paintFullGlitter(canvas, size);
        break;
      default:
        _paintDiagonalGold(canvas, size);
    }
  }

  void _paintGlitterFade(Canvas canvas, Size size) {
    final gold = _goldPaint(size);
    for (var i = 0; i < 24; i++) {
      final x = size.width * (0.2 + (i % 6) * 0.12);
      final y = size.height * (0.55 + (i ~/ 6) * 0.09);
      final radius = size.width * (0.018 + (i % 3) * 0.009);
      canvas.drawCircle(Offset(x, y), radius, gold);
    }
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.68, size.width, size.height * 0.35),
      _goldPaint(size)..color = _goldColor.withAlpha(210),
    );
  }

  void _paintMarble(Canvas canvas, Size size) {
    final soft = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.12
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withAlpha(70);
    final gold = _linePaint(size, size.width * 0.035);
    for (final shift in [0.0, 0.28, 0.55]) {
      final path = Path()
        ..moveTo(size.width * -0.1, size.height * (0.2 + shift))
        ..cubicTo(
          size.width * 0.35,
          size.height * (0.08 + shift),
          size.width * 0.62,
          size.height * (0.42 + shift),
          size.width * 1.1,
          size.height * (0.25 + shift),
        );
      canvas.drawPath(path, soft);
      canvas.drawPath(path, gold);
    }
  }

  void _paintLeaf(Canvas canvas, Size size) {
    final stem = _linePaint(size, size.width * 0.035);
    final path = Path()
      ..moveTo(size.width * 0.38, size.height * 0.86)
      ..cubicTo(
        size.width * 0.62,
        size.height * 0.62,
        size.width * 0.45,
        size.height * 0.36,
        size.width * 0.68,
        size.height * 0.18,
      );
    canvas.drawPath(path, stem);
    final leafPaint = _goldPaint(size);
    for (var i = 0; i < 5; i++) {
      final y = size.height * (0.34 + i * 0.1);
      final left = i.isEven;
      final center = Offset(size.width * (left ? 0.45 : 0.62), y);
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: size.width * 0.22,
          height: size.height * 0.08,
        ),
        leafPaint,
      );
    }
  }

  void _paintFullGlitter(Canvas canvas, Size size) {
    final sparkle = Paint()..color = Colors.white.withAlpha(130);
    final darkGold = Paint()..color = const Color(0xff9d681a).withAlpha(120);
    for (var i = 0; i < 38; i++) {
      final x = size.width * (0.15 + (i * 37 % 70) / 100);
      final y = size.height * (0.08 + (i * 19 % 84) / 100);
      canvas.drawCircle(
        Offset(x, y),
        size.width * (0.01 + (i % 4) * 0.006),
        i.isEven ? sparkle : darkGold,
      );
    }
  }

  void _paintDiagonalGold(Canvas canvas, Size size) {
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        colors: [_goldColor, const Color(0xffffedaa), _goldColor],
      ).createShader(Offset.zero & size);
    final band = Path()
      ..moveTo(size.width * 0.8, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width * 0.2, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(band, fill);
    final line = _linePaint(size, size.width * 0.035);
    canvas.drawLine(
      Offset(size.width * 0.78, size.height * 0.02),
      Offset(size.width * 0.1, size.height * 0.95),
      line,
    );
  }

  void _paintGloss(Canvas canvas, Size size) {
    final gloss = Paint()
      ..color = Colors.white.withAlpha(105)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.58,
          size.height * 0.1,
          size.width * 0.16,
          size.height * 0.48,
        ),
        Radius.circular(size.width * 0.2),
      ),
      gloss,
    );
  }

  Color get _goldColor =>
      roseGold ? const Color(0xffffc0a8) : const Color(0xffd9a029);

  Paint _goldPaint(Size size) {
    return Paint()
      ..shader = LinearGradient(
        colors: [_goldColor, const Color(0xffffefb3), _goldColor],
      ).createShader(Offset.zero & size);
  }

  Paint _linePaint(Size size, double strokeWidth) {
    return Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: [_goldColor, const Color(0xffffefb3), _goldColor],
      ).createShader(Offset.zero & size);
  }

  @override
  bool shouldRepaint(covariant _NailArtPainter oldDelegate) {
    return oldDelegate.designIndex != designIndex ||
        oldDelegate.roseGold != roseGold;
  }
}

const _fallbackNailAnchors = [
  _NailAnchor(x: 0.26, y: 0.57, width: 0.085, height: 0.14, rotation: -0.48),
  _NailAnchor(x: 0.43, y: 0.43, width: 0.092, height: 0.16, rotation: -0.08),
  _NailAnchor(x: 0.51, y: 0.40, width: 0.096, height: 0.17),
  _NailAnchor(x: 0.59, y: 0.43, width: 0.09, height: 0.16, rotation: 0.08),
  _NailAnchor(x: 0.73, y: 0.50, width: 0.08, height: 0.135, rotation: 0.18),
];

class _NailAnchor {
  final double x;
  final double y;
  final double width;
  final double height;
  final double rotation;

  const _NailAnchor({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.rotation = 0,
  });
}

class _NailTransform {
  final Offset adjustment;
  final double scale;
  final double rotation;

  const _NailTransform({
    this.adjustment = Offset.zero,
    this.scale = 1,
    this.rotation = 0,
  });

  _NailTransform copyWith({
    Offset? adjustment,
    double? scale,
    double? rotation,
  }) {
    return _NailTransform(
      adjustment: adjustment ?? this.adjustment,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
    );
  }
}

class _StyleImage extends StatelessWidget {
  final TryOnStyle style;

  const _StyleImage({required this.style});

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(style.assetPath, fit: BoxFit.contain);
    final tint = style.tint;
    if (tint == null) return image;
    return ColorFiltered(
      colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
      child: image,
    );
  }
}

class _Placement {
  final Offset center;
  final double width;
  final double height;
  final double rotation;

  const _Placement({
    required this.center,
    required this.width,
    required this.height,
    required this.rotation,
  });
}
