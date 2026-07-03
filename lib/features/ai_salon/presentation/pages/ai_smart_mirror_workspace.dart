import 'dart:convert';
import 'dart:io';
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
import 'package:video_player/video_player.dart';

import '../../data/models/three_d_tryon_model.dart';
import '../../data/repositories/three_d_model_repository.dart';
import '../../domain/services/advanced_tryon_detection_service.dart';
import '../../domain/services/ar_overlay_renderer.dart';
import '../../domain/services/face_detection_service.dart';
import '../../../premium/data/premium_access_controller.dart';
import '../../../premium/domain/premium_models.dart';
import '../../../premium/presentation/pages/premium_plans_page.dart';

enum TryOnCategory { hairstyle, beard, nailArt, tattoo, mehndi }

enum HairLookGroup { men, women }

enum TryOnMode { twoD, threeD }

enum _EditTool { cut, crop, rotate, mirror, color, draw }

enum _CutMode { brush, lasso, line }

enum _GalleryItemType { photo, video }

class _GalleryItem {
  final String id;
  final _GalleryItemType type;
  final Uint8List? bytes;
  final String? path;
  final String title;

  const _GalleryItem({
    required this.id,
    required this.type,
    required this.bytes,
    this.path,
    required this.title,
  });
}

String _toolLabel(_EditTool tool) => switch (tool) {
  _EditTool.cut => 'Cut',
  _EditTool.crop => 'Crop',
  _EditTool.rotate => 'Rotate',
  _EditTool.mirror => 'Mirror',
  _EditTool.color => 'Color',
  _EditTool.draw => 'Draw',
};

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
    TryOnStyle(
      id: 'mehndi-bridal',
      name: 'Bridal mehndi',
      category: TryOnCategory.mehndi,
      assetPath: '',
      widthFactor: 1.15,
      heightFactor: 1.4,
    ),
    TryOnStyle(
      id: 'mehndi-arabic',
      name: 'Arabic trail',
      category: TryOnCategory.mehndi,
      assetPath: '',
      tint: Color(0xff7b3f22),
      widthFactor: 1.05,
      heightFactor: 1.35,
    ),
    TryOnStyle(
      id: 'mehndi-arabic-bold',
      name: 'Bold Arabic',
      category: TryOnCategory.mehndi,
      assetPath: '',
      tint: Color(0xff5f2d16),
      widthFactor: 1.12,
      heightFactor: 1.28,
    ),
    TryOnStyle(
      id: 'mehndi-arabic-floral',
      name: 'Arabic floral',
      category: TryOnCategory.mehndi,
      assetPath: '',
      tint: Color(0xff7a3b1f),
      widthFactor: 1.18,
      heightFactor: 1.18,
    ),
    TryOnStyle(
      id: 'mehndi-arabic-wrist',
      name: 'Arabic wrist',
      category: TryOnCategory.mehndi,
      assetPath: '',
      tint: Color(0xff8a4d2c),
      widthFactor: 1.24,
      heightFactor: 0.82,
    ),
    TryOnStyle(
      id: 'mehndi-mandala',
      name: 'Palm mandala',
      category: TryOnCategory.mehndi,
      assetPath: '',
      tint: Color(0xff5c2f1b),
      widthFactor: 1.1,
      heightFactor: 1.1,
    ),
    TryOnStyle(
      id: 'mehndi-floral',
      name: 'Floral wrist',
      category: TryOnCategory.mehndi,
      assetPath: '',
      tint: Color(0xff8a4d2c),
      widthFactor: 1.2,
      heightFactor: 0.75,
    ),
    TryOnStyle(
      id: 'mehndi-finger-vines',
      name: 'Finger vines',
      category: TryOnCategory.mehndi,
      assetPath: '',
      tint: Color(0xff663517),
      widthFactor: 0.95,
      heightFactor: 1.45,
    ),
    TryOnStyle(
      id: 'mehndi-minimal',
      name: 'Minimal mehndi',
      category: TryOnCategory.mehndi,
      assetPath: '',
      tint: Color(0xff9a5a32),
      widthFactor: 0.95,
      heightFactor: 0.95,
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
  final List<_GalleryItem> _galleryItems = [];

  Uint8List? _photo;
  Uint8List? _editedResultBytes;
  Size? _photoSize;
  Face? _face;
  FaceMesh? _faceMesh;
  Pose? _pose;
  TryOnMode _mode = TryOnMode.twoD;
  TryOnCategory _category = TryOnCategory.hairstyle;
  ThreeDCategory _threeDCategory = ThreeDCategory.hair;
  TryOnStyle? _selectedPremiumStyle;
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
  Color? _modelColorOverride;
  double _overlayOpacity = 1;
  bool _overlayVisible = true;
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
    await _processPickedPhoto(selected);
  }

  Future<void> _processPickedPhoto(XFile selected) async {
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
          selectedCategory != TryOnCategory.tattoo &&
          selectedCategory != TryOnCategory.mehndi) {
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

      if (selectedCategory == TryOnCategory.tattoo ||
          selectedCategory == TryOnCategory.mehndi) {
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
        _editedResultBytes = null;
        _modelColorOverride = null;
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
            : selectedCategory == TryOnCategory.tattoo ||
                  selectedCategory == TryOnCategory.mehndi
            ? _pose == null
                  ? '${selectedCategory == TryOnCategory.mehndi ? 'Mehndi' : 'Tattoo'} photo ready. Drag, pinch, and rotate to place the design.'
                  : '${selectedCategory == TryOnCategory.mehndi ? 'Mehndi' : 'Tattoo'} auto-fitted from body pose. Adjust if needed.'
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

  Future<void> _openAddMediaSheet() async {
    if (_working) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Open from gallery',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Photo'),
                subtitle: const Text('Preview before using it in try-on'),
                onTap: () async {
                  Navigator.pop(context);
                  final selected = await _picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 95,
                    maxWidth: 1600,
                  );
                  if (!mounted || selected == null) return;
                  await _previewGalleryPhoto(selected);
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library_outlined),
                title: const Text('Video'),
                subtitle: const Text('Preview video with share/delete options'),
                onTap: () async {
                  Navigator.pop(context);
                  final selected = await _picker.pickVideo(
                    source: ImageSource.gallery,
                  );
                  if (!mounted || selected == null) return;
                  await _previewGalleryVideo(selected);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _previewGalleryPhoto(XFile selected) async {
    final bytes = await selected.readAsBytes();
    if (!mounted) return;
    final viewerResult = await Navigator.push<_FullscreenViewerResult>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _FullscreenResultViewer(
          imageBytes: bytes,
          title: 'Gallery photo',
          editImportsToCanvas: true,
        ),
      ),
    );
    if (!mounted || viewerResult == null) return;
    switch (viewerResult.action) {
      case _FullscreenViewerAction.useInCanvas:
        await _processPickedPhoto(selected);
        break;
      case _FullscreenViewerAction.editWithAi:
        await _processPickedPhoto(selected);
        if (!mounted) return;
        setState(() {
          _mode = TryOnMode.threeD;
          _status = 'Gallery photo opened in AI Premium.';
        });
        break;
      case _FullscreenViewerAction.delete:
        setState(() => _status = 'Gallery photo dismissed.');
        break;
      case _FullscreenViewerAction.updated:
        break;
    }
  }

  Future<void> _previewGalleryVideo(XFile selected) async {
    if (!mounted) return;
    final viewerResult = await Navigator.push<_FullscreenViewerResult>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _FullscreenVideoViewer(path: selected.path),
      ),
    );
    if (!mounted || viewerResult == null) return;
    switch (viewerResult.action) {
      case _FullscreenViewerAction.delete:
        setState(() => _status = 'Gallery video dismissed.');
        break;
      case _FullscreenViewerAction.editWithAi:
        setState(() {
          _mode = TryOnMode.threeD;
          _status = 'Video AI edit is not available in this image demo.';
        });
        break;
      case _FullscreenViewerAction.useInCanvas:
      case _FullscreenViewerAction.updated:
        break;
    }
  }

  void _selectCategory(TryOnCategory category) {
    setState(() {
      _category = category;
      _editedResultBytes = null;
      _modelColorOverride = null;
      _style = _firstStyleFor(category);
      _resetTransform();
      _status = category == TryOnCategory.nailArt
          ? _photo == null
                ? 'Upload a top-down hand photo with fingers slightly spread.'
                : 'Drag each nail onto its matching fingertip.'
          : category == TryOnCategory.tattoo
          ? _photo == null
                ? 'Upload a clear photo of arm, wrist, neck, or shoulder skin.'
                : 'Drag, resize, and rotate the tattoo over clean skin.'
          : category == TryOnCategory.mehndi
          ? _photo == null
                ? 'Upload a clear palm, back-hand, or wrist photo for mehndi.'
                : 'Drag, resize, and rotate the mehndi design over the hand.'
          : _photo == null
          ? 'Upload a clear, upright portrait, then tap a style model.'
          : 'Tap a model below to update the converted preview.';
    });
  }

  void _selectMode(TryOnMode mode) {
    setState(() {
      _mode = mode;
      _modelColorOverride = null;
      _status = mode == TryOnMode.twoD
          ? '2D try-on ready. Upload a photo and choose a model.'
          : 'Premium AI edit ready. Upload a photo and choose a style.';
    });
  }

  void _selectThreeDCategory(ThreeDCategory category) {
    setState(() {
      _threeDCategory = category;
      _selectedPremiumStyle = null;
      _modelColorOverride = null;
      _threeDPreviewColor = null;
      _generatedThreeDModelUrl = null;
      _threeDPrompt.clear();
      _threeDPromptStatus = 'Describe the realistic blended look you want.';
      _status = '${_threeDCategoryLabel(category)} AI styles shown.';
    });
  }

  ThreeDModel _activeThreeDModel(List<ThreeDModel> models) {
    return models.firstWhere((model) => model.category == _threeDCategory);
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
    final selectedStyle = _selectedPremiumStyle;
    final prompt = _threeDPrompt.text.trim().isEmpty
        ? selectedStyle?.name ?? model.name
        : _threeDPrompt.text.trim();
    setState(() {
      _threeDGenerating = true;
      _threeDPromptStatus = 'Requesting premium AI image edit from backend...';
      _status = 'Generating premium AI try-on...';
    });

    final result = await _premiumThreeDRepository.generate(
      category: _threeDCategory,
      styleId: selectedStyle?.id ?? model.id,
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
    if (prompt.contains('mehndi') || prompt.contains('henna')) {
      return const Color(0xff7b3f22);
    }
    return null;
  }

  String _threeDCategoryLabel(ThreeDCategory category) {
    return switch (category) {
      ThreeDCategory.hair => 'Hair',
      ThreeDCategory.beard => 'Beard',
      ThreeDCategory.nails => 'Nails',
      ThreeDCategory.mehndi => 'Mehndi',
    };
  }

  PremiumFeature get _selectedPremiumFeature => switch (_threeDCategory) {
    ThreeDCategory.hair => PremiumFeature.aiHair,
    ThreeDCategory.beard => PremiumFeature.aiBeard,
    ThreeDCategory.nails => PremiumFeature.aiNails,
    ThreeDCategory.mehndi => PremiumFeature.aiMehndi,
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
      _selectedPremiumStyle = null;
      _modelColorOverride = null;
      _resetTransform();
      _status =
          '${group == HairLookGroup.men ? 'Men' : 'Women'} hairstyle models shown.';
    });
  }

  void _selectStyle(TryOnStyle style) {
    setState(() {
      _style = style;
      _editedResultBytes = null;
      _modelColorOverride = null;
      _resetTransform();
      _status = _photo == null
          ? 'Now upload a photo to try ${style.name}.'
          : (style.category == TryOnCategory.hairstyle ||
                    style.category == TryOnCategory.beard) &&
                _face == null &&
                _faceMesh == null
          ? '${style.name} placed on image. Drag, pinch, or rotate to fit.'
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
        setState(() {
          _galleryItems.insert(
            0,
            _GalleryItem(
              id: 'photo_${DateTime.now().millisecondsSinceEpoch}',
              type: _GalleryItemType.photo,
              bytes: bytes,
              title: _style.name,
            ),
          );
          _status = 'Result saved to gallery.';
        });
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

  Future<void> _openEditOptions() async {
    if (_photo == null || _working) return;
    setState(() {
      _working = true;
      _status = 'Preparing editor...';
    });
    late final Uint8List resultBytes;
    try {
      resultBytes = await _captureResult();
    } catch (_) {
      if (mounted) {
        setState(() => _status = 'Could not open editor for this result.');
      }
      return;
    } finally {
      if (mounted) setState(() => _working = false);
    }
    if (!mounted) return;

    await _openCapturedEditor(resultBytes, _EditTool.crop);
  }

  Future<void> _openCurrentResultInAiPremium() async {
    if (_photo == null || _working) return;
    setState(() {
      _working = true;
      _status = 'Opening current image in AI Premium...';
    });
    late final Uint8List resultBytes;
    try {
      resultBytes = await _captureResult();
    } catch (_) {
      if (mounted) setState(() => _status = 'Could not open AI Premium.');
      return;
    } finally {
      if (mounted) setState(() => _working = false);
    }
    final decoded = img.decodeImage(resultBytes);
    if (!mounted) return;
    setState(() {
      _photo = resultBytes;
      _editedResultBytes = null;
      _modelColorOverride = null;
      if (decoded != null) {
        _photoSize = Size(decoded.width.toDouble(), decoded.height.toDouble());
      }
      _mode = TryOnMode.threeD;
      _status = 'Current image opened in AI Premium.';
    });
  }

  Future<void> _openCapturedEditor(
    Uint8List resultBytes,
    _EditTool initialTool,
  ) async {
    final editResult = await Navigator.push<_EditorResult>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _EditResultScreen(
          imageBytes: resultBytes,
          initialTool: initialTool,
        ),
      ),
    );
    if (!mounted) return;
    setState(() {
      if (editResult?.imageBytes != null) {
        _editedResultBytes = editResult!.imageBytes;
      }
      if (editResult?.modelColor != null) {
        _modelColorOverride = editResult!.modelColor;
      }
      _status = editResult != null
          ? editResult.modelColor != null
                ? '${_style.name} color updated.'
                : 'Edited result applied. Save or share when ready.'
          : 'Editor closed without saving.';
    });
  }

  Future<void> _openResultViewer() async {
    if (_photo == null || _working) return;
    setState(() {
      _working = true;
      _status = 'Opening result...';
    });
    late final Uint8List resultBytes;
    try {
      resultBytes = await _captureResult();
    } catch (_) {
      if (mounted) setState(() => _status = 'Could not open this result.');
      return;
    } finally {
      if (mounted) setState(() => _working = false);
    }
    if (!mounted) return;

    final viewerResult = await Navigator.push<_FullscreenViewerResult>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _FullscreenResultViewer(
          imageBytes: resultBytes,
        ),
      ),
    );
    if (!mounted) return;
    if (viewerResult == null) {
      setState(() => _status = 'Returned from full screen preview.');
      return;
    }
    setState(() {
      switch (viewerResult.action) {
        case _FullscreenViewerAction.updated:
          _editedResultBytes = viewerResult.imageBytes;
          if (viewerResult.modelColor != null) {
            _modelColorOverride = viewerResult.modelColor;
          }
          _status = 'Fullscreen edit applied.';
          break;
        case _FullscreenViewerAction.delete:
          _photo = null;
          _editedResultBytes = null;
          _photoSize = null;
          _face = null;
          _faceMesh = null;
          _pose = null;
          _status = 'Result deleted.';
          break;
        case _FullscreenViewerAction.editWithAi:
          final imageBytes = viewerResult.imageBytes ?? resultBytes;
          _photo = imageBytes;
          _editedResultBytes = null;
          _modelColorOverride = null;
          final decoded = img.decodeImage(imageBytes);
          if (decoded != null) {
            _photoSize = Size(
              decoded.width.toDouble(),
              decoded.height.toDouble(),
            );
          }
          _mode = TryOnMode.threeD;
          _status = 'Current image opened in AI Premium.';
          break;
        case _FullscreenViewerAction.useInCanvas:
          break;
      }
    });
  }

  Future<void> _openGalleryItem(_GalleryItem item) async {
    if (item.type == _GalleryItemType.video) {
      final path = item.path;
      if (path == null) {
        setState(() => _status = 'Video file is not available.');
        return;
      }
      final viewerResult = await Navigator.push<_FullscreenViewerResult>(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => _FullscreenVideoViewer(path: path),
        ),
      );
      if (!mounted || viewerResult == null) return;
      switch (viewerResult.action) {
        case _FullscreenViewerAction.delete:
          setState(
            () => _galleryItems.removeWhere((entry) => entry.id == item.id),
          );
          break;
        case _FullscreenViewerAction.editWithAi:
          setState(() {
            _mode = TryOnMode.threeD;
            _status = 'Video AI edit is not available in this image demo.';
          });
          break;
        case _FullscreenViewerAction.updated:
        case _FullscreenViewerAction.useInCanvas:
          break;
      }
      return;
    }
    if (item.bytes == null) {
      return;
    }
    final viewerResult = await Navigator.push<_FullscreenViewerResult>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _FullscreenResultViewer(imageBytes: item.bytes!),
      ),
    );
    if (!mounted || viewerResult == null) return;
    setState(() {
      switch (viewerResult.action) {
        case _FullscreenViewerAction.updated:
          final index = _galleryItems.indexWhere((entry) => entry.id == item.id);
          final imageBytes = viewerResult.imageBytes;
          if (index != -1 && imageBytes != null) {
            _galleryItems[index] = _GalleryItem(
              id: item.id,
              type: item.type,
              bytes: imageBytes,
              path: item.path,
              title: item.title,
            );
            _status = 'Gallery photo updated.';
          }
          break;
        case _FullscreenViewerAction.delete:
          _galleryItems.removeWhere((entry) => entry.id == item.id);
          _status = 'Gallery item deleted.';
          break;
        case _FullscreenViewerAction.editWithAi:
          _mode = TryOnMode.threeD;
          _photo = item.bytes;
          _editedResultBytes = null;
          _modelColorOverride = null;
          final decoded = img.decodeImage(item.bytes!);
          if (decoded != null) {
            _photoSize = Size(
              decoded.width.toDouble(),
              decoded.height.toDouble(),
            );
          }
          _status = 'AI Premium opened for this gallery photo.';
          break;
        case _FullscreenViewerAction.useInCanvas:
          break;
      }
    });
  }

  Future<void> _editGalleryPhoto(_GalleryItem item) async {
    final bytes = item.bytes;
    if (bytes == null) {
      setState(
        () => _status =
            'Video editing needs a video pipeline; image edit is ready.',
      );
      return;
    }
    final editResult = await Navigator.push<_EditorResult>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _EditResultScreen(
          imageBytes: bytes,
          initialTool: _EditTool.crop,
        ),
      ),
    );
    if (!mounted || editResult == null) return;
    final editedBytes = editResult.imageBytes;
    if (editedBytes == null) {
      setState(() => _status = 'Color edits apply on the main try-on canvas.');
      return;
    }
    setState(() {
      final index = _galleryItems.indexWhere((entry) => entry.id == item.id);
      if (index == -1) return;
      _galleryItems[index] = _GalleryItem(
        id: item.id,
        type: item.type,
        bytes: editedBytes,
        path: item.path,
        title: item.title,
      );
      _status = 'Gallery photo edited.';
    });
  }

  Future<void> _showGalleryItemActions(_GalleryItem item) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  onTap: () {
                    Navigator.pop(context);
                    setState(
                      () => _galleryItems.removeWhere(
                        (entry) => entry.id == item.id,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  onTap: () {
                    Navigator.pop(context);
                    if (item.type == _GalleryItemType.video) {
                      final path = item.path;
                      if (path == null) {
                        setState(() => _status = 'Video file is not available.');
                        return;
                      }
                      SharePlus.instance.share(
                        ShareParams(
                          text: 'My salon video from The Salon App',
                          files: [XFile(path)],
                        ),
                      );
                    } else if (item.bytes == null) {
                      setState(() => _status = 'Photo file is not available.');
                    } else {
                      SharePlus.instance.share(
                        ShareParams(
                          text: 'My virtual try-on result from The Salon App',
                          files: [
                            XFile.fromData(item.bytes!, mimeType: 'image/png'),
                          ],
                          fileNameOverrides: ['${item.id}.png'],
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  onTap: () {
                    Navigator.pop(context);
                    _editGalleryPhoto(item);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectPremiumStyle(TryOnStyle style) {
    setState(() {
      _selectedPremiumStyle = style;
      _modelColorOverride = null;
      _generatedThreeDModelUrl = null;
    });
    _selectPremiumPreview(style.name);
  }

  TryOnCategory _tryOnCategoryForThreeD(ThreeDCategory category) {
    return switch (category) {
      ThreeDCategory.hair => TryOnCategory.hairstyle,
      ThreeDCategory.beard => TryOnCategory.beard,
      ThreeDCategory.nails => TryOnCategory.nailArt,
      ThreeDCategory.mehndi => TryOnCategory.mehndi,
    };
  }

  List<TryOnStyle> _stylesForCategory(TryOnCategory category) {
    return _styles
        .where(
          (style) =>
              style.category == category &&
              (category != TryOnCategory.hairstyle ||
                  style.hairGroup == _hairLookGroup),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final activeStyleCategory = _mode == TryOnMode.twoD
        ? _category
        : _tryOnCategoryForThreeD(_threeDCategory);
    final models = _stylesForCategory(activeStyleCategory);
    final threeDModels = _threeDRepository.modelsFor(_threeDCategory);
    final activeThreeDModel = _activeThreeDModel(threeDModels);
    final premiumPreviewName =
        _selectedPremiumStyle?.name ?? activeThreeDModel.name;
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
                  editedResultBytes: _editedResultBytes,
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
                  modelColorOverride: _modelColorOverride,
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
                  onOpenFullScreen: _openResultViewer,
                  onDownload: _saveResult,
                  onShare: _shareResult,
                  onEditWithAi: _openCurrentResultInAiPremium,
                  onDelete: () => setState(() {
                    _photo = null;
                    _editedResultBytes = null;
                    _photoSize = null;
                    _face = null;
                    _faceMesh = null;
                    _pose = null;
                    _status = 'Result deleted.';
                  }),
                ),
              ),
              const SizedBox(height: 10),
              _MirrorActionToolbar(
                working: _working,
                hasPhoto: _photo != null,
                onAddMedia: _openAddMediaSheet,
                onCamera: () => _pickPhoto(ImageSource.camera),
                onSave: _saveResult,
                onEdit: _openEditOptions,
                onShare: _shareResult,
              ),
            ] else ...[
              _ThreeDTryOnPreview(
                model: activeThreeDModel,
                styleName: premiumPreviewName,
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
                      icon: const Icon(Icons.add_photo_alternate_outlined),
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
                            previewName: premiumPreviewName,
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
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<TryOnCategory>(
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
                    ButtonSegment(
                      value: TryOnCategory.mehndi,
                      label: Text('Mehndi'),
                    ),
                  ],
                  selected: {_category},
                  onSelectionChanged: (value) => _selectCategory(value.first),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<ThreeDCategory>(
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
                    ButtonSegment(
                      value: ThreeDCategory.mehndi,
                      label: Text('AI Mehndi'),
                      icon: Icon(Icons.draw_outlined),
                    ),
                  ],
                  selected: {_threeDCategory},
                  onSelectionChanged: (value) =>
                      _selectThreeDCategory(value.first),
                ),
              ),
            if (activeStyleCategory == TryOnCategory.hairstyle) ...[
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
                activeStyleCategory == TryOnCategory.nailArt) ...[
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
                activeStyleCategory == TryOnCategory.tattoo) ...[
              const SizedBox(height: 12),
              _TattooPhotoGuide(
                onReset: () => setState(() {
                  _resetTransform();
                  _status = 'Tattoo position reset. Drag it over clean skin.';
                }),
              ),
            ],
            if (_mode == TryOnMode.twoD &&
                activeStyleCategory == TryOnCategory.mehndi) ...[
              const SizedBox(height: 12),
              _MehndiPhotoGuide(
                onReset: () => setState(() {
                  _resetTransform();
                  _status = 'Mehndi position reset. Place it over the hand.';
                }),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              height: 154,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: models.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final model = models[index];
                  return _ModelCard(
                    style: model,
                    selected: _mode == TryOnMode.twoD
                        ? _style.id == model.id
                        : _selectedPremiumStyle?.id == model.id,
                    onTap: () => _mode == TryOnMode.twoD
                        ? _selectStyle(model)
                        : _selectPremiumStyle(model),
                    locked: false,
                  );
                },
              ),
            ),
            if (_mode == TryOnMode.threeD) ...[
              const SizedBox(height: 12),
              _Premium3DCard(
                styleName: premiumPreviewName,
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

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: FittedBox(child: Text(label)),
    );
  }
}

class _MirrorActionToolbar extends StatelessWidget {
  final bool working;
  final bool hasPhoto;
  final VoidCallback onAddMedia;
  final VoidCallback onCamera;
  final VoidCallback onSave;
  final VoidCallback onEdit;
  final VoidCallback onShare;

  const _MirrorActionToolbar({
    required this.working,
    required this.hasPhoto,
    required this.onAddMedia,
    required this.onCamera,
    required this.onSave,
    required this.onEdit,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: working ? null : onAddMedia,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Gallery'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: working ? null : onCamera,
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Camera'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x17000000)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                _ToolbarAction(
                  icon: Icons.file_download_outlined,
                  label: 'Save',
                  onTap: !hasPhoto || working ? null : onSave,
                ),
                _ToolbarAction(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  onTap: !hasPhoto || working ? null : onEdit,
                ),
                _ToolbarAction(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  onTap: !hasPhoto || working ? null : onShare,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ToolbarAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool filled;

  const _ToolbarAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final color = filled
        ? Colors.white
        : enabled
            ? const Color(0xff1e2d3d)
            : Colors.black38;
    final background = filled && enabled
        ? const Color(0xff0f6fb7)
        : const Color(0xfff4f6f8);
    return Expanded(
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 56,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: background,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox.square(
                    dimension: 30,
                    child: Icon(icon, size: 18, color: color),
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: enabled ? const Color(0xff1e2d3d) : Colors.black38,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _FullscreenViewerAction { updated, delete, editWithAi, useInCanvas }

class _FullscreenViewerResult {
  final _FullscreenViewerAction action;
  final Uint8List? imageBytes;
  final Color? modelColor;

  const _FullscreenViewerResult(
    this.action, {
    this.imageBytes,
    this.modelColor,
  });
}

PopupMenuEntry<String> _fullscreenMenuItem({
  required String value,
  required IconData icon,
  required String label,
}) {
  return PopupMenuItem<String>(
    value: value,
    child: Row(
      children: [
        Icon(icon, size: 20, color: Colors.white70),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    ),
  );
}

class _FullscreenResultViewer extends StatefulWidget {
  final Uint8List imageBytes;
  final String title;
  final bool editImportsToCanvas;

  const _FullscreenResultViewer({
    required this.imageBytes,
    this.title = 'Media preview',
    this.editImportsToCanvas = false,
  });

  @override
  State<_FullscreenResultViewer> createState() => _FullscreenResultViewerState();
}

class _FullscreenResultViewerState extends State<_FullscreenResultViewer> {
  late Uint8List _imageBytes;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _imageBytes = widget.imageBytes;
  }

  void _close() {
    Navigator.pop(
      context,
      _changed
          ? _FullscreenViewerResult(
              _FullscreenViewerAction.updated,
              imageBytes: _imageBytes,
            )
          : null,
    );
  }

  Future<void> _download() async {
    try {
      await Gal.putImageBytes(
        _imageBytes,
        name: 'salon_fullscreen_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved to gallery')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save image')),
      );
    }
  }

  Future<void> _share() async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: 'My virtual try-on result from The Salon App',
          files: [XFile.fromData(_imageBytes, mimeType: 'image/png')],
          fileNameOverrides: const ['salon_tryon.png'],
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not share image')),
      );
    }
  }

  Future<void> _edit() async {
    if (widget.editImportsToCanvas) {
      Navigator.pop(
        context,
        _FullscreenViewerResult(
          _FullscreenViewerAction.useInCanvas,
          imageBytes: _imageBytes,
        ),
      );
      return;
    }
    final editResult = await Navigator.push<_EditorResult>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _EditResultScreen(
          imageBytes: _imageBytes,
          initialTool: _EditTool.crop,
        ),
      ),
    );
    if (!mounted || editResult == null) return;
    if (editResult.modelColor != null) {
      Navigator.pop(
        context,
        _FullscreenViewerResult(
          _FullscreenViewerAction.updated,
          imageBytes: _imageBytes,
          modelColor: editResult.modelColor,
        ),
      );
      return;
    }
    final editedBytes = editResult.imageBytes;
    if (editedBytes == null) return;
    setState(() {
      _imageBytes = editedBytes;
      _changed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _close();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: const Color(0xff101819),
          foregroundColor: Colors.white,
          title: Text(widget.title),
          leading: IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back),
            onPressed: _close,
          ),
          actions: [
            IconButton(
              tooltip: 'Download',
              icon: const Icon(Icons.file_download_outlined),
              onPressed: _download,
            ),
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined),
              onPressed: _edit,
            ),
            PopupMenuButton<String>(
              tooltip: 'More',
              icon: const Icon(Icons.more_vert),
              color: const Color(0xff101819),
              surfaceTintColor: Colors.transparent,
              onSelected: (value) {
                if (value == 'share') _share();
                if (value == 'ai') {
                  Navigator.pop(
                    context,
                    _FullscreenViewerResult(
                      _FullscreenViewerAction.editWithAi,
                      imageBytes: _imageBytes,
                    ),
                  );
                }
                if (value == 'delete') {
                  Navigator.pop(
                    context,
                    const _FullscreenViewerResult(
                      _FullscreenViewerAction.delete,
                    ),
                  );
                }
              },
              itemBuilder: (context) => [
                _fullscreenMenuItem(
                  value: 'share',
                  icon: Icons.share_outlined,
                  label: 'Share',
                ),
                _fullscreenMenuItem(
                  value: 'ai',
                  icon: Icons.auto_awesome,
                  label: 'Edit with AI',
                ),
                _fullscreenMenuItem(
                  value: 'delete',
                  icon: Icons.delete_outline,
                  label: 'Delete',
                ),
              ],
            ),
          ],
        ),
        body: Center(
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 5,
            child: Image.memory(_imageBytes, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}

class _FullscreenVideoViewer extends StatefulWidget {
  final String path;

  const _FullscreenVideoViewer({required this.path});

  @override
  State<_FullscreenVideoViewer> createState() => _FullscreenVideoViewerState();
}

class _FullscreenVideoViewerState extends State<_FullscreenVideoViewer> {
  late final VideoPlayerController _controller;
  late final Future<void> _initialize;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.path));
    _initialize = _controller.initialize().then((_) {
      _controller.play();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close() {
    Navigator.pop(context);
  }

  Future<void> _share() async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: 'My salon video from The Salon App',
          files: [XFile(widget.path)],
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not share video')),
      );
    }
  }

  void _download() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Video is already on this device')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xff101819),
        foregroundColor: Colors.white,
        title: const Text('Gallery video'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: _close,
        ),
        actions: [
          IconButton(
            tooltip: 'Download',
            icon: const Icon(Icons.file_download_outlined),
            onPressed: _download,
          ),
          IconButton(
            tooltip: 'Edit unavailable for video',
            icon: const Icon(Icons.edit_outlined),
            onPressed: null,
          ),
          PopupMenuButton<String>(
            tooltip: 'More',
            icon: const Icon(Icons.more_vert),
            color: const Color(0xff101819),
            surfaceTintColor: Colors.transparent,
            onSelected: (value) {
              if (value == 'share') _share();
              if (value == 'ai') {
                Navigator.pop(
                  context,
                  const _FullscreenViewerResult(
                    _FullscreenViewerAction.editWithAi,
                  ),
                );
              }
              if (value == 'delete') {
                Navigator.pop(
                  context,
                  const _FullscreenViewerResult(
                    _FullscreenViewerAction.delete,
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              _fullscreenMenuItem(
                value: 'share',
                icon: Icons.share_outlined,
                label: 'Share',
              ),
              _fullscreenMenuItem(
                value: 'ai',
                icon: Icons.auto_awesome,
                label: 'Edit with AI',
              ),
              _fullscreenMenuItem(
                value: 'delete',
                icon: Icons.delete_outline,
                label: 'Delete',
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _initialize,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_controller.value.hasError) {
            return Center(
              child: Text(
                _controller.value.errorDescription ?? 'Could not play video',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }
          return Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              ),
              Positioned(
                bottom: 24,
                child: FilledButton.icon(
                  onPressed: () {
                    setState(() {
                      _controller.value.isPlaying
                          ? _controller.pause()
                          : _controller.play();
                    });
                  },
                  icon: Icon(
                    _controller.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                  ),
                  label: Text(_controller.value.isPlaying ? 'Pause' : 'Play'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PreviewActionOverlay extends StatelessWidget {
  final VoidCallback onDownload;
  final VoidCallback onShare;
  final VoidCallback onEditWithAi;
  final VoidCallback onDelete;

  const _PreviewActionOverlay({
    required this.onDownload,
    required this.onShare,
    required this.onEditWithAi,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 8,
      right: 8,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(135),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Download',
              icon: const Icon(Icons.file_download_outlined),
              color: Colors.white,
              onPressed: onDownload,
            ),
            const IconButton(
              tooltip: 'Edit disabled here',
              icon: Icon(Icons.edit_outlined),
              color: Colors.white38,
              onPressed: null,
            ),
            PopupMenuButton<String>(
              tooltip: 'More',
              icon: const Icon(Icons.more_vert),
              color: const Color(0xff101819),
              surfaceTintColor: Colors.transparent,
              onSelected: (value) {
                if (value == 'share') onShare();
                if (value == 'ai') onEditWithAi();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (context) => [
                _fullscreenMenuItem(
                  value: 'share',
                  icon: Icons.share_outlined,
                  label: 'Share',
                ),
                _fullscreenMenuItem(
                  value: 'ai',
                  icon: Icons.auto_awesome,
                  label: 'Edit with AI',
                ),
                _fullscreenMenuItem(
                  value: 'delete',
                  icon: Icons.delete_outline,
                  label: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorResult {
  final Uint8List? imageBytes;
  final Color? modelColor;

  const _EditorResult({this.imageBytes, this.modelColor});
}

class _EditSnapshot {
  final Uint8List workingImageBytes;
  final Rect cropRect;
  final int rotationTurns;
  final bool mirrored;
  final Color color;
  final List<Offset> cutPoints;
  final List<Offset> drawPoints;
  final _CutMode cutMode;
  final double cutBrushSize;

  const _EditSnapshot({
    required this.workingImageBytes,
    required this.cropRect,
    required this.rotationTurns,
    required this.mirrored,
    required this.color,
    required this.cutPoints,
    required this.drawPoints,
    required this.cutMode,
    required this.cutBrushSize,
  });
}

class _EditResultScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final _EditTool initialTool;

  const _EditResultScreen({
    required this.imageBytes,
    required this.initialTool,
  });

  @override
  State<_EditResultScreen> createState() => _EditResultScreenState();
}

class _EditResultScreenState extends State<_EditResultScreen> {
  late _EditTool _tool;
  late Uint8List _workingImageBytes;
  Rect _cropRect = const Rect.fromLTWH(0.15, 0.08, 0.7, 0.7);
  Rect _startCropRect = const Rect.fromLTWH(0.15, 0.08, 0.7, 0.7);
  Offset _startCropPoint = Offset.zero;
  bool _resizingCrop = false;
  int _rotationTurns = 0;
  bool _mirrored = false;
  Color _color = const Color(0xff7b3f22);
  final List<Offset> _cutPoints = [];
  final List<Offset> _drawPoints = [];
  _CutMode _cutMode = _CutMode.brush;
  double _cutBrushSize = 34;
  Uint8List? _cutPreviewBytes;
  int _cutPreviewRequest = 0;
  bool _cropTouched = false;
  bool _transformTouched = false;
  bool _drawTouched = false;
  final _editPreviewKey = GlobalKey();
  final List<_EditSnapshot> _undoStack = [];
  final List<_EditSnapshot> _redoStack = [];

  @override
  void initState() {
    super.initState();
    _tool = widget.initialTool;
    _workingImageBytes = widget.imageBytes;
  }

  _EditSnapshot _snapshot() {
    return _EditSnapshot(
      workingImageBytes: Uint8List.fromList(_workingImageBytes),
      cropRect: _cropRect,
      rotationTurns: _rotationTurns,
      mirrored: _mirrored,
      color: _color,
      cutPoints: List<Offset>.from(_cutPoints),
      drawPoints: List<Offset>.from(_drawPoints),
      cutMode: _cutMode,
      cutBrushSize: _cutBrushSize,
    );
  }

  void _restoreSnapshot(_EditSnapshot snapshot) {
    _workingImageBytes = Uint8List.fromList(snapshot.workingImageBytes);
    _cropRect = snapshot.cropRect;
    _rotationTurns = snapshot.rotationTurns;
    _mirrored = snapshot.mirrored;
    _color = snapshot.color;
    _cutPoints
      ..clear()
      ..addAll(snapshot.cutPoints);
    _drawPoints
      ..clear()
      ..addAll(snapshot.drawPoints);
    _cutMode = snapshot.cutMode;
    _cutBrushSize = snapshot.cutBrushSize;
    _cropTouched =
        snapshot.cropRect != const Rect.fromLTWH(0.15, 0.08, 0.7, 0.7);
    _transformTouched = snapshot.rotationTurns != 0 || snapshot.mirrored;
    _drawTouched = snapshot.drawPoints.length > 1;
  }

  void _recordEdit() {
    _undoStack.add(_snapshot());
    _redoStack.clear();
  }

  void _clearLiveCutPreview() {
    _cutPreviewRequest++;
    _cutPreviewBytes = null;
  }

  Future<void> _refreshLiveCutPreview() async {
    if (_cutPoints.length < 2) {
      setState(() => _clearLiveCutPreview());
      return;
    }
    final request = ++_cutPreviewRequest;
    try {
      final bytes = _exportCutBytes();
      if (!mounted || request != _cutPreviewRequest) return;
      setState(() => _cutPreviewBytes = bytes);
    } catch (_) {
      // Keep the editable mask visible if the live preview cannot be generated.
    }
  }

  void _reset() {
    _recordEdit();
    setState(() {
      _workingImageBytes = widget.imageBytes;
      _cropRect = const Rect.fromLTWH(0.15, 0.08, 0.7, 0.7);
      _rotationTurns = 0;
      _mirrored = false;
      _color = const Color(0xff7b3f22);
      _cutPoints.clear();
      _drawPoints.clear();
      _cropTouched = false;
      _transformTouched = false;
      _drawTouched = false;
      _clearLiveCutPreview();
    });
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    final previous = _undoStack.removeLast();
    _redoStack.add(_snapshot());
    setState(() {
      _restoreSnapshot(previous);
      _clearLiveCutPreview();
    });
    _refreshLiveCutPreview();
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    final next = _redoStack.removeLast();
    _undoStack.add(_snapshot());
    setState(() {
      _restoreSnapshot(next);
      _clearLiveCutPreview();
    });
    _refreshLiveCutPreview();
  }

  void _startCutPath(Offset point) {
    _recordEdit();
    setState(() {
      _clearLiveCutPreview();
      if (_cutMode == _CutMode.line) {
        _cutPoints
          ..clear()
          ..add(point)
          ..add(point);
      } else {
        _cutPoints.add(point);
      }
    });
  }

  void _updateCutPath(Offset point) {
    setState(() {
      if (_cutMode == _CutMode.line && _cutPoints.length >= 2) {
        _cutPoints[_cutPoints.length - 1] = point;
      } else {
        _cutPoints.add(point);
      }
    });
  }

  void _startCropDrag(Offset localPosition, Size size) {
    _recordEdit();
    _cropTouched = true;
    _startCropRect = _cropRect;
    _startCropPoint = Offset(
      (localPosition.dx / size.width).clamp(0, 1).toDouble(),
      (localPosition.dy / size.height).clamp(0, 1).toDouble(),
    );
    final handle = Offset(_cropRect.right, _cropRect.bottom);
    _resizingCrop = (handle - _startCropPoint).distance < 0.1;
  }

  void _updateCropDrag(Offset localPosition, Size size) {
    final point = Offset(
      (localPosition.dx / size.width).clamp(0, 1).toDouble(),
      (localPosition.dy / size.height).clamp(0, 1).toDouble(),
    );
    setState(() {
      if (_resizingCrop) {
        final available = math.min(
          1 - _startCropRect.left,
          1 - _startCropRect.top,
        );
        final requested = math.max(
          point.dx - _startCropRect.left,
          point.dy - _startCropRect.top,
        );
        final side = requested.clamp(0.22, available).toDouble();
        _cropRect = Rect.fromLTWH(
          _startCropRect.left,
          _startCropRect.top,
          side,
          side,
        );
        return;
      }
      final delta = point - _startCropPoint;
      final side = _startCropRect.width;
      final left = (_startCropRect.left + delta.dx)
          .clamp(0, 1 - side)
          .toDouble();
      final top = (_startCropRect.top + delta.dy)
          .clamp(0, 1 - side)
          .toDouble();
      _cropRect = Rect.fromLTWH(left, top, side, side);
    });
  }

  Future<Uint8List> _exportEditBytes() async {
    await WidgetsBinding.instance.endOfFrame;
    final boundary =
        _editPreviewKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) throw StateError('Preview not ready');
    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (byteData == null) throw StateError('Could not export edit');
    return byteData.buffer.asUint8List();
  }

  Uint8List _exportCropBytes() {
    final decoded = img.decodeImage(_workingImageBytes);
    if (decoded == null) throw StateError('Could not read crop image');
    final left = (_cropRect.left * decoded.width).round();
    final top = (_cropRect.top * decoded.height).round();
    final side = (_cropRect.width * math.min(decoded.width, decoded.height))
        .round()
        .clamp(1, math.min(decoded.width - left, decoded.height - top))
        .toInt();
    final cropped = img.copyCrop(
      decoded,
      x: left.clamp(0, decoded.width - 1).toInt(),
      y: top.clamp(0, decoded.height - 1).toInt(),
      width: side,
      height: side,
    );
    return Uint8List.fromList(img.encodePng(cropped));
  }

  Uint8List _exportCutBytes() {
    final decoded = img.decodeImage(_workingImageBytes);
    final canvasSize = _editPreviewKey.currentContext?.size;
    if (decoded == null || canvasSize == null) {
      throw StateError('Could not read cut image');
    }
    final edited = decoded.clone();
    int mapX(Offset point) =>
        (point.dx / canvasSize.width * edited.width)
            .round()
            .clamp(0, edited.width - 1)
            .toInt();
    int mapY(Offset point) =>
        (point.dy / canvasSize.height * edited.height)
            .round()
            .clamp(0, edited.height - 1)
            .toInt();
    final mask = Uint8List(edited.width * edited.height);
    final maskedPixels = <int>[];

    void markPixel(int x, int y) {
      if (x < 0 || y < 0 || x >= edited.width || y >= edited.height) return;
      final index = y * edited.width + x;
      if (mask[index] == 1) return;
      mask[index] = 1;
      maskedPixels.add(index);
    }

    void markCircle(int cx, int cy, int radius) {
      final radiusSquared = radius * radius;
      for (var y = cy - radius; y <= cy + radius; y++) {
        for (var x = cx - radius; x <= cx + radius; x++) {
          final dx = x - cx;
          final dy = y - cy;
          if (dx * dx + dy * dy <= radiusSquared) markPixel(x, y);
        }
      }
    }

    void markLine(Offset start, Offset end, int radius) {
      final x1 = mapX(start);
      final y1 = mapY(start);
      final x2 = mapX(end);
      final y2 = mapY(end);
      final steps = math.max((x2 - x1).abs(), (y2 - y1).abs()).clamp(1, 4096);
      for (var i = 0; i <= steps; i++) {
        final t = i / steps;
        markCircle(
          (x1 + (x2 - x1) * t).round(),
          (y1 + (y2 - y1) * t).round(),
          radius,
        );
      }
    }

    bool pointInPolygon(int x, int y, List<img.Point> polygon) {
      var inside = false;
      var j = polygon.length - 1;
      for (var i = 0; i < polygon.length; i++) {
        final pi = polygon[i];
        final pj = polygon[j];
        final intersects =
            ((pi.yi > y) != (pj.yi > y)) &&
            (x <
                (pj.xi - pi.xi) *
                        (y - pi.yi) /
                        ((pj.yi - pi.yi) == 0 ? 1 : pj.yi - pi.yi) +
                    pi.xi);
        if (intersects) inside = !inside;
        j = i;
      }
      return inside;
    }

    void markPolygon(List<img.Point> polygon) {
      final minX = polygon.map((point) => point.xi).reduce(math.min);
      final maxX = polygon.map((point) => point.xi).reduce(math.max);
      final minY = polygon.map((point) => point.yi).reduce(math.min);
      final maxY = polygon.map((point) => point.yi).reduce(math.max);
      for (var y = minY; y <= maxY; y++) {
        for (var x = minX; x <= maxX; x++) {
          if (pointInPolygon(x, y, polygon)) markPixel(x, y);
        }
      }
    }

    if (_cutMode == _CutMode.lasso && _cutPoints.length > 2) {
      markPolygon([
        for (final point in _cutPoints) img.Point(mapX(point), mapY(point)),
      ]);
    } else if (_cutMode == _CutMode.line && _cutPoints.length > 1) {
      final radius = (_cutBrushSize * edited.width / canvasSize.width / 2)
          .round()
          .clamp(2, 80)
          .toInt();
      markLine(_cutPoints.first, _cutPoints.last, radius);
    } else {
      final radius = (_cutBrushSize * edited.width / canvasSize.width / 2)
          .round()
          .clamp(2, 80)
          .toInt();
      for (final point in _cutPoints) {
        markCircle(mapX(point), mapY(point), radius);
      }
    }

    img.Color sampleFillColor(int x, int y) {
      const directions = [
        Offset(1, 0),
        Offset(-1, 0),
        Offset(0, 1),
        Offset(0, -1),
        Offset(1, 1),
        Offset(-1, 1),
        Offset(1, -1),
        Offset(-1, -1),
      ];
      for (var radius = 1; radius <= 42; radius++) {
        var red = 0.0;
        var green = 0.0;
        var blue = 0.0;
        var alpha = 0.0;
        var count = 0;
        for (final direction in directions) {
          final sx = (x + direction.dx * radius).round();
          final sy = (y + direction.dy * radius).round();
          if (sx < 0 || sy < 0 || sx >= edited.width || sy >= edited.height) {
            continue;
          }
          final sampleIndex = sy * edited.width + sx;
          if (mask[sampleIndex] == 1) continue;
          final pixel = decoded.getPixel(sx, sy);
          red += pixel.r;
          green += pixel.g;
          blue += pixel.b;
          alpha += pixel.a;
          count++;
        }
        if (count > 0) {
          return img.ColorRgba8(
            (red / count).round(),
            (green / count).round(),
            (blue / count).round(),
            (alpha / count).round(),
          );
        }
      }
      return decoded.getPixel(x, y);
    }

    for (final index in maskedPixels) {
      final x = index % edited.width;
      final y = index ~/ edited.width;
      edited.setPixel(x, y, sampleFillColor(x, y));
    }

    return Uint8List.fromList(img.encodePng(edited));
  }

  Uint8List _exportTransformBytes() {
    final decoded = img.decodeImage(_workingImageBytes);
    if (decoded == null) throw StateError('Could not transform image');
    var edited = decoded.clone();
    if (_mirrored) {
      edited = img.flipHorizontal(edited);
    }
    if (_rotationTurns != 0) {
      edited = img.copyRotate(edited, angle: _rotationTurns * 90);
    }
    return Uint8List.fromList(img.encodePng(edited));
  }

  Uint8List _exportDrawBytes() {
    final decoded = img.decodeImage(_workingImageBytes);
    final canvasSize = _editPreviewKey.currentContext?.size;
    if (decoded == null || canvasSize == null) {
      throw StateError('Could not draw on image');
    }
    final edited = decoded.clone();
    int mapX(Offset point) =>
        (point.dx / canvasSize.width * edited.width)
            .round()
            .clamp(0, edited.width - 1)
            .toInt();
    int mapY(Offset point) =>
        (point.dy / canvasSize.height * edited.height)
            .round()
            .clamp(0, edited.height - 1)
            .toInt();
    final color = img.ColorRgba8(_color.red, _color.green, _color.blue, 235);
    for (var i = 1; i < _drawPoints.length; i++) {
      img.drawLine(
        edited,
        x1: mapX(_drawPoints[i - 1]),
        y1: mapY(_drawPoints[i - 1]),
        x2: mapX(_drawPoints[i]),
        y2: mapY(_drawPoints[i]),
        color: color,
        thickness: math.max(2, (edited.width * 0.012).round()),
      );
    }
    return Uint8List.fromList(img.encodePng(edited));
  }

  Future<void> _commitActiveTool() async {
    Uint8List? committedBytes;
    if (_tool == _EditTool.crop && _cropTouched) {
      committedBytes = _exportCropBytes();
    } else if (_tool == _EditTool.cut && _cutPoints.length > 1) {
      committedBytes = _cutPreviewBytes ?? _exportCutBytes();
    } else if ((_tool == _EditTool.rotate || _tool == _EditTool.mirror) &&
        _transformTouched) {
      committedBytes = _exportTransformBytes();
    } else if (_tool == _EditTool.draw && _drawTouched) {
      committedBytes = _exportDrawBytes();
    }

    if (committedBytes == null) return;
    setState(() {
      _workingImageBytes = committedBytes!;
      _cropRect = const Rect.fromLTWH(0.15, 0.08, 0.7, 0.7);
      _rotationTurns = 0;
      _mirrored = false;
      _cutPoints.clear();
      _drawPoints.clear();
      _cropTouched = false;
      _transformTouched = false;
      _drawTouched = false;
      _clearLiveCutPreview();
    });
  }

  Future<void> _changeTool(_EditTool nextTool) async {
    if (_tool == nextTool) return;
    await _commitActiveTool();
    if (!mounted) return;
    setState(() => _tool = nextTool);
  }

  Future<void> _download() async {
    try {
      await _commitActiveTool();
      final bytes = _workingImageBytes;
      await Gal.putImageBytes(
        bytes,
        name: 'salon_edit_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved edit to gallery')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not download edit')),
      );
    }
  }

  Future<void> _applyEdit() async {
    await _commitActiveTool();
    if (_tool == _EditTool.color) {
      Navigator.pop(
        context,
        _EditorResult(imageBytes: _workingImageBytes, modelColor: _color),
      );
      return;
    }
    try {
      final bytes = _workingImageBytes;
      if (!mounted) return;
      Navigator.pop(
        context,
        _EditorResult(imageBytes: bytes),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save edit preview')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff151719),
      appBar: AppBar(
        backgroundColor: const Color(0xff151719),
        foregroundColor: Colors.white,
        title: Text(_toolLabel(_tool)),
        actions: [
          IconButton(
            tooltip: 'Undo',
            icon: const Icon(Icons.undo),
            onPressed: _undoStack.isEmpty ? null : _undo,
          ),
          IconButton(
            tooltip: 'Redo',
            icon: const Icon(Icons.redo),
            onPressed: _redoStack.isEmpty ? null : _redo,
          ),
          IconButton(
            tooltip: 'Download',
            icon: const Icon(Icons.file_download_outlined),
            onPressed: _download,
          ),
          IconButton(
            tooltip: 'Save',
            icon: const Icon(Icons.check),
            onPressed: _applyEdit,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xff0f1113),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: GestureDetector(
                          onPanStart:
                              _tool == _EditTool.cut ||
                                  _tool == _EditTool.draw ||
                                  _tool == _EditTool.crop
                              ? (details) {
                                  final size =
                                      _editPreviewKey.currentContext?.size;
                                  if (_tool == _EditTool.crop && size != null) {
                                    _startCropDrag(
                                      details.localPosition,
                                      size,
                                    );
                                    return;
                                  }
                                  if (_tool == _EditTool.cut) {
                                    _startCutPath(details.localPosition);
                                    return;
                                  }
                                  _recordEdit();
                                  setState(
                                    () {
                                      _drawTouched = true;
                                      _drawPoints.add(details.localPosition);
                                    },
                                  );
                                }
                              : null,
                          onPanUpdate:
                              _tool == _EditTool.cut ||
                                  _tool == _EditTool.draw ||
                                  _tool == _EditTool.crop
                              ? (details) {
                                  final size =
                                      _editPreviewKey.currentContext?.size;
                                  if (_tool == _EditTool.crop && size != null) {
                                    _updateCropDrag(
                                      details.localPosition,
                                      size,
                                    );
                                    return;
                                  }
                                  if (_tool == _EditTool.cut) {
                                    _updateCutPath(details.localPosition);
                                    return;
                                  }
                                  setState(
                                    () {
                                      _drawTouched = true;
                                      _drawPoints.add(details.localPosition);
                                    },
                                  );
                                }
                              : null,
                          onPanEnd: _tool == _EditTool.cut
                              ? (_) => _refreshLiveCutPreview()
                              : null,
                          onPanCancel: _tool == _EditTool.cut
                              ? () => _refreshLiveCutPreview()
                              : null,
                          child: RepaintBoundary(
                            key: _editPreviewKey,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Container(color: Colors.black),
                                  ClipRect(
                                    child: RotatedBox(
                                      quarterTurns: _rotationTurns,
                                      child: Transform(
                                        alignment: Alignment.center,
                                        transform: Matrix4.identity()
                                          ..scale(
                                            _mirrored ? -1.0 : 1.0,
                                            1.0,
                                          ),
                                        child: _EditedImagePreview(
                                          imageBytes:
                                              _tool == _EditTool.cut &&
                                                  _cutPreviewBytes != null
                                              ? _cutPreviewBytes!
                                              : _workingImageBytes,
                                          colorPreview: _tool == _EditTool.color
                                              ? _color
                                              : null,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (_tool == _EditTool.crop)
                                    CustomPaint(
                                      painter: _CropOverlayPainter(_cropRect),
                                    ),
                                  if (_tool == _EditTool.cut)
                                    CustomPaint(
                                      painter: _CutPreviewPainter(
                                        points: _cutPoints,
                                        mode: _cutMode,
                                        brushSize: _cutBrushSize,
                                        showMask: _cutPreviewBytes == null,
                                      ),
                                    ),
                                  if (_tool == _EditTool.draw)
                                    CustomPaint(
                                      painter: _DrawPreviewPainter(
                                        _drawPoints,
                                        _color,
                                      ),
                                    ),
                                  Positioned(
                                    left: 10,
                                    bottom: 10,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withAlpha(150),
                                        borderRadius: BorderRadius.circular(
                                          100,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        child: Text(
                                          _toolHint,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _EditControlsPanel(
              tool: _tool,
              cropRect: _cropRect,
              rotationTurns: _rotationTurns,
              mirrored: _mirrored,
              color: _color,
              cutMode: _cutMode,
              cutBrushSize: _cutBrushSize,
              onRotate: () {
                _recordEdit();
                setState(() {
                  _transformTouched = true;
                  _rotationTurns = (_rotationTurns + 1) % 4;
                });
              },
              onMirror: () {
                _recordEdit();
                setState(() {
                  _transformTouched = true;
                  _mirrored = !_mirrored;
                });
              },
              onColorChanged: (value) {
                _recordEdit();
                setState(() => _color = value);
              },
              onCutModeChanged: (value) {
                _recordEdit();
                setState(() {
                  _cutMode = value;
                  _cutPoints.clear();
                  _clearLiveCutPreview();
                });
              },
              onCutBrushSizeChanged: (value) {
                setState(() => _cutBrushSize = value);
              },
              onClearCut: () {
                _recordEdit();
                setState(() {
                  _cutPoints.clear();
                  _clearLiveCutPreview();
                });
              },
              onClearDraw: () {
                _recordEdit();
                setState(() {
                  _drawPoints.clear();
                  _drawTouched = false;
                });
              },
            ),
            Container(
              color: const Color(0xff202326),
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _EditToolTab(
                      icon: Icons.gesture,
                      label: 'Cut',
                      selected: _tool == _EditTool.cut,
                      onTap: () {
                        _changeTool(_EditTool.cut);
                      },
                    ),
                    _EditToolTab(
                      icon: Icons.crop,
                      label: 'Crop',
                      selected: _tool == _EditTool.crop,
                      onTap: () {
                        _changeTool(_EditTool.crop);
                      },
                    ),
                    _EditToolTab(
                      icon: Icons.rotate_right,
                      label: 'Rotate',
                      selected: _tool == _EditTool.rotate,
                      onTap: () {
                        _changeTool(_EditTool.rotate);
                      },
                    ),
                    _EditToolTab(
                      icon: Icons.flip,
                      label: 'Mirror',
                      selected: _tool == _EditTool.mirror,
                      onTap: () {
                        _changeTool(_EditTool.mirror);
                      },
                    ),
                    _EditToolTab(
                      icon: Icons.palette_outlined,
                      label: 'Color',
                      selected: _tool == _EditTool.color,
                      onTap: () {
                        _changeTool(_EditTool.color);
                      },
                    ),
                    _EditToolTab(
                      icon: Icons.draw_outlined,
                      label: 'Draw',
                      selected: _tool == _EditTool.draw,
                      onTap: () {
                        _changeTool(_EditTool.draw);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _toolHint => switch (_tool) {
    _EditTool.cut => _cutPreviewBytes == null
        ? 'Brush or lasso, then release to preview'
        : 'Removal preview applied',
    _EditTool.crop => 'Zoom crop the image',
    _EditTool.rotate => 'Rotate the image',
    _EditTool.mirror => 'Flip the image horizontally',
    _EditTool.color => 'Color preview is visible here',
    _EditTool.draw => 'Draw over the image',
  };
}

class _EditedImagePreview extends StatelessWidget {
  final Uint8List imageBytes;
  final Color? colorPreview;

  const _EditedImagePreview({required this.imageBytes, this.colorPreview});

  @override
  Widget build(BuildContext context) {
    final image = Image.memory(imageBytes, fit: BoxFit.contain);
    final color = colorPreview;
    if (color == null) return image;
    return Stack(
      fit: StackFit.expand,
      children: [
        image,
        IgnorePointer(
          child: Opacity(
            opacity: 0.24,
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(color, BlendMode.softLight),
              child: image,
            ),
          ),
        ),
      ],
    );
  }
}

class _EditControlsPanel extends StatelessWidget {
  final _EditTool tool;
  final Rect cropRect;
  final int rotationTurns;
  final bool mirrored;
  final Color color;
  final _CutMode cutMode;
  final double cutBrushSize;
  final VoidCallback onRotate;
  final VoidCallback onMirror;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<_CutMode> onCutModeChanged;
  final ValueChanged<double> onCutBrushSizeChanged;
  final VoidCallback onClearCut;
  final VoidCallback onClearDraw;

  const _EditControlsPanel({
    required this.tool,
    required this.cropRect,
    required this.rotationTurns,
    required this.mirrored,
    required this.color,
    required this.cutMode,
    required this.cutBrushSize,
    required this.onRotate,
    required this.onMirror,
    required this.onColorChanged,
    required this.onCutModeChanged,
    required this.onCutBrushSizeChanged,
    required this.onClearCut,
    required this.onClearDraw,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xff202326),
      padding: const EdgeInsets.all(12),
      child: switch (tool) {
        _EditTool.cut => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<_CutMode>(
                segments: const [
                  ButtonSegment(
                    value: _CutMode.brush,
                    icon: Icon(Icons.brush_outlined),
                    label: Text('Brush'),
                  ),
                  ButtonSegment(
                    value: _CutMode.lasso,
                    icon: Icon(Icons.gesture),
                    label: Text('Lasso'),
                  ),
                  ButtonSegment(
                    value: _CutMode.line,
                    icon: Icon(Icons.show_chart),
                    label: Text('Line'),
                  ),
                ],
                selected: {cutMode},
                onSelectionChanged: (value) =>
                    onCutModeChanged(value.first),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      cutMode == _CutMode.brush
                          ? 'Brush over the area you want to remove'
                          : cutMode == _CutMode.lasso
                          ? 'Draw around an area to cut it out'
                          : 'Drag once to mark a straight cut',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  TextButton(onPressed: onClearCut, child: const Text('Clear')),
                ],
              ),
              if (cutMode == _CutMode.brush) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const SizedBox(
                      width: 76,
                      child: Text(
                        'Brush',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    Expanded(
                      child: Slider(
                        value: cutBrushSize,
                        min: 12,
                        max: 72,
                        onChanged: onCutBrushSizeChanged,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        _EditTool.crop => Row(
            children: [
              const Expanded(
                child: Text(
                  'Drag the square to move it. Drag the corner dot to resize.',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              Text(
                '${(cropRect.width * 100).round()}%',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        _EditTool.rotate => Row(
            children: [
              Expanded(
                child: Text(
                  'Rotation: ${rotationTurns * 90} deg',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              FilledButton.icon(
                onPressed: onRotate,
                icon: const Icon(Icons.rotate_right),
                label: const Text('Rotate'),
              ),
            ],
          ),
        _EditTool.mirror => Row(
            children: [
              Expanded(
                child: Text(
                  mirrored ? 'Mirror is on' : 'Mirror is off',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              FilledButton.icon(
                onPressed: onMirror,
                icon: const Icon(Icons.flip),
                label: const Text('Mirror'),
              ),
            ],
          ),
        _EditTool.color => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Model color applies to hair, beard, nail, or mehndi after Save.',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  Color(0xff17110d),
                  Color(0xff6b3f2a),
                  Color(0xff8b1620),
                  Color(0xffd9778f),
                  Color(0xff7b3f22),
                ]
                    .map(
                      (item) => ChoiceChip(
                        label: CircleAvatar(backgroundColor: item, radius: 9),
                        selected: item == color,
                        onSelected: (_) => onColorChanged(item),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        _EditTool.draw => Row(
            children: [
              const Expanded(
                child: Text(
                  'Draw on the image with the selected color',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              TextButton(onPressed: onClearDraw, child: const Text('Clear')),
            ],
          ),
      },
    );
  }
}

class _EditToolTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _EditToolTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: SizedBox(
        width: 68,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              color: selected ? Colors.white.withAlpha(34) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 21),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CropOverlayPainter extends CustomPainter {
  final Rect cropRect;

  const _CropOverlayPainter(this.cropRect);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      cropRect.left * size.width,
      cropRect.top * size.height,
      cropRect.width * size.width,
      cropRect.height * size.height,
    );
    final shade = Paint()..color = Colors.black.withAlpha(95);
    final path = Path()
      ..addRect(Offset.zero & size)
      ..addRect(rect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, shade);
    final line = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(rect, line);
    final grid = Paint()
      ..color = Colors.white.withAlpha(120)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (final fraction in [1 / 3, 2 / 3]) {
      canvas.drawLine(
        Offset(rect.left + rect.width * fraction, rect.top),
        Offset(rect.left + rect.width * fraction, rect.bottom),
        grid,
      );
      canvas.drawLine(
        Offset(rect.left, rect.top + rect.height * fraction),
        Offset(rect.right, rect.top + rect.height * fraction),
        grid,
      );
    }
    canvas.drawCircle(
      rect.bottomRight,
      8,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      rect.bottomRight,
      4,
      Paint()..color = const Color(0xff0f6fb7),
    );
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter oldDelegate) {
    return oldDelegate.cropRect != cropRect;
  }
}

class _CutPreviewPainter extends CustomPainter {
  final List<Offset> points;
  final _CutMode mode;
  final double brushSize;
  final bool showMask;

  const _CutPreviewPainter({
    required this.points,
    required this.mode,
    required this.brushSize,
    required this.showMask,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!showMask) return;
    if (points.length < 2) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    if (mode == _CutMode.lasso && points.length > 3) {
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xffff2f4a).withAlpha(92)
          ..style = PaintingStyle.fill,
      );
    }
    final maskPaint = Paint()
      ..color = const Color(0xffff2f4a).withAlpha(155)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = mode == _CutMode.brush
          ? brushSize
          : size.shortestSide * 0.035;
    final edgePaint = Paint()
      ..color = Colors.white.withAlpha(220)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = size.shortestSide * 0.012;
    canvas.drawPath(path, maskPaint);
    canvas.drawPath(path, edgePaint);
  }

  @override
  bool shouldRepaint(covariant _CutPreviewPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.mode != mode ||
        oldDelegate.brushSize != brushSize ||
        oldDelegate.showMask != showMask;
  }
}

class _DrawPreviewPainter extends CustomPainter {
  final List<Offset> points;
  final Color color;

  const _DrawPreviewPainter(this.points, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final paint = Paint()
      ..color = color.withAlpha(230)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = size.shortestSide * 0.018;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DrawPreviewPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.color != color;
  }
}

class _ThreeDTryOnPreview extends StatelessWidget {
  final ThreeDModel model;
  final String styleName;
  final Color? previewColor;
  final bool enableViewer;
  final Uint8List? photo;
  final String? generatedModelUrl;

  const _ThreeDTryOnPreview({
    required this.model,
    required this.styleName,
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
                      styleName: styleName,
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
                    styleName: styleName,
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
                              ? styleName
                              : 'AI result: $styleName',
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
  final String styleName;
  final Color color;
  final bool enableViewer;
  final Uint8List? photo;
  final String? generatedModelUrl;

  const _ThreeDPreviewBody({
    required this.model,
    required this.styleName,
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
                child: photo == null
                    ? _ThreeDViewerFallback(model: model, color: color)
                    : _PremiumPhotoPreview(
                        photo: photo!,
                        color: color,
                        styleName: styleName,
                        generated: generatedModelUrl != null,
                      ),
              ),
              const SizedBox(height: 8),
              _ThreeDPreviewNotes(
                styleName: styleName,
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

class _PremiumPhotoPreview extends StatelessWidget {
  final Uint8List photo;
  final Color color;
  final String styleName;
  final bool generated;

  const _PremiumPhotoPreview({
    required this.photo,
    required this.color,
    required this.styleName,
    required this.generated,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(photo, fit: BoxFit.cover),
          if (!generated)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withAlpha(42),
                    Colors.transparent,
                    Colors.black.withAlpha(86),
                  ],
                ),
              ),
            ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 10,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(135),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                child: Row(
                  children: [
                    Icon(
                      generated ? Icons.auto_awesome : Icons.image_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        generated
                            ? 'AI result ready'
                            : 'Photo ready for $styleName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreeDPreviewNotes extends StatelessWidget {
  final String styleName;
  final bool photoReady;
  final bool viewerEnabled;
  final String? generatedModelUrl;

  const _ThreeDPreviewNotes({
    required this.styleName,
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
                  ? 'Photo attached. Selected: $styleName'
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

class _Premium3DCard extends StatelessWidget {
  final String styleName;
  final bool unlocked;
  final VoidCallback onUnlock;

  const _Premium3DCard({
    required this.styleName,
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
              '$styleName is selected. In development, mock mode returns a test response. When fal.ai credits are available, Nano Banana edits the uploaded photo for a realistic blended result.',
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
                _PremiumPill(label: 'AI Mehndi'),
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

class _ModelCard extends StatelessWidget {
  final TryOnStyle style;
  final bool selected;
  final VoidCallback onTap;
  final bool locked;

  const _ModelCard({
    required this.style,
    required this.selected,
    required this.onTap,
    required this.locked,
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
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _StyleImage(style: style, colorOverride: null),
                  if (locked)
                    const Align(
                      alignment: Alignment.topLeft,
                      child: _CardBadge(
                        icon: Icons.lock_outline,
                        label: 'Pro',
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Expanded(
                  child: Text(
                    style.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Tooltip(
                  triggerMode: TooltipTriggerMode.tap,
                  showDuration: const Duration(seconds: 3),
                  message: _styleTooltip(style, locked),
                  child: const Padding(
                    padding: EdgeInsets.all(3),
                    child: Icon(Icons.info_outline, size: 17),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _styleTooltip(TryOnStyle style, bool locked) {
    final category = switch (style.category) {
      TryOnCategory.hairstyle => 'Hair style',
      TryOnCategory.beard => 'Beard style',
      TryOnCategory.nailArt => 'Nail design',
      TryOnCategory.tattoo => 'Tattoo design',
      TryOnCategory.mehndi => 'Mehndi design',
    };
    final mode = locked
        ? 'Available for 2D preview and Premium AI render.'
        : 'Instant 2D overlay preview.';
    return '$category: ${style.name}\n$mode';
  }
}

class _CardBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _CardBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(6),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(150),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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

class _MehndiPhotoGuide extends StatelessWidget {
  final VoidCallback onReset;

  const _MehndiPhotoGuide({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xfffff0e5),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.draw_outlined, size: 30),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'For mehndi: use a clear palm, back-hand, or wrist photo. '
                'Drag, pinch, and rotate the design until it sits naturally.',
              ),
            ),
            IconButton(
              onPressed: onReset,
              tooltip: 'Reset mehndi position',
              icon: const Icon(Icons.restart_alt),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultPreview extends StatefulWidget {
  final Uint8List? photo;
  final Uint8List? editedResultBytes;
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
  final Color? modelColorOverride;
  final double scale;
  final double rotation;
  final ValueChanged<ScaleStartDetails> onGestureStart;
  final ValueChanged<ScaleUpdateDetails> onGestureUpdate;
  final void Function(int index, ScaleStartDetails details) onNailGestureStart;
  final ValueChanged<ScaleUpdateDetails> onNailGestureUpdate;
  final void Function(int index, Offset delta) onNailDrag;
  final VoidCallback onChoosePhoto;
  final VoidCallback onOpenFullScreen;
  final VoidCallback onDownload;
  final VoidCallback onShare;
  final VoidCallback onEditWithAi;
  final VoidCallback onDelete;

  const _ResultPreview({
    required this.photo,
    required this.editedResultBytes,
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
    required this.modelColorOverride,
    required this.scale,
    required this.rotation,
    required this.onGestureStart,
    required this.onGestureUpdate,
    required this.onNailGestureStart,
    required this.onNailGestureUpdate,
    required this.onNailDrag,
    required this.onChoosePhoto,
    required this.onOpenFullScreen,
    required this.onDownload,
    required this.onShare,
    required this.onEditWithAi,
    required this.onDelete,
  });

  @override
  State<_ResultPreview> createState() => _ResultPreviewState();
}

class _ResultPreviewState extends State<_ResultPreview> {
  bool _showActions = false;

  void _setActionsVisible(bool value) {
    if (_showActions == value) return;
    setState(() => _showActions = value);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.editedResultBytes != null) {
      return MouseRegion(
        onEnter: (_) => _setActionsVisible(true),
        onExit: (_) => _setActionsVisible(false),
        child: GestureDetector(
          onTap: widget.onOpenFullScreen,
          onLongPress: () => _setActionsVisible(true),
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                Image.memory(widget.editedResultBytes!, fit: BoxFit.contain),
                if (_showActions)
                  _PreviewActionOverlay(
                    onDownload: widget.onDownload,
                    onShare: widget.onShare,
                    onEditWithAi: widget.onEditWithAi,
                    onDelete: widget.onDelete,
                  ),
              ],
            ),
          ),
        ),
      );
    }
    if (widget.photo == null || widget.photoSize == null) {
      return Card(
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: Center(
            child: FilledButton.tonalIcon(
              onPressed: widget.onChoosePhoto,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Upload photo'),
            ),
          ),
        ),
      );
    }
    return MouseRegion(
      onEnter: (_) => _setActionsVisible(true),
      onExit: (_) => _setActionsVisible(false),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: AspectRatio(
          aspectRatio: widget.photoSize!.width / widget.photoSize!.height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final viewSize = constraints.biggest;
              final placement = _placement(viewSize);
              final isNailMode = widget.category == TryOnCategory.nailArt;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onOpenFullScreen,
                onLongPress: () => _setActionsVisible(true),
                onScaleStart: placement == null || isNailMode
                    ? null
                    : widget.onGestureStart,
                onScaleUpdate: placement == null || isNailMode
                    ? null
                    : widget.onGestureUpdate,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(widget.photo!, fit: BoxFit.fill),
                    if (isNailMode && widget.overlayVisible)
                      ..._buildNailOverlays(viewSize)
                    else if (widget.overlayVisible && placement != null)
                      Positioned(
                        left: placement.center.dx - placement.width / 2,
                        top: placement.center.dy - placement.height / 2,
                        width: placement.width,
                        height: placement.height,
                        child: IgnorePointer(
                          child: Opacity(
                            opacity: widget.overlayOpacity,
                            child: Transform.rotate(
                              angle: placement.rotation,
                              child: _StyleImage(
                                style: widget.style,
                                colorOverride: widget.modelColorOverride,
                              ),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Chip(label: Text('Result: ${widget.style.name}')),
                    ),
                    if (_showActions)
                      _PreviewActionOverlay(
                        onDownload: widget.onDownload,
                        onShare: widget.onShare,
                        onEditWithAi: widget.onEditWithAi,
                        onDelete: widget.onDelete,
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  _Placement? _placement(Size viewSize) {
    final imageScale = viewSize.width / widget.photoSize!.width;
    if (widget.category == TryOnCategory.nailArt) {
      return _Placement(
        center: Offset(viewSize.width * 0.5, viewSize.height * 0.45),
        width: viewSize.width,
        height: viewSize.height,
        rotation: widget.rotation,
      );
    }
    if (widget.category == TryOnCategory.tattoo ||
        widget.category == TryOnCategory.mehndi) {
      final detectedPose = widget.pose;
      if (detectedPose != null) {
        final overlay = widget.renderer.calculateTattooOverlayFromPose(
          detectedPose,
        );
        if (overlay != null) {
          return _Placement(
            center: overlay.center * imageScale + widget.adjustment,
            width:
                overlay.width *
                imageScale *
                widget.scale *
                widget.style.size *
                widget.style.widthFactor,
            height:
                overlay.height *
                imageScale *
                widget.scale *
                widget.style.size *
                widget.style.heightFactor,
            rotation: overlay.rotation + widget.rotation,
          );
        }
      }
      final baseWidth = widget.category == TryOnCategory.mehndi ? 0.38 : 0.42;
      final baseTop = widget.category == TryOnCategory.mehndi ? 0.5 : 0.52;
      return _Placement(
        center:
            Offset(viewSize.width * 0.5, viewSize.height * baseTop) +
            widget.adjustment,
        width:
            viewSize.width *
            baseWidth *
            widget.scale *
            widget.style.size *
            widget.style.widthFactor,
        height:
            viewSize.width *
            baseWidth *
            widget.scale *
            widget.style.size *
            widget.style.heightFactor,
        rotation: widget.rotation,
      );
    }
    if (widget.category == TryOnCategory.beard) {
      final mesh = widget.faceMesh;
      final detectedFace = widget.face;
      if (mesh == null && detectedFace == null) {
        return _Placement(
          center:
              Offset(viewSize.width * 0.5, viewSize.height * 0.58) +
              widget.adjustment,
          width: viewSize.width * 0.34 * widget.scale * widget.style.size,
          height: viewSize.width * 0.22 * widget.scale * widget.style.size,
          rotation: widget.rotation,
        );
      }
      final overlay = mesh != null
          ? widget.renderer.calculateBeardOverlayFromMesh(mesh)
          : widget.renderer.calculateBeardOverlay(detectedFace!);
      return _Placement(
        center: overlay.center * imageScale + widget.adjustment,
        width: overlay.width * imageScale * widget.scale * widget.style.size,
        height: overlay.height * imageScale * widget.scale * widget.style.size,
        rotation: -overlay.rotation + widget.rotation,
      );
    }
    final mesh = widget.faceMesh;
    final detectedFace = widget.face;
    if (mesh == null && detectedFace == null) {
      return _Placement(
        center:
            Offset(viewSize.width * 0.5, viewSize.height * 0.28) +
            widget.adjustment,
        width:
            viewSize.width *
            0.52 *
            widget.scale *
            widget.style.size *
            widget.style.widthFactor,
        height:
            viewSize.width *
            0.42 *
            widget.scale *
            widget.style.size *
            widget.style.heightFactor,
        rotation: widget.rotation,
      );
    }
    final overlay = mesh != null
        ? widget.renderer.calculateHairstyleOverlayFromMesh(mesh)
        : widget.renderer.calculateHairstyleOverlay(detectedFace!);
    return _Placement(
      center:
          overlay.center * imageScale +
          Offset(
            0,
            overlay.height * imageScale * widget.style.verticalOffsetFactor,
          ) +
          widget.adjustment,
      width:
          overlay.width *
          imageScale *
          widget.scale *
          widget.style.size *
          widget.style.widthFactor,
      height:
          overlay.height *
          imageScale *
          widget.scale *
          widget.style.size *
          widget.style.heightFactor,
      rotation: -overlay.rotation + widget.rotation,
    );
  }

  List<Widget> _buildNailOverlays(Size viewSize) {
    return List.generate(widget.nailAnchors.length, (index) {
      final anchor = widget.nailAnchors[index];
      final transform = widget.nailTransforms[index];
      final width =
          viewSize.width * anchor.width * transform.scale * widget.style.size;
      final height =
          viewSize.height * anchor.height * transform.scale * widget.style.size;
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
          onPointerMove: (event) => widget.onNailDrag(index, event.delta),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onScaleStart: (details) =>
                widget.onNailGestureStart(index, details),
            onScaleUpdate: widget.onNailGestureUpdate,
            child: Center(
              child: SizedBox(
                width: width,
                height: height,
                child: Opacity(
                  opacity: widget.overlayOpacity,
                  child: Transform.rotate(
                    angle: anchor.rotation + transform.rotation,
                    child: _NailPiece(
                      style: widget.style,
                      sourceIndex: index,
                      colorOverride: widget.modelColorOverride,
                    ),
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
  final Color? colorOverride;

  const _NailPiece({
    required this.style,
    required this.sourceIndex,
    required this.colorOverride,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _NailArtPainter(
        designIndex: sourceIndex,
        roseGold: style.tint != null,
        baseColor: colorOverride,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _NailArtPainter extends CustomPainter {
  final int designIndex;
  final bool roseGold;
  final Color? baseColor;

  const _NailArtPainter({
    required this.designIndex,
    required this.roseGold,
    required this.baseColor,
  });

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
    final burgundy = baseColor ?? (roseGold
        ? const Color(0xffc87878)
        : const Color(0xff7d0509));
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
        oldDelegate.roseGold != roseGold ||
        oldDelegate.baseColor != baseColor;
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
  final Color? colorOverride;

  const _StyleImage({required this.style, required this.colorOverride});

  @override
  Widget build(BuildContext context) {
    if (style.category == TryOnCategory.mehndi) {
      return CustomPaint(
        painter: _MehndiPainter(
          patternId: style.id,
          color: colorOverride ?? style.tint ?? const Color(0xff6f351c),
        ),
        child: const SizedBox.expand(),
      );
    }
    final image = Image.asset(style.assetPath, fit: BoxFit.contain);
    final tint = colorOverride ?? style.tint;
    if (tint == null) return image;
    return Stack(
      fit: StackFit.expand,
      children: [
        Opacity(
          opacity: 0.42,
          child: image,
        ),
        Image.asset(
          style.assetPath,
          fit: BoxFit.contain,
          color: tint.withAlpha(185),
          colorBlendMode: BlendMode.modulate,
        ),
        Opacity(
          opacity: 0.22,
          child: Image.asset(style.assetPath, fit: BoxFit.contain),
        ),
      ],
    );
  }
}

class _MehndiPainter extends CustomPainter {
  final String patternId;
  final Color color;

  const _MehndiPainter({required this.patternId, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = _paint(size, 0.022);
    final fine = _paint(size, 0.012)..color = color.withAlpha(220);
    final dot = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    switch (patternId) {
      case 'mehndi-arabic':
        _paintArabicVine(canvas, size, stroke, fine, dot);
        break;
      case 'mehndi-arabic-bold':
        _paintArabicVine(canvas, size, stroke, fine, dot, bold: true);
        _drawPaisley(
          canvas,
          Offset(size.width * 0.58, size.height * 0.46),
          size.shortestSide * 0.16,
          stroke,
        );
        break;
      case 'mehndi-arabic-floral':
        _paintArabicVine(canvas, size, stroke, fine, dot);
        _drawFlower(
          canvas,
          Offset(size.width * 0.34, size.height * 0.62),
          size.shortestSide * 0.1,
          fine,
          dot,
        );
        _drawFlower(
          canvas,
          Offset(size.width * 0.62, size.height * 0.34),
          size.shortestSide * 0.085,
          fine,
          dot,
        );
        break;
      case 'mehndi-arabic-wrist':
        _paintWristBand(canvas, size, stroke, fine, dot);
        _paintArabicVine(canvas, size, stroke, fine, dot, wrist: true);
        break;
      case 'mehndi-mandala':
        _paintMandala(
          canvas,
          size,
          size.center(Offset.zero),
          0.24,
          stroke,
          fine,
          dot,
        );
        _paintDotBracelet(canvas, size, fine, dot);
        break;
      case 'mehndi-floral':
        _paintWristBand(canvas, size, stroke, fine, dot);
        break;
      case 'mehndi-finger-vines':
        _paintFingerVines(canvas, size, stroke, fine, dot);
        break;
      case 'mehndi-minimal':
        _paintMinimal(canvas, size, fine, dot);
        break;
      default:
        _paintBridal(canvas, size, stroke, fine, dot);
    }
  }

  Paint _paint(Size size, double widthFactor) {
    return Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = size.shortestSide * widthFactor;
  }

  void _paintMandala(
    Canvas canvas,
    Size size,
    Offset center,
    double radiusFactor,
    Paint stroke,
    Paint fine,
    Paint dot,
  ) {
    final radius = size.shortestSide * radiusFactor;
    for (var ring = 0; ring < 3; ring++) {
      canvas.drawCircle(
        center,
        radius * (1 + ring * 0.34),
        ring == 0 ? stroke : fine,
      );
    }

    for (var i = 0; i < 18; i++) {
      final angle = math.pi * 2 * i / 18;
      final outer =
          center + Offset(math.cos(angle), math.sin(angle)) * radius * 1.7;
      final inner =
          center + Offset(math.cos(angle), math.sin(angle)) * radius * 1.18;
      final petal = Path()
        ..moveTo(inner.dx, inner.dy)
        ..quadraticBezierTo(
          center.dx + math.cos(angle - 0.18) * radius * 1.55,
          center.dy + math.sin(angle - 0.18) * radius * 1.55,
          outer.dx,
          outer.dy,
        )
        ..quadraticBezierTo(
          center.dx + math.cos(angle + 0.18) * radius * 1.55,
          center.dy + math.sin(angle + 0.18) * radius * 1.55,
          inner.dx,
          inner.dy,
        );
      canvas.drawPath(petal, fine);
    }

    for (var i = 0; i < 18; i++) {
      final angle = math.pi * 2 * i / 18;
      final p =
          center + Offset(math.cos(angle), math.sin(angle)) * radius * 2.05;
      canvas.drawCircle(p, size.shortestSide * 0.015, dot);
    }
    canvas.drawCircle(center, size.shortestSide * 0.028, dot);
  }

  void _paintBridal(
    Canvas canvas,
    Size size,
    Paint stroke,
    Paint fine,
    Paint dot,
  ) {
    final center = Offset(size.width * 0.5, size.height * 0.48);
    _paintMandala(canvas, size, center, 0.17, stroke, fine, dot);
    _paintFingerVines(canvas, size, stroke, fine, dot, compact: true);
    _paintWristBand(canvas, size, stroke, fine, dot, low: true);
  }

  void _paintArabicVine(
    Canvas canvas,
    Size size,
    Paint stroke,
    Paint fine,
    Paint dot, {
    bool bold = false,
    bool wrist = false,
  }) {
    final startY = wrist ? 0.72 : 0.82;
    final endY = wrist ? 0.32 : 0.16;
    final path = Path()
      ..moveTo(size.width * 0.2, size.height * startY)
      ..cubicTo(
        size.width * 0.58,
        size.height * (wrist ? 0.62 : 0.72),
        size.width * 0.28,
        size.height * (wrist ? 0.48 : 0.38),
        size.width * 0.76,
        size.height * endY,
      );
    canvas.drawPath(path, stroke);
    if (bold) {
      canvas.drawPath(path.shift(Offset(size.width * 0.025, 0)), fine);
    }

    for (var i = 0; i < 7; i++) {
      final t = i / 6;
      final x = size.width * (0.24 + 0.48 * t);
      final y =
          size.height *
          ((startY - 0.04) -
              (startY - endY - 0.04) * t +
              math.sin(t * math.pi * 2) * 0.08);
      final angle = i.isEven ? -0.65 : 0.55;
      _drawLeaf(
        canvas,
        Offset(x, y),
        size.shortestSide * (bold ? 0.1 : 0.08),
        angle,
        fine,
      );
      if (i.isOdd) {
        _drawPaisley(
          canvas,
          Offset(x + size.width * 0.06, y),
          size.shortestSide * 0.09,
          fine,
        );
      }
    }
  }

  void _paintWristBand(
    Canvas canvas,
    Size size,
    Paint stroke,
    Paint fine,
    Paint dot, {
    bool low = false,
  }) {
    final top = size.height * (low ? 0.72 : 0.58);
    final bottom = top + size.height * 0.18;
    canvas.drawLine(
      Offset(size.width * 0.14, top),
      Offset(size.width * 0.86, top),
      stroke,
    );
    canvas.drawLine(
      Offset(size.width * 0.14, bottom),
      Offset(size.width * 0.86, bottom),
      stroke,
    );
    for (var i = 0; i < 9; i++) {
      final x = size.width * (0.18 + i * 0.08);
      final c = Offset(x, (top + bottom) / 2);
      _drawFlower(canvas, c, size.shortestSide * 0.045, fine, dot);
    }
    _paintMandala(
      canvas,
      size,
      Offset(size.width * 0.5, top - size.height * 0.16),
      0.12,
      stroke,
      fine,
      dot,
    );
  }

  void _paintFingerVines(
    Canvas canvas,
    Size size,
    Paint stroke,
    Paint fine,
    Paint dot, {
    bool compact = false,
  }) {
    final count = compact ? 5 : 6;
    for (var i = 0; i < count; i++) {
      final x = size.width * (0.22 + i * (0.56 / (count - 1)));
      final top = size.height * 0.12;
      final bottom = compact ? size.height * 0.42 : size.height * 0.72;
      final path = Path()
        ..moveTo(x, top)
        ..cubicTo(
          x + size.width * 0.035,
          top + size.height * 0.12,
          x - size.width * 0.035,
          bottom - size.height * 0.14,
          x,
          bottom,
        );
      canvas.drawPath(path, i == 2 ? stroke : fine);
      for (var j = 0; j < 3; j++) {
        final y = top + (bottom - top) * (0.25 + j * 0.22);
        _drawLeaf(
          canvas,
          Offset(x + (j.isEven ? -1 : 1) * size.width * 0.025, y),
          size.shortestSide * 0.045,
          j.isEven ? math.pi : 0,
          fine,
        );
      }
      canvas.drawCircle(
        Offset(x, top - size.height * 0.025),
        size.shortestSide * 0.014,
        dot,
      );
    }
    if (!compact) {
      _paintMandala(
        canvas,
        size,
        Offset(size.width * 0.5, size.height * 0.78),
        0.11,
        stroke,
        fine,
        dot,
      );
    }
  }

  void _paintMinimal(Canvas canvas, Size size, Paint fine, Paint dot) {
    final center = size.center(Offset.zero);
    _drawFlower(canvas, center, size.shortestSide * 0.08, fine, dot);
    for (var i = 0; i < 5; i++) {
      final p = Offset(size.width * (0.28 + i * 0.11), size.height * 0.34);
      canvas.drawCircle(p, size.shortestSide * 0.017, dot);
      canvas.drawLine(
        p + Offset(0, size.height * 0.04),
        p + Offset(0, size.height * 0.16),
        fine,
      );
    }
  }

  void _paintDotBracelet(Canvas canvas, Size size, Paint fine, Paint dot) {
    final y = size.height * 0.78;
    for (var i = 0; i < 13; i++) {
      final x = size.width * (0.2 + i * 0.05);
      canvas.drawCircle(
        Offset(x, y),
        size.shortestSide * (i.isEven ? 0.017 : 0.011),
        dot,
      );
    }
    canvas.drawLine(
      Offset(size.width * 0.18, y),
      Offset(size.width * 0.82, y),
      fine,
    );
  }

  void _drawLeaf(
    Canvas canvas,
    Offset center,
    double length,
    double angle,
    Paint paint,
  ) {
    final direction = Offset(math.cos(angle), math.sin(angle));
    final normal = Offset(-direction.dy, direction.dx);
    final tip = center + direction * length;
    final base = center - direction * length * 0.5;
    final path = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(
        center.dx + normal.dx * length * 0.45,
        center.dy + normal.dy * length * 0.45,
        tip.dx,
        tip.dy,
      )
      ..quadraticBezierTo(
        center.dx - normal.dx * length * 0.45,
        center.dy - normal.dy * length * 0.45,
        base.dx,
        base.dy,
      );
    canvas.drawPath(path, paint);
  }

  void _drawFlower(
    Canvas canvas,
    Offset center,
    double radius,
    Paint fine,
    Paint dot,
  ) {
    for (var i = 0; i < 6; i++) {
      final angle = math.pi * 2 * i / 6;
      _drawLeaf(
        canvas,
        center + Offset(math.cos(angle), math.sin(angle)) * radius * 0.55,
        radius,
        angle,
        fine,
      );
    }
    canvas.drawCircle(center, radius * 0.25, dot);
  }

  void _drawPaisley(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..cubicTo(
        center.dx + radius,
        center.dy - radius * 0.7,
        center.dx + radius * 0.9,
        center.dy + radius * 0.6,
        center.dx,
        center.dy + radius,
      )
      ..cubicTo(
        center.dx - radius * 0.8,
        center.dy + radius * 0.4,
        center.dx - radius * 0.2,
        center.dy - radius * 0.2,
        center.dx + radius * 0.35,
        center.dy - radius * 0.25,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MehndiPainter oldDelegate) {
    return oldDelegate.patternId != patternId || oldDelegate.color != color;
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
